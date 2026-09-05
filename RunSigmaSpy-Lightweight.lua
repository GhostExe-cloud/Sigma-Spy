--[[
    Sigma Spy - LIGHTWEIGHT VERSION
    Simple Roblox GUI instead of ReGui
    Works without freezing!
]]

print("[Sigma Spy LIGHTWEIGHT] Starting...")

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
    Communication = readfile("src/lib/Communication.lua"),
    Generation = readfile("src/lib/Generation.lua")
}

print("[Sigma Spy LIGHTWEIGHT] Loading libraries...")
local Modules = Files:LoadLibraries(Scripts)

local Process = Modules.Process
local Hook = Modules.Hook
local Communication = Modules.Communication
local Generation = Modules.Generation

print("[Sigma Spy LIGHTWEIGHT] Configuring...")
Process:CheckConfig(Modules.Config)
Files:LoadModules(Modules, {Modules = Modules, Services = Services})

-- Create simple GUI
print("[Sigma Spy LIGHTWEIGHT] Creating GUI...")
local CoreGui = Services.CoreGui
local Players = Services.Players

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SigmaSpyLite"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 400)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(100, 100, 255)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.Text = "🔍 Sigma Spy - Lightweight"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame

-- Log ScrollFrame
local LogFrame = Instance.new("ScrollingFrame")
LogFrame.Name = "LogFrame"
LogFrame.Size = UDim2.new(1, -10, 1, -75)
LogFrame.Position = UDim2.new(0, 5, 0, 35)
LogFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
LogFrame.BorderSizePixel = 1
LogFrame.ScrollBarThickness = 6
LogFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
LogFrame.Parent = MainFrame

local LogList = Instance.new("UIListLayout")
LogList.SortOrder = Enum.SortOrder.LayoutOrder
LogList.Padding = UDim.new(0, 2)
LogList.Parent = LogFrame

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "Status"
StatusLabel.Size = UDim2.new(1, -10, 0, 25)
StatusLabel.Position = UDim2.new(0, 5, 1, -30)
StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusLabel.Text = "✅ Ready - Logging remotes..."
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.Parent = MainFrame

-- Toggle Button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "Toggle"
ToggleButton.Size = UDim2.new(0, 80, 0, 25)
ToggleButton.Position = UDim2.new(1, -90, 1, -30)
ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 180)
ToggleButton.Text = "Hide [P]"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.Gotham
ToggleButton.TextSize = 11
ToggleButton.Parent = MainFrame

local LogCount = 0
local MaxLogs = 100

-- Add log entry
local function AddLog(logData)
    LogCount = LogCount + 1
    
    local LogEntry = Instance.new("TextButton")
    LogEntry.Name = "Log_" .. LogCount
    LogEntry.Size = UDim2.new(1, -10, 0, 25)
    LogEntry.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    LogEntry.AutoButtonColor = true
    LogEntry.Font = Enum.Font.Code
    LogEntry.TextSize = 11
    LogEntry.TextColor3 = Color3.fromRGB(255, 255, 255)
    LogEntry.TextXAlignment = Enum.TextXAlignment.Left
    LogEntry.Text = string.format("  [%s] %s:%s | Args: %d", 
        os.date("%H:%M:%S"), 
        tostring(logData.Remote):gsub("^.*%.", ""), 
        logData.Method, 
        #logData.Args
    )
    LogEntry.LayoutOrder = -LogCount
    LogEntry.Parent = LogFrame
    
    -- Click to copy code
    LogEntry.MouseButton1Click:Connect(function()
        local Module = Generation:NewParser()
        local code = Generation:RemoteScript(Module, logData, "Remote")
        setclipboard(code)
        StatusLabel.Text = "📋 Copied script to clipboard!"
        wait(2)
        StatusLabel.Text = "✅ Ready - Logging remotes..."
    end)
    
    -- Remove old logs
    if LogCount > MaxLogs then
        local children = LogFrame:GetChildren()
        for i, child in ipairs(children) do
            if child:IsA("TextButton") and child.LayoutOrder > -LogCount + MaxLogs then
                child:Destroy()
            end
        end
    end
    
    -- Update canvas size
    LogFrame.CanvasSize = UDim2.new(0, 0, 0, LogList.AbsoluteContentSize.Y)
end

-- Toggle visibility
local visible = true
ToggleButton.MouseButton1Click:Connect(function()
    visible = not visible
    MainFrame.Visible = visible
    ToggleButton.Text = visible and "Hide [P]" or "Show [P]"
end)

-- Keybind
Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.P then
        visible = not visible
        MainFrame.Visible = visible
        ToggleButton.Text = visible and "Hide [P]" or "Show [P]"
    end
end)

-- Create communication channel
print("[Sigma Spy LIGHTWEIGHT] Creating channel...")
local ChannelId, Event = Communication:CreateChannel()

-- Logger with GUI
Communication:AddCommCallback("QueueLog", function(Data)
    pcall(function()
        AddLog(Data)
    end)
end)

Communication:AddCommCallback("Print", function(...)
    print("[COMM]", ...)
end)

-- Generation swaps
local LocalPlayer = Players.LocalPlayer
Generation:SetSwapsCallback(function(self)
    self:AddSwap(LocalPlayer, {String = "LocalPlayer"})
    if LocalPlayer.Character then
        self:AddSwap(LocalPlayer.Character, {String = "Character", NextParent = LocalPlayer})
    end
end)

-- Load hooks
print("[Sigma Spy LIGHTWEIGHT] Loading hooks...")
local ActorCode = Files:MakeActorScript(Scripts, ChannelId)
Hook:LoadMetaHooks(ActorCode, ChannelId)

-- Begin hooks
print("[Sigma Spy LIGHTWEIGHT] Starting hooks...")
Event:Fire("BeginHooks", {PatchFunctions = false})

print("[Sigma Spy LIGHTWEIGHT] ✅ READY!")
print("[Sigma Spy LIGHTWEIGHT] Press P to toggle UI")
print("[Sigma Spy LIGHTWEIGHT] Click on any log to copy the script!")
