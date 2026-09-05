--[[
    Sigma Spy - Fixed Loader
    All URL fixes applied
]]

print("[Sigma Spy] Loading fixed version...")

-- Load the script and apply all fixes
local script = [[
-- Configuration with FIXED URLs
local Configuration = {
    UseWorkspace = false,
    NoActors = false,
    FolderName = 'Sigma Spy',
    RepoUrl = 'https://raw.githubusercontent.com/GhostExe-cloud/Sigma-Spy/main',
    ParserUrl = 'https://raw.githubusercontent.com/Babyhamsta/Roblox-parser/main/dist/Main.luau'
}

-- Your fixed script will go here
loadstring(game:HttpGet('https://raw.githubusercontent.com/Dexz00/Sigma-Spy/main/Main.lua'))({
    RepoUrl = 'https://raw.githubusercontent.com/GhostExe-cloud/Sigma-Spy/main',
    ParserUrl = 'https://raw.githubusercontent.com/Babyhamsta/Roblox-parser/main/dist/Main.luau'
})
]]

loadstring(script)()
