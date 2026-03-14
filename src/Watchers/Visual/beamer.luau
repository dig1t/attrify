--!strict
--[[
	@class Beamer
	Creates a beam between this part and a target part.

	Attributes:
	- attr_target_name: string (required) - Name of the target part
	- attr_beam_color: Color3 (default: white) - Color of the beam
	- attr_width: number (default: 1) - Width of the beam
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "beamer"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_BEAM_COLOR = Color3.new(1, 1, 1)
local DEFAULT_WIDTH = 1

local Beamer: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Beamer:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_CLIENT then
		return
	end

	local targetName = object.context:GetAttribute("attr_target_name") :: string?
	local beamColor = object.context:GetAttribute("attr_beam_color") :: Color3? or DEFAULT_BEAM_COLOR
	local width = object.context:GetAttribute("attr_width") :: number? or DEFAULT_WIDTH

	if not targetName then
		warn("Beamer requires attr_target_name attribute")
		return
	end

	local target = workspace:FindFirstChild(targetName, true)
	if not target or not target:IsA("BasePart") then
		warn(`Beamer target "{targetName}" not found`)
		return
	end

	local attachment0 = Instance.new("Attachment")
	attachment0.Parent = object.context

	local attachment1 = Instance.new("Attachment")
	attachment1.Parent = target

	local beam = Instance.new("Beam")
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Color = ColorSequence.new(beamColor)
	beam.Width0 = width
	beam.Width1 = width
	beam.FaceCamera = true
	beam.Parent = object.context

	local attributeConnection = object.context.AttributeChanged:Connect(function(attributeName)
		if attributeName == "attr_beam_color" then
			local newColor = object.context:GetAttribute("attr_beam_color") :: Color3? or DEFAULT_BEAM_COLOR
			beam.Color = ColorSequence.new(newColor)
		elseif attributeName == "attr_width" then
			local newWidth = object.context:GetAttribute("attr_width") :: number? or DEFAULT_WIDTH
			beam.Width0 = newWidth
			beam.Width1 = newWidth
		end
	end)

	object.Destroyed:Once(function()
		attributeConnection:Disconnect()
		beam:Destroy()
		attachment0:Destroy()
		attachment1:Destroy()
	end)
end)

return Beamer
