--!strict
--[[
	@class SpeedBoost
	Temporarily increases player walk speed when touched.

	Attributes:
	- attr_multiplier: number (default: 2) - Speed multiplier
	- attr_duration: number (default: 5) - Duration of the boost in seconds
	- attr_cooldown: number (default: 10) - Cooldown before player can get another boost
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Util = require(Packages.Util)

local COLLECTION_TAG = "speed_boost"
local IS_SERVER = RunService:IsServer()
local DEFAULT_MULTIPLIER = 2
local DEFAULT_DURATION = 5
local DEFAULT_COOLDOWN = 10

local SpeedBoost: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

SpeedBoost:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local multiplier = object.context:GetAttribute("attr_multiplier") :: number? or DEFAULT_MULTIPLIER
	local duration = object.context:GetAttribute("attr_duration") :: number? or DEFAULT_DURATION
	local cooldown = object.context:GetAttribute("attr_cooldown") :: number? or DEFAULT_COOLDOWN

	local cooldowns: { Player } = {}
	local activeBoosted: { [Player]: number } = {}

	local connection = Util.onPlayerTouch(object.context, function(player: Player)
		if table.find(cooldowns, player) then
			return
		end

		local humanoid = Util.getHumanoid(player)
		if not humanoid then
			return
		end

		table.insert(cooldowns, player)

		local originalSpeed = activeBoosted[player] or humanoid.WalkSpeed
		if not activeBoosted[player] then
			activeBoosted[player] = originalSpeed
		end

		humanoid.WalkSpeed = originalSpeed * multiplier

		task.delay(duration, function()
			if humanoid and humanoid.Parent then
				humanoid.WalkSpeed = originalSpeed
			end
			activeBoosted[player] = nil
		end)

		task.delay(cooldown, function()
			local index = table.find(cooldowns, player)
			if index then
				table.remove(cooldowns, index)
			end
		end)
	end)

	object.Destroyed:Once(function()
		if connection then
			connection:Disconnect()
		end
	end)
end)

return SpeedBoost
