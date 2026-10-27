--!strict
--[[
	@class SwingGate
	Rotating gate that swings open when triggered.

	Make sure to edit the part's "PivotOffset" so it swings from that pivot.

	Attributes:
	- attr_open_angle: number (default: 90) - Angle to rotate when open
	- attr_open_time: number (default: 0.5) - Time to open/close
	- attr_trigger_distance: number (default: 10) - Distance to trigger opening
	- attr_axis: Vector3 (default: 0, 1, 0) - Rotation axis

	Children:
	- Open: Sound (optional) - Plays when the gate starts opening
	- Close: Sound (optional) - Plays when the gate finishes closing
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "swing_gate"
local IS_CLIENT = RunService:IsClient()
local LOCAL_PLAYER = Players.LocalPlayer
local DEFAULT_OPEN_ANGLE = 90
local DEFAULT_OPEN_TIME = 0.5
local DEFAULT_TRIGGER_DISTANCE = 10
local DEFAULT_AXIS = Vector3.yAxis

local SwingGate: CollectionWatcher.CollectionWatcher<Model | BasePart> = CollectionWatcher.new(COLLECTION_TAG)

SwingGate:RegisterHandler(function(object: CollectionWatcher.CollectionObject<Model | BasePart>)
	if not IS_CLIENT then
		return
	end

	local openAngle = object.context:GetAttribute("attr_open_angle") :: number? or DEFAULT_OPEN_ANGLE
	local openTime = object.context:GetAttribute("attr_open_time") :: number? or DEFAULT_OPEN_TIME
	local triggerDistance = object.context:GetAttribute("attr_trigger_distance") :: number? or DEFAULT_TRIGGER_DISTANCE
	local axis = object.context:GetAttribute("attr_axis") :: Vector3? or DEFAULT_AXIS

	local closedPivot = object.context:GetPivot()

	local currentAngle = 0
	local targetAngle = 0
	local isOpen = false
	local isClosing = false

	local triggerDistanceSq = triggerDistance * triggerDistance
	-- Unsigned so a negative attr_open_angle swings the other way
	local rotationSpeed = math.abs(openAngle) / openTime

	local function playSound(name: string)
		local sound = object.context:FindFirstChild(name)

		if sound and sound:IsA("Sound") then
			sound:Play()
		end
	end

	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not object.context or not object.context.Parent then
			return
		end

		local character = LOCAL_PLAYER and LOCAL_PLAYER.Character
		local shouldBeOpen = false

		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if rootPart then
				local gatePosition = object.context:GetPivot().Position
				local offset = rootPart.Position - gatePosition
				local distanceSq = offset.X * offset.X + offset.Y * offset.Y + offset.Z * offset.Z
				shouldBeOpen = distanceSq <= triggerDistanceSq
			end
		end

		if shouldBeOpen ~= isOpen then
			isOpen = shouldBeOpen
			isClosing = not shouldBeOpen

			if shouldBeOpen then
				playSound("Open")
			end
		end

		targetAngle = shouldBeOpen and openAngle or 0

		local angleDiff = targetAngle - currentAngle

		if angleDiff ~= 0 then
			local angleStep = rotationSpeed * deltaTime

			-- The last step lands exactly on the target, so a resting gate
			-- is never left slightly ajar
			if math.abs(angleDiff) <= angleStep then
				currentAngle = targetAngle
			else
				currentAngle += math.sign(angleDiff) * angleStep
			end

			object.context:PivotTo(
				closedPivot
					* CFrame.Angles(
						axis.X * math.rad(currentAngle),
						axis.Y * math.rad(currentAngle),
						axis.Z * math.rad(currentAngle)
					)
			)
		end

		if isClosing and currentAngle == 0 then
			isClosing = false
			playSound("Close")
		end
	end)

	object.Destroyed:Once(function()
		if connection.Connected then
			connection:Disconnect()
		end
	end)
end)

return SwingGate
