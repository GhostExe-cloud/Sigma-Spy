-- Sigma Spy Quick Loader
-- This loads the fixed Main.lua directly

local RepoUrl = "https://raw.githubusercontent.com/GhostExe-cloud/Sigma-Spy/main"

-- Fetch and patch Main.lua on the fly
local MainCode = game:HttpGet(RepoUrl .. "/src/Main.lua")

-- Fetch and patch Ui.lua with nil checks
local UiCode = game:HttpGet(RepoUrl .. "/lib/Ui.lua")

-- Fix Ui.lua LoadReGui function
UiCode = UiCode:gsub(
    "local ThemeConfig = Config%.ThemeConfig",
    "local ThemeConfig = (Config and Config.ThemeConfig) or {BaseTheme = \"ImGui\", TextSize = 12}"
)

-- Fix Ui.lua SyntaxColors references
UiCode = UiCode:gsub(
    "local SyntaxColors = Config%.SyntaxColors",
    "local SyntaxColors = (Config and Config.SyntaxColors) or {}"
)

-- Fix Ui.lua Colors reference
UiCode = UiCode:gsub(
    "local Colors = Config%.SyntaxColors\n",
    "local Colors = (Config and Config.SyntaxColors) or {}\n"
)

-- Fix Ui.lua Debug check
UiCode = UiCode:gsub(
    "if Config%.Debug then",
    "if Config and Config.Debug then"
)

-- Save patched Ui.lua to a temporary location
writefile("SigmaSpy_Temp_Ui.lua", UiCode)

-- Patch Main.lua to use local patched Ui
MainCode = MainCode:gsub(
    'Ui = Files:GetFile%("lib/Ui%.lua"%)',
    'Ui = readfile("SigmaSpy_Temp_Ui.lua")'
)

-- Add Configuration to Modules
MainCode = MainCode:gsub(
    "local Modules = Files:LoadLibraries%(Scripts%)",
    "local Modules = Files:LoadLibraries(Scripts)\nModules.Configuration = Configuration"
)

-- Run the patched script
local Func = loadstring(MainCode, "SigmaSpy-Patched")
if Func then
    Func()
else
    error("[Sigma Spy] Failed to load patched script")
end

-- Cleanup
task.delay(5, function()
    if isfile("SigmaSpy_Temp_Ui.lua") then
        delfile("SigmaSpy_Temp_Ui.lua")
    end
end)
