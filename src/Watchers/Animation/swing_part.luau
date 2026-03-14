--!strict
--[[
	@class SwingPart
	Swings a Model or BasePart like a pendulum.

	Make sure to edit the part's "PivotOffset" so it swings from that pivot.

	Attributes:
	- attr_seconds_per_cycle: number (default: 2.5) - Time for a full swing cycle
	- attr_swing_angle: number (default: 30) - Maximum swing angle in degrees
	- attr_axis: Vector3 (default: 0, 0, 1) - Swing axis (Z-axis by default)
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "swing_part"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_SECONDS_PER_CYCLE = 2.5
local DEFAULT_SWING_ANGLE = 30
local DEFAULT_AXIS = Vector3.new(0, 0, 1)

local SwingPart: CollectionWatcher.CollectionWatcher<Model | BasePart> = CollectionWatcher.new(COLLECTION_TAG)

SwingPart:RegisterHandler(function(object: CollectionWatcher.CollectionObject<Model | BasePart>)
	if not IS_CLIENT then
		return
	end

	local secondsPerCycle = object.context:GetAttribute("attr_seconds_per_cycle") :: number? or DEFAULT_SECONDS_PER_CYCLE
	local swingAngle = object.context:GetAttribute("attr_swing_angle") :: number? or DEFAULT_SWING_ANGLE
	local axis = object.context:GetAttribute("attr_axis") :: Vector3? or DEFAULT_AXIS
	local originalPivot = object.context:GetPivot()
	local cycleTime = 0

	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not object.context or not object.context.Parent then
			return
		end

		cycleTime += deltaTime

		while cycleTime >= secondsPerCycle do
			cycleTime -= secondsPerCycle
		end

		local swingProgress = math.sin((cycleTime / secondsPerCycle) * math.pi * 2)
		local currentAngle = swingProgress * swingAngle

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

return SwingPart
