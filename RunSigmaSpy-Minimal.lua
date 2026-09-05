--[[
    Sigma Spy - MINIMAL TEST
    No UI, just console logging to test if hooks work
]]

print("[Sigma Spy MINIMAL] Starting...")

-- Load Files library
local Files = loadstring(readfile("src/lib/Files.lua"))()

-- Configuration
local Configuration = {
    UseWorkspace = false,
    NoActors = true,
    FolderName = "Sigma Spy",
    RepoUrl = "https://raw.githubusercontent.com/Dexz00/Sigma-Spy/main",
    ParserUrl = "https://raw.githubusercontent.com/xfwil/Roblox-parser/main/dist/Main.luau"
}

-- Services
local Services = setmetatable({}, {
    __index = function(self, Name)
        return cloneref(game:GetService(Name))
    end,
})

Files:PushConfig(Configuration)
Files:Init({Services = Services})

-- Safe config
local SafeConfig = [[return {
    NoReceiveHooking = true,
    NoFunctionPatching = true,
    BlackListedServices = {"RobloxReplicatedStorage", "CoreGui", "CorePackages", "Players"},
    ForceUseCustomComm = false,
    Debug = true
}]]

-- Load libraries
local Scripts = {
    Config = SafeConfig,
    ReturnSpoofs = Files:GetModule(`{Configuration.FolderName}/Return spoofs`, "Return Spoofs"),
    Configuration = Configuration,
    Files = Files,
    Process = readfile("src/lib/Process.lua"),
    Hook = readfile("src/lib/Hook.lua"),
    Flags = readfile("src/lib/Flags.lua"),
    Communication = readfile("src/lib/Communication.lua")
}

print("[Sigma Spy MINIMAL] Loading libraries...")
local Modules = Files:LoadLibraries(Scripts)

local Process = Modules.Process
local Hook = Modules.Hook
local Communication = Modules.Communication

print("[Sigma Spy MINIMAL] Configuring...")
Process:CheckConfig(Modules.Config)
Files:LoadModules(Modules, {Modules = Modules, Services = Services})

-- Create communication channel
print("[Sigma Spy MINIMAL] Creating channel...")
local ChannelId, Event = Communication:CreateChannel()

-- Simple console logger
Communication:AddCommCallback("QueueLog", function(Data)
    local Remote = Data.Remote
    local Method = Data.Method
    local Args = Data.Args or {}
    
    print(string.format("[REMOTE LOG] %s:%s | Args: %d", tostring(Remote), Method, #Args))
end)

Communication:AddCommCallback("Print", function(...)
    print("[COMM]", ...)
end)

-- Load hooks (meta only)
print("[Sigma Spy MINIMAL] Loading hooks...")
local ActorCode = Files:MakeActorScript(Scripts, ChannelId)
Hook:LoadMetaHooks(ActorCode, ChannelId)

-- Begin hooks
print("[Sigma Spy MINIMAL] Starting hooks...")
Event:Fire("BeginHooks", {PatchFunctions = false})

print("[Sigma Spy MINIMAL] ✅ READY! Remote calls will be logged to console (F9)")
print("[Sigma Spy MINIMAL] Press F9 to open console and see logged remotes")
