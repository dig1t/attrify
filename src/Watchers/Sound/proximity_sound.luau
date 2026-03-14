--!strict
--[[
	@class ProximitySound
	Plays a sound when a player comes within range.

	Attributes:
	- attr_sound_id: string (required) - Asset ID of the sound
	- attr_volume: number (default: 0.5) - Sound volume
	- attr_range: number (default: 20) - Trigger distance
	- attr_cooldown: number (default: 5) - Minimum time between plays
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "proximity_sound"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_VOLUME = 0.5
local DEFAULT_RANGE = 20
local DEFAULT_COOLDOWN = 5

local ProximitySound: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

ProximitySound:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_CLIENT then
		return
	end

	local soundId = object.context:GetAttribute("attr_sound_id") :: string?
	local volume = object.context:GetAttribute("attr_volume") :: number? or DEFAULT_VOLUME
	local range = object.context:GetAttribute("attr_range") :: number? or DEFAULT_RANGE
	local cooldown = object.context:GetAttribute("attr_cooldown") :: number? or DEFAULT_COOLDOWN

	if not soundId then
		warn("ProximitySound requires attr_sound_id attribute")
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = `rbxassetid://{soundId}`
	sound.Volume = volume
	sound.Parent = object.context

	local isOnCooldown = false
	local wasInRange = false

	local connection = RunService.Heartbeat:Connect(function()
		if not object.context or not object.context.Parent then
			return
		end

		local partPosition = object.context.Position
		local isInRange = false

		for _, player in Players:GetPlayers() do
			local character = player.Character
			if character then
				local rootPart = character:FindFirstChild("HumanoidRootPart")
				if rootPart and rootPart:IsA("BasePart") then
					local distance = (rootPart.Position - partPosition).Magnitude
					if distance <= range then
						isInRange = true
						break
					end
				end
			end
		end

		if isInRange and not wasInRange and not isOnCooldown then
			isOnCooldown = true
			sound:Play()

			task.delay(cooldown, function()
				isOnCooldown = false
			end)
		end

		wasInRange = isInRange
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
		if connection.Connected then
			connection:Disconnect()
		end
		attributeConnection:Disconnect()
		sound:Destroy()
	end)
end)

return ProximitySound
