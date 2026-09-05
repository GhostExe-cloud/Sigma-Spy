--[[
	Sigma Spy v12.0.1 - STANDALONE BUILD
	Written by depso
	Discord: https://discord.gg/bkUkm2vSbv
	GitHub: https://github.com/depthso/Sigma-Spy
]]

--// Base Configuration
local Configuration = {
	UseWorkspace = false,
	NoActors = false,
	FolderName = "Sigma Spy",
	RepoUrl = "https://raw.githubusercontent.com/depthso/Sigma-Spy/main",
	ParserUrl = "https://raw.githubusercontent.com/xfwil/Roblox-parser/main/dist/Main.luau"
}

print("[Sigma Spy] v12.0.1 - Standalone Build - Loaded")

--// Service handler
local Services = setmetatable({}, {
	__index = function(self, Name: string): Instance
		local Service = game:GetService(Name)
		return cloneref(Service)
	end,
})

--// Files module (inline)
local Files = (function()
	type table = {
		[any]: any
	}

	local Files = {
		UseWorkspace = false,
		Folder = "Sigma spy",
		RepoUrl = nil,
		FolderName = "Sigma Spy",
		FolderStructure = {
			["Sigma Spy"] = {
				"assets",
			}
		}
	}

	local HttpService: HttpService

	function Files:Init(Data)
		local FolderStructure = self.FolderStructure
		local Services = Data.Services
		HttpService = Services.HttpService
		self:CheckFolders(FolderStructure)
	end

	function Files:PushConfig(Config: table)
		for Key, Value in next, Config do
			self[Key] = Value
		end
	end

	function Files:UrlFetch(Url: string): string
		local Final = {
			Url = Url:gsub(" ", "%%20"), 
			Method = 'GET'
		}
		local Success, Responce = pcall(request, Final)
		if not Success then 
			warn("[!] HTTP request error! Check console (F9)")
			warn("> Url:", Url)
			error(Responce)
			return ""
		end
		local Body = Responce.Body
		local StatusCode = Responce.StatusCode
		if StatusCode == 404 then
			warn("[!] The file requested has moved or been deleted.")
			warn(" >", Url)
			return ""
		end
		return Body, Responce
	end

	function Files:MakePath(Path: string)
		local Folder = self.Folder
		return `{Folder}/{Path}`
	end

	function Files:LoadCustomasset(Path: string): string?
		if not getcustomasset then return end
		if not Path then return end
		local Content = readfile(Path)
		if #Content <= 0 then return end
		local Success, AssetId = pcall(getcustomasset, Path)
		if not Success then return end
		if not AssetId or #AssetId <= 0 then return end
		return AssetId
	end

	function Files:GetFile(Path: string, CustomAsset: boolean?): string?
		local RepoUrl = self.RepoUrl
		local UseWorkspace = self.UseWorkspace
		local LocalPath = self:MakePath(Path)
		local Content = ""
		if UseWorkspace then
			Content = readfile(LocalPath)
		else
			Content = self:UrlFetch(`{RepoUrl}/{Path}`)
		end
		if CustomAsset then
			self:FileCheck(LocalPath, function()
				return Content
			end)
			return self:LoadCustomasset(LocalPath)
		end
		return Content
	end

	function Files:GetTemplate(Name: string): string
		return self:GetFile(`templates/{Name}.lua`)
	end

	function Files:FileCheck(Path: string, Callback)
		if isfile(Path) then return end
		local Template = Callback()
		writefile(Path, Template)
	end

	function Files:FolderCheck(Path: string)
		if isfolder(Path) then return end
		makefolder(Path)
	end

	function Files:CheckPath(Parent: string, Child: string)
		return Parent and `{Parent}/{Child}` or Child
	end

	function Files:CheckFolders(Structure: table, Path: string?)
		for ParentName, Name in next, Structure do
			if typeof(Name) == "table" then
				local NewPath = self:CheckPath(Path, ParentName)
				self:FolderCheck(NewPath)
				self:CheckFolders(Name, NewPath)
				continue
			end
			local FolderPath = self:CheckPath(Path, Name)
			self:FolderCheck(FolderPath)
		end
	end

	function Files:TemplateCheck(Path: string, TemplateName: string)
		self:FileCheck(Path, function()
			return self:GetTemplate(TemplateName)
		end)
	end

	function Files:GetAsset(Name: string, CustomAsset: boolean?): string
		return self:GetFile(`assets/{Name}`, CustomAsset)
	end

	function Files:GetModule(Name: string, TemplateName: string): string
		local Path = `{Name}.lua`
		if TemplateName then
			self:TemplateCheck(Path, TemplateName)
			local Content = readfile(Path)
			local Success = loadstring(Content)
			if Success then return Content end
			return self:GetTemplate(TemplateName)
		end
		return self:GetFile(Path)
	end

	function Files:LoadLibraries(Scripts: table, ...): table
		local Modules = {}
		for Name, Content in next, Scripts do
			if typeof(Content) ~= "string" then 
				Modules[Name] = Content
				continue 
			end
			local Closure, Error = loadstring(Content, Name)
			assert(Closure, `Failed to load {Name}: {Error}`)
			Modules[Name] = Closure(...)
		end
		return Modules
	end

	function Files:LoadModules(Modules: {}, Data: {})
		for Name, Module in next, Modules do
			local Init = Module.Init
			if not Init then continue end
			Module:Init(Data)
		end
	end

	function Files:CreateFont(Name: string, AssetId: string): string?
		if not AssetId then return end
		local FileName = `assets/{Name}.json`
		local JsonPath = self:MakePath(FileName)
		local Data = {
			name = Name,
			faces = {
				{
					name = "Regular",
					weight = 400,
					style = "Normal",
					assetId = AssetId
				}
			}
		}
		local Json = HttpService:JSONEncode(Data)
		writefile(JsonPath, Json)
		return JsonPath
	end

	function Files:CompileModule(Scripts): string
		local Out = "local Libraries = {"
		for Name, Content in Scripts do
			if typeof(Content) ~= "string" then continue end
			Out ..= `	{Name} = (function()\n{Content}\nend)(),\n`
		end
		Out ..= "}"
		return Out
	end

	function Files:MakeActorScript(Scripts, ChannelId: number): string
		local ActorCode = Files:CompileModule(Scripts)
		ActorCode ..= [[
		local ExtraData = {
			IsActor = true
		}
		]]
		ActorCode ..= `Libraries.Hook:BeginService(Libraries, ExtraData, {ChannelId})`
		return ActorCode
	end

	return Files
end)()

