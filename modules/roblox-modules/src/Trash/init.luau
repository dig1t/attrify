--[=[
	@class Trash

	Trash is a class that allows you to destroy an instance after a certain amount of time.

	If the instance is destroyed before the time is up, the `Trash` object will automatically clear itself

	In addition to instances, this class can be used to destroy any class object that has a `Destroy` method.

	Migrating from Debris:
	`Debris:AddItem(part, 8)` -> `Trash.new(part, 8)`

	Timed class destruction:
	```lua
	local MyClass = require(class)

	local myInstance = MyClass.new()

	Trash.new(myInstance, 10) -- Destroy the instance after 10 seconds
	```

	Use case:
	```lua
	local function partExplosion()
		for i = 1, 100 do
			local part = Instance.new("Part")
			part.Parent = Workspace

			Trash.new(part, 10) -- Destroy the part after 10 seconds

			part.Touched:Connect(function()
				part:Destroy()
				-- `Trash` will now automatically clear the Trash object
			end)
		end
	end
	```

	Install with wally by adding the following to your `wally.toml`:
	```toml
	Trash = "dig1t/trash@1.0.3"
	```
]=]

--!native

local RunService = game:GetService("RunService")

local DEFAULT_DESTRUCTION_TIME = 60

local trash: { Trash } = {}

local Trash = {}
Trash.__index = Trash

export type Trash = typeof(setmetatable(
	{} :: {
		instance: any,
		destroyAt: number,
		callback: () -> (),
	},
	Trash
))

local function destroyTrash(trashIndex: number)
	local debris = trash[trashIndex]

	if not debris then
		return
	end

	pcall(debris.instance.Destroy, debris.instance) -- Safely destroy the instance

	if debris.callback then
		task.spawn(debris.callback)
	end

	table.remove(trash, trashIndex)
end

--- Destroys all instances waiting to be destroyed.
function Trash.empty()
	for trashIndex = #trash, 1, -1 do
		destroyTrash(trashIndex)
	end

	trash = {}
end

--- Stops an instance from being destroyed.
function Trash.removeFromTrash(instance: any)
	-- Search for the instance
	for trashIndex, debris in trash do
		if debris.instance == instance then
			table.remove(trash, trashIndex)
			break
		end
	end
end

--[=[
	Creates a new Trash object

	@param instance Instance -- The instance to destroy
	@param life number? -- The amount of time (seconds) to wait before destroying the instance. Defaults to 60 seconds.
	@param callback function? -- A callback function to call when the instance is destroyed
	@return Trash
]=]
function Trash.new(instance: any, life: number?, callback: () -> ()?): Trash
	assert(instance.Destroy, "Instance must have a Destroy method")

	local self = setmetatable({
		instance = instance,
		destroyAt = os.clock() + (life or DEFAULT_DESTRUCTION_TIME),
		callback = callback,
	}, Trash) :: Trash

	table.insert(trash, self)

	-- Order the trash by destruction time
	table.sort(trash, function(a, b)
		return a.destroyAt > b.destroyAt
	end)

	-- Is this instance has a Destroying signal
	-- Connect to it to remove the instance from the trash list
	-- If the instance is destroyed before the time is up
	if instance.Destroying then
		instance.Destroying:Once(function()
			local trashIndex = table.find(trash, self)

			if trashIndex then
				table.remove(trash, trashIndex)
			end
		end)
	end

	return self
end

--[=[
	Destroys a Trash object

	@method Destroy
	@within Trash
	@tag Cleanup
]=]
function Trash.Destroy(self: Trash)
	local trashIndex = table.find(trash, self)

	if trashIndex then
		destroyTrash(trashIndex)
	end
end

RunService.Stepped:Connect(function()
	local now = os.clock()
	local trashAmount = #trash

	if trashAmount == 0 then
		return
	end

	for trashIndex = trashAmount, 1, -1 do
		local debris = trash[trashIndex]

		if debris.destroyAt <= now then
			destroyTrash(trashIndex)
		end
	end

	trashAmount = #trash -- Update the trash amount

	if trashAmount == 0 then
		return
	end

	for garbageIndex = trashAmount, 1, -1 do
		local debris = trash[garbageIndex]

		if not debris then
			continue
		end

		if now > debris.destroyAt then
			destroyTrash(garbageIndex)
		else
			-- The trash list is ordered by destruction time
			-- If we reach an instance that has not yet expired,
			-- we can safely break the loop
			return
		end
	end
end)

return Trash
