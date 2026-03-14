--!strict
--[[
	@class Spotlighter
	Adds a spotlight to a part. The spotlight uses the bottom face.

	Attributes:
	- attr_range: number (default: 16) - Light range
	- attr_angle: number (default: 90) - Spotlight angle in degrees
	- attr_light_color: Color3 (default: white) - Color of the light
	- attr_brightness: number (default: 1) - Light brightness
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "spotlighter"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_RANGE = 16
local DEFAULT_ANGLE = 180
local DEFAULT_LIGHT_COLOR = Color3.new(1, 1, 1)
local DEFAULT_BRIGHTNESS = 1

local Spotlighter: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Spotlighter:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_CLIENT then
		return
	end

	local range = object.context:GetAttribute("attr_range") :: number? or DEFAULT_RANGE
	local angle = object.context:GetAttribute("attr_angle") :: number? or DEFAULT_ANGLE
	local lightColor = object.context:GetAttribute("attr_light_color") :: Color3? or DEFAULT_LIGHT_COLOR
	local brightness = object.context:GetAttribute("attr_brightness") :: number? or DEFAULT_BRIGHTNESS

	local spotlight = Instance.new("SpotLight")
	spotlight.Range = range
	spotlight.Angle = angle
	spotlight.Color = lightColor
	spotlight.Brightness = brightness
	spotlight.Face = Enum.NormalId.Bottom
	spotlight.Parent = object.context

	local attributeConnection = object.context.AttributeChanged:Connect(function(attributeName)
		if attributeName == "attr_range" then
			spotlight.Range = object.context:GetAttribute("attr_range") :: number? or DEFAULT_RANGE
		elseif attributeName == "attr_angle" then
			spotlight.Angle = object.context:GetAttribute("attr_angle") :: number? or DEFAULT_ANGLE
		elseif attributeName == "attr_light_color" then
			spotlight.Color = object.context:GetAttribute("attr_light_color") :: Color3? or DEFAULT_LIGHT_COLOR
		elseif attributeName == "attr_brightness" then
			spotlight.Brightness = object.context:GetAttribute("attr_brightness") :: number? or DEFAULT_BRIGHTNESS
		end
	end)

	object.Destroyed:Once(function()
		attributeConnection:Disconnect()
		spotlight:Destroy()
	end)
end)

return Spotlighter
