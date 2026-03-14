--!strict
--[=[
	@class Attrify
	No-code behavior system for Roblox using CollectionService tags and attributes.

	Usage:
	```lua
	-- Server script - Load all watchers
	local Attrify = require(ReplicatedStorage.Packages.Attrify)
	Attrify.start()

	-- Or load only specific watchers to reduce memory usage
	Attrify.start({
		modules = { "kill_part", "jump_pad", "checkpoint" }
	})

	-- You can also use category.module format
	Attrify.start({
		modules = { "Combat.kill_part", "Movement.jump_pad" }
	})
	```

	Available behaviors are auto-loaded based on tags:
	- **Combat:** kill_part, damage_zone, heal_part, heal_zone
	- **Movement:** jump_pad, bounce_pad, teleporter, speed_boost, slow_zone, conveyor, push_zone, gravity_zone
	- **Collectibles:** collectible, coin
	- **Animation:** spinner, moving_platform, swing_part, thwomp, bobber, orbiter, shaker, escalator, elevator, path_follower
	- **Obby:** checkpoint, spawn_point, fading_part, cycling_platform, crumbling_part
	- **Visual:** glowing, color_cycler, fader, pulser, trailer, particle_emitter, beamer, spotlighter, billboard, flickerer
	- **Interaction:** prompt_part, clickable, button, pressure_plate
	- **Door:** auto_door, swing_gate, sliding_panel
	- **Destruction:** breakable, respawner, touch_fade_out
	- **Sound:** touch_sound, ambient_sound, proximity_sound
	- **Logic:** toggler, sequencer, timer_part, random_activator
	- **Constraint:** rope_part, hinge_part
]=]

local CollectionWatcher = require(script.Modules.CollectionWatcher)
local Signal = require(script.Signal)

export type Config = {
	--- List of module names to load. If nil, all modules are loaded.
	--- Accepts module names (e.g., "KillPart") or category.module format (e.g., "Combat.KillPart")
	modules: { string }?,
}

local Attrify = {}

Attrify.CollectionWatcher = CollectionWatcher

local started = false

local function shouldLoadModule(moduleName: string, categoryName: string?, allowedModules: { string }?): boolean
	if not allowedModules then
		return true
	end

	for _, allowed in allowedModules do
		-- Check for exact module name match (e.g., "KillPart")
		if allowed == moduleName then
			return true
		end

		-- Check for category.module format (e.g., "Combat.KillPart")
		if categoryName then
			local fullPath = `{categoryName}.{moduleName}`
			if allowed == fullPath then
				return true
			end
		end
	end

	return false
end

local function requireWatchers(parent: Instance, allowedModules: { string }?, categoryName: string?)
	for _, child in parent:GetChildren() do
		if child:IsA("ModuleScript") then
			if shouldLoadModule(child.Name, categoryName, allowedModules) then
				(require :: any)(child)
			end
		elseif child:IsA("Folder") then
			requireWatchers(child, allowedModules, child.Name)
		end
	end
end

--[=[
	Starts Attrify watchers. Call this once on both server and client.
	Each watcher automatically determines if it should run on server or client.

	@param config Config? -- Optional configuration table
]=]
function Attrify.start(config: Config?)
	if started then
		warn("[Attrify] start() has already been called. Attrify can only be started once.")
		return
	end
	started = true

	local allowedModules = if config then config.modules else nil

	local watchersFolder = script:FindFirstChild("Watchers")
	if watchersFolder then
		requireWatchers(watchersFolder, allowedModules)
	end
end

-- Expose signals from watchers that have them
Attrify.Signals = {} :: {
	[string]: Signal.Signal<...any>
}

