--!strict
--[[
	@class Pulser
	Pulses a part's size between min and max scale.

	Attributes:
	- attr_min_scale: number (default: 0.8) - Minimum size multiplier
	- attr_max_scale: number (default: 1.2) - Maximum size multiplier
	- attr_pulse_speed: number (default: 1) - Pulse cycles per second
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "pulser"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_MIN_SCALE = 0.8
local DEFAULT_MAX_SCALE = 1.2
local DEFAULT_PULSE_SPEED = 1

local Pulser: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Pulser:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_CLIENT then
		return
	end

	local minScale = object.context:GetAttribute("attr_min_scale") :: number? or DEFAULT_MIN_SCALE
	local maxScale = object.context:GetAttribute("attr_max_scale") :: number? or DEFAULT_MAX_SCALE
	local pulseSpeed = object.context:GetAttribute("attr_pulse_speed") :: number? or DEFAULT_PULSE_SPEED

	local originalSize = object.context.Size
	local elapsedTime = 0

	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not object.context or not object.context.Parent then
			return
		end

		elapsedTime += deltaTime

		local progress = (math.sin(elapsedTime * pulseSpeed * math.pi * 2) + 1) / 2
		local scale = minScale + (maxScale - minScale) * progress
		object.context.Size = originalSize * scale
	end)

	object.Destroyed:Once(function()
		if connection.Connected then
			connection:Disconnect()
		end
	end)
end)

return Pulser
