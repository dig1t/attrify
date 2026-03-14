local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local SystemUtil = {}

--[=[
	Generates a UUID/GUID (Universally Unique Identifier) random string using HttpService:GenerateGUID.

	@within Util
	@return string
]=]
function SystemUtil.generateUUID(): string
	return HttpService:GenerateGUID(false)
end

--[=[
	Alternative for `task.delay`.

	Runs a function after `delay` seconds.
	Returns the time elapsed in seconds.

	#### Example:
	```lua
	Util.timeout(1, function(elapsedTime: number)
		print("Hello, world!")
	end)
	```

	@within Util
	@param delay number
	@param callback function
]=]
function SystemUtil.timeout(delay: number, callback: (number) -> ())
	assert(typeof(delay) == "number", "Util.timeout - delay must be a number")
	assert(typeof(callback) == "function", "Util.timeout - callback must be a function")

	task.spawn(function()
		local start = os.clock()
		local connection: RBXScriptConnection
		local elapsedTime: number = 0

		connection = RunService.Stepped:Connect(function(deltaTime: number)
			elapsedTime += deltaTime

			if os.clock() - start >= delay then
				connection:Disconnect()
				callback(elapsedTime)
			end
		end)
	end)
end

--[=[
	Runs a function every `interval` in seconds.
	Return `false` within the callback to stop the interval or call `:Disconnect()` on the returned `RBXScriptConnection`.

	This function returns an `RBXScriptConnection` that can be disconnected to stop the interval.

	#### Example:
	```lua
	Util.interval(1, function(elapsedTime: number, deltaTime: number)
		print(elapsedTime)
	end)
	```

	@within Util
	@param interval number
	@param callback function
	@return RBXScriptConnection
]=]
function SystemUtil.interval(
	interval: number,
	callback: (number, number) -> boolean?
): RBXScriptConnection
	assert(typeof(interval) == "number", "Util.interval - interval must be a number")
	assert(typeof(callback) == "function", "Util.interval - callback must be a function")

	local elapsedTime: number = 0
	local lastEventAt: number = os.clock()

	local connection: RBXScriptConnection

	connection = RunService.Stepped:Connect(function(deltaTime: number)
		elapsedTime += deltaTime

		if os.clock() - lastEventAt >= interval then
			lastEventAt = os.clock()

			task.spawn(function()
				local success = callback(elapsedTime, deltaTime)

				if success == false then
					connection:Disconnect()
				end
			end)
		end
	end)

	return connection
end

--[=[
	Checks if a value is in a table.

	#### Example:
	```lua
	Util.inTable({ 1, 2, 3 }, 2) -- true
	Util.inTable({ 1, 2, 3 }, 4) -- false
	Util.inTable({ Part, 2, 3, Part2 = true }, Part) -- true
	```

	@within Util
	@param searchTable { [any]: any }
	@param target any
	@return boolean
]=]
function SystemUtil.inTable(searchTable: { [any]: any }, target: any): boolean
	assert(typeof(searchTable) == "table", "Util.inTable - searchTable must be a table")

	for _, value: any in pairs(searchTable) do
		if value == target then
			return true
		end
	end

	return false
end

return SystemUtil
