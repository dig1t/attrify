local valueClasses = {
	BoolValue = true,
	BrickColorValue = true,
	CFrameValue = true,
	Color3Value = true,
	IntValue = true,
	NumberValue = true,
	ObjectValue = true,
	RayValue = true,
	StringValue = true,
	Vector3Value = true,
}

local TableUtil = {}

--[=[
	Unsafely sets a key in a table or Instance without erroring.

	Returns a boolean indicating if the operation was successful.

	#### Example:
	```lua
	Util.unsafeSet(Workspace.Player1.Humanoid, "Health", 100)
	```

	@within Util
	@param object Instance | { [any]: any }
	@param key any
	@param value any
	@return boolean -- Whether the operation was successful
]=]
function TableUtil.unsafeSet(
	object: Instance | { [any]: any },
	key: any,
	value: any
): boolean
	assert(
		typeof(object) == "Instance" or typeof(object) == "table",
		"Util.unsafeSet - object must be an Instance or table"
	)

	return pcall(function()
		(object :: any)[key] = value
	end)
end

--[=[
	Flips the table's keys with its values.
	If `mergeDuplicates` is `true`, All values will be stored in a table at the key's index, instead of overwriting them.

	#### Example:
	```lua
	Util.flip({ a = 1, b = 2 }) -- { [1] = "a", [2] = "b" }
	Util.flip({ a = 1, b = 2 }, true) -- { [1] = { "a" }, [2] = { "b" } }

	-- Use case: finding all keys with the same value
	local newTable = Util.flip({ a = 1, b = 2, c = 2 }, true) -- { [1] = { "a" }, [2] = { "b", "c" } }
	print(#newTable[2]) -- 2
	```

	@within Util
	@param source { [any]: any } -- The table you want to flip
	@param mergeDuplicates boolean? -- Merge key duplicates into a table instead of overwriting them.
	@return { [any]: any }
]=]
function TableUtil.flip(source: { [any]: any }, mergeDuplicates: boolean?): { [any]: any }
	assert(typeof(source) == "table", `Util.flip - Cannot index {typeof(source)}`)
	assert(
		mergeDuplicates == nil or typeof(mergeDuplicates) == "boolean",
		"Util.flip - mergeDuplicates must be a boolean or nil"
	)

	local res: { [any]: any } = {}
	local duplicates: { [any]: { any } } = {}

	for key: any, value: any in pairs(source) do
		if res[value] == nil then
			res[value] = key
		elseif mergeDuplicates then
			if not duplicates[value] then
				duplicates[value] = { key }
				res[value] = duplicates[value]
			else
				duplicates[value][#duplicates[value] + 1] = key
			end
		end
	end

	return res
end

--[=[
	Maps a table or instance to a new table.

	#### Example:
	```lua
	Util.map({ 1, 2, 3 }, function(v)
		return v * 2
	end) -- { 2, 4, 6 }

	Util.map({ 1, 2, 3 }, function(v, i)
		return i * 2
	end) -- { 2, 4, 6 }
	```

	@within Util
	@param source { [any]: any } -- The table you want to map
	@param callbackFn (any, any, any) -> (any, any) -- The function to map the table with
	@return { [any]: any }
]=]
function TableUtil.map(
	source: { [any]: any },
	callbackFn: (any, any, any) -> (any, any)
): { [any]: any }
	assert(
		typeof(source) == "table" or typeof(source) == "Instance",
		"source must be a table or instance"
	)
	assert(
		callbackFn == nil or typeof(callbackFn) == "function",
		"callbackFn must be a function or nil"
	)

	local res = {}

	for key: any, value: any in
		pairs(
			-- If instance, convert variable to a table of its children
			typeof(source) == "Instance" and source:GetChildren() or source
		)
	do
		local index: any = #res + 1

		if callbackFn then
			local result, secondResult = callbackFn(value, key, source)

			if secondResult ~= nil then -- Both the index and value are specified
				index = result
				value = secondResult
			else -- If there is no second result, we will use "#res + 1" as the index
				value = result -- Use the first result as the value
			end
		end

		res[index] = value
	end

	return res
end

--[=[
	Filter a table or instance to a new table.

	#### Example:
	```lua
	local noTwo = Util.filter({ 1, 2, 3 }, function(value)
		return value ~= 2
	end) -- { 1, 3 }

	local parts = Util.filter(Workspace, function(value)
		return value:IsA("Part")
	end) -- { Part = Instance, Part2 = Instance }
	```

	@within Util
	@param source { [any]: any } -- The table you want to filter
	@param callbackFn (any, any, any) -> (boolean?) -- The function to filter the table with (element, index, source)
	@return { [any]: any }
]=]
function TableUtil.filter(
	source: { [any]: any },
	callbackFn: (any, any, any) -> boolean?
): { [any]: any }
	assert(
		typeof(source) == "table" or typeof(source) == "Instance",
		"source must be a table or instance"
	)
	assert(
		callbackFn == nil or typeof(callbackFn) == "function",
		"callbackFn must be a function or nil"
	)

	local res = {}

	for key: any, value: any in
		pairs(
			-- If instance, convert variable to a table of its children
			typeof(source) == "Instance" and source:GetChildren() or source
		)
	do
		if callbackFn(value, key, source) == true then
			table.insert(res, value)
		end
	end

	return res
end

-- Map an object by index

--[=[
	Maps a table to a new table using the index as the key.

	Includes a second argument as a function to filter the table with.

	#### Example:
	```lua
	Util.mapIndex({ 1, 2, 3 }) -- { [1] = 1, [2] = 2, [3] = 3 }

	Util.mapIndex({ 1, 2, 3 }, function(v)
		return v * 2
	end) -- { [1] = 2, [2] = 4, [3] = 6 }

	Util.mapIndex({ 1, 2, 3 }, function(v, i)
		return i * 2
	end) -- { [2] = 2, [4] = 4, [6] = 6 }
	```

	@within Util
	@param source { [any]: any } -- The table you want to map
	@param filterFn (key: any, value: any, source: any) -> (value: any, key: any) -- The function to filter the table with
	@return { [any]: any }
]=]
function TableUtil.mapIndex(
	source: { [any]: any },
	filterFn: (any, any, any) -> (any, any)
): { [any]: any }
	assert(typeof(source) == "table", "source must be a table")
	assert(
		filterFn == nil or typeof(filterFn) == "function",
		"filterFn must be a function or nil"
	)

	local res = {}

	for key: any, value: any in source do
		local index = #res + 1

		if filterFn then
			local fnVal, fnKey = filterFn(value, key, source)

			if fnKey then
				index = fnKey
			end

			if fnVal ~= nil then
				value = fnVal
			end
		end

		res[index] = value
	end

	return res
end

--[=[
	Trims leading and trailing whitespace from a string.

	#### Example:
	```lua
	Util.trimWhitespace("  Hello, world!  ") -- "Hello, world!"
	```

	@within Util
	@param text string
	@return string
]=]
function TableUtil.trimWhitespace(text: string): string
	assert(typeof(text) == "string", "text must be a string")

	return string.match(text, "^%s*(.-)%s*$") :: string
end

--[=[
	Trims leading whitespace from a string.

	#### Example:
	```lua
	Util.trimLeadingWhitespace("  Hello, world!") -- "Hello, world!"
	```

	@within Util
	@param text string
	@return string
]=]
function TableUtil.trimLeadingWhitespace(text: string): string
	assert(typeof(text) == "string", "text must be a string")

	return string.match(text, "^%s*(.-)$") :: string
end

--[=[
	Trims trailing whitespace from a string.

	#### Example:
	```lua
	Util.trimTrailingWhitespace("Hello, world!  ") -- "Hello, world!"
	```

	@within Util
	@param text string
	@return string
]=]
function TableUtil.trimTrailingWhitespace(text: string): string
	assert(typeof(text) == "string", "text must be a string")

	return string.match(text, "^(.-)%s*$") :: string
end

--[=[
	Splits a string into a table of strings using a delimiter.
	If `delimiter` is not provided, it defaults to a space.

	Setting `trimTrailingDelimiter` to `false` will result in an empty string at the end of the table if the text ends with the delimiter

	Setting `trim` to `false` will result in whitespace not being trimmed from each chunk

	#### Example:
	```lua
	Util.split("Hello, world!") -- { "Hello,", "world!" }
	Util.split("Hello, world!", ", ") -- { "Hello", "world!" }
	Util.split("Hello, world!", ",", nil, false) -- { "Hello", " world!" } -- no whitespace is trimmed
	Util.split("Hello, world!,", ",", false) -- { "Hello", "world!", "" } -- trailing delimiter is included

	Util.split("path/to/file", "/") -- { "path", "to", "file" }
	Util.split("path/to/file/", "/") -- { "path", "to", "file" } -- trailing delimiter is trimmed
	```

	@within Util
	@param text string | number?
	@param delimiter string?
	@param trimTrailingDelimiter boolean?
	@param trim boolean? -- Trim whitespace from each chunk
	@return { string }
]=]
function TableUtil.split(
	text: string | number?,
	delimiter: string?,
	trimTrailingDelimiter: boolean?,
	trim: boolean?
): { string }
	if typeof(text) == "number" then
		text = tostring(text) :: string
	end

	if not text then
		return {}
	end

	assert(typeof(text) == "string", "text must be a string")
	assert(
		delimiter == nil or typeof(delimiter) == "string",
		"delimiter must be a string or nil"
	)
	assert(
		trimTrailingDelimiter == nil or typeof(trimTrailingDelimiter) == "boolean",
		"trimTrailingDelimiter must be a boolean or nil"
	)
	assert(trim == nil or typeof(trim) == "boolean", "trim must be a boolean or nil")

	if trimTrailingDelimiter == nil then
		trimTrailingDelimiter = true
	end

	if trim == nil then
		trim = true
	end

	if not delimiter then
		delimiter = " " :: string
	end

	text = tostring(text)

	local chunks: { string } = {}

	if not trimTrailingDelimiter and text:sub(0, 1) == delimiter then
		chunks[1] = ""
	end

	-- Trim trailing spaces
	while string.len(text) > 0 and string.sub(text, -1, -1) == " " do
		text = text:sub(0, -2)
	end

	for match: string in string.gmatch(text, `([^{delimiter}]+)`) do
		table.insert(chunks, trim and TableUtil.trimWhitespace(match) or match)
	end

	if not trimTrailingDelimiter and text:sub(-1, -1) == delimiter then
		table.insert(chunks, "")
	end

	return chunks
end

--[[
-- Todo: add nested merge
function TableUtil.mergeNested(to, from) -- Merges to the first given table
	assert(typeof(to) == "table", "First argument must be a table")
	assert(typeof(from) == "table", "Second argument must be a table")

	for k, v in pairs(from) do
		to[k] = v

		if typeof(v) == "table" then
			TableUtil.mergeNested(to[k], v)
		end
	end
end]]

--[=[
	Joins a table of strings and numbers into a single string.

	The string is joined using a separator, which defaults to a comma.

	#### Example:
	```lua
	Util.join({"Hello", "world!"}) -- "Hello,world!"
	Util.join({"Hello", "world!"}, ", ") -- "Hello, world!"
	```

	@within Util
	@param stringTable { [any]: string | number } -- The table you want to join
	@param separator string? -- The separator to use when joining the table (defaults to ",")
	@return string
]=]
function TableUtil.join(
	stringTable: { [any]: string | number },
	separator: string
): string
	assert(stringTable, "Util.join - Missing object")
	assert(
		typeof(stringTable) == "table",
		"Util.join - Cannot index " .. typeof(stringTable)
	)
	assert(typeof(separator) == "string", "Util.join - Separator must be a string or nil")

	if not separator then
		separator = ","
	end

	local res: string = ""

	for index: number, value: string | number in stringTable do
		local _value: string | number? = value

		if typeof(_value) == "number" then
			_value = tostring(_value) :: string
		end

		if typeof(_value) == "string" then
			res = res .. (index == #stringTable and _value or _value .. separator)
		end
	end

	return res
end

--[=[
	Extends a table with one or more tables.

	#### Example:
	```lua
	Util.extend({ a = 1 }, { b = 2 }, { c = 3 }) -- { a = 1, b = 2, c = 3 }
	Util.extend({ a = 1 }, { a = 2 }, { a = 3 }) -- { a = 3 } -- Last argument overwrites previous arguments
	Util.extend({ a = 1 }, { a = 2 }, { a = 3 }, true) -- Error: 4th argument must be a table
	```

	#### Config override example:
	```lua
	local function getDefaultConfig()
		return {
			health = 100
		}
	end

	local buffConfig = {
		health = 150,
		speed = 1.5
	}

	local hasBuff: boolean = true
	local playerConfig: { [any]: any } = Util.extend(getDefaultConfig(), hasBuff and buffConfig) -- { health = 150, speed = 1.5 }
	```

	@within Util
	@param targetTable { [any]: any } -- The target table you want to extend
	@param ... { [any]: any }? -- The tables you want to merge into the target table
	@return { [any]: any }
]=]
function TableUtil.extend(
	targetTable: { [any]: any },
	...: { [any]: any }?
): { [any]: any }
	for argIndex: number, sourceTable: { [any]: any } in pairs({ ... } :: { [any]: any }) do
		assert(typeof(sourceTable) == "table", `Argument #{argIndex} must be a table`)

		for key, value in pairs(sourceTable) do
			targetTable[key] = value
		end
	end

	return targetTable
end

--[=[
	Recursively merges two or more tables into one.

	#### Example:
	```lua
	Util.deepMerge({ a = { b = { c = 1 } } }, { a = { b = { d = 2 } } }) -- { a = { b = { c = 1, d = 2 } } }
	```

	@within Util
	@param targetTable { [any]: any } -- The target table you want to merge into
	@param ... { [any]: any } -- The tables you want to merge into the target table
	@return { [any]: any }
]=]
function TableUtil.deepMerge(
	targetTable: { [any]: any },
	...: { [any]: any }
): { [any]: any }
	targetTable = table.clone(targetTable)

	local args: { [any]: any } = { targetTable, ... }

	for _, sourceTable in pairs(args) do
		for key, value in pairs(sourceTable) do
			if typeof(value) == "table" then
				targetTable[key] = TableUtil.deepMerge(targetTable[key], value)
			else
				targetTable[key] = value
			end
		end
	end

	return targetTable
end

--[=[
	The assign function copies all properties from one or more source objects to a target object.

	Alias for `Util.extend`.

	@within Util
	@param targetTable { [any]: any } -- The target table you want to assign values to
	@param ... { [any]: any } -- The tables you want to merge into the target table
	@return { [any]: any }
]=]
function TableUtil.assign(targetTable: { [any]: any }, ...): { [any]: any }
	for argIndex: number, sourceTable: { [any]: any } in pairs({ ... } :: { [any]: any }) do
		assert(typeof(sourceTable) == "table", `Argument #{argIndex} must be a table`)

		for key, value in pairs(sourceTable) do
			if typeof(key) == "number" and targetTable[key] ~= nil then
				table.insert(targetTable, value)
			else
				targetTable[key] = value
			end
		end
	end

	return targetTable
end

--[=[
	Gets a value from a table or Instance using a path.

	#### Example:
	```lua
	Util.treePath({ a = { b = { c = 1 } } }, "a.b.c") -- 1
	Util.treePath({ a = { b = { c = 1 } } }, "a.b") -- { c = 1 }
	Util.treePath(game.Workspace, "House.Door") -- Door instance
	Util.treePath(script, "NonexistantChild") -- nil
	```

	@within Util
	@param tree { [any]: any } | Instance -- The table or instance you want to get the value from
	@param path string? -- The path to the value
	@param delimiter string? -- The delimiter to use when splitting the path
	@return any
]=]
function TableUtil.treePath(
	tree: { [any]: any } | Instance,
	path: string?,
	delimiter: string?
): any
	assert(
		typeof(tree) == "table" or typeof(tree) == "Instance",
		"Tree must be a table or instance"
	)
	assert(typeof(path) == "string" or path == nil, "path must be a string")

	if path == nil then
		return tree
	end

	local node = tree
	local steps: { string } = TableUtil.split(path, delimiter or ".")
	local stepIndex: number = 1

	if #steps == 0 then
		return node -- Return the root node
	end

	while node ~= nil and stepIndex <= #steps do
		local childNode = steps[stepIndex]

		if typeof(node) ~= "Instance" and node[childNode] then
			node = node[childNode] :: { [any]: any }
		elseif typeof(node) == "Instance" and node:FindFirstChild(childNode) then
			node = node:FindFirstChild(childNode) :: Instance
		else
			return nil
		end

		stepIndex += 1
	end

	-- Reached last step in path, return the node
	return node
end

-- Inserts a value into a table if the test condition is true

--[=[
	Inserts a value into a table if the test condition is true.

	#### Example:
	```lua
	Util.insertIf({ 1, 2, 3 }, 4, true) -- { 1, 2, 3, 4 }
	Util.insertIf({ 1, 2, 3 }, 4, false) -- { 1, 2, 3 }
	Util.insertIf({ 1, 2, 3 }, 4, function()
		return true
	end) -- { 1, 2, 3, 4 }
	```

	@within Util
	@param target { [any]: any } -- The table you want to insert the value into
	@param value any -- The value you want to insert
	@param condition nil | boolean | () -> boolean? -- The test condition
]=]
function TableUtil.insertIf(
	target: { [any]: any },
	value: any,
	condition: nil | boolean | (() -> boolean?)
)
	assert(typeof(target) == "table", "Target is missing")
	assert(typeof(value) ~= "nil", "Value is missing")
	assert(
		condition == nil
			or typeof(condition) == "function"
			or typeof(condition) == "boolean",
		"Test must be a function, boolean, or nil"
	)

	local canInsert: boolean? = if typeof(condition) ~= "function"
		then condition
		else condition()

	if canInsert == true then
		table.insert(target, value)
	end
end

--[=[
	Collects all children of an instance into a table.

	#### Example:
	```lua
	Util.instanceChildrenToTable(game.Workspace) -- { Part = Instance, Part2 = Instance }
	Util.instanceChildrenToTable(game.ReplicatedStorage.Config) -- { Config1 = CFrameValue, Config2 = StringValue }
	```

	@within Util
	@param instance Instance -- The instance you want to collect children from
	@return { [string]: Instance }
]=]
function TableUtil.instanceChildrenToTable(instance: Instance): { [string]: Instance }
	assert(typeof(instance) == "Instance", "Instance is missing")

	local children = {}

	for _, child in instance:GetChildren() do
		children[child.Name] = child
	end

	return children
end

--[=[
	Returns the total amount of values in a table.

	#### Example:
	```lua
	Util.tableLength({ 1, 2, 3 }) -- 3
	Util.tableLength({ a = 1, b = 2, c = 3 }) -- 3
	```

	@within Util
	@param source { [any]: any }
	@return number
]=]
function TableUtil.tableLength(source: { [any]: any }): number
	assert(source, "Util.tableLength - Missing object")

	local length: number = 0

	for _index, _value in pairs(source) do
		length += 1
	end

	return length
end

--[=[
	Returns a random index from a table or instance.

	#### Example:
	```lua
	Util.tableRandomIndex({ 1, 2, 3 }) -- 2
	Util.tableRandomIndex({ a = 1, b = 2, c = 3 }) -- "b"
	```

	@within Util
	@param obj { [any]: any } | Instance -- The table or instance you want to get a random index from
	@return any
]=]
function TableUtil.tableRandomIndex(obj: { [any]: any } | Instance): any
	assert(
		typeof(obj) == "table" or typeof(obj) == "Instance",
		"Util.tableRandomIndex - Cannot index " .. typeof(obj)
	)

	local collection: { [any]: any } = if typeof(obj) == "Instance"
		then obj:GetChildren()
		else obj

	local indexes = {}

	-- Map all children names and indexes into a table
	for index, _ in pairs(collection) do
		table.insert(indexes, index)
	end

	return #indexes > 0 and indexes[Random.new():NextInteger(1, #indexes)] or nil
end

--[=[
	Returns the index of a value in a table.
	This works for both dictionaries and arrays.

	#### Example:
	```lua
	Util.indexOf({ 1, 2, 3 }, 2) -- 2
	Util.indexOf({ a = 1, b = 2, c = 3 }, 2) -- "b"
	```

	Use `table.find` for a more efficient way to find the index of a value in an array.
	```lua
	table.find({ 1, 2, 3 }, 2) -- 2
	```

	@within Util
	@param obj { [any]: any } -- The table you want to get the index from
	@param value any -- The value you want to find the index of
	@return any
]=]
function TableUtil.indexOf(obj: { [any]: any }, value: any): any
	assert(obj, "Util.indexOf - Missing object")
	assert(typeof(obj) == "table", "Util.indexOf - Cannot index " .. typeof(obj))

	for index, childValue in pairs(obj) do
		if childValue == value then
			return index
		end
	end

	return nil -- No index found
end

function TableUtil.tableRandom(obj: { [any]: any } | Instance): any
	assert(obj, "Util.tableRandom - Missing object")
	assert(
		typeof(obj) == "table" or typeof(obj) == "Instance",
		"Util.tableRandomIndex - Cannot index " .. typeof(obj)
	)

	local collection: { [any]: any } = if typeof(obj) == "Instance"
		then obj:GetChildren()
		else obj

	return collection[TableUtil.tableRandomIndex(collection)]
end

--[=[
	Creates a nested table of value instances from a Folder or Configuration instance.

	#### Example:

	- Config (Folder) -- in ReplicatedStorage
	  - Origin (CFrameValue), Value = CFrame.new(0, 1, 0)
	  - WelcomeMessage (StringValue), Value = "Hello, world!"

	```lua
	Util.makeConfigFromValues(game.ReplicatedStorage.Config)
	```

	Result:
	```lua
	{
		Origin = CFrame.new(0, 1, 0),
		WelcomeMessage = "Hello, world!"
	}
	```

	@within Util
	@param folder Folder | Configuration -- The folder or Configuration you want to make a table from
	@return { [string]: any }
]=]
function TableUtil.makeConfigFromValues(folder: Folder | Configuration): { [string]: any }
	assert(
		typeof(folder) == "Instance"
			and (folder:IsA("Folder") or folder:IsA("Configuration")),
		"Util.makeConfigFromValues - Folder is missing"
	)

	local config: { [string]: any } = {}

	for _, child: Instance in folder:GetChildren() do
		if child:IsA("Folder") or child:IsA("Configuration") then -- Nest
			config[child.Name] = TableUtil.makeConfigFromValues(child)
		elseif valueClasses[child.ClassName] then
			config[child.Name] = (child :: any).Value
		else --elseif configClasses[el.ClassName] then
			config[child.Name] = child
		end
	end

	return config
end

--[=[
	Removes a value from a table or instance.

	#### Example:
	```lua
	Util.tableRemove({ 1, 2, 3 }, 2) -- { 1, 3 }
	Util.tableRemove({ 1, 2, 3 }, { 2, 3 }) -- { 1 }
	Util.tableRemove({ 1, 2, 3 }, function(value, newIndex, i)
		return value == 2
	end) -- { 1, 3 }
	```

	@within Util
	@param obj { [any]: any } | Instance -- The table or instance you want to remove the value from
	@param removeTest number | { any } | (any, number, number) -> boolean -- The value to remove or reducing function to use
]=]
function TableUtil.tableRemove(obj: { [any]: any }, removeTest: number | { any })
	-- Convert to a test function if the test value is a number or table
	local test: (any, number, number) -> boolean?

	if typeof(removeTest) == "number" then
		test = function(_value, _newIndex, i)
			return i == removeTest
		end
	elseif typeof(removeTest) == "table" then
		test = function(value, _newIndex, _i)
			for _, v in removeTest do
				return value == v
			end

			return false
		end
	end

	if not test then
		return
	end

	local newIndex = 1

	for i, value in obj do
		if not test(value, newIndex, i) then
			if i ~= newIndex then
				obj[newIndex] = obj[i] -- Move to new index
				obj[i] = nil -- Delete from old index
			end

			newIndex += 1 -- Increment index
		else
			obj[i] = nil
		end
	end
end

--[=[
	Executes a series of tasks in a waterfall fashion.

	#### Example:
	```lua
	Util.waterfall(
		function(a, b, callback)
			print("Task 1:", a, b)
			callback(nil, "Task 1 result")
		end,
		function(result, callback)
			print("Task 2:", result)
			callback(nil, "Task 2 result")
		end,
		function(result, callback)
			print("Task 3:", result)
			callback(nil, "Task 3 result")
		end,
		function(err, result)
			if err then
				print("Error:", err)
			else
				print("Final result:", result)
			end
		end
	)
	```

	@within Util
	@param tasks { (...any) -> ...any } -- The tasks to execute
	@param finalCallback (err: any, ...any) -> () -- The final callback to execute
]=]
function TableUtil.waterfall(
	tasks: { (...any) -> ...any },
	finalCallback: (err: any, ...any) -> ()
)
	local function runNextTask(index: number, ...: any)
		local args = { ... }
		local task = tasks[index]

		if task then
			local function stepCallback(...)
				runNextTask(index + 1, ...)
			end

			table.insert(args, stepCallback)

			local success, res = pcall(task, unpack(args))

			if not success then
				finalCallback(res)
			end
		else
			finalCallback(nil, ...)
		end
	end

	runNextTask(1)
end

return TableUtil