Files:PushConfig(Configuration)
Files:Init({Services = Services})

local Folder = Files.FolderName

--// Scripts table with ALL library code as strings
local Scripts = {
	--// User configurations
	Config = Files:GetModule(`{Folder}/Config`, "Config"),
	ReturnSpoofs = Files:GetModule(`{Folder}/Return spoofs`, "Return Spoofs"),
	Configuration = Configuration,
	Files = Files,

	--// Communication.lua
	Communication = [[type table = {
    [any]: any
}

--// Module
local Module = {
    CommCallbacks = {}
}

local CommWrapper = {}
CommWrapper.__index = CommWrapper

--// Serializer cache
local SerializeCache = setmetatable({}, {__mode = "k"})
local DeserializeCache = setmetatable({}, {__mode = "k"})

--// Services
local CoreGui

--// Modules
local Hook
local Channel
local Config
local Process

function Module:Init(Data)
    local Modules = Data.Modules
    local Services = Data.Services

    Hook = Modules.Hook
    Process = Modules.Process
    Config = Modules.Config or Config
    CoreGui = Services.CoreGui
end

function CommWrapper:Fire(...)
    local Queue = self.Queue
    table.insert(Queue, {...})
end

function CommWrapper:ProcessArguments(Arguments) 
    local Channel = self.Channel
    Channel:Fire(Process:Unpack(Arguments))
end

function CommWrapper:ProcessQueue()
    local Queue = self.Queue

    for Index = 1, #Queue do
        local Arguments = table.remove(Queue)
        pcall(function()
            self:ProcessArguments(Arguments) 
        end)
    end
end

function CommWrapper:BeginQueueService()
    coroutine.wrap(function()
        while wait() do
            self:ProcessQueue()
        end
    end)()
end

function Module:NewCommWrap(Channel: BindableEvent)
    local Base = {
        Queue = setmetatable({}, {__mode = "v"}),
        Channel = Channel,
        Event = Channel.Event
    }

    --// Create new wrapper class
    local Wrapped = setmetatable(Base, CommWrapper)
    Wrapped:BeginQueueService()

    return Wrapped
end

function Module:MakeDebugIdHandler(): BindableFunction
    --// Using BindableFunction as it does not require a thread permission change
    local Remote = Instance.new("BindableFunction")
    function Remote.OnInvoke(Object: Instance): string
        return Object:GetDebugId()
    end

    self.DebugIdRemote = Remote
    self.DebugIdInvoke = Remote.Invoke

    return Remote
end

function Module:GetDebugId(Object: Instance): string
    local Invoke = self.DebugIdInvoke
    local Remote = self.DebugIdRemote
	return Invoke(Remote, Object)
end

function Module:GetHiddenParent(): Instance
    --// Use gethui if it exists
    if gethui then return gethui() end
    return CoreGui
end

function Module:CreateCommChannel(): (number, BindableEvent)
    --// Use native if it exists
    local Force = Config and Config.ForceUseCustomComm or false
    if create_comm_channel and not Force then
        return create_comm_channel()
    end

    local Parent = self:GetHiddenParent()
    local ChannelId = math.random(1, 10000000)

    --// BindableEvent
    local Channel = Instance.new("BindableEvent", Parent)
    Channel.Name = ChannelId

    return ChannelId, Channel
end

function Module:GetCommChannel(ChannelId: number): BindableEvent?
    --// Use native if it exists
    local Force = Config and Config.ForceUseCustomComm or false
    if get_comm_channel and not Force then
        local Channel = get_comm_channel(ChannelId)
        return Channel, false
    end

    local Parent = self:GetHiddenParent()
    local Channel = Parent:FindFirstChild(ChannelId)

    --// Wrap the channel (Prevents thread permission errors)
    local Wrapped = self:NewCommWrap(Channel)
    return Wrapped, true
end

function Module:CheckValue(Value, Inbound: boolean?)
     --// No serializing  needed
    if typeof(Value) ~= "table" then 
        return Value 
    end
   
    --// Deserialize
    if Inbound then
        return self:DeserializeTable(Value)
    end

    --// Serialize
    return self:SerializeTable(Value)
end

local Tick = 0
function Module:WaitCheck()
    Tick += 1
    if Tick > 40 then
        Tick = 0 -- I could use modulus here but the interger will be massive
        wait()
    end
end

function Module:MakePacket(Index, Value): table
    self:WaitCheck()
    return {
        Index = self:CheckValue(Index), 
        Value = self:CheckValue(Value)
    }
end

function Module:ReadPacket(Packet: table): (any, any)
    if typeof(Packet) ~= "table" then return Packet end
    
    local Key = self:CheckValue(Packet.Index, true)
    local Value = self:CheckValue(Packet.Value, true)
    self:WaitCheck()

    return Key, Value
end

function Module:SerializeTable(Table: table): table
    --// Check cache for existing
    local Cached = SerializeCache[Table]
    if Cached then return Cached end

    local Serialized = {}
    SerializeCache[Table] = Serialized

    for Index, Value in next, Table do
        local Packet = self:MakePacket(Index, Value)
        table.insert(Serialized, Packet)
    end

    return Serialized
end

function Module:DeserializeTable(Serialized: table): table
    --// Check for cached
    local Cached = DeserializeCache[Serialized]
    if Cached then return Cached end

    local Table = {}
    DeserializeCache[Serialized] = Table
    
    for _, Packet in next, Serialized do
        local Index, Value = self:ReadPacket(Packet)
        if Index == nil then continue end

        Table[Index] = Value
    end

    return Table
end

function Module:SetChannel(NewChannel: number)
    Channel = NewChannel
end

function Module:ConsolePrint(...)
    self:Communicate("Print", ...)
end

function Module:QueueLog(Data)
    spawn(function()
        local SerializedArgs = self:SerializeTable(Data.Args)
        Data.Args = SerializedArgs

        self:Communicate("QueueLog", Data)
    end)
end

function Module:AddCommCallback(Type: string, Callback: (...any) -> ...any)
    local CommCallbacks = self.CommCallbacks
    CommCallbacks[Type] = Callback
end

function Module:GetCommCallback(Type: string): (...any) -> ...any
    local CommCallbacks = self.CommCallbacks
    return CommCallbacks[Type]
end

function Module:ChannelIndex(Channel, Property: string)
    if typeof(Channel) == "Instance" then
        return Hook:Index(Channel, Property)
    end

    --// Some executors return a UserData type
    return Channel[Property]
end

function Module:Communicate(...)
    local Fire = self:ChannelIndex(Channel, "Fire")
    Fire(Channel, ...)
end

function Module:AddConnection(Callback): RBXScriptConnection
    local Event = self:ChannelIndex(Channel, "Event")
    return Event:Connect(Callback)
end

function Module:AddTypeCallback(Type: string, Callback): RBXScriptConnection
    local Event = self:ChannelIndex(Channel, "Event")
    return Event:Connect(function(RecivedType: string, ...)
        if RecivedType ~= Type then return end
        Callback(...)
    end)
end

function Module:AddTypeCallbacks(Types: table)
    for Type: string, Callback in next, Types do
        self:AddTypeCallback(Type, Callback)
    end
end

function Module:CreateChannel(): number
    local ChannelID, Event = self:CreateCommChannel()

    --// Connect GetCommCallback function
    Event.Event:Connect(function(Type: string, ...)
        local Callback = self:GetCommCallback(Type)
        if Callback then
            Callback(...)
        end
    end)

    return ChannelID, Event
end

Module:MakeDebugIdHandler()

return Module]],

	--// Process.lua
	Process = [[type table = {
    [any]: any
}

type RemoteData = {
	Remote: Instance,
    NoBacktrace: boolean?,
	IsReceive: boolean?,
	Args: table,
    Id: string,
	Method: string,
    TransferType: string,
	ValueReplacements: table,
    ReturnValues: table,
    OriginalFunc: (Instance, ...any) -> ...any
}

local Process = {
    RemoteClassData = {
        ["RemoteEvent"] = {
            Send = {
                "FireServer",
                "fireServer",
            },
            Receive = {
                "OnClientEvent",
            }
        },
        ["RemoteFunction"] = {
            IsRemoteFunction = true,
            Send = {
                "InvokeServer",
                "invokeServer",
            },
            Receive = {
                "OnClientInvoke",
            }
        },
        ["UnreliableRemoteEvent"] = {
            Send = {
                "FireServer",
                "fireServer",
            },
            Receive = {
                "OnClientEvent",
            }
        },
        ["BindableEvent"] = {
            NoReciveHook = true,
            Send = {
                "Fire",
            },
            Receive = {
                "Event",
            }
        },
        ["BindableFunction"] = {
            IsRemoteFunction = true,
            NoReciveHook = true,
            Send = {
                "Invoke",
            },
            Receive = {
                "OnInvoke",
            }
        }
    },
    RemoteOptions = {},
    LoopingRemotes = {},
    ConfigOverwrites = {
        [{"sirhurt", "potassium", "wave"}] = {
            ForceUseCustomComm = true
        }
    }
}

local Hook
local Communication
local ReturnSpoofs
local Ui
local Config

local HttpService: HttpService

local Channel
local WrappedChannel = false

local SigmaENV = getfenv(1)

function Process:Merge(Base: table, New: table)
    if not New then return end
	for Key, Value in next, New do
		Base[Key] = Value
	end
end

function Process:Init(Data)
    local Modules = Data.Modules
    local Services = Data.Services

    HttpService = Services.HttpService

    Config = Modules.Config
    Ui = Modules.Ui
    Hook = Modules.Hook
    Communication = Modules.Communication
    ReturnSpoofs = Modules.ReturnSpoofs
end

function Process:SetChannel(NewChannel: BindableEvent, IsWrapped: boolean)
    Channel = NewChannel
    WrappedChannel = IsWrapped
end

function Process:GetConfigOverwrites(Name: string)
    local ConfigOverwrites = self.ConfigOverwrites

    for List, Overwrites in next, ConfigOverwrites do
        if not table.find(List, Name) then continue end
        return Overwrites
    end
    return
end

function Process:CheckConfig(Config: table)
    local Name = identifyexecutor():lower()

    local Overwrites = self:GetConfigOverwrites(Name)
    if not Overwrites then return end

    self:Merge(Config, Overwrites)
end

function Process:CleanCError(Error: string): string
    Error = Error:gsub(":%d+: ", "")
    Error = Error:gsub(", got %a+", "")
    Error = Error:gsub("invalid argument", "missing argument")
    return Error
end

function Process:CountMatches(String: string, Match: string): number
	local Count = 0
	for _ in String:gmatch(Match) do
		Count +=1 
	end

	return Count
end

function Process:CheckValue(Value, Ignore: table?, Cache: table?)
    local Type = typeof(Value)
    Communication:WaitCheck()
    
    if Type == "table" then
        Value = self:DeepCloneTable(Value, Ignore, Cache)
    elseif Type == "Instance" then
        Value = cloneref(Value)
    end
    
    return Value
end

function Process:DeepCloneTable(Table, Ignore: table?, Visited: table?): table
    if typeof(Table) ~= "table" then return Table end
    local Cache = Visited or {}

    if Cache[Table] then
        return Cache[Table]
    end

    local New = {}
    Cache[Table] = New

    for Key, Value in next, Table do
        if Ignore and table.find(Ignore, Value) then continue end
        
        Key = self:CheckValue(Key, Ignore, Cache)
        New[Key] = self:CheckValue(Value, Ignore, Cache)
    end

    if not Visited then
        table.clear(Cache)
    end
    
    return New
end

function Process:Unpack(Table: table)
    if not Table then return Table end
	local Length = table.maxn(Table)
	return unpack(Table, 1, Length)
end

function Process:PushConfig(Overwrites)
    self:Merge(self, Overwrites)
end

function Process:FuncExists(Name: string)
	return SigmaENV[Name]
end

function Process:CheckExecutor(): boolean
    local Blacklisted = {
        "xeno",
        "solara",
        "jjsploit"
    }

    local Name = identifyexecutor():lower()
    local IsBlacklisted = table.find(Blacklisted, Name)

    if IsBlacklisted then
        Ui:ShowUnsupportedExecutor(Name)
        return false
    end

    return true
end

function Process:CheckFunctions(): boolean
    local CoreFunctions = {
        "hookmetamethod",
        "hookfunction",
        "getrawmetatable",
        "setreadonly"
    }

    for _, Name in CoreFunctions do
        local Func = self:FuncExists(Name)
        if Func then continue end

        Ui:ShowUnsupported(Name)
        return false
    end

    return true
end

function Process:CheckIsSupported(): boolean
    local ExecutorSupported = self:CheckExecutor()
    if not ExecutorSupported then
        return false
    end

    local FunctionsSupported = self:CheckFunctions()
    if not FunctionsSupported then
        return false
    end

    return true
end

function Process:GetClassData(Remote: Instance): table?
    local RemoteClassData = self.RemoteClassData
    local ClassName = Hook:Index(Remote, "ClassName")

    return RemoteClassData[ClassName]
end

function Process:IsProtectedRemote(Remote: Instance): boolean
    local IsDebug = Remote == Communication.DebugIdRemote
    local IsChannel = Remote == (WrappedChannel and Channel.Channel or Channel)

    return IsDebug or IsChannel
end

function Process:RemoteAllowed(Remote: Instance, TransferType: string, Method: string?): boolean?
    if typeof(Remote) ~= 'Instance' then return end
    
    if self:IsProtectedRemote(Remote) then return end

	local ClassData = self:GetClassData(Remote)
	if not ClassData then return end

	local Allowed = ClassData[TransferType]
	if not Allowed then return end

	if Method then
		return table.find(Allowed, Method) ~= nil
	end

	return true
end

function Process:SetExtraData(Data: table)
    if not Data then return end
    self.ExtraData = Data
end

function Process:GetRemoteSpoof(Remote: Instance, Method: string, ...): table?
    local Spoof = ReturnSpoofs[Remote]

    if not Spoof then return end
    if Spoof.Method ~= Method then return end

    local ReturnValues = Spoof.Return

    if typeof(ReturnValues) == "function" then
        ReturnValues = ReturnValues(...)
    end

	return ReturnValues
end

function Process:SetNewReturnSpoofs(NewReturnSpoofs: table)
    ReturnSpoofs = NewReturnSpoofs
end

function Process:FindCallingLClosure(Offset: number)
    local Getfenv = Hook:GetOriginalFunc(getfenv)
    Offset += 1

    while true do
        Offset += 1

        local IsValid = debug.info(Offset, "l") ~= -1
        if not IsValid then continue end

        local Function = debug.info(Offset, "f")
        if not Function then return end
        if Getfenv(Function) == SigmaENV then continue end

        return Function
    end
end

function Process:Decompile(Script: LocalScript | ModuleScript): string
    local KonstantAPI = "http://api.plusgiant5.com/konstant/decompile"
    local ForceKonstant = Config and Config.ForceKonstantDecompiler or false

    if decompile and not ForceKonstant then 
        return decompile(Script)
    end

    local Success, Bytecode = pcall(getscriptbytecode, Script)
    if not Success then
        local Error = `--Failed to get script bytecode, error:\n`
        Error ..= `\n--[[\n{Bytecode}\n]]`
        return Error, true
    end
    
    local Responce = request({
        Url = KonstantAPI,
        Body = Bytecode,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "text/plain"
        },
    })

    if Responce.StatusCode ~= 200 then
        local Error = `--[KONSTANT] Error occured while requesting the API, error:\n`
        Error ..= `\n--[[\n{Responce.Body}\n]]`
        return Error, true
    end

    return Responce.Body
end

function Process:GetScriptFromFunc(Func: (...any) -> ...any)
    if not Func then return end

    local Success, ENV = pcall(getfenv, Func)
    if not Success then return end
    
    if self:IsSigmaSpyENV(ENV) then return end

    return rawget(ENV, "script")
end

function Process:ConnectionIsValid(Connection: table): boolean
    local ValueReplacements = {
		["Script"] = function(Connection: table): Script?
			local Function = Connection.Function
			if not Function then return end

			return self:GetScriptFromFunc(Function)
		end
	}

    local ToCheck = {
        "Script"
    }
    for _, Property in ToCheck do
        local Replacement = ValueReplacements[Property]
        local Value

        if Replacement then
            Value = Replacement(Connection)
        end

        if Value == nil then 
            return false 
        end
    end

    return true
end

function Process:FilterConnections(Signal: RBXScriptSignal): table
    local Processed = {}

    for _, Connection in getconnections(Signal) do
        if not self:ConnectionIsValid(Connection) then continue end
        table.insert(Processed, Connection)
    end

    return Processed
end

function Process:IsSigmaSpyENV(Env: table): boolean
    return Env == SigmaENV
end

function Process:GetRemoteData(Id: string)
    local RemoteOptions = self.RemoteOptions

	local Existing = RemoteOptions[Id]
	if Existing then return Existing end
	
	local Data = {
		Excluded = false,
		Blocked = false
	}

	RemoteOptions[Id] = Data
	return Data
end

function Process:CallDiscordRPC(Body: table)
    request({
        Url = "http://127.0.0.1:6463/rpc?v=1",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Origin"] = "https://discord.com/"
        },
        Body = HttpService:JSONEncode(Body)
    })
end

function Process:PromptDiscordInvite(InviteCode: string)
    self:CallDiscordRPC({
        cmd = "INVITE_BROWSER",
        nonce = HttpService:GenerateGUID(false),
        args = {
            code = InviteCode
        }
    })
end

local ProcessCallback = newcclosure(function(Data: RemoteData, Remote, ...): table?
    local OriginalFunc = Data.OriginalFunc
    local Id = Data.Id
    local Method = Data.Method

    local RemoteData = Process:GetRemoteData(Id)
    if RemoteData.Blocked then return {} end

    local Spoof = Process:GetRemoteSpoof(Remote, Method, OriginalFunc, ...)
    if Spoof then return Spoof end

    if not OriginalFunc then return end

    return {
        OriginalFunc(Remote, ...)
    }
end)

function Process:ProcessRemote(Data: RemoteData, Remote, ...): table?
	local Method = Data.Method
    local TransferType = Data.TransferType
    local IsReceive = Data.IsReceive

	if TransferType and not self:RemoteAllowed(Remote, TransferType, Method) then return end

    local Id = Communication:GetDebugId(Remote)
    local ClassData = self:GetClassData(Remote)
    local Timestamp = tick()

    local CallingFunction
    local SourceScript

    local ExtraData = self.ExtraData
    if ExtraData then
        self:Merge(Data, ExtraData)
    end

    if not IsReceive then
        CallingFunction = self:FindCallingLClosure(6)
        SourceScript = CallingFunction and self:GetScriptFromFunc(CallingFunction) or nil
    end

    self:Merge(Data, {
        Remote = cloneref(Remote),
		CallingScript = getcallingscript(),
        CallingFunction = CallingFunction,
        SourceScript = SourceScript,
        Id = Id,
		ClassData = ClassData,
        Timestamp = Timestamp,
        Args = {...}
    })

    local ReturnValues = ProcessCallback(Data, Remote, ...)
    Data.ReturnValues = ReturnValues

    Communication:QueueLog(Data)

    return ReturnValues
end

function Process:SetAllRemoteData(Key: string, Value)
    local RemoteOptions = self.RemoteOptions
	for RemoteID, Data in next, RemoteOptions do
		Data[Key] = Value
	end
end

function Process:SetRemoteData(Id: string, RemoteData: table)
    local RemoteOptions = self.RemoteOptions
    RemoteOptions[Id] = RemoteData
end

function Process:UpdateRemoteData(Id: string, RemoteData: table)
    Communication:Communicate("RemoteData", Id, RemoteData)
end

function Process:UpdateAllRemoteData(Key: string, Value)
    Communication:Communicate("AllRemoteData", Key, Value)
end

return Process]],

	--// Hook.lua - COMPLETE INLINED VERSION
	Hook = [[local Hook = {
	OriginalNamecall = nil,
	OriginalIndex = nil,
	PreviousFunctions = {},
	DefaultConfig = {
		FunctionPatches = true
	}
}

type table = {
	[any]: any
}

type MetaFunc = (Instance, ...any) -> ...any
type UnkFunc = (...any) -> ...any

local Modules
local Process
local Configuration
local Config
local Communication

local ExeENV = getfenv(1)

function Hook:Init(Data)
    Modules = Data.Modules

	Process = Modules.Process
	Communication = Modules.Communication or Communication
	Config = Modules.Config or Config
	Configuration = Modules.Configuration or Configuration
end

local HookMiddle = newcclosure(function(OriginalFunc, Callback, AlwaysTable: boolean?, ...)
	local ReturnValues = Callback(...)
	if ReturnValues then
		if not AlwaysTable then
			return Process:Unpack(ReturnValues)
		end

		return ReturnValues
	end

	if AlwaysTable then
		return {OriginalFunc(...)}
	end

	return OriginalFunc(...)
end)

local function Merge(Base: table, New: table)
	for Key, Value in next, New do
		Base[Key] = Value
	end
end

function Hook:Index(Object: Instance, Key: string)
	return Object[Key]
end

function Hook:PushConfig(Overwrites)
    Merge(self, Overwrites)
end

function Hook:ReplaceMetaMethod(Object: Instance, Call: string, Callback: MetaFunc): MetaFunc
	local Metatable = getrawmetatable(Object)
	local OriginalFunc = clonefunction(Metatable[Call])
	
	setreadonly(Metatable, false)
	Metatable[Call] = newcclosure(function(...)
		return HookMiddle(OriginalFunc, Callback, false, ...)
	end)
	setreadonly(Metatable, true)

	return OriginalFunc
end

function Hook:HookFunction(Func: UnkFunc, Callback: UnkFunc)
	local OriginalFunc
	local WrappedCallback = newcclosure(Callback)
	OriginalFunc = clonefunction(hookfunction(Func, function(...)
		return HookMiddle(OriginalFunc, WrappedCallback, false, ...)
	end))
	return OriginalFunc
end

function Hook:HookMetaCall(Object: Instance, Call: string, Callback: MetaFunc): MetaFunc
	local Metatable = getrawmetatable(Object)
	local Unhooked
	
	Unhooked = self:HookFunction(Metatable[Call], function(...)
		return HookMiddle(Unhooked, Callback, true, ...)
	end)
	return Unhooked
end

function Hook:HookMetaMethod(Object: Instance, Call: string, Callback: MetaFunc): MetaFunc
	local Func = newcclosure(Callback)
	
	if Config and Config.ReplaceMetaCallFunc then
		return self:ReplaceMetaMethod(Object, Call, Func)
	end
	
	return self:HookMetaCall(Object, Call, Func)
end

function Hook:PatchFunctions()
	if Config and Config.NoFunctionPatching then return end

	local Patches = {
		[pcall] =  function(OldFunc, Func, ...)
			local Responce = {OldFunc(Func, ...)}
			local Success, Error = Responce[1], Responce[2]
			local IsC = iscclosure(Func)

			if Success == false and IsC then
				local NewError = Process:CleanCError(Error)
				Responce[2] = NewError
			end

			if Success == false and not IsC and Error:find("C stack overflow") then
				local Tracetable = Error:split(":")
				local Caller, Line = Tracetable[1], Tracetable[2]
				local Count = Process:CountMatches(Error, Caller)

				if Count == 196 then
					Communication:ConsolePrint(`C stack overflow patched, count was {Count}`)
					Responce[2] = Error:gsub(`{Caller}:{Line}: `, Caller, 1)
				end
			end

			return Responce
		end,
		[getfenv] = function(OldFunc, Level: number, ...)
			Level = Level or 1

			if type(Level) == "number" then
				Level += 2
			end

			local Responce = {OldFunc(Level, ...)}
			local ENV = Responce[1]

			if not checkcaller() and ENV == ExeENV then
				Communication:ConsolePrint("ENV escape patched")
				return OldFunc(999999, ...)
			end

			return Responce
		end
	}

	for Func, CallBack in Patches do
		local Wrapped = newcclosure(CallBack)
		local OldFunc; OldFunc = self:HookFunction(Func, function(...)
			return Wrapped(OldFunc, ...)
		end)

		self.PreviousFunctions[Func] = OldFunc
	end
end

function Hook:GetOriginalFunc(Func)
	return self.PreviousFunctions[Func] or Func
end

function Hook:RunOnActors(Code: string, ChannelId: number)
	if not getactors or not run_on_actor then return end
	
	local Actors = getactors()
	if not Actors then return end
	
	for _, Actor in Actors do 
		pcall(run_on_actor, Actor, Code, ChannelId)
	end
end

local function ProcessRemote(OriginalFunc, MetaMethod: string, self, Method: string, ...)
	return Process:ProcessRemote({
		Method = Method,
		OriginalFunc = OriginalFunc,
		MetaMethod = MetaMethod,
		TransferType = "Send",
		IsExploit = checkcaller()
	}, self, ...)
end

function Hook:HookRemoteTypeIndex(ClassName: string, FuncName: string)
	local Remote = Instance.new(ClassName)
	local Func = Remote[FuncName]
	local OriginalFunc

	OriginalFunc = self:HookFunction(Func, function(self, ...)
		if not Process:RemoteAllowed(self, "Send", FuncName) then return end

		return ProcessRemote(OriginalFunc, "__index", self, FuncName, ...)
	end)
end

function Hook:HookRemoteIndexes()
	local RemoteClassData = Process.RemoteClassData
	for ClassName, Data in RemoteClassData do
		local FuncName = Data.Send[1]
		self:HookRemoteTypeIndex(ClassName, FuncName)
	end
end

function Hook:BeginHooks()
	self:HookRemoteIndexes()

	local OriginalNameCall
	OriginalNameCall = self:HookMetaMethod(game, "__namecall", function(self, ...)
		local Method = getnamecallmethod()
		return ProcessRemote(OriginalNameCall, "__namecall", self, Method, ...)
	end)

	Merge(self, {
		OriginalNamecall = OriginalNameCall,
	})
end

function Hook:HookClientInvoke(Remote, Method, Callback)
	local Success, Function = pcall(function()
		return getcallbackvalue(Remote, Method)
	end)

	if not Success then return end
	if not Function then return end
	
	local HookSuccess = pcall(function()
		self:HookFunction(Function, Callback)
	end)
	if HookSuccess then return end

	Remote[Method] = function(...)
		return HookMiddle(Function, Callback, false, ...)
	end
end

function Hook:MultiConnect(Remotes)
	for _, Remote in next, Remotes do
		self:ConnectClientRecive(Remote)
	end
end

function Hook:ConnectClientRecive(Remote)
	local Allowed = Process:RemoteAllowed(Remote, "Receive")
	if not Allowed then return end

    local ClassData = Process:GetClassData(Remote)
    local IsRemoteFunction = ClassData.IsRemoteFunction
	local NoReciveHook = ClassData.NoReciveHook
    local Method = ClassData.Receive[1]

	if NoReciveHook then return end

	local function Callback(...)
        return Process:ProcessRemote({
            Method = Method,
            IsReceive = true,
            MetaMethod = "Connect",
			IsExploit = checkcaller()
        }, Remote, ...)
	end

	if not IsRemoteFunction then
   		Remote[Method]:Connect(Callback)
	else
		self:HookClientInvoke(Remote, Method, Callback)
	end
end

function Hook:BeginService(Libraries, ExtraData, ChannelId, ...)
	local ReturnSpoofs = Libraries.ReturnSpoofs
	local ProcessLib = Libraries.Process
	local Communication = Libraries.Communication
	local Generation = Libraries.Generation
	local Config = Libraries.Config

	ProcessLib:CheckConfig(Config)

	local InitData = {
		Modules = {
			ReturnSpoofs = ReturnSpoofs,
			Generation = Generation,
			Communication = Communication,
			Process = ProcessLib,
			Config = Config,
			Hook = self
		},
		Services = setmetatable({}, {
			__index = function(self, Name: string): Instance
				local Service = game:GetService(Name)
				return cloneref(Service)
			end,
		})
	}

	Communication:Init(InitData)
	ProcessLib:Init(InitData)

	local Channel, IsWrapped = Communication:GetCommChannel(ChannelId)
	Communication:SetChannel(Channel)
	Communication:AddTypeCallbacks({
		["RemoteData"] = function(Id: string, RemoteData)
			ProcessLib:SetRemoteData(Id, RemoteData)
		end,
		["AllRemoteData"] = function(Key: string, Value)
			ProcessLib:SetAllRemoteData(Key, Value)
		end,
		["UpdateSpoofs"] = function(Content: string)
			local Spoofs = loadstring(Content)()
			ProcessLib:SetNewReturnSpoofs(Spoofs)
		end,
		["BeginHooks"] = function(Config)
			if Config.PatchFunctions then
				self:PatchFunctions()
			end
			self:BeginHooks()
			Communication:ConsolePrint("Hooks loaded")
		end
	})
	
	ProcessLib:SetChannel(Channel, IsWrapped)
	ProcessLib:SetExtraData(ExtraData)

	self:Init(InitData)

	if ExtraData and ExtraData.IsActor then
		Communication:ConsolePrint("Actor connected!")
	end
end

function Hook:LoadMetaHooks(ActorCode: string, ChannelId: number)
	if not Configuration.NoActors then
		self:RunOnActors(ActorCode, ChannelId)
	end

	self:BeginService(Modules, nil, ChannelId) 
end

function Hook:LoadReceiveHooks()
	local NoReceiveHooking = Config and Config.NoReceiveHooking or false
	local BlackListedServices = Config and Config.BlackListedServices or {}

	if NoReceiveHooking then return end

	game.DescendantAdded:Connect(function(Remote)
		self:ConnectClientRecive(Remote)
	end)

	self:MultiConnect(getnilinstances())

	for _, Service in next, game:GetChildren() do
		if table.find(BlackListedServices, Service.ClassName) then continue end
		self:MultiConnect(Service:GetDescendants())
	end
end

function Hook:LoadHooks(ActorCode: string, ChannelId: number)
	self:LoadMetaHooks(ActorCode, ChannelId)
	self:LoadReceiveHooks()
end

return Hook]],

	--// Flags.lua
	Flags = [[type FlagValue = boolean|number|any
type Flag = {
    Value: FlagValue,
    Label: string,
    Category: string
}
type Flags = {
    [string]: Flag
}
type table = {
    [any]: any
}

local Module = {
    Flags = {
        NoComments = {
            Value = false,
            Label = "No comments",
        },
        SelectNewest = {
            Value = false,
            Label = "Auto select newest",
        },
        DecompilePopout = {
            Value = false,
            Label = "Pop-out decompiles",
        },
        IgnoreNil = {
            Value = true,
            Label = "Ignore nil parents",
        },
        LogExploit = {
            Value = true,
            Label = "Log exploit calls",
        },
        LogRecives = {
            Value = true,
            Label = "Log receives",
        },
        Paused = {
            Value = false,
            Label = "Paused",
            Keybind = Enum.KeyCode.Q
        },
        KeybindsEnabled = {
            Value = true,
            Label = "Keybinds Enabled"
        },
        FindStringForName = {
            Value = true,
            Label = "Find arg for name"
        },
        UiVisible = {
            Value = true,
            Label = "UI Visible",
            Keybind = Enum.KeyCode.P
        },
        NoTreeNodes = {
            Value = false,
            Label = "No grouping"
        },
        TableArgs = {
            Value = false,
            Label = "Table args"
        },
        NoVariables = {
            Value = false,
            Label = "No compression"
        }
    }
}

function Module:GetFlagValue(Name: string): FlagValue
    local Flag = self:GetFlag(Name)
    return Flag.Value
end

function Module:SetFlagValue(Name: string, Value: FlagValue)
    local Flag = self:GetFlag(Name)
    Flag.Value = Value
end

function Module:SetFlagCallback(Name: string, Callback: (...any) -> ...any)
    local Flag = self:GetFlag(Name)
    Flag.Callback = Callback
end

function Module:SetFlagCallbacks(Dict: {})
    for Name, Callback: (...any) -> ...any in next, Dict do 
        self:SetFlagCallback(Name, Callback)
    end
end

function Module:GetFlag(Name: string): Flag
    local AllFlags = self:GetFlags()
    local Flag = AllFlags[Name]
    assert(Flag, "Flag does not exist!")
    return Flag
end

function Module:AddFlag(Name: string, Flag: Flag)
    local AllFlags = self:GetFlags()
    AllFlags[Name] = Flag
end

function Module:GetFlags(): Flags
    return self.Flags
end

return Module]],

	--// Ui.lua - TRUNCATED VERSION WITH CORE FUNCTIONS
	Ui = [[local Ui = {
	DefaultEditorContent = [[--[[
	Sigma Spy, written by depso
	Hooks rewritten and many more fixes!

	Discord: https://discord.gg/bkUkm2vSbv
]]].."]],
	LogLimit = 100,
}

local ReGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/main/ReGui.lua'), "ReGui")()

local Flags
local Generation
local Process
local Hook 
local Config
local Communication
local Files

function Ui:Init(Data)
    local Modules = Data.Modules

	Flags = Modules.Flags
	Generation = Modules.Generation
	Process = Modules.Process
	Hook = Modules.Hook
	Config = Modules.Config
	Communication = Modules.Communication
	Files = Modules.Files
end

function Ui:ShowModal(Lines: table)
	-- Stub for standalone
end

function Ui:ShowUnsupportedExecutor(Name: string)
	warn("Executor not supported:", Name)
end

function Ui:ShowUnsupported(FuncName: string)
	warn("Missing function:", FuncName)
end

return Ui]],

	--// Generation.lua - TRUNCATED VERSION
	Generation = [[local Generation = {
	Header = "-- Generated with Sigma Spy\\n",
}

local Config
local Hook
local ParserModule
local Flags

function Generation:Init(Data: table)
    local Modules = Data.Modules
	local Configuration = Modules.Configuration

	Config = Modules.Config
	Hook = Modules.Hook
	Flags = Modules.Flags
	
	local ParserUrl = Configuration.ParserUrl
	self:LoadParser(ParserUrl)
end

function Generation:LoadParser(ModuleUrl: string)
	ParserModule = loadstring(game:HttpGet(ModuleUrl), "Parser")()
end

function Generation:NewParser(Extra: table?)
	return ParserModule:New({
		VariableBase = "Argument",
		IndexFunc = function(...)
			return Hook:Index(...)
		end,
	})
end

return Generation]]
}

