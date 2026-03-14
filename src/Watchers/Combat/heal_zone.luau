--!strict
--[[
	@class HealZone
	Continuously heals players while they remain inside the zone.

	Attributes:
	- attr_heal_rate: number (default: 1) - Time between heal ticks in seconds
	- attr_heal_amount: number (default: 5) - Health restored per tick
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Util = require(Packages.Util)

local COLLECTION_TAG = "heal_zone"
local IS_SERVER = RunService:IsServer()
local DEFAULT_HEAL_RATE = 1
local DEFAULT_HEAL_AMOUNT = 5

local HealZone: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

HealZone:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local healRate = object.context:GetAttribute("attr_heal_rate") :: number? or DEFAULT_HEAL_RATE
	local healAmount = object.context:GetAttribute("attr_heal_amount") :: number? or DEFAULT_HEAL_AMOUNT

	local playersInZone: { [Player]: boolean } = {}
	local healThread: thread?

	local function startHealLoop()
		if healThread then
			return
		end

		healThread = task.spawn(function()
			while true do
				task.wait(healRate)

				for player in playersInZone do
					local humanoid = Util.getHumanoid(player)
					if humanoid and humanoid.Health > 0 then
						humanoid.Health = math.min(humanoid.Health + healAmount, humanoid.MaxHealth)
					end
				end

				if next(playersInZone) == nil then
					healThread = nil
					break
				end
			end
		end)
	end

	local touchConnection = object.context.Touched:Connect(function(hit)
		local player = Util.getPlayerFromPart(hit)
		if player and not playersInZone[player] then
			playersInZone[player] = true
			startHealLoop()
		end
	end)

	local touchEndedConnection = object.context.TouchEnded:Connect(function(hit)
		local player = Util.getPlayerFromPart(hit)
		if player then
			playersInZone[player] = nil
		end
	end)

	object.Destroyed:Once(function()
		touchConnection:Disconnect()
		touchEndedConnection:Disconnect()
		if healThread then
			task.cancel(healThread)
		end
	end)
end)

return HealZone
