--!strict
--[[
	@class MovingPlatform
	Moves a platform between two attachment points.

	Requires:
	- Point1 (Attachment) - First position
	- Point2 (Attachment) - Second position

	Attributes:
	- attr_studs_per_second: number (default: 1) - Movement speed
	- attr_wait_time: number (default: 1) - Time to wait at each end
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "moving_platform"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_STUDS_PER_SECOND = 1
local DEFAULT_WAIT_TIME = 1

local MovingPlatform: CollectionWatcher.CollectionWatcher<Model | BasePart> = CollectionWatcher.new(COLLECTION_TAG)

local function getAlpha(cycleTime: number, duration: number)
	return TweenService:GetValue(cycleTime / duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
end

MovingPlatform:RegisterHandler(function(object: CollectionWatcher.CollectionObject<Model | BasePart>)
	if not IS_CLIENT then
		return
	end

	local studsPerSecond = object.context:GetAttribute("attr_studs_per_second") :: number? or DEFAULT_STUDS_PER_SECOND
	local waitTime = object.context:GetAttribute("attr_wait_time") :: number? or DEFAULT_WAIT_TIME

	local point1: CFrame?
	local point2: CFrame?

	for _, child in object.context:GetChildren() do
		if child:IsA("Attachment") and child.Name == "Point1" then
			point1 = child.WorldCFrame
		elseif child:IsA("Attachment") and child.Name == "Point2" then
			point2 = child.WorldCFrame
		end
	end

	if not point1 or not point2 then
		warn("MovingPlatform requires Point1 and Point2 attachments")
		return
	end

	object.context:PivotTo(point1)

	local cycleTime = 0
	local distance = (point2.Position - point1.Position).Magnitude
	local moveTime = distance / studsPerSecond
	local totalCycleTime = (moveTime + waitTime) * 2

	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not object.context or not object.context.Parent then
			return
		end

		cycleTime += deltaTime

		if cycleTime >= totalCycleTime then
			cycleTime = 0
		end

		local progress = cycleTime / totalCycleTime

		local movePhase1End = moveTime / totalCycleTime
		local waitPhase1End = (moveTime + waitTime) / totalCycleTime
		local movePhase2End = (moveTime + waitTime + moveTime) / totalCycleTime

		if progress < movePhase1End then
			local moveProgress = progress / movePhase1End
			local alpha = getAlpha(moveProgress * moveTime, moveTime)
			object.context:PivotTo(point1:Lerp(point2, alpha))
		elseif progress < waitPhase1End then
			object.context:PivotTo(point2)
		elseif progress < movePhase2End then
			local moveProgress = (progress - waitPhase1End) / (movePhase2End - waitPhase1End)
			local alpha = getAlpha(moveProgress * moveTime, moveTime)
			object.context:PivotTo(point2:Lerp(point1, alpha))
		else
			object.context:PivotTo(point1)
		end
	end)

	object.Destroyed:Once(function()
		if connection.Connected then
			connection:Disconnect()
		end
	end)
end)

return MovingPlatform
