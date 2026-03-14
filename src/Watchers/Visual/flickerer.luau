--!strict
--[[
	@class Flickerer
	Makes a part flicker on and off randomly.

	Attributes:
	- attr_flicker_speed: number (default: 10) - Average flickers per second
	- attr_flicker_chance: number (default: 0.3) - Chance to be "off" (0-1)
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "flickerer"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_FLICKER_SPEED = 10
local DEFAULT_FLICKER_CHANCE = 0.3

local Flickerer: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Flickerer:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_CLIENT then
		return
	end

	local flickerSpeed = object.context:GetAttribute("attr_flicker_speed") :: number? or DEFAULT_FLICKER_SPEED
	local flickerChance = object.context:GetAttribute("attr_flicker_chance") :: number? or DEFAULT_FLICKER_CHANCE

	local originalTransparency = object.context.Transparency
	local elapsedTime = 0
	local nextFlickerTime = 0
	local _isFlickeredOff = false

	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not object.context or not object.context.Parent then
			return
		end

		elapsedTime += deltaTime

		if elapsedTime >= nextFlickerTime then
			local interval = 1 / flickerSpeed
			nextFlickerTime = elapsedTime + interval * (0.5 + math.random())

			if math.random() < flickerChance then
				_isFlickeredOff = true
				object.context.Transparency = 1
			else
				_isFlickeredOff = false
				object.context.Transparency = originalTransparency
			end
		end
	end)

	object.Destroyed:Once(function()
		if connection.Connected then
			connection:Disconnect()
		end
	end)
end)

return Flickerer
