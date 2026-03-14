--!strict
--[[
	@class FadingPart
	Part that fades out when touched and optionally reappears after a delay.

	Attributes:
	- attr_fade_time: number (default: 1) - Time to fade in/out
	- attr_respawn_time: number (default: 3) - Time before fading back in (0 = no respawn)
	- attr_cooldown: number (default: 0) - Cooldown after reappearing before can trigger again
	- attr_per_player: boolean (default: false) - If true, runs client-side (per-player state)
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Util = require(Packages.Util)

local COLLECTION_TAG = "fading_part"
local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()
local DEFAULT_FADE_TIME = 1
local DEFAULT_RESPAWN_TIME = 3
local DEFAULT_COOLDOWN = 0
local DEFAULT_PER_PLAYER = false

local FadingPart: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

FadingPart:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	local perPlayer = object.context:GetAttribute("attr_per_player") :: boolean? or DEFAULT_PER_PLAYER

	local shouldRun = (perPlayer and IS_CLIENT) or (not perPlayer and IS_SERVER)
	if not shouldRun then
		return
	end

	local fadeTime = object.context:GetAttribute("attr_fade_time") :: number? or DEFAULT_FADE_TIME
	local respawnTime = object.context:GetAttribute("attr_respawn_time") :: number? or DEFAULT_RESPAWN_TIME
	local cooldown = object.context:GetAttribute("attr_cooldown") :: number? or DEFAULT_COOLDOWN

	local originalTransparency = object.context.Transparency
	local originalCanCollide = object.context.CanCollide
	local isFading = false

	local tweenInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Linear)

	local connection = Util.onPlayerTouch(object.context, function(_player: Player)
		if isFading then
			return
		end

		isFading = true

		local fadeOutTween = TweenService:Create(object.context, tweenInfo, { Transparency = 1 })
		fadeOutTween:Play()
		fadeOutTween.Completed:Wait()

		object.context.CanCollide = false

		if respawnTime > 0 then
			task.delay(respawnTime, function()
				if not object.context or not object.context.Parent then
					return
				end

				local fadeInTween = TweenService:Create(object.context, tweenInfo, { Transparency = originalTransparency })
				fadeInTween:Play()
				fadeInTween.Completed:Wait()

				object.context.CanCollide = originalCanCollide

				if cooldown > 0 then
					task.wait(cooldown)
				end

				isFading = false
			end)
		end
	end)

	object.Destroyed:Once(function()
		if connection then
			connection:Disconnect()
		end
	end)
end)

return FadingPart
