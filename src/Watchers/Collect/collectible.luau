--!strict
--[[
	@class Collectible
	Generic collectible item that can be picked up by players.

	Attributes:
	- attr_type: string (default: "generic") - Type of collectible
	- attr_amount: number (default: 1) - Amount/value of the collectible
	- attr_respawn_time: number (default: 10) - Time before respawning (0 = no respawn)

	Fires BindableEvent "CollectibleCollected" with (player, type, amount, part)
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Signal = require(Packages.Signal)
local Util = require(Packages.Util)

local COLLECTION_TAG = "collectible"
local IS_SERVER = RunService:IsServer()
local DEFAULT_TYPE = "generic"
local DEFAULT_RESPAWN_TIME = 10

local CollectibleCollected = Signal.new()

local Collectible: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Collectible:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local collectibleType = object.context:GetAttribute("attr_type") :: string? or DEFAULT_TYPE
	local value = object.context:GetAttribute("attr_value") :: any
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

		CollectibleCollected:Fire(player, collectibleType, value, object.context)

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
end)

local module = {
	watcher = Collectible,
	CollectibleCollected = CollectibleCollected,
}

return module
