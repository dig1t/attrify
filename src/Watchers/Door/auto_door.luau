--!strict
--[[
	@class AutoDoor
	Auto-opening door that slides open when a player approaches.

	Attributes:
	- attr_open_offset: Vector3 (default: 0, 5, 0) - How far the door moves when open
	- attr_open_time: number (default: 0.5) - Time to open/close
	- attr_trigger_distance: number (default: 10) - Distance to trigger opening
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "auto_door"
local IS_CLIENT = RunService:IsClient()
local LOCAL_PLAYER = Players.LocalPlayer
local DEFAULT_OPEN_OFFSET = Vector3.new(0, 5, 0)
local DEFAULT_OPEN_TIME = 0.5
local DEFAULT_TRIGGER_DISTANCE = 10

local AutoDoor: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

AutoDoor:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_CLIENT then
		return
	end

	local openOffset = object.context:GetAttribute("attr_open_offset") :: Vector3? or DEFAULT_OPEN_OFFSET
	local openTime = object.context:GetAttribute("attr_open_time") :: number? or DEFAULT_OPEN_TIME
	local triggerDistance = object.context:GetAttribute("attr_trigger_distance") :: number? or DEFAULT_TRIGGER_DISTANCE

	local closedCFrame = object.context.CFrame
	local openCFrame = closedCFrame + openOffset
	local isOpen = false
	local currentTween: Tween?

	local tweenInfo = TweenInfo.new(openTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	local function openDoor()
		if isOpen then
			return
		end
		isOpen = true

		if currentTween then
			currentTween:Cancel()
		end

		currentTween = TweenService:Create(object.context, tweenInfo, { CFrame = openCFrame })

		if currentTween then
			currentTween:Play()
		end
	end

	local function closeDoor()
		if not isOpen then
			return
		end
		isOpen = false

		if currentTween then
			currentTween:Cancel()
		end

		currentTween = TweenService:Create(object.context, tweenInfo, { CFrame = closedCFrame })

		if currentTween then
			currentTween:Play()
		end
	end

	local triggerDistanceSq = triggerDistance * triggerDistance

	local connection = RunService.Heartbeat:Connect(function()
		if not object.context or not object.context.Parent then
			return
		end

		local character = LOCAL_PLAYER and LOCAL_PLAYER.Character
		if not character then
			closeDoor()
			return
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not rootPart then
			closeDoor()
			return
		end

		local offset = rootPart.Position - object.context.Position
		local distanceSq = offset.X * offset.X + offset.Y * offset.Y + offset.Z * offset.Z

		if distanceSq <= triggerDistanceSq then
			openDoor()
		else
			closeDoor()
		end
	end)

	object.Destroyed:Once(function()
		if connection.Connected then
			connection:Disconnect()
		end
		if currentTween then
			currentTween:Cancel()
		end
	end)
end)

return AutoDoor
