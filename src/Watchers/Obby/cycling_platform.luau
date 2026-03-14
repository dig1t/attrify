--!strict
--[[
	@class CyclingPlatform
	Platform that cycles between visible and hidden states.

	Attributes:
	- attr_visible_time: number (default: 2) - Time the platform is visible
	- attr_hidden_time: number (default: 2) - Time the platform is hidden
	- attr_delay: number (default: 0) - Initial delay before starting cycle
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "cycling_platform"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_VISIBLE_TIME = 2
local DEFAULT_HIDDEN_TIME = 2
local DEFAULT_DELAY = 0

local CyclingPlatform: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

CyclingPlatform:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_CLIENT then
		return
	end

	local visibleTime = object.context:GetAttribute("attr_visible_time") :: number? or DEFAULT_VISIBLE_TIME
	local hiddenTime = object.context:GetAttribute("attr_hidden_time") :: number? or DEFAULT_HIDDEN_TIME
	local delayTime = object.context:GetAttribute("attr_delay") :: number? or DEFAULT_DELAY

	local originalTransparency = object.context.Transparency
	local totalCycleTime = visibleTime + hiddenTime
	local cycleTime = -delayTime

	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not object.context or not object.context.Parent then
			return
		end

		cycleTime += deltaTime

		if cycleTime < 0 then
			return
		end

		while cycleTime >= totalCycleTime do
			cycleTime -= totalCycleTime
		end

		local isVisible = cycleTime < visibleTime

		if isVisible then
			object.context.Transparency = originalTransparency
			object.context.CanCollide = true
		else
			object.context.Transparency = 1
			object.context.CanCollide = false
		end
	end)

	object.Destroyed:Once(function()
		if connection.Connected then
			connection:Disconnect()
		end
	end)
end)

return CyclingPlatform
