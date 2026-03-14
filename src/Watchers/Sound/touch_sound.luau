--!strict
--[[
	@class TouchSound
	Plays a sound when a player touches the part.

	Attributes:
	- attr_sound_id: string (required) - Asset ID of the sound
	- attr_volume: number (default: 0.5) - Sound volume
	- attr_cooldown: number (default: 0.5) - Minimum time between plays
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Util = require(Packages.Util)

local COLLECTION_TAG = "touch_sound"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_VOLUME = 0.5
local DEFAULT_COOLDOWN = 0.5

local TouchSound: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

TouchSound:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_CLIENT then
		return
	end

	local soundId = object.context:GetAttribute("attr_sound_id") :: string?
	local volume = object.context:GetAttribute("attr_volume") :: number? or DEFAULT_VOLUME
	local cooldown = object.context:GetAttribute("attr_cooldown") :: number? or DEFAULT_COOLDOWN

	if not soundId then
		warn("TouchSound requires attr_sound_id attribute")
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = `rbxassetid://{soundId}`
	sound.Volume = volume
	sound.Parent = object.context

	local isOnCooldown = false

	local connection = Util.onPlayerTouch(object.context, function(_player: Player)
		if isOnCooldown then
			return
		end

		isOnCooldown = true
		sound:Play()

		task.delay(cooldown, function()
			isOnCooldown = false
		end)
	end)

	local attributeConnection = object.context.AttributeChanged:Connect(function(attributeName)
		if attributeName == "attr_sound_id" then
			local newId = object.context:GetAttribute("attr_sound_id") :: string?
			if newId then
				sound.SoundId = `rbxassetid://{newId}`
			end
		elseif attributeName == "attr_volume" then
			sound.Volume = object.context:GetAttribute("attr_volume") :: number? or DEFAULT_VOLUME
		end
	end)

	object.Destroyed:Once(function()
		if connection then
			connection:Disconnect()
		end
		attributeConnection:Disconnect()
		sound:Destroy()
	end)
end)

return TouchSound
