--[[
	|     .-.
	|    /   \         .-.
	|   /     \       /   \       .-.     .-.     _   _
	+--/-------\-----/-----\-----/---\---/---\---/-\-/-\/\/---
	| /         \   /       \   /     '-'     '-'
	|/           '-'         '-'
	
	parser library or whatever to call it since its yours not mine 
	i know you wont credit me or any of my work
	somebody shoot me 
]]

local modules = {
	cache = {},
	load = function(moduleName)
		if not modules.cache[moduleName] then
			modules.cache[moduleName] = { exports = modules[moduleName]() }
		end
		return modules.cache[moduleName].exports
	end
}

modules.a = function()
	local Formatter = {}
	Formatter.__index = Formatter
	
	local defaultTweenInfo = TweenInfo.new()
	local getServerTimeNow = workspace.GetServerTimeNow

	Formatter.ClassNameStrings = {
		DataModel = 'game',
		Workspace = 'workspace',
		Stats = 'stats()',
		GlobalSettings = 'settings()',
		PluginManagerInterface = 'PluginManager()',
		UserSettings = 'UserSettings()',
		DebuggerManager = 'DebuggerManager()'
	}

	Formatter.Formats = {
		CFrame = function(self, value)
			local str = self:FormatVectorValues(value, false, true)
			return `CFrame.new({str})`
		end,
		Vector3 = function(self, value)
			local str = self:FormatVectorValues(value)
			return `Vector3.new({str})`
		end,
		Vector2 = function(self, value)
			local str = self:FormatVectorValues(value, true)
			return `Vector2.new({str})`
		end,
		Vector2int16 = function(self, value)
			local str = self:FormatVectorValues(value, true)
			return `Vector2int16.new({str})`
		end,
		Vector3int16 = function(self, value)
			local str = self:FormatVectorValues(value)
			return `Vector3int16.new({str})`
		end,
		Color3 = function(self, value)
			return `Color3.fromRGB({value.R * 255}, {value.G * 255}, {value.B * 255})`
		end,
		NumberRange = function(self, value)
			local minStr, maxStr = self:Format(value.Min), self:Format(value.Max)
			return `NumberRange.new({minStr}, {maxStr})`
		end,
		NumberSequenceKeypoint = function(self, value)
			return `NumberSequenceKeypoint.new({value.Time}, {value.Value}, {value.Envelope})`
		end,
		ColorSequenceKeypoint = function(self, value)
			return `ColorSequenceKeypoint.new({value.Time}, {value.Value})`
		end,
		PathWaypoint = function(self, value)
			local posStr = self:Format(value.Position)
			local actionStr = `Enum.PathWaypointAction.{value.Action.Name}`
			return `PathWaypoint.new({posStr}, {actionStr}, "{value.Label}")`
		end,
		PhysicalProperties = function(self, value)
			return `PhysicalProperties.new({value.Density}, {value.Friction}, {value.Elasticity}, {value.FrictionWeight}, {value.ElasticityWeight})`
		end,
		Ray = function(self, value)
			local originStr, directionStr = self:Format(value.Origin), self:Format(value.Direction)
			return `Ray.new({originStr}, {directionStr})`
		end,
		UDim2 = function(self, value)
			return `UDim2.new({value.X.Scale}, {value.X.Offset}, {value.Y.Scale}, {value.Y.Offset})`
		end,
		UDim = function(self, value)
			return `UDim.new({value.Scale}, {value.Offset})`
		end,
		BrickColor = function(self, value)
			return `BrickColor.new("{value.Name}")`
		end,
		buffer = function(self, value)
			local str = buffer.tostring(value)
			str = self:Format(str)
			return `buffer.fromstring({str}) --[[{value}]]`
		end,
		DateTime = function(self, value)
			return `DateTime.fromUnixTimestampMillis({value.UnixTimestampMillis})`
		end,
		Font = function(self, value)
			local familyStr = self:Format(value.Family)
			return `Font.new({familyStr}, {value.Weight}, {value.Style.Name})`
		end,
		Enum = `%*`,
		string = function(self, value)
			local safeStr = self:MakePrintable(value)
			local formatStr = `"%*"`
			local hasMultilineStart, hasLineBreaks = safeStr:find('%[%[=*%[%['), safeStr:find('[\n\r]')
			if not hasMultilineStart and hasLineBreaks then
				formatStr = '[[%*]]'
			end
			return formatStr:format(safeStr)
		end,
		number = `%*`,
		TweenInfo = function(self, value)
			local styleStr = `Enum.EasingStyle.{value.EasingStyle.Name}`
			local dirStr = `Enum.EasingDirection.{value.EasingDirection.Name}`
			local isDefaultStyle = value.EasingStyle == defaultTweenInfo.EasingStyle
			local isDefaultDir = value.EasingDirection == defaultTweenInfo.EasingDirection
			local timeRounded = math.round(value.Time * 100) / 100
			
			if isDefaultStyle and isDefaultDir then
				return `TweenInfo.new({timeRounded})`
			end
			return `TweenInfo.new({timeRounded}, {styleStr}, {dirStr})`
		end,
		boolean = `%*`,
		Instance = function(self, value)
			local pathStr, parentCount = self.Parser:MakePathString({Object = value})
			return pathStr, parentCount > 2
		end,
		['function'] = function(self, value)
			local funcName = debug.info(value, 'n')
			local comment = ''
			if #funcName <= 0 then
				comment = `{value}`
			else
				comment = `function {funcName}`
			end
			return `function() end --[[{comment}]]`
		end,
		table = function(self, value, options)
			local indent = options.Indent or 0
			local str = self.Parser:ParseTableIntoString({
				NoBrackets = false, 
				Indent = indent + 1, 
				Table = value
			})
			return str
		end,
		RBXScriptSignal = function(self, value, options)
			local signalName = tostring(value):match(' (%a+)')
			return `nil --[[Signal: {signalName}]]`
		end
	}

	function Formatter:IsPrintable(str, isString)
		if isString then
			return str:match('[%g ]')
		end
		return str:match('[\n\r%g ]')
	end

	function Formatter:MakePrintable(str, isString)
		local safeStr = str:gsub('"', '\\"')
		return safeStr:gsub('.', function(char)
			if isString then
				char = char:gsub('\n', '\\n')
				char = char:gsub('\r', '\\r')
			end
			if self:IsPrintable(char, isString) then
				return char
			end
			return `\\{char:byte()}`
		end)
	end

	function Formatter:FormatVectorValues(vector, ...)
		local values = {self:RoundVector(vector, ...)}
		return table.concat(values, ', ')
	end

	function Formatter:RoundValues(valuesTable)
		local rounded = {}
		for _, val in next, valuesTable do
			table.insert(rounded, math.round(val))
		end
		return rounded
	end

	function Formatter:RoundVector(vector, ignoreZ, returnTable)
		local x, y, z = vector.X, vector.Y, not ignoreZ and vector.Z or 0
		if returnTable then
			local components = {vector:GetComponents()}
			return unpack(self:RoundValues(components))
		end
		return math.round(x), math.round(y), not ignoreZ and math.round(z) or nil
	end

	function Formatter:GetServerTimeNow()
		return getServerTimeNow(workspace)
	end

	function Formatter:MakeReplacements(startTime)
		local elapsedTime = tick() - (startTime or tick())
		local roundedServerTime = math.round(self:GetServerTimeNow() - elapsedTime)
		local roundedGameTime = math.round(workspace.DistributedGameTime - elapsedTime)
		local replacements = {}
		
		local function addSwap(value, name)
			if typeof(value) == 'number' then
				replacements[-value] = `-{name}`
			end
			replacements[value] = name
		end
		
		addSwap(Vector2.one, 'Vector2.one')
		addSwap(Vector2.zero, 'Vector2.zero')
		addSwap(Vector3.one, 'Vector3.one')
		addSwap(Vector3.zero, 'Vector3.zero')
		addSwap(math.huge, 'math.huge')
		addSwap(math.pi, 'math.pi')
		addSwap(workspace.Gravity, 'workspace.Gravity')
		addSwap(workspace.AirDensity, 'workspace.AirDensity')
		addSwap(workspace.CurrentCamera.CFrame, 'workspace.CurrentCamera.CFrame')
		addSwap(roundedGameTime, 'workspace.DistributedGameTime')
		addSwap(roundedServerTime, 'workspace:GetServerTimeNow()')
		
		return replacements
	end

	function Formatter:SetValueSwaps(swaps)
		self.ValueSwaps = swaps
	end

	function Formatter:FindStringIntSwap(str)
		local num = tonumber(str)
		if not num then return end
		return self:FindValueSwap(num)
	end

	function Formatter:FindValueSwap(value)
		local swaps = self.ValueSwaps
		local swapStr = swaps[value]
		if swapStr then return swapStr end
		
		if typeof(value) == 'string' then
			local numSwap = self:FindStringIntSwap(value)
			if numSwap then
				return `tostring({numSwap})`
			end
		end
		
		if typeof(value) ~= 'number' then return end
		return swaps[math.round(value)]
	end

	function Formatter:NeedsBrackets(str)
		if not str then return end
		if typeof(str) ~= 'string' then return true end
		return not str:match('^[%a_][%w_]*$')
	end

	function Formatter:MakeName(instance)
		local name = self:ObjectToString(instance)
		name = name:gsub('[./ #%@$%\u{a3}+-()\n\r]', '')
		name = self:MakePrintable(name, true)
		if self:NeedsBrackets(name) then return end
		if #name < 1 or #name > 30 then return end
		return name
	end

	function Formatter.new(config)
		local self = setmetatable({}, Formatter)
		self.ValueSwaps = self:MakeReplacements()
		return self
	end

	function Formatter:Format(value, options)
		local formats = self.Formats
		local variables = self.Variables
		options = options or {}
		
		local disableVariables = self.NoVariables or options.NoVariables
		local swapVal = self:FindValueSwap(value)
		
		if swapVal then return swapVal end
		
		local valType = typeof(value)
		local formatFunc = formats[valType]
		local instanceName = nil
		
		if valType == 'Instance' then
			instanceName = self:MakeName(value)
		end
		
		if typeof(formatFunc) == 'function' then
			local strRes, needsVar = formatFunc(self, value, options)
			if needsVar and not disableVariables then
				strRes = variables:MakeVariable({Name = instanceName, Lookup = value, Value = strRes})
			end
			return strRes
		end
		
		if not formatFunc then
			return `{value} --[[{valType} not supported]]`
		end
		
		return formatFunc:format(value)
	end

	function Formatter:ObjectToString(instance)
		local swaps = self.Swaps
		local indexFunc = self.IndexFunc
		local classNameStrings = self.ClassNameStrings
		
		local name = indexFunc(instance, 'Name')
		local className = indexFunc(instance, 'ClassName')
		local mappedClass = classNameStrings[className]
		
		local resultStr = mappedClass or name
		resultStr = self:MakePrintable(resultStr, true)
		
		if swaps then
			local swapData = swaps[instance]
			if swapData then
				resultStr = swapData.String
			end
		end
		
		return resultStr
	end

	return Formatter
