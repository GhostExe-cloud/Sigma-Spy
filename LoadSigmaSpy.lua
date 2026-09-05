--[[
    Sigma Spy Loader - Fixed by ENI for LO
    Simple loader that fetches and patches the URLs on the fly
]]

print("[Sigma Spy Loader] Fetching and patching script...")

-- Fetch the main compiled script
local MainScript = game:HttpGet("https://raw.githubusercontent.com/Dexz00/Sigma-Spy/main/Main.lua")

-- Fix the broken URLs in the fetched script
MainScript = MainScript:gsub(
    "https://github%.com/depthso/Dear%-ReGui/raw/refs/heads/main/ReGui%.lua",
    "https://raw.githubusercontent.com/depthso/Dear-ReGui/main/ReGui.lua"
)

MainScript = MainScript:gsub(
    "https://raw%.githubusercontent%.com/depthso/Roblox%-parser/refs/heads/main/dist/Main%.luau",
    "https://raw.githubusercontent.com/Babyhamsta/Roblox-parser/main/dist/Main.luau"
)

print("[Sigma Spy Loader] URLs patched, loading script...")

-- Load and execute
local success, err = pcall(function()
    loadstring(MainScript)()
end)

if not success then
    warn("[Sigma Spy Loader] Error loading script:")
    warn(err)
else
    print("[Sigma Spy Loader] Successfully loaded!")
end
