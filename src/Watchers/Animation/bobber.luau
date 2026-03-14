--!strict
--[[
	@class Bobber
	Floats an object up and down continuously.

	Attributes:
	- attr_bob_height: number (default: 2) - Maximum bob distance in studs
	- attr_bob_speed: number (default: 1) - Cycles per second
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "bobber"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_BOB_HEIGHT = 2
local DEFAULT_BOB_SPEED = 1

local Bobber: CollectionWatcher.CollectionWatcher<Model | BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Bobber:RegisterHandler(function(object: CollectionWatcher.CollectionObject<Model | BasePart>)
	if not IS_CLIENT then
		return
	end

	local bobHeight = object.context:GetAttribute("attr_bob_height") :: number? or DEFAULT_BOB_HEIGHT
	local bobSpeed = object.context:GetAttribute("attr_bob_speed") :: number? or DEFAULT_BOB_SPEED

	local originalPivot = object.context:GetPivot()
	local elapsedTime = 0

	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not object.context or not object.context.Parent then
			return
		end

		elapsedTime += deltaTime

		local bobOffset = math.sin(elapsedTime * bobSpeed * math.pi * 2) * bobHeight
		object.context:PivotTo(originalPivot + Vector3.new(0, bobOffset, 0))
	end)

	object.Destroyed:Once(function()
		if connection.Connected then
			connection:Disconnect()
		end
	end)
end)

return Bobber
