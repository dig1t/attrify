--!strict
--[[
	@class CrumblingPart
	Platform that crumbles after being stood on.

	Attributes:
	- attr_crumble_delay: number (default: 1) - Time before crumbling after touch
	- attr_respawn_time: number (default: 5) - Time before respawning (0 = no respawn)
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Util = require(Packages.Util)

local COLLECTION_TAG = "crumbling_part"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_CRUMBLE_DELAY = 1
local DEFAULT_RESPAWN_TIME = 5

local CrumblingPart: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

CrumblingPart:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_CLIENT then
		return
	end

	local crumbleDelay = object.context:GetAttribute("attr_crumble_delay") :: number? or DEFAULT_CRUMBLE_DELAY
	local respawnTime = object.context:GetAttribute("attr_respawn_time") :: number? or DEFAULT_RESPAWN_TIME

	local originalTransparency = object.context.Transparency
	local originalColor = object.context.Color
	local isCrumbling = false
	local hasCrumbled = false

	local shakeConnection: RBXScriptConnection?

	local connection = Util.onPlayerTouch(object.context, function(_player: Player)
		if isCrumbling or hasCrumbled then
			return
		end

		isCrumbling = true

		local shakeIntensity = 0.15
		local originalCFrame = object.context.CFrame
		local seed = math.random(1000)
		local shakeTime = 0

		shakeConnection = RunService.Heartbeat:Connect(function(deltaTime)
			shakeTime += deltaTime
			local noiseX = math.noise(shakeTime * 30, seed, 0) * shakeIntensity
			local noiseY = math.noise(shakeTime * 30, seed + 100, 0) * shakeIntensity
			local noiseZ = math.noise(shakeTime * 30, seed + 200, 0) * shakeIntensity
			object.context.CFrame = originalCFrame + Vector3.new(noiseX, noiseY, noiseZ)
		end)

		local warningTween = TweenService:Create(
			object.context,
			TweenInfo.new(crumbleDelay, Enum.EasingStyle.Linear),
			{ Color = Color3.fromRGB(255, 100, 100) }
		)
		warningTween:Play()

		task.delay(crumbleDelay, function()
			if shakeConnection then
				shakeConnection:Disconnect()
			end

			object.context.CFrame = originalCFrame
			object.context.Transparency = 1
			object.context.CanCollide = false
			hasCrumbled = true
			isCrumbling = false

			if respawnTime > 0 then
				task.delay(respawnTime, function()
					if object.context and object.context.Parent then
						object.context.Transparency = originalTransparency
						object.context.Color = originalColor
						object.context.CanCollide = true
						hasCrumbled = false
					end
				end)
			end
		end)
	end)

	object.Destroyed:Once(function()
		if connection then
			connection:Disconnect()
		end
		if shakeConnection then
			shakeConnection:Disconnect()
		end
	end)
end)

return CrumblingPart
