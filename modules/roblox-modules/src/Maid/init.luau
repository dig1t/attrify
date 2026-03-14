local Util = require(script.Parent.Util)

--[=[
	@class Maid

	Task management class for cleaning up things for garbage collection.

	Install with wally by adding the following to your `wally.toml`:
	```toml
	Maid = "dig1t/maid@1.0.8"
	```
]=]
local Maid = {}
Maid.__index = Maid

export type Maid = typeof(setmetatable(
	{} :: {
		_tasks: { [string]: MaidTask },
	},
	Maid
))

export type MaidTask = {
	Connected: boolean?,
	Disconnect: () -> (),
	Destroy: (any) -> (),
	Destructor: (task: any) -> (),
	Stop: () -> (),
}? | () -> ()? | Instance | RBXScriptConnection

--[=[
	Creates a new Maid instance.

	```lua
	local maid = Maid.new()
	```

	@return Maid
]=]
function Maid.new(): Maid
	local self = setmetatable({}, Maid) :: Maid

	self._tasks = {}

	return self
end

--[=[
	Adds a task to the Maid instance.

	```lua
	local maid = Maid.new()

	maid:Task(function()
		print("Hello world!")
	end)
	```

	Multiple types of tasks can be added to the Maid instance.

	```lua
	local maid: Maid.Maid = Maid.new()

	-- Functions
	maid:Task(function()
		print("Hello world!")
	end)

	-- RBXScriptConnections
	maid:Task(workspace.ChildAdded:Connect(function()
		print("Hello world!")
	end))

	-- Instances with "Destroy" methods
	maid:Task(Instance.new("Part"))

	-- Packages with "Destroy", "destroy", or "destructor" methods
	local instance = Class.new({
		PackageVariable = "Hello world!",
		Destroy = function()
			-- destroy this package instance
		end
	})

	maid:Task(instance)
	```

	@method Task
	@within Maid
	@param _task MaidTask -- The task to add
	@return (MaidTask, string) -- The task and the task id are returned
]=]
function Maid.Task(self: Maid, _task: MaidTask): (MaidTask, string)
	local taskId = Util.randomString(14)

	self._tasks[taskId] = _task

	return _task, taskId
end

--[=[
	Alias for Maid.Task

	@method Add
	@within Maid
	@param _task MaidTask -- The task to add
	@return (MaidTask, string) -- The task and the task id are returned
]=]
function Maid.Add(self: Maid, _task: MaidTask): (MaidTask, string)
	return self:Task(_task)
end

--[=[
	Removes a task from the Maid instance.

	```lua
	local maid: Maid.Maid = Maid.new()

	local taskId = maid:Task(function()
		print("Hello world!")
	end)

	maid:RemoveTask(taskId)
	```

	@method RemoveTask
	@within Maid
	@param taskToRemove any -- The task item to remove.
]=]
function Maid.RemoveTask(self: Maid, taskToRemove: string | MaidTask): ()
	-- Remove by task id
	if typeof(taskToRemove) == "string" then
		self._tasks[taskToRemove] = nil

		return
	end

	-- Remove by task
	for taskId: string, _task: MaidTask in pairs(self._tasks) do
		if _task == taskToRemove then
			self._tasks[taskId] = nil
		end
	end
end

--[=[
	Cleans up all tasks in the Maid instance.

	```lua
	local maid: Maid.Maid = Maid.new()

	maid:Task(function()
		print("Hello world!")
	end)

	maid:Clean() -- Hello world!
	```

	@method Clean
	@within Maid
	@tag Cleanup
]=]
function Maid.Clean(self: Maid)
	for taskId, _task: MaidTask in pairs(self._tasks) do
		if typeof(_task) == "function" then
			_task() -- Run cleaning _task
		elseif typeof(_task) == "RBXScriptConnection" and _task.Connected then
			_task:Disconnect()
		elseif typeof(_task) == "Instance" then
			if _task:IsA("AnimationTrack") then
				_task:Stop()
			else
				_task:Destroy()
			end
		elseif typeof(_task) == "table" then
			-- Type workaround for non-roblox instances with Destroy methods
			if _task.Destroy then
				_task:Destroy()
			elseif _task.Destructor then
				_task:Destructor()
			end
		end

		self._tasks[taskId] = nil
	end
end

--[=[
	Alias for Maid.Clean

	@method Cleanup
	@within Maid
	@tag Cleanup
]=]
function Maid.Cleanup(self: Maid)
	self:Clean()
end

--[=[
	Destroys the Maid instance.

	```lua
	local maid = Maid.new()

	maid:Task(function()
		print("Hello world!")
	end)

	maid:Destroy()

	maid:Clean() -- method no longer exists
	```

	@method Destroy
	@within Maid
	@tag Cleanup
]=]
function Maid.Destroy(self: Maid)
	for key: any, _ in pairs(self) do
		self[key] = nil
	end
end

return Maid
