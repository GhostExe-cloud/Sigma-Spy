--// Base Configuration
local Configuration = {
	UseWorkspace = false,
	NoActors = false,
	FolderName = "Sigma Spy",
	RepoUrl = "https://raw.githubusercontent.com/GhostExe-cloud/Sigma-Spy/main",
	ParserUrl = "https://raw.githubusercontent.com/depthso/Roblox-parser/refs/heads/main/dist/Main.luau"
}

print("[Sigma Spy] v12.0.1 - Config Fix Build - Loaded")

--// Load overwrites
local Parameters = {...}
local Overwrites = Parameters[1]
if typeof(Overwrites) == "table" then
	for Key, Value in Overwrites do
		Configuration[Key] = Value
	end
end

--// Service handler
local Services = setmetatable({}, {
	__index = function(self, Name: string): Instance
		local Service = game:GetService(Name)
		return cloneref(Service)
	end,
})

--// Files module
local Files = (function()
	type table = {
		[any]: any
	}

	--// Module
	local Files = {
		UseWorkspace = false,
		Folder = "Sigma spy",
		RepoUrl = nil,
		FolderStructure = {
			["Sigma Spy"] = {
				"assets",
			}
		}
	}

	--// Services
	local HttpService: HttpService

	function Files:Init(Data)
		local FolderStructure = self.FolderStructure
		local Services = Data.Services

		HttpService = Services.HttpService

		--// Check if the folders need to be created
		self:CheckFolders(FolderStructure)
	end

	function Files:PushConfig(Config: table)
		for Key, Value in next, Config do
			self[Key] = Value
		end
	end

	function Files:UrlFetch(Url: string): string
		--// Request data
		local Final = {
			Url = Url:gsub(" ", "%%20"), 
			Method = 'GET'
		}

		 --// Send HTTP request
		local Success, Responce = pcall(request, Final)

		--// Error check
		if not Success then 
			warn("[!] HTTP request error! Check console (F9)")
			warn("> Url:", Url)
			error(Responce)
			return ""
		end

		local Body = Responce.Body
		local StatusCode = Responce.StatusCode

		--// Status code check
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

		--// Check content
		local Content = readfile(Path)
		if #Content <= 0 then return end

		--// Load custom AssetId
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

		--// Check if the files should be fetched from the workspace instead
		if UseWorkspace then
			Content = readfile(LocalPath)
		else
			--// Download with a HTTP request
			Content = self:UrlFetch(`{RepoUrl}/{Path}`)
		end

		--// Custom asset
		if CustomAsset then
			--// Check if the file should be written to
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

		--// Create and write the template to the missing file
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
			--// Check existance of the parent folder
			if typeof(Name) == "table" then
				local NewPath = self:CheckPath(Path, ParentName)
				self:FolderCheck(NewPath)
				self:CheckFolders(Name, NewPath)
				continue
			end

			--// Check existance of child folder
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

		--// The file will be declared local if the template argument is provided
		if TemplateName then
			self:TemplateCheck(Path, TemplateName)

			--// Check if it successfuly loads
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
			--// Base64 format
			local IsBase64 = typeof(Content) == "table" and Content[1] == "base64"
			Content = IsBase64 and Content[2] or Content

			--// Tables
			if typeof(Content) ~= "string" and not IsBase64 then 
				Modules[Name] = Content
				continue 
			end

			--// Decode Base64
			if IsBase64 then
				Content = crypt.base64decode(Content)
				Scripts[Name] = Content
			end

			--// Compile library 
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

			--// Invoke :Init function 
			Module:Init(Data)
		end
	end

	function Files:CreateFont(Name: string, AssetId: string): string?
		if not AssetId then return end

		--// Custom font Json
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

		--// Write Json
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
Files:Init({
	Services = Services
})

local Folder = Files.FolderName
local Scripts = {
	--// User configurations
	Config = Files:GetModule(`{Folder}/Config`, "Config"),
	ReturnSpoofs = Files:GetModule(`{Folder}/Return spoofs`, "Return Spoofs"),
	Configuration = Configuration,
	Files = Files,

	--// Libraries - Load from GitHub repo
	Process = Files:GetFile("lib/Process.lua"),
	Hook = Files:GetFile("lib/Hook.lua"),
	Flags = Files:GetFile("lib/Flags.lua"),
	Ui = Files:GetFile("lib/Ui.lua"),
	Generation = Files:GetFile("lib/Generation.lua"),
	Communication = Files:GetFile("lib/Communication.lua")
}

--// Services
local Players: Players = Services.Players

--// Dependencies
local Modules = Files:LoadLibraries(Scripts)
local Process = Modules.Process
local Hook = Modules.Hook
local Ui = Modules.Ui
local Generation = Modules.Generation
local Communication = Modules.Communication
local Config = Modules.Config

--// Use custom font (optional)
local FontContent = Files:GetAsset("ProggyClean.ttf", true)
local FontJsonFile = Files:CreateFont("ProggyClean", FontContent)
Ui:SetFontFile(FontJsonFile)

--// Load modules
Process:CheckConfig(Config)
Files:LoadModules(Modules, {
	Modules = Modules,
	Services = Services
})

--// ReGui Create window
local Window = Ui:CreateMainWindow()

--// Check if Sigma spy is supported
local Supported = Process:CheckIsSupported()
if not Supported then 
	Window:Close()
	return
end

--// Create communication channel
local ChannelId, Event = Communication:CreateChannel()
Communication:AddCommCallback("QueueLog", function(...)
	Ui:QueueLog(...)
end)
Communication:AddCommCallback("Print", function(...)
	Ui:ConsoleLog(...)
end)

--// Generation swaps
local LocalPlayer = Players.LocalPlayer
Generation:SetSwapsCallback(function(self)
	self:AddSwap(LocalPlayer, {
		String = "LocalPlayer",
	})
	self:AddSwap(LocalPlayer.Character, {
		String = "Character",
		NextParent = LocalPlayer
	})
end)

--// Create window content
Ui:CreateWindowContent(Window)

--// Begin the Log queue 
Ui:SetCommChannel(Event)
Ui:BeginLogService()

--// Load hooks
local ActorCode = Files:MakeActorScript(Scripts, ChannelId)
Hook:LoadHooks(ActorCode, ChannelId)

local EnablePatches = Ui:AskUser({
	Title = "Enable function patches?",
	Content = {
		"On some executors, function patches can prevent common detections that executor has",
		"By enabling this, it MAY trigger hook detections in some games, this is why you are asked.",
		"If it doesn't work, rejoin and press 'No'",
		"",
		"(This does not affect game functionality)"
	},
	Options = {"Yes", "No"}
}) == "Yes"

--// Begin hooks
Event:Fire("BeginHooks", {
	PatchFunctions = EnablePatches
})