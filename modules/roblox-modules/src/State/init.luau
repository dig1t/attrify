--[=[
	@class State

	The State class is used to manage state for anything.
	It can be used to store data for the game, UI, or any other feature.

	Usage example

	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	local connection: RBXScriptConnection = state.Changed:Connect(function(newState, prevState)
		print(prevState, newState)
	end)

	state:Set("val", 11)

	print(state:Length()) -- expect 3

	state:Set(function(state)
		state.val = 111
	end)

	state:Set({
		val = 1111
	})

	state.val = 11111

	state:Remove("val") -- Removes val from the state

	state:Reset() -- Reset the state to the initial state

	connection:Disconnect()

	state:Destroy()

	local success = pcall(function()
		state:Set("val", 1)
	end)

	print("state destroyed:", not success) -- expect: state destroyed: true
	```

	### Signals

	`State.Changed :: Signal.Signal<newState: T, prevState: T>`
	Signal that is fired when the state changes

	Install with wally by adding the following to your `wally.toml`:
	```toml
	State = "dig1t/state@1.1.2"
	```
]=]

--!strict

local Signal = require(script.Parent.Signal)
local Util = require(script.Parent.Util)

local State = {}
State.__index = State

export type State<T> = typeof(setmetatable(
	{} :: {
		--[=[
			Signal that is fired when the state changes

			Example:
			```lua
			local connection: RBXScriptConnection = state.Changed:Connect(function(newState, prevState)
				print(prevState, newState)
			end)
			```

			@prop Changed Signal.Signal<T, T>
			@within State
			@tag Signal
		]=]
		Changed: Signal.Signal<T, T>,

		_context: T,
		_initialState: T,
	},
	State
))

--[=[
	Creates a new state instance

	@param initialState T -- Initial state values
	@return State<T>
]=]
function State.new<T>(initialState: T): State<T>
	return setmetatable({
		__index = function(_self, key)
			return _self._context[key] or _self[key]
		end,

		Changed = Signal.new(),

		_context = initialState :: T,
		_initialState = initialState,
	}, State) :: State<T>
end

-- Number of first level children

--[=[
	Returns the size of the state if the state is a table.

	Example:
	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	print(state:Length()) -- expect 3
	```

	@method Length
	@within State
	@return number
]=]
function State.Length<T>(self: State<T>): number
	assert(typeof(self._context) == "table", "State context is not a table")

	return self._context and Util.tableLength(self._context) or 0
end

--[=[
	Returns the value at the given path.
	The path parameter can only be used if the state is a table.

	Example:
	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	print(state:Get("val")) -- expect 1
	print(state:Get("nest.val")) -- expect 123123

	-- True as the argument returns the entire state
	print(state:Get()) -- expect { val = 1, time = tick(), nest = { val = 123123 } }
	```

	@method Get
	@within State
	@param path string | number? -- The path to the value to get. Leave empty to get the entire state
	@return any
]=]
function State.Get<T>(
	self: State<T>,
	path: string | number?
): any -- Todo: support for nested tables
	if path == nil then
		return self._context
	end

	-- The following requires context to be a table
	assert(typeof(self._context) == "table", "State context is not a table")

	if typeof(path) == "number" then
		return self._context[path] -- Return the index, if exists
	end

	if typeof(path) == "table" then
		return Util.treePath(self._context, path, ".")
	end

	error("Invalid path type")
end

--[=[
	Fires the Changed signal with the new state

	@private
]=]
function State._pushUpdates<T>(self: State<T>, newState: T, prevState: T)
	local _newState = newState or self._context

	self.Changed:Fire(_newState, prevState)
end

--[=[
	Pushes a new value to the state.

	The state must be a table to use this method.

	Example:
	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	state:Push("val", 2)

	print(state:Get("val")) -- expect 2
	```

	@method Push
	@within State
	@param keyOrValue any -- The key of the pushed value or the value itself if the state is an array
	@param value any? -- The value to push
	@return any -- The key of the pushed value
]=]
function State.Push<T>(self: State<T>, keyOrValue: any, value: any?): any
	assert(typeof(self._context) == "table", "Cannot push to a non-table state")

	local prevState: T = table.clone(self._context) :: any -- Create a 1 level copy -- TODO: change to deep copy
	local key: any = value ~= nil and keyOrValue or #self._context + 1

	self._context[key] = value ~= nil and value or keyOrValue

	self:_pushUpdates(self._context, prevState)

	return key
end

