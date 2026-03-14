--!native

local SearchUtil = {}

--[=[
	Gets the number of parts in the given instance

	Example:
	```lua
	Util.getPartCount(game.Workspace.NPC) -- 5
	```

	@within Util
	@param instance Instance
	@return number
]=]
function SearchUtil.getPartCount(instance: Instance?): number
	if instance == nil then
		warn("Util.getPartCount() - instance is nil")
		return 0
	end

	assert(
		typeof(instance) == "Instance",
		"Util.getPartCount() - argument must be an Instance"
	)

	local count: number = 0

	for _, part in instance:GetDescendants() do
		if part:IsA("BasePart") then
			count += 1
		end
	end

	return count
end

--[=[
	Gets all parts in the given instance

	Example:
	```lua
	Util.getDescendantParts(game.Workspace.LightPost) -- { [1] = Light, [2] = PostMeshPart }
	```

	@within Util
	@param instance Instance
	@return { BasePart }
]=]
function SearchUtil.getDescendantParts(instance: Instance): { BasePart }
	assert(
		typeof(instance) == "Instance",
		"Util.getDescendantParts() - argument must be an Instance"
	)

	local parts: { BasePart } = {}

	for _, part: Instance | BasePart in instance:GetDescendants() do
		if part:IsA("BasePart") then
			table.insert(parts, part)
		end
	end

	return parts
end

--[=[
	Gets the first descendant of the given instance that matches the given condition.
	This will search all descendants of the given instance, including the instance itself.
	It will stop  if no ancestor is found.

	Example 1:
	```lua
	detector.Touched:Connect(function(part: BasePart)
		local humanoid = Util.getAncestor(part, "Humanoid")

		if humanoid ~= nil then
			print("Humanoid touched the detector")
		end
	end)
	```

	Example 2:
	```lua
	detector.Touched:Connect(function(part: BasePart)
		local bot: Model? = Util.getAncestor(part, function(instance: Instance)
			return instance:HasTag("NPC")
		end)

		if bot ~= nil then
			bot.
			print("NPC bot touched the detector")
		end
	end)
	```

	@within Util
	@param child Instance
	@param condition string | (obj: Instance) -> boolean
	@return any
]=]
function SearchUtil.getAncestor(
	child: Instance,
	condition: string | (obj: Instance) -> boolean
): any
	assert(
		typeof(child) == "Instance",
		"Util.getAncestor() - child argument must be an Instance"
	)
	assert(
		typeof(condition) == "string" or typeof(condition) == "function",
		"Util.getAncestor() - condition argument must be a string name or function"
	)

	if typeof(condition) == "string" then
		local searchString = condition

		condition = function(_child: Instance)
			return _child.Name == searchString
		end
	end

	local _condition = condition :: (_child: Instance) -> boolean

	while child do
		if _condition(child) then
			return child
		elseif child.Parent then
			child = child.Parent :: Instance
		else
			break
		end
	end

	return nil
end

