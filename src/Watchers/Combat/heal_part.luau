--!strict
--[[
	@class HealPart
	Heals players on touch.

	Attributes:
	- attr_heal_amount: number (default: 25) - Amount of health to restore
	- attr_cooldown: number (default: 3) - Cooldown between heals per player
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Util = require(Packages.Util)

local COLLECTION_TAG = "heal_part"
local IS_SERVER = RunService:IsServer()
local DEFAULT_HEAL_AMOUNT = 25
local DEFAULT_COOLDOWN = 3

local HealPart: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

HealPart:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local healAmount = object.context:GetAttribute("attr_heal_amount") :: number? or DEFAULT_HEAL_AMOUNT
	local cooldown = object.context:GetAttribute("attr_cooldown") :: number? or DEFAULT_COOLDOWN

	local cooldowns: { Player } = {}

	local connection = Util.onPlayerTouch(object.context, function(player: Player)
		if table.find(cooldowns, player) then
			return
		end

		table.insert(cooldowns, player)

		task.delay(cooldown, function()
			local index = table.find(cooldowns, player)

			if index then
				table.remove(cooldowns, index)
			end
		end)

		local humanoid = Util.getHumanoid(player)

		if humanoid then
			humanoid.Health = math.min(humanoid.Health + healAmount, humanoid.MaxHealth)
		end
	end)

	object.Destroyed:Once(function()
		if connection then
			connection:Disconnect()
		end
	end)
end)

return HealPart