--[=[
	Resets the state to the initial state

	Example:
	```lua
	local state = State.new({
		val = 1
	})

	state:Set("val", 2)

	state:Reset()

	state:Get() -- expect { val = 1 }
	```

	@method Reset
	@within State
]=]
function State.Reset<T>(self: State<T>)
	self:_pushUpdates(self._initialState, self._context)

	self._context = self._initialState
end

--[=[
	Sets the state with a new value.

	Example:
	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	state:Set({
		val = 1111
	}) -- Change val to 1111
	```

	@method Set
	@within State
	@param newState T -- The new state value
]=]
function State.Set<T>(self: State<T>, newState: T)
	-- TODO: Create a deep copy if the newState is a table
	local prevState: T = if typeof(self._context) == "table"
		then Util.extend({}, self._context :: any) :: any
		else self._context

	self._context = newState

	self:_pushUpdates(self._context, prevState)
end

--[=[
	Sets the state with a new value.

	The `modifier` function should NOT yield as it can cause issues or data loss.
	This function should be used as a shortcut to modify the state.

	For example
	```
	local value = state:Get()

	value.number += 1

	state:Set(value)
	```

	Turns into:
	```
	state:SetCallback(function(context)
		context.number += 1
	end)
	```

	Example:
	```lua
	type NumberState = {
		val: number
	}

	local state: State.State<NumberState> = State.new({
		val = 1
	})

	state:SetCallback(function(prevState: NumberState)
		prevState.val = 111
	end) -- Change val to 111
	```

	@method SetCallback
	@within State
	@param modifier (T) -> ()
]=]
function State.SetCallback<T>(self: State<T>, modifier: (T) -> ())
	local prevState: T = if typeof(self._context) == "table"
		then Util.extend({}, self._context :: any) :: any
		else self._context

	-- call the "modifier" function so _context can be altered
	-- the "modifier" function should NOT yield
	modifier(self._context)

	self:_pushUpdates(self._context, prevState)
end

--[=[
	Sets the state with a new value

	Example:
	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	state:SetPath("nest.val", 11111) -- Change nest.val from 123123 to 11111
	```

	@method SetPath
	@within State
	@param pathString string -- The path to set
	@param value any? -- The value to set
]=]
function State.SetPath<T>(self: State<T>, pathString: string, value: any)
	assert(typeof(self._context) == "table", "State context must be a table")

	local prevState: T = table.clone(self._context) :: any -- Create a copy
	local path: { string } = Util.split(pathString, ".", true)
	local res = self._context

	if not res then
		return
	end

	-- Go through nest until the last nest level is reached
	for i: number, childName: string in path do
		local numberIndex: number? = tonumber(childName)
		local resIndex: number | string = numberIndex or childName

		if res[resIndex] and i ~= #path then
			res = res[resIndex]
		elseif i == #path then
			-- Change the value if end of the path was reached
			res[resIndex] = value
		else
			break
		end
	end

	self:_pushUpdates(self._context, prevState)
end

--[=[
	Removes a value from the state

	Example:
	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	state:Remove("val") -- Removes val from the state

	state:Get() -- expect { time = tick(), nest = { val = 123123 } }
	```

	@method Remove
	@within State
	@param path string | number -- The path to the value to remove
]=]
function State.Remove<T>(self: State<T>, path: string | number)
	assert(typeof(self._context) == "table", "State context must be a table")

	local prevState: T = table.clone(self._context) :: any -- Create a local copy
	local treePath = Util.split(tostring(path), ".", true)
	local res = self._context

	if not res then
		return
	end

	-- Dig through nest until the last nest level is reached
	for i: number, childName: string in treePath do
		local numberIndex: number? = tonumber(childName)
		local resIndex: number | string = numberIndex or childName

		if res[resIndex] and i ~= #treePath then
			res = res[resIndex]
		elseif i == #treePath then
			-- Remove the value if end of the path was reached
			res[resIndex] = nil
		else
			break
		end
	end

	self:_pushUpdates(self._context, prevState)
end

--[=[
	Destroys the state

	Example:
	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	state:Destroy()

	local success = pcall(function()
		-- This should throw an error since the state object was destroyed
		state:Set("val", 1)
	end)

	print('state destroyed?', not success) -- expect: true
	```

	@method Destroy
	@within State
	@tag Cleanup
]=]
function State.Destroy<T>(self: State<T>)
	self._context = nil :: any

	pcall(setmetatable, self, {})
end

return State