end


modules.b = function()
	local Parser = {}
	Parser.__index = Parser

	local function GetDictSize(dict)
		local count = 0
		for _ in next, dict do count += 1 end
		return count
	end

	function Parser.new(config)
		return setmetatable({}, Parser)
	end

	function Parser:FormatTableKey(key)
		local formatter = self.Formatter
		if typeof(key) ~= 'string' then return end
		if formatter:NeedsBrackets(key) then return end
		return `{key} = `
	end

	function Parser:ParseTableIntoString(args)
		local formatter = self.Formatter
		local indent = args.Indent or 0
		local tbl = args.Table
		local noBrackets = args.NoBrackets
		
		local dictSize = GetDictSize(tbl)
		local isArray = true
		
		if dictSize == 0 then
			return noBrackets and '' or '{}', dictSize, true
		end
		
		local tabs = string.rep('\t', indent)
		local str = `{not noBrackets and '{' or ''}\n`
		local count = 0
		
		for key, val in next, tbl do
			count += 1
			local valStr = formatter:Format(val, args)
			local isNumericOrder = key == count
			local comma = ''
			local keyStr = ''
			
			if typeof(key) ~= 'number' or not isNumericOrder then
				keyStr = self:FormatTableKey(key)
				isArray = false
				if not keyStr then
					local formattedKey = formatter:Format(key, args)
					keyStr = `[{formattedKey}] = `
				end
			end
			
			if count < dictSize then
				comma = ','
			end
			
			str ..= `{tabs}\t{keyStr}{valStr}{comma}\n`
		end
		
		str ..= `{tabs}{not noBrackets and '}' or ''}`
		return str, dictSize, isArray
	end

	function Parser:MakeVariableCodeLine(args)
		local varName, varValue, comment = args.Name, args.Value, args.Comment
		local declaration = `local {varName} = {varValue}`
		local commentStr = comment and ` -- {comment}` or ''
		return `{declaration}{commentStr}`
	end

	function Parser:MakeVariableCodeLines(args)
		local varsSystem = self.Variables
		local variables = args.Variables
		local ordered = varsSystem:OrderVariables(variables)
		local output = ''
		
		for _, varData in ordered do
			local line = self:MakeVariableCodeLine(varData)
			output ..= `{line}\n`
		end
		
		return output
	end

	function Parser:MakeVariableCode(classes, skipComments)
		local varsSystem = self.Variables
		local dict = varsSystem.VariablesDict
		local output = ''
		local count = 0
		
		for _, className in next, classes do
			local classVars = dict[className]
			if classVars then
				count += 1
				output ..= count > 1 and '\n' or ''
				output ..= skipComments and '' or `-- {className}\n`
				output ..= self:MakeVariableCodeLines(classVars)
			end
		end
		
		return output
	end

	function Parser:MakePathString(args)
		local varsSystem = self.Variables
		local formatter = self.Formatter
		local instance = args.Object
		local parents = args.Parents
		local noVariables = self.NoVariables or args.NoVariables
		
		local pathStr = ''
		local parentCount = 0
		parents = parents or varsSystem:MakeParentsTable(instance, noVariables)
		
		local function checkService(parentInst, strName)
			local serviceName = varsSystem:IsService(parentInst)
			if not serviceName then return false end
			
			local getServiceStr = `game:GetService("{serviceName}")`
			if noVariables then
				pathStr = getServiceStr
				return true
			end
			
			local varName = varsSystem:MakeVariable({Name = serviceName, Class = 'Services', Value = getServiceStr})
			pathStr = varName
			return true
		end
		
		for index, parentInst in next, parents do
			local strObj = formatter:ObjectToString(parentInst)
			local varData = varsSystem:GetVariable(parentInst)
			
			if varData and not noVariables then
				strObj = varData.Name
			end
			
			if index == 2 and parents[1] == game then
				if checkService(parentInst, strObj) then
					continue
				end
			end
			
			local needsBrackets = formatter:NeedsBrackets(strObj)
			local prefix = index > 1 and '.' or ''
			parentCount += 1
			pathStr ..= needsBrackets and `["{strObj}"]` or `{prefix}{strObj}`
		end
		
		return pathStr, parentCount
	end

	return Parser
