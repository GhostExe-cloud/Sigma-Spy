--[[
    Sigma Spy - SAFE MODE Loader
    Minimal hooks - only logs outgoing remote calls
    No receive hooks, no actors, no function patches
]]

print("[Sigma Spy SAFE MODE] Loading...")

-- Load Files library first
local Files = loadstring(readfile("src/lib/Files.lua"))()

-- Configuration
local Configuration = {
    UseWorkspace = false,
    NoActors = true,  -- DISABLED
    FolderName = "Sigma Spy",
    RepoUrl = "https://raw.githubusercontent.com/Dexz00/Sigma-Spy/main",
    ParserUrl = "https://raw.githubusercontent.com/xfwil/Roblox-parser/main/dist/Main.luau"
}

-- Services
local Services = setmetatable({}, {
    __index = function(self, Name)
        local Service = game:GetService(Name)
        return cloneref(Service)
    end,
})

Files:PushConfig(Configuration)
Files:Init({Services = Services})

local Folder = Files.FolderName

-- Create safe config
local SafeConfig = [[return {
    NoReceiveHooking = true,
    NoFunctionPatching = true,
    BlackListedServices = {
        "RobloxReplicatedStorage",
        "CoreGui",
        "CorePackages",
        "Players",
    },
    ForceUseCustomComm = false,
    ReplaceMetaCallFunc = false,
    Debug = true
}]]

-- Write safe config
if not isfile("Sigma Spy/Config.lua") or readfile("Sigma Spy/Config.lua"):find("NoReceiveHooking = false") then
    writefile("Sigma Spy/Config.lua", SafeConfig)
    print("[Sigma Spy SAFE MODE] Wrote safe config")
end

-- Load all libraries
local Scripts = {
    Config = SafeConfig,  -- Use safe config directly
    ReturnSpoofs = Files:GetModule(`{Folder}/Return spoofs`, "Return Spoofs"),
    Configuration = Configuration,
    Files = Files,
    Process = readfile("src/lib/Process.lua"),
    Hook = readfile("src/lib/Hook.lua"),
    Flags = readfile("src/lib/Flags.lua"),
    Ui = readfile("src/lib/Ui.lua"),
    Generation = readfile("src/lib/Generation.lua"),
    Communication = readfile("src/lib/Communication.lua")
}

-- Rest of initialization
local Players = Services.Players
local Modules = Files:LoadLibraries(Scripts)
local Process = Modules.Process
local Hook = Modules.Hook
local Ui = Modules.Ui
local Generation = Modules.Generation
local Communication = Modules.Communication
local Config = Modules.Config

print("[Sigma Spy SAFE MODE] Loaded Config:", Config.NoReceiveHooking)

-- Font (optional)
pcall(function()
    local FontContent = Files:GetAsset("ProggyClean.ttf", true)
    if FontContent then
        local FontJsonFile = Files:CreateFont("ProggyClean", FontContent)
        Ui:SetFontFile(FontJsonFile)
        print("[Sigma Spy SAFE MODE] Font loaded")
    end
end)

-- Load modules
print("[Sigma Spy SAFE MODE] Loading modules...")
Process:CheckConfig(Config)
Files:LoadModules(Modules, {Modules = Modules, Services = Services})

-- Create window
print("[Sigma Spy SAFE MODE] Creating window...")
local Window = Ui:CreateMainWindow()
print("[Sigma Spy SAFE MODE] Window created!")

-- Check support
print("[Sigma Spy SAFE MODE] Checking support...")
local Supported = Process:CheckIsSupported()
if not Supported then 
    Window:Close()
    return
end

-- Communication
print("[Sigma Spy SAFE MODE] Creating channel...")
local ChannelId, Event = Communication:CreateChannel()
Communication:AddCommCallback("QueueLog", function(...) Ui:QueueLog(...) end)
Communication:AddCommCallback("Print", function(...) Ui:ConsoleLog(...) end)

-- Generation
local LocalPlayer = Players.LocalPlayer
Generation:SetSwapsCallback(function(self)
    self:AddSwap(LocalPlayer, {String = "LocalPlayer"})
    if LocalPlayer.Character then
        self:AddSwap(LocalPlayer.Character, {String = "Character", NextParent = LocalPlayer})
    end
end)

-- UI
print("[Sigma Spy SAFE MODE] Setting up UI...")
Ui:CreateWindowContent(Window)
Ui:SetCommChannel(Event)
Ui:BeginLogService()

-- Hooks (META HOOKS ONLY - NO RECEIVE HOOKS)
print("[Sigma Spy SAFE MODE] Loading meta hooks only...")
local ActorCode = Files:MakeActorScript(Scripts, ChannelId)
Hook:LoadMetaHooks(ActorCode, ChannelId)  -- Only meta hooks, skip LoadReceiveHooks

-- NO FUNCTION PATCHES
print("[Sigma Spy SAFE MODE] Communicating begin hooks...")
Event:Fire("BeginHooks", {PatchFunctions = false})

print("[Sigma Spy SAFE MODE] ✅ Loaded successfully! (Outgoing calls only)")
warn("[Sigma Spy SAFE MODE] NOTE: Only logging OUTGOING remote calls (FireServer/InvokeServer)")
warn("[Sigma Spy SAFE MODE] Receive hooks disabled to prevent freezing")
