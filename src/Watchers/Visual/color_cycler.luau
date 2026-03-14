--!strict
--[[
	@class ColorCycler
	Cycles a part through a rainbow or custom color sequence.

	Attributes:
	- attr_cycle_speed: number (default: 1) - Full cycles per second
	- attr_use_rainbow: boolean (default: true) - Use rainbow colors instead of custom
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "color_cycler"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_CYCLE_SPEED = 1

local ColorCycler: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

ColorCycler:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_CLIENT then
		return
	end

	local cycleSpeed = object.context:GetAttribute("attr_cycle_speed") :: number? or DEFAULT_CYCLE_SPEED

	local elapsedTime = 0

	local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		if not object.context or not object.context.Parent then
			return
		end

		elapsedTime += deltaTime * cycleSpeed

		local hue = elapsedTime % 1
		object.context.Color = Color3.fromHSV(hue, 1, 1)
	end)

	object.Destroyed:Once(function()
		if connection.Connected then
			connection:Disconnect()
		end
	end)
end)

return ColorCycler
