--!strict
--[[
	@class JumpPad
	Launches players into the air on touch.

	Attributes:
	- attr_jump_distance: number (default: 20) - Target studs distance to launch
	- attr_cooldown: number (default: 1) - Cooldown between launches per player
	- attr_push_relative_to_object: boolean (default: true) - Push relative to object's up vector
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Util = require(Packages.Util)

local COLLECTION_TAG = "jump_pad"
local IS_SERVER = RunService:IsServer()
local DEFAULT_COOLDOWN = 1
local DEFAULT_JUMP_DISTANCE = 20
local DEFAULT_PUSH_RELATIVE_TO_OBJECT = true

local JumpPad: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

JumpPad:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local cooldown = object.context:GetAttribute("attr_cooldown") :: number? or DEFAULT_COOLDOWN
	local jumpDistance = object.context:GetAttribute("attr_jump_distance") :: number? or DEFAULT_JUMP_DISTANCE
	local pushRelativeToObject = object.context:GetAttribute("attr_push_relative_to_object") :: boolean?
	if pushRelativeToObject == nil then
		pushRelativeToObject = DEFAULT_PUSH_RELATIVE_TO_OBJECT
	end

	local pushDirection = pushRelativeToObject and object.context.CFrame.UpVector or Vector3.new(0, 1, 0)

	local cooldowns: { Player } = {}

	local connection = Util.onPlayerTouch(object.context, function(player: Player)
		if table.find(cooldowns, player) then
			return
		end

		table.insert(cooldowns, player)

		task.delay(cooldown, function()
			local index = table.find(cooldowns, player)

			if index then
				table.remove(cooldowns, index)
			end
		end)

		local character = player.Character

		if not character then
			return
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart or not rootPart:IsA("BasePart") then
			return
		end

		local attachment = Instance.new("Attachment")
		attachment.Parent = rootPart

		local mass = rootPart.AssemblyMass
		local forceMagnitude = jumpDistance * mass * 30
		local force = pushDirection * forceMagnitude

		local vectorForce = Instance.new("VectorForce")
		vectorForce.Force = force
		vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
		vectorForce.ApplyAtCenterOfMass = true
		vectorForce.Attachment0 = attachment
		vectorForce.Parent = rootPart

		local duration = 0.5
		local initialForce = force
		local elapsed = 0
		local distanceTravelled = 0

		local originalPosition = rootPart.Position

		local heartbeatConnection: RBXScriptConnection
		heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
			distanceTravelled = (rootPart.Position - originalPosition).Magnitude
			elapsed += deltaTime

			local progress = elapsed / duration

			if distanceTravelled >= jumpDistance or progress >= 1 then
				vectorForce:Destroy()
				attachment:Destroy()
				heartbeatConnection:Disconnect()
			else
				local forceMultiplier = 1 - (progress * progress)
				vectorForce.Force = initialForce * forceMultiplier
			end
		end)
	end)

	object.Destroyed:Once(function()
		if connection then
			connection:Disconnect()
		end
	end)
end)

return JumpPad
