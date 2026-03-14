--!strict
--[[
	@class Breakable
	Part that can be destroyed by taking damage.

	Attributes:
	- attr_health: number (default: 100) - Part health
	- attr_respawn_time: number (default: 10) - Time before respawning (0 = no respawn)

	Fires Signal "PartBroken" with (part)
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Signal = require(Packages.Signal)

local COLLECTION_TAG = "breakable"
local IS_SERVER = RunService:IsServer()
local DEFAULT_HEALTH = 100
local DEFAULT_RESPAWN_TIME = 10

local PartBroken = Signal.new()

local Breakable: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Breakable:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local maxHealth = object.context:GetAttribute("attr_health") :: number? or DEFAULT_HEALTH
	local respawnTime = object.context:GetAttribute("attr_respawn_time") :: number? or DEFAULT_RESPAWN_TIME
	local currentHealth = maxHealth

	local originalTransparency = object.context.Transparency
	local originalCanCollide = object.context.CanCollide
	local isBroken = false

	object.context:SetAttribute("attr_current_health", currentHealth)

	local attributeConnection = object.context.AttributeChanged:Connect(function(attributeName)
		if attributeName == "attr_current_health" then
			currentHealth = object.context:GetAttribute("attr_current_health") :: number? or currentHealth

			if currentHealth <= 0 and not isBroken then
				isBroken = true
				object.context.Transparency = 1
				object.context.CanCollide = false
				PartBroken:Fire(object.context)

				if respawnTime > 0 then
					task.delay(respawnTime, function()
						if object.context and object.context.Parent then
							currentHealth = maxHealth
							object.context:SetAttribute("attr_current_health", currentHealth)
							object.context.Transparency = originalTransparency
							object.context.CanCollide = originalCanCollide
							isBroken = false
						end
					end)
				end
			end
		end
	end)

	object.Destroyed:Once(function()
		attributeConnection:Disconnect()
	end)
end)

local module = {
	watcher = Breakable,
	PartBroken = PartBroken,
}

return module
