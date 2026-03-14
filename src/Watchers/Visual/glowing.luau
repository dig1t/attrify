--!strict
--[[
	@class Glowing
	Adds a neon glow effect to a part.

	Attributes:
	- attr_glow_color: Color3 (optional) - Color of the glow (defaults to part color)
	- attr_brightness: number (default: 1) - PointLight brightness
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "glowing"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_BRIGHTNESS = 1

local Glowing: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Glowing:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_CLIENT then
		return
	end

	local glowColor = object.context:GetAttribute("attr_glow_color") :: Color3? or object.context.Color
	local brightness = object.context:GetAttribute("attr_brightness") :: number? or DEFAULT_BRIGHTNESS

	object.context.Material = Enum.Material.Neon

	local pointLight = Instance.new("PointLight")
	pointLight.Color = glowColor
	pointLight.Brightness = brightness
	pointLight.Range = math.max(object.context.Size.X, object.context.Size.Y, object.context.Size.Z) * 2
	pointLight.Parent = object.context

	local attributeConnection = object.context.AttributeChanged:Connect(function(attributeName)
		if attributeName == "attr_glow_color" then
			local newColor = object.context:GetAttribute("attr_glow_color") :: Color3?
			if newColor then
				pointLight.Color = newColor
			end
		elseif attributeName == "attr_brightness" then
			pointLight.Brightness = object.context:GetAttribute("attr_brightness") :: number? or DEFAULT_BRIGHTNESS
		end
	end)

	object.Destroyed:Once(function()
		attributeConnection:Disconnect()
		pointLight:Destroy()
	end)
end)

return Glowing
