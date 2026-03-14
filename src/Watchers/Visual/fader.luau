--!strict
--[[
	@class Fader
	Pulses a part's transparency between min and max values.

	Attributes:
	- attr_min_transparency: number (default: 0) - Minimum transparency
	- attr_max_transparency: number (default: 0.8) - Maximum transparency
	- attr_fade_speed: number (default: 1) - Fade cycles per second
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "fader"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_MIN_TRANSPARENCY = 0
local DEFAULT_MAX_TRANSPARENCY = 0.8
local DEFAULT_FADE_SPEED = 1

local Fader: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Fader:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_CLIENT then
		return
	end

	local minTransparency = object.context:GetAttribute("attr_min_transparency") :: number? or DEFAULT_MIN_TRANSPARENCY
	local maxTransparency = object.context:GetAttribute("attr_max_transparency") :: number? or DEFAULT_MAX_TRANSPARENCY
	local fadeSpeed = object.context:GetAttribute("attr_fade_speed") :: number? or DEFAULT_FADE_SPEED

	local elapsedTime = 0

	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not object.context or not object.context.Parent then
			return
		end

		elapsedTime += deltaTime

		local progress = (math.sin(elapsedTime * fadeSpeed * math.pi * 2) + 1) / 2
		object.context.Transparency = minTransparency + (maxTransparency - minTransparency) * progress
	end)

	object.Destroyed:Once(function()
		if connection.Connected then
			connection:Disconnect()
		end
	end)
end)

return Fader
