--!strict
--[[
	@class Coin
	Currency collectible that players can pick up.

	Attributes:
	- attr_value: number (default: 1) - Coin value
	- attr_respawn_time: number (default: 10) - Time before respawning (0 = no respawn)
	- attr_spin_speed: number (default: 90) - Degrees per second to spin (client-side)
	- attr_spin_axis: Vector3 (default: 0, 1, 0) - Axis to spin around (client-side)
	- attr_owner: number (optional) - UserId of the only player who can collect the
	  coin. Other players can't pick it up, and their clients hide it
	- attr_auto_collect: number (optional) - With attr_owner, the seconds after which
	  your server credits the owner. The owner's client fires LocalTouched just
	  before then, so the pickup visual still plays (client-side; Attrify does not
	  credit the owner)
	- attr_pivot_root: boolean (default: false) - When the part's parent is a Model,
	  spin the whole Model around its pivot instead of the part (client-side)
	- attr_bob_height: number (default: 0) - With attr_pivot_root, studs the Model
	  bobs up and down (client-side)

	Children:
	- PickupHitbox: BasePart (optional) - Local touches of this part also fire
	  LocalTouched, for servers that collect through a wider invisible hitbox

	Fires Signal "CoinCollected" with (player, value, part)
	Fires Signal "LocalTouched" with (part) on the client when the local
	character first touches the coin (client-side pickup prediction). It fires
	once per coin, so it suits coins that are removed when collected.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Signal = require(Packages.Signal)
local Util = require(Packages.Util)

local COLLECTION_TAG = "coin"
local IS_SERVER = RunService:IsServer()
local LOCAL_PLAYER = Players.LocalPlayer
local DEFAULT_VALUE = 1
local DEFAULT_RESPAWN_TIME = 10
local DEFAULT_SPIN_SPEED = 90
local DEFAULT_SPIN_AXIS = Vector3.yAxis
local DEFAULT_BOB_HEIGHT = 0
-- Bob rate for attr_pivot_root coins, in radians per second (~0.4 cycles/s)
local BOB_SPEED = 2.5
-- attr_auto_collect fires LocalTouched this many seconds early, so a client
-- can clone the coin for its pickup visual before the server's collect
-- replicates and removes the original
local AUTO_COLLECT_VISUAL_LEAD = 0.35

local CoinCollected = Signal.new() :: Signal.Signal<Player, number, BasePart>
local LocalTouched = Signal.new() :: Signal.Signal<BasePart>

local Coin: CollectionWatcher.CollectionWatcher<BasePart> =
	CollectionWatcher.new(COLLECTION_TAG)

--[[
	Returns the Model an attr_pivot_root coin drives, or nil for a bare part.
]]
local function getPivotModel(part: BasePart): Model?
	local parent = part.Parent

	if
		part:GetAttribute("attr_pivot_root") == true
		and parent
		and parent:IsA("Model")
	then
		return parent
	end

	return nil
end

--[[
	Hides an instance and its descendants for this client only.
]]
local function hideLocally(visual: Instance)
	for _, descendant in visual:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = 1
		elseif descendant:IsA("ParticleEmitter") then
			descendant.Enabled = false
		end
	end

	if visual:IsA("BasePart") then
		visual.LocalTransparencyModifier = 1
	end
end

Coin:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if IS_SERVER then
		-- Server: Handle touch collection
		local value = object.context:GetAttribute("attr_value") :: number?
			or DEFAULT_VALUE
		local respawnTime = object.context:GetAttribute("attr_respawn_time") :: number?
			or DEFAULT_RESPAWN_TIME

		local isCollected = false
		local originalTransparency = object.context.Transparency
		local originalCanCollide = object.context.CanCollide

		local connection = Util.onPlayerTouch(object.context, function(player: Player)
			if isCollected then
				return
			end

			-- An owned coin stays in place when anyone else walks through it
			local ownerUserId = object.context:GetAttribute("attr_owner") :: number?
			if ownerUserId and player.UserId ~= ownerUserId then
				return
			end

			isCollected = true
			object.context.Transparency = 1
			object.context.CanCollide = false

			CoinCollected:Fire(player, value, object.context)

			if respawnTime > 0 then
				task.delay(respawnTime, function()
					if object.context and object.context.Parent then
						object.context.Transparency = originalTransparency
						object.context.CanCollide = originalCanCollide
						isCollected = false
					end
				end)
			end
		end)

		object.Destroyed:Once(function()
			if connection then
				connection:Disconnect()
			end
		end)
	else
		-- Client: Spin the coin and predict local pickups
		local context = object.context
		local ownerUserId = context:GetAttribute("attr_owner") :: number?
		local isOwner = LOCAL_PLAYER ~= nil and LOCAL_PLAYER.UserId == ownerUserId

		-- An owned coin only exists for its owner: other clients hide it and
		-- skip the spin and pickup prediction
		if ownerUserId and LOCAL_PLAYER and not isOwner then
			hideLocally(getPivotModel(context) or context)
			return
		end

		local spinSpeed = context:GetAttribute("attr_spin_speed") :: number?
			or DEFAULT_SPIN_SPEED
		local spinAxis = context:GetAttribute("attr_spin_axis") :: Vector3?
			or DEFAULT_SPIN_AXIS
		local spinRadiansPerSecond = math.rad(spinSpeed)
		local normalizedAxis = spinAxis.Unit

		local model = getPivotModel(context)
		local bobHeight = context:GetAttribute("attr_bob_height") :: number?
			or DEFAULT_BOB_HEIGHT
		local basePivot = if model then model:GetPivot() else CFrame.identity
		local elapsed = 0

		local localTouched = false
		local touchConnections: { RBXScriptConnection } = {}

		local function fireLocalTouched()
			if localTouched then
				return
			end

			localTouched = true

			for _, touchConnection in touchConnections do
				touchConnection:Disconnect()
			end

			LocalTouched:Fire(context)
		end

		local function onTouched(hit: BasePart)
			local character = LOCAL_PLAYER and LOCAL_PLAYER.Character

			if character and hit:IsDescendantOf(character) then
				fireLocalTouched()
			end
		end

		local function watchHitbox(child: Instance)
			if child.Name == "PickupHitbox" and child:IsA("BasePart") then
				table.insert(touchConnections, child.Touched:Connect(onTouched))
			end
		end

		table.insert(touchConnections, context.Touched:Connect(onTouched))

		local hitbox = context:FindFirstChild("PickupHitbox")

		if hitbox then
			watchHitbox(hitbox)
		end

		-- The hitbox can replicate after the coin registers
		table.insert(touchConnections, context.ChildAdded:Connect(watchHitbox))

		local autoCollectDelay = context:GetAttribute("attr_auto_collect") :: number?

		if isOwner and autoCollectDelay then
			local leadDelay = math.max(autoCollectDelay - AUTO_COLLECT_VISUAL_LEAD, 0)

			task.delay(leadDelay, function()
				if context.Parent then
					fireLocalTouched()
				end
			end)
		end

		local connection = RunService.RenderStepped:Connect(function(deltaTime: number)
			if not (context and context.Parent) then
				return
			end

			if model then
				elapsed += deltaTime

				local rotation =
					CFrame.fromAxisAngle(normalizedAxis, spinRadiansPerSecond * elapsed)
				local bobOffset = math.sin(elapsed * BOB_SPEED) * bobHeight

				model:PivotTo(CFrame.new(0, bobOffset, 0) * basePivot * rotation)
			else
				local rotation =
					CFrame.fromAxisAngle(normalizedAxis, spinRadiansPerSecond * deltaTime)

				context.CFrame = context.CFrame * rotation
			end
		end)

		object.Destroyed:Once(function()
			-- A pending attr_auto_collect delay must not fire for a removed coin
			localTouched = true

			connection:Disconnect()

			for _, touchConnection in touchConnections do
				touchConnection:Disconnect()
			end
		end)
	end
end)

local module = {
	watcher = Coin,
	CoinCollected = CoinCollected,
	LocalTouched = LocalTouched,
}

return module
