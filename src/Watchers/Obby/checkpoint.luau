--!strict
--[[
	@class Checkpoint
	Checkpoint system for obby games with persistence support.

	Tags:
	- "checkpoint" - Checkpoint marker, sets checkpoint when touched, acts as spawn point
	- "spawn_point" - Optional explicit spawn location (overrides checkpoint position)

	Attributes (checkpoint):
	- attr_checkpoint_number: number (required) - Checkpoint number (1 and up)
	- attr_checkpoint_effect: boolean? - Show visual effect on reach (default: true)

	Attributes (spawn_point):
	- attr_checkpoint_number: number (required) - Associated checkpoint number
	- attr_spawn_offset: Vector3? - Offset from part center (default: 0, 3, 0)

	Signals:
	- PlayerReachedCheckpoint(player: Player, checkpointNumber: number)
	- PlayerSpawnedAtCheckpoint(player: Player, checkpointNumber: number)

	Usage:
	```lua
	local Attrify = require(Packages.Attrify)

	-- When player reaches a new checkpoint, update their profile
	Attrify.Signals.PlayerReachedCheckpoint:Connect(function(player, checkpoint)
		local profile = getProfile(player)
		profile.Data.checkpoint = checkpoint
	end)

	-- When player joins, set their checkpoint from persistence and spawn
	local function onPlayerAdded(player)
		local profile = loadProfile(player)
		local savedCheckpoint = profile.Data.checkpoint or 1

		Attrify.setPlayerCheckpoint(player, savedCheckpoint)

		player.CharacterAdded:Connect(function()
			task.wait(0.1)
			Attrify.spawnPlayerAtCheckpoint(player, savedCheckpoint)
		end)
	end
	```
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Maid = require(Packages.Maid)
local Signal = require(Packages.Signal)
local Util = require(Packages.Util)

-- Constants
local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()
local DEFAULT_SPAWN_OFFSET = Vector3.new(0, 3, 0)

-- Signals
local PlayerReachedCheckpoint = Signal.new() :: Signal.Signal<Player, number>
local PlayerSpawnedAtCheckpoint = Signal.new() :: Signal.Signal<Player, number>

-- State
local checkpointParts: { [number]: BasePart } = {}
local spawnPoints: { [number]: { CFrame } } = {}
local playerCheckpoints: { [Player]: number } = {}
local totalCheckpoints: number = 0
local checkpointCount: number = 0

-- Watching state
local isWatching = false
local watchCleanup = Maid.new()

-- Forward declaration
local getSpawnCFrameInternal: (checkpointNumber: number) -> CFrame?

local function spawnPlayerAtCheckpointInternal(player: Player, checkpointNumber: number)
	local character = player.Character
	if not character then
		return
	end

	local spawnCFrame = getSpawnCFrameInternal(checkpointNumber)
	if not spawnCFrame then
		return
	end

	character:PivotTo(spawnCFrame)
	PlayerSpawnedAtCheckpoint:Fire(player, checkpointNumber)
end

local function setupPlayerCheckpoint(player: Player)
	if not playerCheckpoints[player] then
		playerCheckpoints[player] = 1
	end

	-- Spawn at checkpoint when character is added
	local connection = player.CharacterAdded:Connect(function(character: Model)
		-- Wait for character to be ready
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
		if not humanoidRootPart then
			return
		end

		local checkpoint = playerCheckpoints[player] or 1
		spawnPlayerAtCheckpointInternal(player, checkpoint)
	end)

	watchCleanup:Add(connection)

	-- Handle existing character
	if player.Character then
		local checkpoint = playerCheckpoints[player] or 1
		spawnPlayerAtCheckpointInternal(player, checkpoint)
	end
end

local function watchForPlayers()
	if isWatching then
		return
	end

	isWatching = true

	-- Set up existing players
	for _, player in Players:GetPlayers() do
		setupPlayerCheckpoint(player)
	end

	-- Listen for new players
	watchCleanup:Add(Players.PlayerAdded:Connect(function(player: Player)
		setupPlayerCheckpoint(player)
	end))

	watchCleanup:Add(function()
		isWatching = false
	end)
end

local function unwatchForPlayers()
	watchCleanup:Clean()
end

--------------------------------------------------------------------------------
-- Visual Effect (Client)
--------------------------------------------------------------------------------

local function playCheckpointEffect(part: BasePart)
	local originalColor = part.Color
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local flashTween = TweenService:Create(part, tweenInfo, {
		Color = Color3.fromRGB(100, 255, 100),
	})

	flashTween:Play()
	flashTween.Completed:Once(function()
		local revertTween = TweenService:Create(part, tweenInfo, {
			Color = originalColor,
		})
		revertTween:Play()
	end)
end

--------------------------------------------------------------------------------
-- Checkpoint Validation
--------------------------------------------------------------------------------

local function canProgressToCheckpoint(player: Player, checkpointNumber: number): boolean
	local currentCheckpoint = playerCheckpoints[player] or 1

	-- Only allow forward progression by exactly one checkpoint
	return checkpointNumber == currentCheckpoint + 1
end

local function trySetCheckpoint(player: Player, checkpointNumber: number): boolean
	if not canProgressToCheckpoint(player, checkpointNumber) then
		return false
	end

	local currentCheckpoint = playerCheckpoints[player] or 1
	if checkpointNumber == currentCheckpoint then
		return false -- Already at this checkpoint
	end

	playerCheckpoints[player] = checkpointNumber
	PlayerReachedCheckpoint:Fire(player, checkpointNumber)
	return true
end

--------------------------------------------------------------------------------
-- Touch Handler Setup
--------------------------------------------------------------------------------

local function setupServerTouchHandler(
	object: CollectionWatcher.CollectionObject<BasePart>,
	checkpointNumber: number
)
	local connection = Util.onPlayerTouch(object.context, function(player: Player)
		trySetCheckpoint(player, checkpointNumber)
	end)

	object.Destroyed:Once(function()
		if connection then
			connection:Disconnect()
		end
	end)

	return connection
end

local function setupClientEffectHandler(
	object: CollectionWatcher.CollectionObject<BasePart>,
	checkpointNumber: number
): RBXScriptConnection?
	local showEffect = object.context:GetAttribute("attr_checkpoint_effect") :: boolean?
	if showEffect == false then
		return nil
	end

	local connection = Util.onPlayerTouch(object.context, function(_player: Player)
		if _player ~= Players.LocalPlayer then
			return
		end

		local currentCheckpoint = playerCheckpoints[_player] or 1
		-- Only show effect if this is the next checkpoint
		if checkpointNumber == currentCheckpoint + 1 then
			playCheckpointEffect(object.context)
		end
	end)

	object.Destroyed:Once(function()
		if connection then
			connection:Disconnect()
		end
	end)

	return connection
end

--------------------------------------------------------------------------------
-- Checkpoint Watcher (tag: "checkpoint")
--------------------------------------------------------------------------------

local CheckpointWatcher: CollectionWatcher.CollectionWatcher<BasePart> =
	CollectionWatcher.new("checkpoint")

CheckpointWatcher:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	local checkpointNumber = object.context:GetAttribute("attr_checkpoint_number") :: number?

	if not checkpointNumber then
		warn("[Checkpoint] Part missing attr_checkpoint_number:", object.context:GetFullName())
		return
	end

	-- Register the checkpoint part (for spawn fallback)
	checkpointParts[checkpointNumber] = object.context
	totalCheckpoints = math.max(totalCheckpoints, checkpointNumber)
	checkpointCount += 1

	if IS_SERVER then
		-- Start watching for players when first checkpoint is detected
		watchForPlayers()

		setupServerTouchHandler(object, checkpointNumber)

		object.Destroyed:Once(function()
			checkpointParts[checkpointNumber] = nil
			checkpointCount -= 1

			-- Recalculate total checkpoints
			totalCheckpoints = 0
			for num, _ in pairs(checkpointParts) do
				totalCheckpoints = math.max(totalCheckpoints, num)
			end

			-- Stop watching if no checkpoints remain
			if checkpointCount == 0 then
				unwatchForPlayers()
			end
		end)
	elseif IS_CLIENT then
		setupClientEffectHandler(object, checkpointNumber)
	end
end)

--------------------------------------------------------------------------------
-- Spawn Point Watcher (tag: "spawn_point")
--------------------------------------------------------------------------------

local SpawnPointWatcher: CollectionWatcher.CollectionWatcher<BasePart> =
	CollectionWatcher.new("spawn_point")

SpawnPointWatcher:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local checkpointNumber = object.context:GetAttribute("attr_checkpoint_number") :: number?

	if not checkpointNumber then
		warn("[SpawnPoint] Part missing attr_checkpoint_number:", object.context:GetFullName())
		return
	end

	local offset = object.context:GetAttribute("attr_spawn_offset") :: Vector3? or DEFAULT_SPAWN_OFFSET
	local spawnCFrame = object.context.CFrame + offset

	-- Register spawn point
	if not spawnPoints[checkpointNumber] then
		spawnPoints[checkpointNumber] = {}
	end
	table.insert(spawnPoints[checkpointNumber], spawnCFrame)

	object.Destroyed:Once(function()
		local points = spawnPoints[checkpointNumber]
		if points then
			for i, cf in points do
				if cf == spawnCFrame then
					table.remove(points, i)
					break
				end
			end
		end
	end)
end)

