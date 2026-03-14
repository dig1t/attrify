--!strict
--[[
	@class SpeedZone
	Increases player movement speed while inside the zone.

	Attributes:
	- attr_multiplier: number (default: 1.5) - Speed multiplier (1.5 = 150% speed)
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Util = require(Packages.Util)

local COLLECTION_TAG = "speed_zone"
local IS_SERVER = RunService:IsServer()
local DEFAULT_MULTIPLIER = 1.5

local SpeedZone: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

SpeedZone:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local multiplier = object.context:GetAttribute("attr_multiplier") :: number? or DEFAULT_MULTIPLIER

	local playersInZone: { [Player]: number } = {}

	local touchConnection = object.context.Touched:Connect(function(hit)
		local player = Util.getPlayerFromPart(hit)
		if not player or playersInZone[player] then
			return
		end

		local humanoid = Util.getHumanoid(player)
		if not humanoid then
			return
		end

		playersInZone[player] = humanoid.WalkSpeed
		humanoid.WalkSpeed = humanoid.WalkSpeed * multiplier
	end)

	local touchEndedConnection = object.context.TouchEnded:Connect(function(hit)
		local player = Util.getPlayerFromPart(hit)
		if not player or not playersInZone[player] then
			return
		end

		local humanoid = Util.getHumanoid(player)
		if humanoid then
			humanoid.WalkSpeed = playersInZone[player]
		end

		playersInZone[player] = nil
	end)

	object.Destroyed:Once(function()
		touchConnection:Disconnect()
		touchEndedConnection:Disconnect()

		for player, originalSpeed in playersInZone do
			local humanoid = Util.getHumanoid(player)
			if humanoid then
				humanoid.WalkSpeed = originalSpeed
			end
		end
	end)
end)

return SpeedZone
