--!strict
--[[
	@class Trail
	Adds a trail attachment to a part.

	Attributes:
	- attr_trail_color: Color3 (default: white) - Color of the trail
	- attr_lifetime: number (default: 1) - Trail lifetime in seconds
	- attr_width: number (default: 1) - Trail width
	- attr_axis: Vector3 (default: 0, 1, 0) - Axis for trail attachments (X, Y, or Z)
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "trail"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_TRAIL_COLOR = Color3.new(1, 1, 1)
local DEFAULT_LIFETIME = 1
local DEFAULT_WIDTH = 1
local DEFAULT_AXIS = Vector3.yAxis

local Trail: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Trail:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_CLIENT then
		return
	end

	local trailColor = object.context:GetAttribute("attr_trail_color") :: Color3? or DEFAULT_TRAIL_COLOR
	local lifetime = object.context:GetAttribute("attr_lifetime") :: number? or DEFAULT_LIFETIME
	local width = object.context:GetAttribute("attr_width") :: number? or DEFAULT_WIDTH
	local axis = object.context:GetAttribute("attr_axis") :: Vector3? or DEFAULT_AXIS

	local normalizedAxis = axis.Unit
	local halfSize = (object.context.Size * normalizedAxis).Magnitude / 2

	local attachment0 = Instance.new("Attachment")
	attachment0.Position = normalizedAxis * halfSize
	attachment0.Parent = object.context

	local attachment1 = Instance.new("Attachment")
	attachment1.Position = normalizedAxis * -halfSize
	attachment1.Parent = object.context

	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Color = ColorSequence.new(trailColor)
	trail.Lifetime = lifetime
	trail.MinLength = 0.1
	trail.WidthScale = NumberSequence.new(width)
	trail.Parent = object.context

	local attributeConnection = object.context.AttributeChanged:Connect(function(attributeName)
		if attributeName == "attr_trail_color" then
			local newColor = object.context:GetAttribute("attr_trail_color") :: Color3? or DEFAULT_TRAIL_COLOR
			trail.Color = ColorSequence.new(newColor)
		elseif attributeName == "attr_lifetime" then
			trail.Lifetime = object.context:GetAttribute("attr_lifetime") :: number? or DEFAULT_LIFETIME
		elseif attributeName == "attr_width" then
			local newWidth = object.context:GetAttribute("attr_width") :: number? or DEFAULT_WIDTH
			trail.WidthScale = NumberSequence.new(newWidth)
		end
	end)

	object.Destroyed:Once(function()
		attributeConnection:Disconnect()
		trail:Destroy()
		attachment0:Destroy()
		attachment1:Destroy()
	end)
end)

return Trail
