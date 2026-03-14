--!strict
--[[
	@class Clickable
	Adds a ClickDetector to a part.

	Attributes:
	- attr_max_distance: number (default: 32) - Maximum click distance

	Fires Signal "Clicked" with (player, part)
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Signal = require(Packages.Signal)

local COLLECTION_TAG = "clickable"
local IS_SERVER = RunService:IsServer()
local DEFAULT_MAX_DISTANCE = 32

local Clicked = Signal.new()

local Clickable: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Clickable:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local maxDistance = object.context:GetAttribute("attr_max_distance") :: number? or DEFAULT_MAX_DISTANCE

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = maxDistance
	clickDetector.Parent = object.context

	local clickConnection = clickDetector.MouseClick:Connect(function(player: Player)
		Clicked:Fire(player, object.context)
	end)

	local attributeConnection = object.context.AttributeChanged:Connect(function(attributeName)
		if attributeName == "attr_max_distance" then
			clickDetector.MaxActivationDistance = object.context:GetAttribute("attr_max_distance") :: number?
				or DEFAULT_MAX_DISTANCE
		end
	end)

	object.Destroyed:Once(function()
		clickConnection:Disconnect()
		attributeConnection:Disconnect()
		clickDetector:Destroy()
	end)
end)

local module = {
	watcher = Clickable,
	Clicked = Clicked,
}

return module
