--!strict
--[[
	@class DamageZone
	Continuously damages players while they remain inside the zone.

	Attributes:
	- attr_damage_rate: number (default: 1) - Time between damage ticks in seconds
	- attr_damage_amount: number (default: 10) - Damage dealt per tick
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Util = require(Packages.Util)

local COLLECTION_TAG = "damage_zone"
local IS_SERVER = RunService:IsServer()
local DEFAULT_DAMAGE_RATE = 1
local DEFAULT_DAMAGE_AMOUNT = 10

local DamageZone: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

DamageZone:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local damageRate = object.context:GetAttribute("attr_damage_rate") :: number? or DEFAULT_DAMAGE_RATE
	local damageAmount = object.context:GetAttribute("attr_damage_amount") :: number? or DEFAULT_DAMAGE_AMOUNT

	local playersInZone: { [Player]: boolean } = {}
	local damageThread: thread?

	local function startDamageLoop()
		if damageThread then
			return
		end

		damageThread = task.spawn(function()
			while true do
				task.wait(damageRate)

				for player in playersInZone do
					local humanoid = Util.getHumanoid(player)
					if humanoid and humanoid.Health > 0 then
						humanoid:TakeDamage(damageAmount)
					end
				end

				if next(playersInZone) == nil then
					damageThread = nil
					break
				end
			end
		end)
	end

	local touchConnection = object.context.Touched:Connect(function(hit)
		local player = Util.getPlayerFromPart(hit)
		if player and not playersInZone[player] then
			playersInZone[player] = true
			startDamageLoop()
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
		if damageThread then
			task.cancel(damageThread)
		end
	end)
end)

return DamageZone
