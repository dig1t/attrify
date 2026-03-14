--!strict
--[[
	@class Conveyor
	Moves players and parts along the conveyor direction.

	Attributes:
	- attr_speed: number (default: 10) - Conveyor speed in studs per second
	- attr_direction: Vector3 (default: 0, 0, -1) - Direction relative to part's CFrame
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "conveyor"
local IS_SERVER = RunService:IsServer()
local DEFAULT_SPEED = 10
local DEFAULT_DIRECTION = Vector3.new(0, 0, -1)

local Conveyor: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Conveyor:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local speed = object.context:GetAttribute("attr_speed") :: number? or DEFAULT_SPEED
	local direction = object.context:GetAttribute("attr_direction") :: Vector3? or DEFAULT_DIRECTION

	local worldDirection = object.context.CFrame:VectorToWorldSpace(direction.Unit)
	object.context.AssemblyLinearVelocity = worldDirection * speed

	local attributeConnection = object.context.AttributeChanged:Connect(function(attributeName)
		if attributeName == "attr_speed" then
			speed = object.context:GetAttribute("attr_speed") :: number? or DEFAULT_SPEED
			object.context.AssemblyLinearVelocity = worldDirection * speed
		elseif attributeName == "attr_direction" then
			direction = object.context:GetAttribute("attr_direction") :: Vector3? or DEFAULT_DIRECTION
			worldDirection = object.context.CFrame:VectorToWorldSpace(direction.Unit)
			object.context.AssemblyLinearVelocity = worldDirection * speed
		end
	end)

	object.Destroyed:Once(function()
		attributeConnection:Disconnect()
	end)
end)

return Conveyor
