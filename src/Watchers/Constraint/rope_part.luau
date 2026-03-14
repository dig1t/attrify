--!strict
--[[
	@class RopePart
	Creates a rope constraint between this part and a target.

	Attributes:
	- attr_target_name: string (required) - Name of the target part
	- attr_length: number (default: 10) - Rope length in studs
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "rope_part"
local IS_SERVER = RunService:IsServer()
local DEFAULT_LENGTH = 10

local RopePart: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

RopePart:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local targetName = object.context:GetAttribute("attr_target_name") :: string?
	local length = object.context:GetAttribute("attr_length") :: number? or DEFAULT_LENGTH

	if not targetName then
		warn("RopePart requires attr_target_name attribute")
		return
	end

	local target = workspace:FindFirstChild(targetName, true)
	if not target or not target:IsA("BasePart") then
		warn(`RopePart target "{targetName}" not found`)
		return
	end

	local attachment0 = Instance.new("Attachment")
	attachment0.Parent = object.context

	local attachment1 = Instance.new("Attachment")
	attachment1.Parent = target

	local rope = Instance.new("RopeConstraint")
	rope.Attachment0 = attachment0
	rope.Attachment1 = attachment1
	rope.Length = length
	rope.Visible = true
	rope.Parent = object.context

	local attributeConnection = object.context.AttributeChanged:Connect(function(attributeName)
		if attributeName == "attr_length" then
			rope.Length = object.context:GetAttribute("attr_length") :: number? or DEFAULT_LENGTH
		end
	end)

	object.Destroyed:Once(function()
		attributeConnection:Disconnect()
		rope:Destroy()
		attachment0:Destroy()
		attachment1:Destroy()
	end)
end)

return RopePart
