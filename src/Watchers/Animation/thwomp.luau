--!strict
--[[
	@class Thwomp
	Smash/crusher behavior that drops down and rises back up.

	Requires:
	- Floor (Attachment) - The target position when dropped

	Attributes:
	- attr_animation_time: number (default: 1) - Time to animate up/down
	- attr_time_on_floor: number (default: 1) - Time to stay at floor position
	- attr_time_between_drops: number (default: 1) - Wait time before dropping again
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "thwomp"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_ANIMATION_TIME = 1
local DEFAULT_TIME_ON_FLOOR = 1
local DEFAULT_TIME_BETWEEN_DROPS = 1

local Thwomp: CollectionWatcher.CollectionWatcher<Model | BasePart> = CollectionWatcher.new(COLLECTION_TAG)

local function getAlpha(cycleTime: number, duration: number, animatingIn: boolean)
	return TweenService:GetValue(
		cycleTime / duration,
		Enum.EasingStyle.Back,
		animatingIn and Enum.EasingDirection.In or Enum.EasingDirection.Out
	)
end

Thwomp:RegisterHandler(function(object: CollectionWatcher.CollectionObject<Model | BasePart>)
	if not IS_CLIENT then
		return
	end

	local animationTime = object.context:GetAttribute("attr_animation_time") :: number? or DEFAULT_ANIMATION_TIME
	local timeOnFloor = object.context:GetAttribute("attr_time_on_floor") :: number? or DEFAULT_TIME_ON_FLOOR
	local timeBetweenDrops = object.context:GetAttribute("attr_time_between_drops") :: number? or DEFAULT_TIME_BETWEEN_DROPS

	local floorAttachment: Attachment?

	for _, child in object.context:GetChildren() do
		if child:IsA("Attachment") and child.Name == "Floor" then
			floorAttachment = child
			break
		end
	end

	if not floorAttachment then
		warn("Thwomp requires a Floor attachment")
		return
	end

	local originalPivot = object.context:GetPivot()
	local floorPosition = floorAttachment.WorldCFrame

	local cycleTime = 0
	local totalCycleTime = animationTime + timeOnFloor + animationTime + timeBetweenDrops

	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not object.context or not object.context.Parent then
			return
		end

		cycleTime += deltaTime

		if cycleTime >= totalCycleTime then
			cycleTime = 0
		end

		local progress = cycleTime / totalCycleTime

		local dropPhaseEnd = animationTime / totalCycleTime
		local floorPhaseEnd = (animationTime + timeOnFloor) / totalCycleTime
		local risePhaseEnd = (animationTime + timeOnFloor + animationTime) / totalCycleTime

		if progress < dropPhaseEnd then
			local dropProgress = progress / dropPhaseEnd
			local alpha = getAlpha(dropProgress * animationTime, animationTime, true)
			object.context:PivotTo(originalPivot:Lerp(floorPosition, alpha))
		elseif progress < floorPhaseEnd then
			object.context:PivotTo(floorPosition)
		elseif progress < risePhaseEnd then
			local riseProgress = (progress - floorPhaseEnd) / (risePhaseEnd - floorPhaseEnd)
			local alpha = getAlpha(riseProgress * animationTime, animationTime, false)
			object.context:PivotTo(floorPosition:Lerp(originalPivot, alpha))
		else
			object.context:PivotTo(originalPivot)
		end
	end)

	object.Destroyed:Once(function()
		if connection.Connected then
			connection:Disconnect()
		end
	end)
end)

return Thwomp
