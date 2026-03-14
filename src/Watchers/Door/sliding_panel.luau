--!strict
--[[
	@class SlidingPanel
	Panel that slides open when triggered.

	Attributes:
	- attr_slide_offset: Vector3 (default: 5, 0, 0) - How far the panel slides
	- attr_slide_time: number (default: 0.5) - Time to slide open/close
	- attr_trigger_distance: number (default: 10) - Distance to trigger
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "sliding_panel"
local IS_CLIENT = RunService:IsClient()
local LOCAL_PLAYER = Players.LocalPlayer
local DEFAULT_SLIDE_OFFSET = Vector3.new(5, 0, 0)
local DEFAULT_SLIDE_TIME = 0.5
local DEFAULT_TRIGGER_DISTANCE = 10

local SlidingPanel: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

SlidingPanel:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_CLIENT then
		return
	end

	local slideOffset = object.context:GetAttribute("attr_slide_offset") :: Vector3? or DEFAULT_SLIDE_OFFSET
	local slideTime = object.context:GetAttribute("attr_slide_time") :: number? or DEFAULT_SLIDE_TIME
	local triggerDistance = object.context:GetAttribute("attr_trigger_distance") :: number? or DEFAULT_TRIGGER_DISTANCE

	local closedCFrame = object.context.CFrame
	local openCFrame = closedCFrame + object.context.CFrame:VectorToWorldSpace(slideOffset)
	local isOpen = false
	local currentTween: Tween?

	local tweenInfo = TweenInfo.new(slideTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	local function openPanel()
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

	local function closePanel()
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
			closePanel()
			return
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not rootPart then
			closePanel()
			return
		end

		local offset = rootPart.Position - object.context.Position
		local distanceSq = offset.X * offset.X + offset.Y * offset.Y + offset.Z * offset.Z

		if distanceSq <= triggerDistanceSq then
			openPanel()
		else
			closePanel()
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

return SlidingPanel
