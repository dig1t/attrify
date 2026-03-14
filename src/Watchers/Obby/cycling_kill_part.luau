--!strict
--[[
	@class CyclingKillPart
	Kill part that cycles between active and inactive states.
	Only damages players when visible/active.

	Attributes:
	- attr_active_time: number (default: 2) - Time the part is active (visible and deadly)
	- attr_inactive_time: number (default: 2) - Time the part is inactive (hidden and safe)
	- attr_delay: number (default: 0) - Initial delay before starting cycle
	- attr_damage: number (default: 100) - Amount of damage to deal
	- attr_cooldown: number (default: 1) - Cooldown between damage applications per player
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Util = require(Packages.Util)

local COLLECTION_TAG = "cycling_kill_part"
local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()
local DEFAULT_ACTIVE_TIME = 2
local DEFAULT_INACTIVE_TIME = 2
local DEFAULT_DELAY = 0
local DEFAULT_DAMAGE = 100
local DEFAULT_COOLDOWN = 1

local CyclingKillPart: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

local function getCycleState(delayTime: number, activeTime: number, totalCycleTime: number): boolean
	local serverTime = workspace:GetServerTimeNow()
	local cyclePosition = (serverTime - delayTime) % totalCycleTime
	return cyclePosition < activeTime
end

CyclingKillPart:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	local activeTime = object.context:GetAttribute("attr_active_time") :: number? or DEFAULT_ACTIVE_TIME
	local inactiveTime = object.context:GetAttribute("attr_inactive_time") :: number? or DEFAULT_INACTIVE_TIME
	local delayTime = object.context:GetAttribute("attr_delay") :: number? or DEFAULT_DELAY

	local totalCycleTime = activeTime + inactiveTime

	if IS_SERVER then
		local damage = object.context:GetAttribute("attr_damage") :: number? or DEFAULT_DAMAGE
		local cooldown = object.context:GetAttribute("attr_cooldown") :: number? or DEFAULT_COOLDOWN

		local cooldowns: { [Player]: boolean } = {}

		local connection = Util.onPlayerTouch(object.context, function(player: Player)
			if not getCycleState(delayTime, activeTime, totalCycleTime) then
				return
			end

			if cooldowns[player] then
				return
			end

			cooldowns[player] = true

			task.delay(cooldown, function()
				cooldowns[player] = nil
			end)

			local humanoid = Util.getHumanoid(player)
			if humanoid then
				humanoid:TakeDamage(damage)
			end
		end)

		object.Destroyed:Once(function()
			connection:Disconnect()
		end)
	elseif IS_CLIENT then
		local originalTransparency = object.context.Transparency

		local connection = RunService.Heartbeat:Connect(function()
			if not object.context or not object.context.Parent then
				return
			end

			local isActive = getCycleState(delayTime, activeTime, totalCycleTime)

			if isActive then
				object.context.Transparency = originalTransparency
				object.context.CanCollide = true
			else
				object.context.Transparency = 1
				object.context.CanCollide = false
			end
		end)

		object.Destroyed:Once(function()
			if connection.Connected then
				connection:Disconnect()
			end
		end)
	end
end)

return CyclingKillPart
