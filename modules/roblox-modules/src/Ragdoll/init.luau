local Debris = game:GetService("Debris") -- TODO: Replace with a better Debris module
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Util = require(script.Parent.Util)

local PLAYER_COLLISION_GROUP_NAME: string = "Player"
local RAGDOLL_COLLISION_GROUP_NAME: string = "Ragdoll"

--[=[
	@class Ragdoll

	Ragdoll package for converting a player's character into a ragdoll.

	Install with wally by adding the following to your `wally.toml`:
	```toml
	Ragdoll = "dig1t/ragdoll@1.0.4"
	```
]=]
local Ragdoll = {}

Ragdoll.isReady = false

--[=[
	Whether or not the ragdoll is collidable (default: false)

	@prop isCollidable boolean
	@within Ragdoll
]=]
Ragdoll.isCollidable = false

--[=[
	Seconds before the ragdoll is destroyed (default: 5)

	@prop destroyTime number
	@within Ragdoll
]=]
Ragdoll.destroyTime = 5 -- Roblox default for characters

--[=[
	Sets up the player's collision group and sets the attr_ragdoll_ready attribute to true.

	This should be run when the player's character is created or loaded.

	@param character Model -- The player's character
]=]
function Ragdoll.setup(character: Model) -- Sets up the player's collision group
	-- Insert collision groups if missing or if isCollidable changed
	if not Ragdoll.isReady and not Ragdoll.isCollidable and RunService:IsServer() then
		local playerGroupExists
		local ragdollGroupExists

		for _, group in PhysicsService:GetRegisteredCollisionGroups() do
			if group.name == PLAYER_COLLISION_GROUP_NAME then
				playerGroupExists = true
			elseif group.name == RAGDOLL_COLLISION_GROUP_NAME then
				ragdollGroupExists = true
			end
		end

		if not playerGroupExists then
			PhysicsService:RegisterCollisionGroup(PLAYER_COLLISION_GROUP_NAME)
		end

		if not ragdollGroupExists then
			PhysicsService:RegisterCollisionGroup(RAGDOLL_COLLISION_GROUP_NAME)
		end

		if not playerGroupExists or not ragdollGroupExists then
			-- Disable collisions with ragdoll characters
			PhysicsService:CollisionGroupSetCollidable(
				PLAYER_COLLISION_GROUP_NAME,
				RAGDOLL_COLLISION_GROUP_NAME,
				false
			)
		end

		Ragdoll.isReady = true
	end

	local _successful, humanoid, _tries = Util.attempt(function()
		return character:FindFirstChild("Humanoid")
	end, 80, 0.1) -- 80 tries * .1 yield times = 8 second max yield

	if not humanoid then
		return
	end

	humanoid.BreakJointsOnDeath = false

	if not Ragdoll.isCollidable then
		for _, obj: BasePart | Instance in character:GetDescendants() do
			if obj:IsA("BasePart") then
				obj.CollisionGroup = PLAYER_COLLISION_GROUP_NAME
			end
		end
	end

	character:SetAttribute("attr_ragdoll_ready", true)
end

-- Convert the player's character into a ragdoll
local function createRagdoll(character: Model)
	if not character or not character.Parent then
		return
	end

	local partAttachment: Attachment = Instance.new("Attachment")
	partAttachment.Parent = character:FindFirstChild("Head")
		or character.PrimaryPart
		or Util.getFirstPart(character)

	-- Push player backwards
	if partAttachment.Parent then
		local force: VectorForce = Instance.new("VectorForce")
		force.Force = Vector3.new(0, -200, 60)
		force.Attachment0 = partAttachment
		force.Parent = partAttachment
	end

	for _, obj: Motor6D | BasePart | Script | Instance in character:GetDescendants() do
		if obj:IsA("Motor6D") then
			local root: Attachment = Instance.new("Attachment")
			local attachment: Attachment = Instance.new("Attachment")
			root.CFrame = obj.C0
			root.Parent = obj.Part0
			attachment.CFrame = obj.C1
			attachment.Parent = obj.Part1

			local ballSocket: BallSocketConstraint = Instance.new("BallSocketConstraint")
			ballSocket.LimitsEnabled = true
			ballSocket.TwistLimitsEnabled = true -- Disable joints from freely rotating
			ballSocket.Attachment0 = root
			ballSocket.Attachment1 = attachment
			ballSocket.Parent = obj.Parent

			obj:Destroy() -- Remove the Motor6D instance
		end

		if obj:IsA("BasePart") then
			-- Switch collision group so players can't interact with the ragdoll
			obj.CanCollide = true

			if not Ragdoll.isCollidable then
				obj.CollisionGroup = RAGDOLL_COLLISION_GROUP_NAME
			end
		elseif obj:IsA("Script") then
			obj:Destroy()
		end
	end
end

--[=[
	Converts the player's character into a ragdoll and removes the player's character.

	This should be run when the player dies.

	@param player Player -- The player
	@param parent Instance? -- The parent of the ragdoll
	@param destroyTime number? -- The time in seconds before the ragdoll is destroyed
	@param keepRagdollInWorld boolean? -- Whether or not to keep the ragdoll in the world
]=]
function Ragdoll.playerDied(
	player: Player,
	parent: Instance?,
	destroyTime: number?,
	keepRagdollInWorld: boolean?
)
	if not player.Character or not player.Character:GetAttribute("attr_ragdoll_ready") then
		return
	end

	parent = parent or Workspace -- Default parent to Workspace

	local newCharacter: Model = Instance.new("Model")
	newCharacter.Name = player.Character.Name
	newCharacter.Parent = parent

	-- Ragdolls automatically disappear after 2 minutes
	-- whether or not keepRagdollInWorld is enabled
	Debris:AddItem(newCharacter, 120)

	parent = newCharacter -- Assign parent as newCharacter

	createRagdoll(player.Character) -- Convert the player's character into a ragdoll

	if parent then
		-- Place parts inside the ragdoll model (newCharacter)
		-- and filter out unwanted instances and scripts
		for _, obj in player.Character:GetChildren() do
			if not obj:IsA("Tool") then
				obj.Parent = parent
			elseif obj:FindFirstChild("Handle") then
				local handle = obj:FindFirstChild("Handle")

				if handle then
					handle.Parent = parent
					obj:Destroy()
				end
			end
		end
	end

	player.Character:Destroy()
	player.Character = nil

	task.wait(destroyTime or Ragdoll.destroyTime)

	if not parent or not parent.Parent then
		return
	elseif not keepRagdollInWorld then
		parent:Destroy()
	else
		for _, obj: BasePart | Instance in parent:GetDescendants() do
			if obj:IsA("BasePart") then
				obj.Anchored = true
			end
		end
	end
end

return Ragdoll