--------------------------------------------------------------------------------
-- Player Cleanup
--------------------------------------------------------------------------------

if IS_SERVER then
	Players.PlayerRemoving:Connect(function(player)
		playerCheckpoints[player] = nil
	end)
end

--------------------------------------------------------------------------------
-- Internal Helpers
--------------------------------------------------------------------------------

getSpawnCFrameInternal = function(checkpointNumber: number): CFrame?
	-- Try spawn_point first
	local points = spawnPoints[checkpointNumber]
	if points and #points > 0 then
		return points[math.random(1, #points)]
	end

	-- Fallback to checkpoint part
	local checkpointPart = checkpointParts[checkpointNumber]
	if checkpointPart then
		return checkpointPart.CFrame + DEFAULT_SPAWN_OFFSET
	end

	return nil
end

--------------------------------------------------------------------------------
-- Module API
--------------------------------------------------------------------------------

local module = {
	-- Signals
	PlayerReachedCheckpoint = PlayerReachedCheckpoint,
	PlayerSpawnedAtCheckpoint = PlayerSpawnedAtCheckpoint,

	--- Get the part for a checkpoint number
	getCheckpointPart = function(checkpointNumber: number): BasePart?
		return checkpointParts[checkpointNumber]
	end,

	--- Get total number of checkpoints
	getTotalCheckpoints = function(): number
		return totalCheckpoints
	end,

	--- Get player's current checkpoint (defaults to 1)
	getPlayerCheckpoint = function(player: Player): number
		return playerCheckpoints[player] or 1
	end,

	--- Set player's checkpoint (for loading from persistence)
	setPlayerCheckpoint = function(player: Player, checkpointNumber: number): boolean
		if checkpointNumber < 1 then
			return false
		end
		playerCheckpoints[player] = checkpointNumber

		-- If player has a character, teleport them to the checkpoint
		if player.Character then
			spawnPlayerAtCheckpointInternal(player, checkpointNumber)
		end

		return true
	end,

	--- Spawn player at checkpoint
	spawnPlayerAtCheckpoint = function(player: Player, checkpointNumber: number): boolean
		if not IS_SERVER then
			warn("[Checkpoint] spawnPlayerAtCheckpoint can only be called on server")
			return false
		end

		local character = player.Character
		if not character then
			return false
		end

		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not humanoidRootPart then
			return false
		end

		local spawnCFrame = getSpawnCFrameInternal(checkpointNumber)
		if not spawnCFrame then
			warn("[Checkpoint] No spawn location for checkpoint", checkpointNumber)
			return false
		end

		humanoidRootPart.CFrame = spawnCFrame
		PlayerSpawnedAtCheckpoint:Fire(player, checkpointNumber)

		return true
	end,

	--- Get spawn CFrame for a checkpoint
	getSpawnCFrame = function(checkpointNumber: number): CFrame?
		return getSpawnCFrameInternal(checkpointNumber)
	end,
}

return module
