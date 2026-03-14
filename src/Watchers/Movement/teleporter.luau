--!strict
--[[
	@class Teleporter
	Teleports players between two parts within a Model.

	Structure:
	- Model (tagged with "teleporter")
		- From: BasePart - Entry point
		- To: BasePart - Exit point

	Attributes:
	- attr_cooldown: number (default: 1) - Cooldown between teleports per player
	- attr_one_way: boolean (default: false) - If true, only "From" teleports to "To"
	- attr_teleport_offset: Vector3 (default: 0, 3, 0) - Offset applied when teleporting
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Util = require(Packages.Util)

local COLLECTION_TAG = "teleporter"
local IS_SERVER = RunService:IsServer()
local DEFAULT_COOLDOWN = 1
local DEFAULT_ONE_WAY = false
local DEFAULT_TELEPORT_OFFSET = Vector3.new(0, 0, 0)

local Teleporter: CollectionWatcher.CollectionWatcher<Model> = CollectionWatcher.new(COLLECTION_TAG)

Teleporter:RegisterHandler(function(object: CollectionWatcher.CollectionObject<Model>)
	if not IS_SERVER then
		return
	end

	local fromPart = object.context:FindFirstChild("From")
	local toPart = object.context:FindFirstChild("To")

	if not fromPart or not fromPart:IsA("BasePart") then
		warn("Teleporter requires a BasePart named 'From'")
		return
	end

	if not toPart or not toPart:IsA("BasePart") then
		warn("Teleporter requires a BasePart named 'To'")
		return
	end

	local cooldown = object.context:GetAttribute("attr_cooldown") :: number? or DEFAULT_COOLDOWN
	local oneWay = object.context:GetAttribute("attr_one_way") :: boolean? or DEFAULT_ONE_WAY
	local teleportOffset = object.context:GetAttribute("attr_teleport_offset") :: Vector3? or DEFAULT_TELEPORT_OFFSET

	local cooldowns: { [Player]: boolean } = {}

	local function teleportPlayer(player: Player, target: BasePart)
		if cooldowns[player] then
			return
		end

		cooldowns[player] = true

		task.delay(cooldown, function()
			cooldowns[player] = nil
		end)

		local character = player.Character
		if not character then
			return
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart and rootPart:IsA("BasePart") then
			rootPart.CFrame = target.CFrame + teleportOffset
		end
	end

	local fromConnection = Util.onPlayerTouch(fromPart, function(player: Player)
		teleportPlayer(player, toPart)
	end)

	local toConnection: RBXScriptConnection?
	if not oneWay then
		toConnection = Util.onPlayerTouch(toPart, function(player: Player)
			teleportPlayer(player, fromPart)
		end)
	end

	object.Destroyed:Once(function()
		fromConnection:Disconnect()
		if toConnection then
			toConnection:Disconnect()
		end
	end)
end)

return Teleporter
