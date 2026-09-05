--[[
    Sigma Spy - Local Loader (Fixed by ENI)
    Make sure src/, templates/, and assets/ folders are in your executor workspace!
]]

print("[Sigma Spy] Loading from local files...")

-- Load Files library first
local Files = loadstring(readfile("src/lib/Files.lua"))()

-- Configuration
local Configuration = {
    UseWorkspace = false,  -- Changed to false to fetch Config/templates from GitHub
    NoActors = false,
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

-- Load all libraries
local Scripts = {
    Config = Files:GetModule(`{Folder}/Config`, "Config"),
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

-- Font (optional - skip if file doesn't exist)
local FontSuccess, FontContent = pcall(function()
    return Files:GetAsset("ProggyClean.ttf", true)
end)
if FontSuccess and FontContent then
    local FontJsonFile = Files:CreateFont("ProggyClean", FontContent)
    Ui:SetFontFile(FontJsonFile)
    print("[Sigma Spy] Custom font loaded successfully")
else
    print("[Sigma Spy] Using default font (ProggyClean.ttf not found)")
end

-- Load modules
print("[Sigma Spy] Loading modules...")
Process:CheckConfig(Config)
Files:LoadModules(Modules, {Modules = Modules, Services = Services})

-- Create window
print("[Sigma Spy] Creating main window...")
local Window = Ui:CreateMainWindow()
print("[Sigma Spy] Window created!")

-- Check support
print("[Sigma Spy] Checking executor support...")
local Supported = Process:CheckIsSupported()
if not Supported then 
    Window:Close()
    return
end
print("[Sigma Spy] Executor supported!")

-- Communication
print("[Sigma Spy] Creating communication channel...")
local ChannelId, Event = Communication:CreateChannel()
print("[Sigma Spy] Channel created!")
Communication:AddCommCallback("QueueLog", function(...) Ui:QueueLog(...) end)
Communication:AddCommCallback("Print", function(...) Ui:ConsoleLog(...) end)

-- Generation
local LocalPlayer = Players.LocalPlayer
Generation:SetSwapsCallback(function(self)
    self:AddSwap(LocalPlayer, {String = "LocalPlayer"})
    self:AddSwap(LocalPlayer.Character, {String = "Character", NextParent = LocalPlayer})
end)

-- UI
Ui:CreateWindowContent(Window)
Ui:SetCommChannel(Event)
Ui:BeginLogService()

-- Hooks
local ActorCode = Files:MakeActorScript(Scripts, ChannelId)
Hook:LoadHooks(ActorCode, ChannelId)

local EnablePatches = Ui:AskUser({
    Title = "Enable function patches?",
    Content = {
        "On some executors, function patches can prevent common detections",
        "By enabling this, it MAY trigger hook detections in some games",
        "If it doesn't work, rejoin and press 'No'",
        "",
        "(This does not affect game functionality)"
    },
    Options = {"Yes", "No"}
}) == "Yes"

Event:Fire("BeginHooks", {PatchFunctions = EnablePatches})

print("[Sigma Spy] Loaded successfully!")