end


modules.c = function()
	local Variables = { VariableBase = 'Jit' }
	Variables.__index = Variables
	
	local env = getfenv(1)
	
	local function appendTable(dest, src)
		for _, v in next, src do
			table.insert(dest, v)
		end
	end

	local typeHandlers = {
		Instance = function(self, instances)
			local parentsList, parentMap = self:BulkCollectParents(instances)
			local duplicates = self:FindDuplicates(parentsList)
			
			for _, inst in next, duplicates do
				local pathStr, parentCount = self.Parser:MakePathString({Object = inst})
				if parentCount >= 3 then
					local name = self.Formatter:MakeName(inst)
					self:MakeVariable({Lookup = inst, Name = name, Value = pathStr})
				end
			end
		end
	}

	function Variables.new(config)
		local self = {
			VariablesDict = {},
			VariableLookup = {},
			InstanceQueue = {},
			VariableNames = {},
			NoNameCount = 0
		}
		return setmetatable(self, Variables)
	end

	function Variables:GetNoNameCount()
		return self.NoNameCount
	end

	function Variables:AddVariableToClass(classDict, varData)
		local val = varData.Value
		local lookupKey = varData.Lookup or val
		
		classDict.VariableCount += 1
		varData.Order = classDict.VariableCount
		classDict.Variables[lookupKey] = varData
	end

	function Variables:GetClassDict(className)
		local dict = self.VariablesDict
		local classData = dict[className]
		if classData then return classData end
		
		classData = { VariableCount = 0, Variables = {} }
		dict[className] = classData
		return classData
	end

	function Variables:IsGlobal(value)
		local indexFunc = self.IndexFunc
		if typeof(value) == 'Instance' then
			local name = indexFunc(value, 'Name')
			return env[name] == value
		end
		return env[value] and value or false
	end

	function Variables:IsService(instance)
		local indexFunc = self.IndexFunc
		local className = indexFunc(instance, 'ClassName')
		local success = pcall(function() return game:GetService(className) end)
		return success and className or false
	end

	function Variables:IncreaseNameUseCount(name)
		if not name then return 0 end
		local namesDict = self.VariableNames
		local count = namesDict[name]
		if not count then
			count = 0
			namesDict[name] = count
		end
		namesDict[name] += 1
		return count
	end

	function Variables:IncreaseNoNameCount()
		self.NoNameCount += 1
		return self.NoNameCount
	end

	function Variables:CheckName(varData)
		local name = varData.Name
		local useCount = self:IncreaseNameUseCount(name)
		
		if name then
			if useCount <= 0 then
				return name
			else
				return `{name}{useCount}`
			end
		end
		
		local noNameID = self:IncreaseNoNameCount()
		return self.VariableBase:format(noNameID)
	end

	function Variables:GetVariable(lookup)
		return self.VariableLookup[lookup]
	end

	function Variables:OrderVariables(dict)
		local ordered = {}
		for _, varData in next, dict do
			table.insert(ordered, varData.Order, varData)
		end
		return ordered
	end

	function Variables:MakeVariable(varData)
		local lookupDict = self.VariableLookup
		local queue = self.InstanceQueue
		local val = varData.Value
		local lookupKey = varData.Lookup or val
		local className = varData.Class or 'Variables'
		
		local existingVar = self:GetVariable(lookupKey)
		if existingVar then
			return existingVar.Name
		end
		
		local isGlobal = self:IsGlobal(val)
		if isGlobal then
			return isGlobal
		end
		
		if not varData.Name and typeof(val) == 'Instance' then
			queue[val] = varData
		end
		
		local finalName = self:CheckName(varData)
		varData.Name = finalName
		
		local classDict = self:GetClassDict(className)
		self:AddVariableToClass(classDict, varData)
		lookupDict[lookupKey] = varData
		
		return finalName
	end

	function Variables:CollectTableItems(tbl, callback)
		local function traverse(item)
			if typeof(item) == 'table' then
				self:CollectTableItems(item, callback)
				return
			end
			callback(item)
		end
		
		for k, v in next, tbl do
			traverse(k)
			traverse(v)
		end
	end

	function Variables:FindDuplicates(tbl)
		local duplicates = {}
		local counts = {}
		
		for _, item in next, tbl do
			local count = counts[item]
			if count == 1 then
				counts[item] = 2
				table.insert(duplicates, item)
			else
				counts[item] = 1
			end
		end
		
		table.clear(counts)
		return duplicates
	end

	function Variables:CollectTableTypes(tbl, allowedTypes)
		local sortedTypes = {}
		
		local function typeCheckCallback(item)
			local t = typeof(item)
			if not table.find(allowedTypes, t) then return end
			
			local list = sortedTypes[t]
			if not list then
				list = {}
				sortedTypes[t] = list
			end
			table.insert(list, item)
		end
		
		self:CollectTableItems(tbl, typeCheckCallback)
		return sortedTypes
	end

	function Variables:MakeParentsTable(instance, noVariables)
		local indexFunc = self.IndexFunc
		local swaps = self.Swaps
		local varSystem = self.Variables
		noVariables = self.NoVariables or noVariables
		
		local hierarchy = {}
		local current = instance
		
		while true do
			local previous = current
			current = indexFunc(current, 'Parent')
			
			if current == game and self:IsGlobal(previous) then
				current = nil
			end
			
			if swaps then
				local swapData = swaps[previous]
				if swapData and swapData.NextParent then
					current = swapData.NextParent
				end
			end
			
			local existingVar = varSystem:GetVariable(previous)
			if not noVariables and existingVar and current then
				current = nil
			end
			
			table.insert(hierarchy, 1, previous)
			if not current then break end
		end
		
		return hierarchy
	end

	function Variables:BulkCollectParents(instances)
		local allParentsList = {}
		local mappedParents = {}
		
		for _, inst in next, instances do
			if typeof(inst) == 'Instance' then
				local parentsTable = self:MakeParentsTable(inst)
				appendTable(allParentsList, parentsTable)
				mappedParents[inst] = parentsTable
			end
		end
		
		return allParentsList, mappedParents
	end

	function Variables:PrerenderVariables(tbl, allowedTypes)
		if self.NoVariables then return end
		
		local typedItems = self:CollectTableTypes(tbl, allowedTypes)
		for typeName, list in next, typedItems do
			local handler = typeHandlers[typeName]
			if handler then
				handler(self, list)
			end
		end
	end

	return Variables
end

local MainModule = {
	Version = '1.0.8',
	Author = 'Depso',
	License = 'GNU-GPLv3',
	Repository = 'https://github.com/depthso/Roblox-parser',
	ImportUrl = [[https://raw.githubusercontent.com/mmmhlecaca/Sigma-Spy/refs/heads/main/lib]],
	Modules = {
		Formatter = modules.load('a'),
		Parser = modules.load('b'),
		Variables = modules.load('c')
	}
}

local function extendTable(dest, src)
	for k, v in next, src do
		dest[k] = v
	end
end

function MainModule:New(config)
	local mods = self.Modules
	local instance = {
		Variables = mods.Variables.new(),
		Formatter = mods.Formatter.new(),
		Parser = mods.Parser.new()
	}
	
	if config then
		extendTable(instance, config)
	end
	
	for _, moduleInst in next, instance do
		if typeof(moduleInst) == 'table' and moduleInst.new then
			extendTable(moduleInst, instance)
		end
	end
	
	return instance
end

return MainModule
