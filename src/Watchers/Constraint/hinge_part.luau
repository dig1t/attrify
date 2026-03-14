--!strict
--[[
	@class HingePart
	Creates a hinge constraint on this part.

	Attributes:
	- attr_target_name: string (required) - Name of the target part to hinge to
	- attr_hinge_axis: Vector3 (default: 0, 1, 0) - Axis of rotation
	- attr_motor_enabled: boolean (default: false) - Enable motor rotation
	- attr_motor_speed: number (default: 45) - Motor rotation speed in degrees/second
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "hinge_part"
local IS_SERVER = RunService:IsServer()
local DEFAULT_HINGE_AXIS = Vector3.new(0, 1, 0)
local DEFAULT_MOTOR_ENABLED = false
local DEFAULT_MOTOR_SPEED = 45

local HingePart: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

HingePart:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local targetName = object.context:GetAttribute("attr_target_name") :: string?
	local hingeAxis = object.context:GetAttribute("attr_hinge_axis") :: Vector3? or DEFAULT_HINGE_AXIS
	local motorEnabled = object.context:GetAttribute("attr_motor_enabled") :: boolean? or DEFAULT_MOTOR_ENABLED
	local motorSpeed = object.context:GetAttribute("attr_motor_speed") :: number? or DEFAULT_MOTOR_SPEED

	if not targetName then
		warn("HingePart requires attr_target_name attribute")
		return
	end

	local target = workspace:FindFirstChild(targetName, true)
	if not target or not target:IsA("BasePart") then
		warn(`HingePart target "{targetName}" not found`)
		return
	end

	local attachment0 = Instance.new("Attachment")
	attachment0.Axis = hingeAxis
	attachment0.Parent = object.context

	local attachment1 = Instance.new("Attachment")
	attachment1.Axis = hingeAxis
	attachment1.Parent = target

	local hinge = Instance.new("HingeConstraint")
	hinge.Attachment0 = attachment0
	hinge.Attachment1 = attachment1

	if motorEnabled then
		hinge.ActuatorType = Enum.ActuatorType.Motor
		hinge.AngularVelocity = math.rad(motorSpeed)
		hinge.MotorMaxTorque = math.huge
	end

	hinge.Parent = object.context

	local attributeConnection = object.context.AttributeChanged:Connect(function(attributeName)
		if attributeName == "attr_motor_enabled" then
			local enabled = object.context:GetAttribute("attr_motor_enabled") :: boolean? or DEFAULT_MOTOR_ENABLED
			if enabled then
				hinge.ActuatorType = Enum.ActuatorType.Motor
				hinge.MotorMaxTorque = math.huge
			else
				hinge.ActuatorType = Enum.ActuatorType.None
			end
		elseif attributeName == "attr_motor_speed" then
			hinge.AngularVelocity = math.rad(
				object.context:GetAttribute("attr_motor_speed") :: number? or DEFAULT_MOTOR_SPEED
			)
		end
	end)

	object.Destroyed:Once(function()
		attributeConnection:Disconnect()
		hinge:Destroy()
		attachment0:Destroy()
		attachment1:Destroy()
	end)
end)

return HingePart
