--!strict
--[[
	@class Button
	Touch-activated button with optional cooldown.

	Attributes:
	- attr_cooldown: number (default: 1) - Cooldown between activations

	Fires Signal "ButtonPressed" with (player, part)
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Signal = require(Packages.Signal)
local Util = require(Packages.Util)

local COLLECTION_TAG = "button"
local IS_SERVER = RunService:IsServer()
local DEFAULT_COOLDOWN = 1

local ButtonPressed = Signal.new()

local Button: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Button:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local cooldown = object.context:GetAttribute("attr_cooldown") :: number? or DEFAULT_COOLDOWN

	local isOnCooldown = false

	local connection = Util.onPlayerTouch(object.context, function(player: Player)
		if isOnCooldown then
			return
		end

		isOnCooldown = true
		ButtonPressed:Fire(player, object.context)

		task.delay(cooldown, function()
			isOnCooldown = false
		end)
	end)

	object.Destroyed:Once(function()
		if connection then
			connection:Disconnect()
		end
	end)
end)

local module = {
	watcher = Button,
	ButtonPressed = ButtonPressed,
}

return module
