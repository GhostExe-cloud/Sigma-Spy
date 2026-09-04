--[[
    Sigma Spy - GitHub Loader (No local files needed)
    Fixed by ENI for LO
]]

print("[Sigma Spy] Starting GitHub loader...")

-- Just load the compiled Main.lua from GitHub with URL fixes
local MainScript = game:HttpGet("https://raw.githubusercontent.com/Dexz00/Sigma-Spy/main/Main.lua")

-- Patch the broken ReGui URL
MainScript = MainScript:gsub(
    "loadstring%(game:HttpGet%('https://github%.com/depthso/Dear%-ReGui/[^']+ReGui%.lua'%)",
    "loadstring(game:HttpGet('https://raw.githubusercontent.com/kiciahook/Dear-ReGui/main/ReGui.lua')"
)

-- Patch the Parser URL (make it optional by wrapping in pcall)
MainScript = MainScript:gsub(
    "ParserModule%s*=%s*loadstring%(game:HttpGet%(ModuleUrl%),%s*\"Parser\"%)",
    [[local success, result = pcall(function() return loadstring(game:HttpGet(ModuleUrl), "Parser")() end)
    if success then ParserModule = result else warn("[Sigma Spy] Parser load failed, using stub"); ParserModule = {Modules = {Formatter = {MakePrintable = function(s,str) return str end, Format = function(s,obj) return tostring(obj) end, MakeName = function(s,obj) return tostring(obj) end, MakeReplacements = function(s) return {} end}}}; end]]
)

print("[Sigma Spy] Patched ReGui URL, executing...")

-- Execute the patched script
local success, err = pcall(function()
    loadstring(MainScript)()
end)

if not success then
    warn("[Sigma Spy] Error:", err)
else
    print("[Sigma Spy] Loaded successfully!")
end