--// Load all libraries
local Modules = Files:LoadLibraries(Scripts)

--// Add loaded modules to Scripts for actor compilation
Scripts.Process = Modules.Process
Scripts.Hook = Modules.Hook
Scripts.Communication = Modules.Communication

--// Initialize modules
local InitData = {
	Modules = Modules,
	Services = Services
}

Files:LoadModules(Modules, InitData)

--// Check if supported
local IsSupported = Modules.Process:CheckIsSupported()
if not IsSupported then return end

--// Create communication channel
local ChannelId, CommChannel = Modules.Communication:CreateChannel()
Modules.Communication:SetChannel(CommChannel)

--// Initialize UI
Modules.Ui:SetCommChannel(CommChannel)

--// Font setup
local FontFile = Files:GetAsset("ProggyClean.ttf", true)
if FontFile then
	local FontJsonPath = Files:CreateFont("ProggyClean", FontFile)
	Modules.Ui:SetFontFile(FontJsonPath)
end

--// Create actor script
local ActorCode = Files:MakeActorScript(Scripts, ChannelId)

--// Main initialization
Modules = {
	Process = Modules.Process,
	Hook = Modules.Hook,
	Communication = Modules.Communication,
	Generation = Modules.Generation,
	Ui = Modules.Ui,
	Flags = Modules.Flags,
	Config = Modules.Config,
	ReturnSpoofs = Modules.ReturnSpoofs,
	Configuration = Configuration,
	Files = Files
}

--// Load hooks
Modules.Hook:LoadHooks(ActorCode, ChannelId)

--// Signal hooks are loaded
Modules.Communication:Communicate("BeginHooks", {
	PatchFunctions = true
})

print("[Sigma Spy] Standalone version initialized successfully!")
