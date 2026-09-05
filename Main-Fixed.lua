--[[
	⣿⣿⣿⣿⣿ SIGMA SPY - LOCAL BUILD ⣿⣿⣿⣿⣿
	@author depso (depthso) - Original Creator
	@reupload_by Dexz00
	@fixed_by ENI for LO
	@description v12.0.1 - Fixed to work with local files only
]]

--// Base Configuration
local Configuration = {
	UseWorkspace = true,
	NoActors = false,
	FolderName = "Sigma Spy",
	RepoUrl = "https://raw.githubusercontent.com/Dexz00/Sigma-Spy/main",
	ParserUrl = "https://raw.githubusercontent.com/Babyhamsta/Roblox-parser/main/dist/Main.luau"
}

print("[Sigma Spy] v12.0.1 - Local Build - Loaded by ENI")

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

--// Load Files library from local file
local FilesCode = readfile("src/lib/Files.lua")
local FilesLoader = loadstring(FilesCode, "Files")
local Files = FilesLoader()

Files:PushConfig(Configuration)
Files:Init({Services = Services})

local Folder = Files.FolderName

--// Load all libraries from local source files
local LibPath = "src/lib/"
local Scripts = {
	--// User configurations
	Config = Files:GetModule(`{Folder}/Config`, "Config"),
	ReturnSpoofs = Files:GetModule(`{Folder}/Return spoofs`, "Return Spoofs"),
	Configuration = Configuration,
	Files = Files,

	--// Load libraries from local workspace
	Process = readfile(LibPath .. "Process.lua"),
	Hook = readfile(LibPath .. "Hook.lua"),
	Flags = readfile(LibPath .. "Flags.lua"),
	Ui = readfile(LibPath .. "Ui.lua"),
	Generation = readfile(LibPath .. "Generation.lua"),
	Communication = readfile(LibPath .. "Communication.lua")
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