-- Lazy-load signals when accessed
setmetatable(Attrify.Signals, {
	__index = function(_self, key)
		local watcherPaths = {
			-- [signal name in module] = "path.to.module"
			CollectibleCollected = "Collect.collectible",
			CoinCollected = "Collect.coin",
			PromptTriggered = "Interaction.prompt_part",
			Clicked = "Interaction.clickable",
			ButtonPressed = "Interaction.button",
			PressurePlateActivated = "Interaction.pressure_plate",
			PressurePlateDeactivated = "Interaction.pressure_plate",
			PartBroken = "Destruction.breakable",
			Toggled = "Logic.toggler",
			SequenceStep = "Logic.sequencer",
			TimerTick = "Logic.timer_part",
			RandomActivated = "Logic.random_activator",
			-- Checkpoint signals
			PlayerReachedCheckpoint = "Obby.checkpoint",
			PlayerSpawnedAtCheckpoint = "Obby.checkpoint",
		}

		local path = watcherPaths[key]
		if path then
			local parts = string.split(path, ".")
			local watchersFolder = script:FindFirstChild("Watchers")
			if watchersFolder then
				local folder = watchersFolder:FindFirstChild(parts[1])
				if folder then
					local watcher = folder:FindFirstChild(parts[2])
					if watcher and watcher:IsA("ModuleScript") then
						local module = require(watcher) :: any
						if typeof(module) == "table" and module[key] then
							return module[key]
						end
					end
				end
			end
		end

		return nil
	end,
})

-- Checkpoint API (lazy-loaded)
local checkpointModule: any = nil

local function getCheckpointModule(): any
	if checkpointModule then
		return checkpointModule
	end

	local watchersFolder = script:FindFirstChild("Watchers")
	local obbyFolder = watchersFolder and watchersFolder:FindFirstChild("Obby") :: Folder?
	local module = obbyFolder and obbyFolder:FindFirstChild("checkpoint") :: ModuleScript?

	if module and module:IsA("ModuleScript") then
		checkpointModule =  require(module) :: any
		return checkpointModule
	end

	return nil
end

--[=[
	Set player's checkpoint state (for loading from persistence).
	Call this when player joins to restore their saved checkpoint.

	@param player Player -- The player to set checkpoint for
	@param checkpointNumber number -- The checkpoint number to set
	@return boolean -- True if checkpoint was set successfully
]=]
function Attrify.setPlayerCheckpoint(player: Player, checkpointNumber: number): boolean
	local module = getCheckpointModule()
	if module and module.setPlayerCheckpoint then
		return module.setPlayerCheckpoint(player, checkpointNumber)
	end
	warn("[Attrify] Checkpoint module not loaded. Call Attrify.start() first.")
	return false
end

--[=[
	Spawn player at a specific checkpoint.

	@param player Player -- The player to spawn
	@param checkpointNumber number -- The checkpoint number to spawn at
	@return boolean -- True if spawn was successful
]=]
function Attrify.spawnPlayerAtCheckpoint(player: Player, checkpointNumber: number): boolean
	local module = getCheckpointModule()
	if module and module.spawnPlayerAtCheckpoint then
		return module.spawnPlayerAtCheckpoint(player, checkpointNumber)
	end
	warn("[Attrify] Checkpoint module not loaded. Call Attrify.start() first.")
	return false
end

--[=[
	Get player's current in-memory checkpoint (not persisted).

	@param player Player -- The player to get checkpoint for
	@return number? -- The current checkpoint number, or nil if not set
]=]
function Attrify.getPlayerCheckpoint(player: Player): number?
	local module = getCheckpointModule()
	if module and module.getPlayerCheckpoint then
		return module.getPlayerCheckpoint(player)
	end
	return nil
end

--[=[
	Get the total number of checkpoints in the game.

	@return number -- Total number of checkpoints
]=]
function Attrify.getTotalCheckpoints(): number
	local module = getCheckpointModule()
	if module and module.getTotalCheckpoints then
		return module.getTotalCheckpoints()
	end
	return 0
end

--[=[
	Get the part instance for a specific checkpoint.

	@param checkpointNumber number -- The checkpoint number
	@return BasePart? -- The checkpoint part, or nil if not found
]=]
function Attrify.getCheckpointPart(checkpointNumber: number): BasePart?
	local module = getCheckpointModule()
	if module and module.getCheckpointPart then
		return module.getCheckpointPart(checkpointNumber)
	end
	return nil
end

--[=[
	Get spawn CFrame for a checkpoint.

	@param checkpointNumber number -- The checkpoint number
	@return CFrame? -- The spawn CFrame, or nil if not found
]=]
function Attrify.getSpawnCFrame(checkpointNumber: number): CFrame?
	local module = getCheckpointModule()
	if module and module.getSpawnCFrame then
		return module.getSpawnCFrame(checkpointNumber)
	end
	return nil
end

return Attrify
