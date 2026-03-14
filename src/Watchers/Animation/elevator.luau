--!strict
--[[
	@class Elevator
	Multi-floor elevator that moves between stops.

	Requires:
	- Stop1, Stop2, Stop3... (Attachments) - Floor positions

	Attributes:
	- attr_move_time: number (default: 2) - Time to move between floors
	- attr_wait_time: number (default: 3) - Time to wait at each floor
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "elevator"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_MOVE_TIME = 2
local DEFAULT_WAIT_TIME = 3

local Elevator: CollectionWatcher.CollectionWatcher<Model | BasePart> = CollectionWatcher.new(COLLECTION_TAG)

local function getAlpha(progress: number)
	return TweenService:GetValue(progress, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
end

Elevator:RegisterHandler(function(object: CollectionWatcher.CollectionObject<Model | BasePart>)
	if not IS_CLIENT then
		return
	end

	local moveTime = object.context:GetAttribute("attr_move_time") :: number? or DEFAULT_MOVE_TIME
	local waitTime = object.context:GetAttribute("attr_wait_time") :: number? or DEFAULT_WAIT_TIME

	local stops: { CFrame } = {}

	for i = 1, 20 do
		local stopName = `Stop{i}`
		for _, child in object.context:GetChildren() do
			if child:IsA("Attachment") and child.Name == stopName then
				table.insert(stops, child.WorldCFrame)
				break
			end
		end
	end

	if #stops < 2 then
		warn("Elevator requires at least Stop1 and Stop2 attachments")
		return
	end

	object.context:PivotTo(stops[1])

	local currentStopIndex = 1
	local nextStopIndex = 2
	local direction = 1
	local cycleTime = 0
	local isMoving = false
	local totalCycleTime = moveTime + waitTime

	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not object.context or not object.context.Parent then
			return
		end

		cycleTime += deltaTime

		if cycleTime >= totalCycleTime then
			cycleTime = 0

			currentStopIndex = nextStopIndex
			nextStopIndex = currentStopIndex + direction

			if nextStopIndex > #stops then
				direction = -1
				nextStopIndex = currentStopIndex + direction
			elseif nextStopIndex < 1 then
				direction = 1
				nextStopIndex = currentStopIndex + direction
			end

			isMoving = true
		end

		if isMoving then
			local progress = cycleTime / moveTime
			if progress >= 1 then
				object.context:PivotTo(stops[nextStopIndex])
				isMoving = false
			else
				local alpha = getAlpha(progress)
				object.context:PivotTo(stops[currentStopIndex]:Lerp(stops[nextStopIndex], alpha))
			end
		end
	end)

	object.Destroyed:Once(function()
		if connection.Connected then
			connection:Disconnect()
		end
	end)
end)

return Elevator
