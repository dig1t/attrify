--!strict
local CollectionService = game:GetService("CollectionService")

local Maid = require(script.Parent.Parent.Maid)
local Signal = require(script.Parent.Parent.Signal)

--[[
	@class CollectionObject
	Wrapper for CollectionService instances found using CollectionWatcher.
	Provides a `Destroyed` signal that fires when the object is removed.
]]
local CollectionObject = {}
CollectionObject.__index = CollectionObject

export type CollectionObject<T> = typeof(setmetatable(
	{} :: {
		context: T,
		Destroyed: Signal.Signal<nil>,
	},
	CollectionObject
))

local function newCollectionObject<T>(instance: T): CollectionObject<T>
	return setmetatable({
		context = instance,
		Destroyed = Signal.new(),
	}, CollectionObject) :: CollectionObject<T>
end

function CollectionObject._destroy<T>(self: CollectionObject<T>)
	self.Destroyed:Fire()
end

--[[
	@class CollectionWatcher
	Watches for instances with a specific CollectionService tag.

	Example:
	```lua
	local killPart = CollectionWatcher.new("KillPart")

	killPart:RegisterHandler(function(object)
		object.context.Touched:Connect(function(part)
			-- Handle touch
		end)

		object.Destroyed:Once(function()
			-- Cleanup
		end)
	end)
	```
]]
local CollectionWatcher = {}
CollectionWatcher.__index = CollectionWatcher

local TAG_PREFIX = "attr_"

export type CollectionWatcher<T> = typeof(setmetatable(
	{} :: {
		_maid: Maid.Maid,
		_instances: { [T]: CollectionObject<T> },
		Added: Signal.Signal<CollectionObject<T>>,
	},
	CollectionWatcher
))

--[[
	Creates a new CollectionWatcher for the given tag.
	@param tag string -- The CollectionService tag to watch
	@return CollectionWatcher
]]
function CollectionWatcher.new<T>(tag: string): CollectionWatcher<T>
	tag = TAG_PREFIX .. tag -- Prepend the tag prefix
	
	local self = setmetatable({
		_maid = Maid.new(),
		_instances = {},
		Added = Signal.new(),
	}, CollectionWatcher) :: CollectionWatcher<T>

	local function handleNewObject(obj: T)
		local newObject: CollectionObject<T> = newCollectionObject(obj)
		self._instances[obj] = newObject
		self.Added:Fire(newObject)
	end

	for _, obj in CollectionService:GetTagged(tag) do
		handleNewObject(obj)
	end

	self._maid:Add(CollectionService:GetInstanceAddedSignal(tag):Connect(handleNewObject))
	self._maid:Add(
		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(obj: T)
			if self._instances[obj] then
				self._instances[obj]:_destroy()
				self._instances[obj] = nil
			end
		end)
	)

	return self
end

--[[
	Returns all CollectionObjects in the collection.
	@return { CollectionObject }
]]
function CollectionWatcher.GetAll<T>(self: CollectionWatcher<T>): { CollectionObject<T> }
	local result: { CollectionObject<T> } = {}

	for _, object in pairs(self._instances) do
		table.insert(result, object)
	end

	return result
end

--[[
	Fires the callback for all existing objects and connects it to the Added signal.
	@param callback (object: CollectionObject<T>) -> ()
	@return RBXScriptConnection
]]
function CollectionWatcher.RegisterHandler<T>(
	self: CollectionWatcher<T>,
	callback: (object: CollectionObject<T>) -> ()
)
	for _, object in pairs(self._instances) do
		callback(object)
	end

	return self.Added:Connect(callback)
end

--[[
	Disconnects all signals and stops listening for new objects.
]]
function CollectionWatcher.Destroy<T>(self: CollectionWatcher<T>)
	self._maid:Clean()
end

return CollectionWatcher
