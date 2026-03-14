--!strict
--[[
	@class GravityZone
	Applies custom gravity to players while inside the zone.

	Attributes:
	- attr_gravity_force: number (default: 50) - Gravity force (positive = down, negative = up)
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Util = require(Packages.Util)

local COLLECTION_TAG = "gravity_zone"
local IS_SERVER = RunService:IsServer()
local DEFAULT_GRAVITY_FORCE = 50

local GravityZone: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

GravityZone:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local gravityForce = object.context:GetAttribute("attr_gravity_force") :: number? or DEFAULT_GRAVITY_FORCE

	local playersInZone: { [Player]: BodyForce } = {}

	local touchConnection = object.context.Touched:Connect(function(hit)
		local player = Util.getPlayerFromPart(hit)
		if not player or playersInZone[player] then
			return
		end

		local character = player.Character
		if not character then
			return
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart or not rootPart:IsA("BasePart") then
			return
		end

		local mass = rootPart.AssemblyMass
		local defaultGravity = workspace.Gravity
		local counterForce = mass * defaultGravity
		local customGravityForce = mass * gravityForce

		local bodyForce = Instance.new("BodyForce")
		bodyForce.Force = Vector3.new(0, counterForce - customGravityForce, 0)
		bodyForce.Parent = rootPart

		playersInZone[player] = bodyForce
	end)

	local touchEndedConnection = object.context.TouchEnded:Connect(function(hit)
		local player = Util.getPlayerFromPart(hit)
		if not player or not playersInZone[player] then
			return
		end

		playersInZone[player]:Destroy()
		playersInZone[player] = nil
	end)

	object.Destroyed:Once(function()
		touchConnection:Disconnect()
		touchEndedConnection:Disconnect()

		for _, bodyForce in playersInZone do
			bodyForce:Destroy()
		end
	end)
end)

return GravityZone
