--!strict
--[[
	@class Shaker
	Applies a vibration/jitter effect to an object.

	Attributes:
	- attr_intensity: number (default: 0.1) - Maximum shake offset in studs
	- attr_speed: number (default: 20) - Shake frequency
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "shaker"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_INTENSITY = 0.2
local DEFAULT_SPEED = 20

local Shaker: CollectionWatcher.CollectionWatcher<Model | BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Shaker:RegisterHandler(function(object: CollectionWatcher.CollectionObject<Model | BasePart>)
	if not IS_CLIENT then
		return
	end

	local intensity = object.context:GetAttribute("attr_intensity") :: number? or DEFAULT_INTENSITY
	local speed = object.context:GetAttribute("attr_speed") :: number? or DEFAULT_SPEED

	local originalPivot = object.context:GetPivot()
	local elapsedTime = 0
	local seed = math.random(1000)

	local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		if not object.context or not object.context.Parent then
			return
		end

		elapsedTime += deltaTime

		local noiseX = math.noise(elapsedTime * speed, seed, 0) * intensity
		local noiseY = math.noise(elapsedTime * speed, seed + 100, 0) * intensity
		local noiseZ = math.noise(elapsedTime * speed, seed + 200, 0) * intensity

		object.context:PivotTo(originalPivot + Vector3.new(noiseX, noiseY, noiseZ))
	end)

	object.Destroyed:Once(function()
		if connection.Connected then
			connection:Disconnect()
		end
	end)
end)

return Shaker
