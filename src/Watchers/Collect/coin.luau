--!strict
--[[
	@class Coin
	Currency collectible that players can pick up.

	Attributes:
	- attr_value: number (default: 1) - Coin value
	- attr_respawn_time: number (default: 10) - Time before respawning (0 = no respawn)
	- attr_spin_speed: number (default: 90) - Degrees per second to spin (client-side)
	- attr_spin_axis: Vector3 (default: 0, 1, 0) - Axis to spin around (client-side)

	Fires Signal "CoinCollected" with (player, value, part)
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Signal = require(Packages.Signal)
local Util = require(Packages.Util)

local COLLECTION_TAG = "coin"
local IS_SERVER = RunService:IsServer()
local DEFAULT_VALUE = 1
local DEFAULT_RESPAWN_TIME = 10
local DEFAULT_SPIN_SPEED = 90
local DEFAULT_SPIN_AXIS = Vector3.yAxis

local CoinCollected = Signal.new() :: Signal.Signal<Player, number, BasePart>

local Coin: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Coin:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if IS_SERVER then
		-- Server: Handle touch collection
		local value = object.context:GetAttribute("attr_value") :: number? or DEFAULT_VALUE
		local respawnTime = object.context:GetAttribute("attr_respawn_time") :: number? or DEFAULT_RESPAWN_TIME

		local isCollected = false
		local originalTransparency = object.context.Transparency
		local originalCanCollide = object.context.CanCollide

		local connection = Util.onPlayerTouch(object.context, function(player: Player)
			if isCollected then
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
		-- Client: Spin the coin
		local spinSpeed = object.context:GetAttribute("attr_spin_speed") :: number? or DEFAULT_SPIN_SPEED
		local spinAxis = object.context:GetAttribute("attr_spin_axis") :: Vector3? or DEFAULT_SPIN_AXIS
		local spinRadiansPerSecond = math.rad(spinSpeed)
		local normalizedAxis = spinAxis.Unit

		local connection = RunService.RenderStepped:Connect(function(deltaTime: number)
			if object.context and object.context.Parent then
				local rotation = CFrame.fromAxisAngle(normalizedAxis, spinRadiansPerSecond * deltaTime)
				object.context.CFrame = object.context.CFrame * rotation
			end
		end)

		object.Destroyed:Once(function()
			if connection then
				connection:Disconnect()
			end
		end)
	end
end)

local module = {
	watcher = Coin,
	CoinCollected = CoinCollected,
}

return module
