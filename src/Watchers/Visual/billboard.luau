--!strict
--[[
	@class Billboard
	Adds a BillboardGui with text above a part.

	Attributes:
	- attr_text: string (default: "") - Text to display
	- attr_text_color: Color3 (default: white) - Text color
	- attr_text_size: number (default: 24) - Text size
	- attr_offset: number (default: 3) - Offset above the part
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "billboard"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_TEXT = ""
local DEFAULT_TEXT_COLOR = Color3.new(1, 1, 1)
local DEFAULT_TEXT_SIZE = 24
local DEFAULT_OFFSET = 3

local BillboardWatcher: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

BillboardWatcher:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_CLIENT then
		return
	end

	local text = object.context:GetAttribute("attr_text") :: string? or DEFAULT_TEXT
	local textColor = object.context:GetAttribute("attr_text_color") :: Color3? or DEFAULT_TEXT_COLOR
	local textSize = object.context:GetAttribute("attr_text_size") :: number? or DEFAULT_TEXT_SIZE
	local offset = object.context:GetAttribute("attr_offset") :: number? or DEFAULT_OFFSET

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, offset, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = object.context

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = textColor
	textLabel.TextSize = textSize
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextScaled = false
	textLabel.Parent = billboard

	local attributeConnection = object.context.AttributeChanged:Connect(function(attributeName)
		if attributeName == "attr_text" then
			textLabel.Text = object.context:GetAttribute("attr_text") :: string? or DEFAULT_TEXT
		elseif attributeName == "attr_text_color" then
			textLabel.TextColor3 = object.context:GetAttribute("attr_text_color") :: Color3? or DEFAULT_TEXT_COLOR
		elseif attributeName == "attr_text_size" then
			textLabel.TextSize = object.context:GetAttribute("attr_text_size") :: number? or DEFAULT_TEXT_SIZE
		elseif attributeName == "attr_offset" then
			billboard.StudsOffset = Vector3.new(
				0,
				object.context:GetAttribute("attr_offset") :: number? or DEFAULT_OFFSET,
				0
			)
		end
	end)

	object.Destroyed:Once(function()
		attributeConnection:Disconnect()
		billboard:Destroy()
	end)
end)

return BillboardWatcher
