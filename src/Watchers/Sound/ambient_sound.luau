--!strict
--[[
	@class AmbientSound
	Plays an ambient looping sound.

	Attributes:
	- attr_sound_id: string (required) - Asset ID of the sound
	- attr_volume: number (default: 0.5) - Sound volume
	- attr_range: number (default: 50) - Maximum audible distance
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "ambient_sound"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_VOLUME = 0.5
local DEFAULT_RANGE = 50

local AmbientSound: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

AmbientSound:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_CLIENT then
		return
	end

	local soundId = object.context:GetAttribute("attr_sound_id") :: string?
	local volume = object.context:GetAttribute("attr_volume") :: number? or DEFAULT_VOLUME
	local range = object.context:GetAttribute("attr_range") :: number? or DEFAULT_RANGE

	if not soundId then
		warn("AmbientSound requires attr_sound_id attribute")
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = `rbxassetid://{soundId}`
	sound.Volume = volume
	sound.Looped = true
	sound.RollOffMaxDistance = range
	sound.RollOffMinDistance = range * 0.1
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.Parent = object.context
	sound:Play()

	local attributeConnection = object.context.AttributeChanged:Connect(function(attributeName)
		if attributeName == "attr_sound_id" then
			local newId = object.context:GetAttribute("attr_sound_id") :: string?
			if newId then
				sound.SoundId = `rbxassetid://{newId}`
				sound:Play()
			end
		elseif attributeName == "attr_volume" then
			sound.Volume = object.context:GetAttribute("attr_volume") :: number? or DEFAULT_VOLUME
		elseif attributeName == "attr_range" then
			local newRange = object.context:GetAttribute("attr_range") :: number? or DEFAULT_RANGE
			sound.RollOffMaxDistance = newRange
			sound.RollOffMinDistance = newRange * 0.1
		end
	end)

	object.Destroyed:Once(function()
		attributeConnection:Disconnect()
		sound:Destroy()
	end)
end)

return AmbientSound