--[=[
	Starts at the given node and searches all children for the first child that matches the given condition.
	This search will continue until `maxDepth` is reached, a match is found, or no more children are found.
	When a match is found, it will return the matching child.
	When no match is found, it will return nil.

	By default `maxDepth` is 1. Only the children of the given node will be searched.

	Function condition example:
	```lua
	local player: Player? = Util.find(game.Players, function(player: Player)
		return player.Name == "Player1"
	end)
	```

	Instance example:
	```lua
	local player: Player? = Util.find(game.Players, "Player1")
	```

	Filtering example:
	```lua
	local NPCs = {
		{ Name = "NPC1" },
		{ Name = "NPC1" },
		{ Name = "NPC1" },
	}

	local player = Util.find(NPCs, function(NPC)
		return NPC.Name == "NPC1"
	end)
	```

	Advanced example:
	```lua
	local NPCs = {
		{ Name = "NPC1", Health = 0 },
		{ Name = "NPC1", Health = 20 },
		{ Name = "NPC1", Health = 0 },
	}

	local firstAliveNPC = Util.find(NPCs, function(NPC)
		return NPC.Health > 0
	end)
	```

	@within Util
	@param node Instance | { [any]: any }
	@param condition string | (obj: Instance) -> boolean
	@param maxDepth number -- Default: 1
	@param _depth number -- Internal use, used to track the current depth
	@return any
]=]
function SearchUtil.find(
	node: Instance | { [any]: any },
	condition: any | (obj: Instance) -> boolean,
	maxDepth: number?,
	_depth: number?
): any
	assert(
		typeof(node) == "Instance" or typeof(node) == "table",
		"Util.find() - node argument must be an Instance or table"
	)
	assert(condition ~= nil, "Util.find() - condition argument must be a function or key")
	assert(
		typeof(maxDepth) == "number" or maxDepth == nil,
		"Util.find() - maxDepth must be a number or nil"
	)
	assert(
		typeof(_depth) == "number" or _depth == nil,
		"Util.find() - _depth must be a number or nil"
	)

	local function test(child: Instance): (boolean, any)
		if typeof(condition) == "function" then
			local runner = condition :: (child: Instance) -> boolean
			return runner(child), child
		end

		if typeof(child) == "Instance" then
			local result = child:FindFirstChild(condition)

			return result ~= nil, result
		end

		return child[condition] ~= nil, child
	end
	local currentDepth: number = _depth or 1
	local children: { [any]: any } = {}

	local nodes: { [any]: any } = {}

	if typeof(node) == "Instance" then
		nodes = node:GetChildren()
	elseif typeof(node) == "table" then
		nodes = node
	end

	for _, child: any in pairs(nodes) do
		local childIsInstance: boolean = typeof(child) == "Instance"
		local success: boolean, match: any = test(child)

		if success then
			return match -- Test passed, return the match
		elseif (childIsInstance and #child:GetChildren() or #child) > 0 then
			table.insert(children, child) -- Add to search the children of this node later
		end
	end

	if currentDepth >= (maxDepth or 1) then
		return nil
	end

	for _, child: any in pairs(children) do
		if not child then
			continue
		end

		local match: any = SearchUtil.find(child, condition, maxDepth, currentDepth + 1)

		if match ~= nil then
			return match
		end
	end

	return nil
end

--[=[
	Checks if the given instance has the children with the given key names.
	A single child name can be passed as a string, or multiple child names can be passed as a table.

	Table of children example:
	```lua
	Util.exists(
		game.Workspace.Player1,
		{ "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
	) -- true
	```

	String child example:
	```lua
	Util.exists(game.Workspace.Player1, "Head") -- true
	```

	Table of children in a table node example:
	```lua
	Util.exists(
		game.Workspace.Player1:GetChildren(), -- table
		{ "Head", "Torso" }
	) -- true
	```

	Table node and string child example:
	```lua
	Util.exists(
		game.Workspace.Player1:GetChildren(), -- table
		"HumanoidRootPart"
	) -- true
	```

	@within Util
	@param node Instance | { [string]: any }
	@param children string | { string }
	@return boolean
]=]
function SearchUtil.exists(
	node: Instance | { [string]: any },
	children: (string | { string })?
): boolean
	assert(
		typeof(node) == "Instance" or typeof(node) == "table",
		"Util.exists() - node argument must be an Instance or table"
	)
	assert(
		typeof(children) == "string" or typeof(children) == "table" or children == nil,
		"Util.exists() - children argument must be a string or table"
	)

	if children == nil then
		return false
	end

	local nodes: { [string]: any } = {}

	if typeof(node) == "Instance" then
		-- Insert all children into a table with their name as the key
		for _, child: Instance in node:GetChildren() do
			nodes[child.Name] = child
		end
	elseif typeof(node) == "table" then
		nodes = node
	end

	if typeof(children) == "string" then
		-- Search a single child name

		return nodes[children] ~= nil
	elseif typeof(children) == "table" then
		-- Search multiple child names

		for _, childName: string in pairs(children) do
			if nodes[childName] == nil then
				return false
			end
		end

		return true
	end

	return false
end

--[=[
	Returns the first part in the given instance

	Example:
	```lua
	Util.getFirstPart(game.Workspace.Player1) -- Head
	```

	@within Util
	@param instance Instance
	@return BasePart?
]=]
function SearchUtil.getFirstPart(instance: Instance?): BasePart?
	if instance == nil then
		return nil
	end

	assert(typeof(instance) == "Instance", "instance argument must be an Instance")

	local children: { BasePart | Instance } = instance:GetChildren()

	if not children or #children == 0 then
		return
	end

	local index: number = 1
	local current: Instance? = nil

	while index < #children do
		current = children[index]

		if current and current:IsA("BasePart") then
			return current
		end

		index += 1
	end

	return nil
end

return SearchUtil
