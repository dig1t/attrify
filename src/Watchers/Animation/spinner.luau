--!strict
--[[
	@class Spinner
	Continuously rotates a Model or BasePart around a specified axis.

	Attributes:
	- attr_seconds_per_round: number (default: 2.5) - Time to complete a 360 degree rotation
	- attr_axis: Vector3 (default: 0, 1, 0) - Rotation axis (Y-axis by default)
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "spinner"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_SECONDS_PER_ROUND = 2.5
local DEFAULT_AXIS = Vector3.new(0, 1, 0)

local Spinner: CollectionWatcher.CollectionWatcher<Model | BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Spinner:RegisterHandler(function(object: CollectionWatcher.CollectionObject<Model | BasePart>)
	if not IS_CLIENT then
		return
	end

	local secondsPerRound = object.context:GetAttribute("attr_seconds_per_round") :: number? or DEFAULT_SECONDS_PER_ROUND
	local axis = object.context:GetAttribute("attr_axis") :: Vector3? or DEFAULT_AXIS

	local originalPivot = object.context:GetPivot()
	local currentAngle = 0

	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not object.context or not object.context.Parent then
			return
		end

		currentAngle += (360 / secondsPerRound) * deltaTime
		object.context:PivotTo(
			originalPivot
				* CFrame.Angles(
					axis.X * math.rad(currentAngle),
					axis.Y * math.rad(currentAngle),
					axis.Z * math.rad(currentAngle)
				)
		)
	end)

	object.Destroyed:Once(function()
		if connection.Connected then
			connection:Disconnect()
		end
	end)
end)

return Spinner
