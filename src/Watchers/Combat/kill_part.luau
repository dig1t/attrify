--!strict
--[[
	@class KillPart
	Damages or kills players on touch.

	Attributes:
	- attr_damage: number (default: 100) - Amount of damage to deal
	- attr_cooldown: number (default: 3) - Cooldown between damage applications per player
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Util = require(Packages.Util)

local COLLECTION_TAG = "kill_part"
local IS_SERVER = RunService:IsServer()
local DEFAULT_DAMAGE = 100
local DEFAULT_COOLDOWN = 3

local KillPart: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

KillPart:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local damage = object.context:GetAttribute("attr_damage") :: number? or DEFAULT_DAMAGE
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
			humanoid:TakeDamage(damage)
		end
	end)

	object.Destroyed:Once(function()
		if connection then
			connection:Disconnect()
		end
	end)
end)

return KillPart
