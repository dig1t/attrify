--[[
	@name Weapon System Server
	@description A weapon library for quickly building weapons.
	@author dig1t
	@version 1.0.0
]]

--!nocheck

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Util = require(script.Parent.Parent.Util)
local WeaponClient = require(script.Parent.WeaponClient)
-- local CollectionService = require(script.Parent.Parent.CollectionService)
local CollectionService = {
	watch = function(_) end,
	getAll = function()
		return {}
	end,
} -- TODO: replace when CollectionService util is fixed

-- Amount to subtract from the cooldown since players
-- will always be ready before the server by a small amount
local COOLDOWN_OFFSET = 0.2

local DEFAULT_CONFIG = {
	hitscan = true, -- No projectiles will be rendered
	tracerRound = false,

	damage = 30,
	maxRange = 2048,
	rangeModifier = 0.75,
}

local passthroughObjects = CollectionService.watch("BULLET_PASSTHROUGH")

local WeaponServer, methods = {}, {}
methods.__index = methods

-- globalWeaponRemote calls all clients to replicate
-- weapon projectiles and tracers
local globalWeaponRemote = ReplicatedStorage:FindFirstChild("WeaponRemote")

if not globalWeaponRemote then
	globalWeaponRemote = Instance.new("RemoteEvent")
	globalWeaponRemote.Name = "WeaponRemote"
	globalWeaponRemote.Parent = ReplicatedStorage
end

--[[
-- @param type The type of action to identify the aciton by.
-- @desc Binds an action to the remote listener
so it can later be called by client-side code.
]]
function methods:bind(type, fn)
	assert(typeof(type) == "string", "Weapon:bind - No action type given")
	assert(typeof(fn) == "function", "Weapon:bind - No function given")

	self.events[type] = fn
end

--[[
-- @param actionType The action type to check
-- @desc Checks if an action is in cooldown (example: A gun reloading)
]]
function methods:inCooldown(actionType)
	if not self.lastActions[actionType] then
		return
	end

	return os.clock() - self.lastActions[actionType] <= self.config.cooldown[actionType]
end

--[[
-- @param action The action to process
-- @desc Simplified "red" store. Processes an action. The action must include
an action type for it to successfully processed
]]
function methods:processAction(action)
	if not action.type or not self.events[action.type] or not self:ready(action.type) then
		return
	end

	-- Process mobile button triggers
	if action.source == "MOBILE_CONTROL" then
		self.remote:FireClient(self.localPlayer, {
			type = "WEAPON_REMOTE_ACTION",
			payload = {
				actionType = action.type,
			},
		})
	end

	if action.type == "WEAPON_EQUIP" then
		self.equipped = Util.unix()
	elseif action.type == "WEAPON_UNEQUIP" then
		self.equipped = nil
	end

	if self.config.sfx[action.type] then
		self:playSFX(action.type)
	end

	self.events[action.type](action.payload)

	if self.config.cooldown[action.type] then
		self.lastActions[action.type] = os.clock() - COOLDOWN_OFFSET
	end
end

--[[
-- @param actionType The action type to check
-- @desc Makes sure the action is ready to be further processed
by checking if the player is alive and the weapon is not currently
in a cooldown
]]
function methods:ready(actionType)
	return Util.isAlive(self.localPlayer) and not self:inCooldown(actionType)
end

function methods:playSFX(state)
	local id = Util.tableRandom(self.config.sfx[state])
	self.currentSFX = self.handle:FindFirstChild(id)
		or Util.instance("Sound")({
			Name = id,
			Parent = self.handle,
			SoundId = Util.asset .. id,
			Volume = 0.3,
		})

	self.currentSFX:Play()
end

--[[
-- @param player The target player
-- @desc Returns the player's team color, if available
-- @return Color3|nil
]]
function methods:getTeam(player)
	return player
		and player.Character
		and player.Character:FindFirstChild("Team")
		and player.Character.Team.Value
end

--[[
-- @desc Tags the player with a kill tag of the local
player's UserId to later track who they were killed by
]]
function methods:tag(player)
	if not player.Character then
		return
	end

	player.Character:SetAttribute("attr_kill_tag", self.localPlayer.UserId)
end

--[[
-- @param victim The player to damage
-- @param amount Amount to damage player
-- @desc Damages a player. If friendly fire is disabled, it will check
to make sure they are not damaging teammates. If successfully damaged
the function will return true to let the caller know the victim was damaged
-- @return true | nil
]]
function methods:damagePlayer(victim, amount)
	if not victim or victim == self.localPlayer then
		return
	elseif not self.config.friendlyFire then
		local victimTeamColor = self:getTeam(victim)
		local localPlayerTeamColor = self:getTeam(self.localPlayer)

		-- Make sure the local player and the victim are both
		-- in teams before checking to see if they're teammates
		if
			victimTeamColor
			and localPlayerTeamColor
			and victimTeamColor == localPlayerTeamColor
		then
			-- Cannot damage teammates
			return
		end
	end

	local humanoid = Util.getHumanoid(victim)

	if humanoid then
		humanoid:TakeDamage(amount)
		self:tag(victim)

		return true
	end

	return false
end

--[[
-- @param object The projectile reference to save. This object must be a descendant of ReplicatedStorage
-- @desc Saves a reference of the projectile that will be later shot
]]
function methods:setProjectileReference(object)
	assert(object, "WeaponServer:setProjectileReference - Missing reference object")
	if typeof(object) == "Instance" then
		assert(
			object:IsDescendantOf(ReplicatedStorage),
			"WeaponServer:setProjectileReference - Object must be a descendant of ReplicatedStorage"
		)
	end

	if typeof(object) == "function" then
		object = object()
	end

	self.projectileReference = object
end

function methods:createRemoteConfig(name, value)
	Util.set(self.config.tool, name, value)
end

function methods:addMobileControlButton(name)
	if not self.config.tool or not self.config.tool.Parent then
		return
	end

	local controlContainer = self.config.tool:FindFirstChild("MobileControls")

	if not controlContainer then
		controlContainer = Instance.new("Configuration")
		controlContainer.Name = "MobileControls"
		controlContainer.Parent = self.config.tool
	end

	if controlContainer:FindFirstChild(name) then
		-- No need to add another value
		return
	end

	local control = Instance.new("StringValue")
	control.Name = name
	-- control.Value = value
	control.Parent = controlContainer

	return control
end

-- Begin projectile functions
function methods:computeDirection(vec) -- From old roblox rocket launcher
	local invSqrt = 1 / math.sqrt(vec.magnitude * vec.magnitude)
	return Vector3.new(vec.x * invSqrt, vec.y * invSqrt, vec.z * invSqrt)
end

function methods:calcInitialProjectilePosition(target)
	if not self.handle or not self.handle.Parent then
		return CFrame.new()
	end

	target = target or (self.handle.CFrame * CFrame.new(0, 0, -2)).p

	local rootPos = self.handle.Position
	local direction = self:computeDirection(target - rootPos)
	local pos = rootPos + (direction * 2)

	return CFrame.new(pos, pos + direction)
end

function methods:raycast(origin, direction)
	return Workspace:Raycast(
		origin.Position,
		(direction and direction or origin.LookVector) * self.config.maxRange,
		self.raycastFilter
	) or {}
end

function methods:renderProjectile() end

-- ProjectilePassThrough
function methods:shoot(data)
	assert(data and typeof(data) == "table", "WeaponServer:shoot - Missing data table")
	assert(data.callback, "WeaponServer:shoot - Missing callback")

	data.origin = (
		self.localPlayer.Character
		and self.localPlayer.Character.PrimaryPart
		and self.localPlayer.Character.PrimaryPart.CFrame
	)

	if not data.origin then
		return
	end

	local start = os.clock() -- When the projectile first started shooting

	if self.config.hitscan then
		assert(data.target, "WeaponServer:shoot - Missing target")

		self.raycastFilter.FilterDescendantsInstances = Util.extend(
			{ self.localPlayer.Character },
			-- Gather passthrough objects so raycast does not detect them
			passthroughObjects:getAll()
		)

		local direction = data.direction or (data.target - data.origin.Position).Unit

		local hit = self:raycast(data.origin, direction)

		if self.config.tracerRound and self.config.tool:IsDescendantOf(Workspace) then
			for _, player in Players:GetPlayers() do
				if player ~= self.localPlayer then
					globalWeaponRemote:FireClient(player, {
						type = "WEAPON_TRACER",
						payload = {
							origin = data.origin,
							direction = direction,
							handle = self.handle,
							projectileReference = self.projectileReference,
							useModelAsProjectile = self.config.useModelAsProjectile,
							--tool = self.config.tool,
							modelParts = self.modelParts,
							projectileWeldToHit = self.config.projectileWeldToHit,
							projectileRotation = self.config.projectileRotation,
							distance = hit.Position
									and (data.origin.Position - hit.Position).Magnitude
								or self.config.maxRange,
							velocity = self.config.projectileVelocity or 16,
						},
					})
				end
			end
		end

		if hit.Instance then
			data.callback(hit)
		end
	else
		-- Initial variables
		local velocity = self.config.projectileVelocity or 4
		local bulletDrop = self.config.projectileDrop

		-- The slowest velocity the bullet can travel (max 2)
		local minVelocity = velocity > 2 and 2 or velocity

		local projectile = data.projectile or self.projectileReference:Clone()

		if data.projectile:IsA("Model") then
			assert(
				data.projectile.PrimaryPart,
				"Projectile model must have a PrimaryPart defined"
			)

			projectile = data.projectile.PrimaryPart
		end

		projectile.Anchored = true
		projectile.CanCollide = false

		-- If the weapon server controller has not set the parent,
		-- then parent the projectile to Workspace
		if not data.projectile.Parent then
			data.projectile.Parent = Workspace
		end

		Debris:AddItem(data.projectile, self.config.projectileLife or 16)

		local prevCFrame = projectile.CFrame

		-- Loop in a separate thread
		task.spawn(function()
			repeat
				local direction = prevCFrame.LookVector
				local position = prevCFrame.Position
					+ (direction * velocity)
					- Vector3.new(0, bulletDrop, 0)
				local distance = (position - prevCFrame.Position).magnitude

				local hit = self:raycast(
					prevCFrame,
					(position - prevCFrame.Position).unit * velocity
				)

				local nextCFrame = CFrame.new(prevCFrame.Position, position)
					* CFrame.new(0, 0, -distance / 2)

				prevCFrame = nextCFrame
				projectile.CFrame = data.modifier and data.modifier(nextCFrame)
					or nextCFrame

				if hit.Instance then
					data.callback(hit)
					break
				end

				-- Set variables for next frame
				velocity = velocity > minVelocity and velocity - 0.01 or 2
				bulletDrop = self.config.projectileDrop
						and bulletDrop > 0
						and bulletDrop + (self.config.projectileDrop or 0.002)
					or 0

				RunService.Heartbeat:Wait()
			until not data.projectile.Parent
				or not projectile.Parent
				or os.clock() - start > (self.config.projectileLife or 8)

			-- An instance where this would be set could be where the projectile
			-- sticks to a part such as a sticky grenade sticking to a wall
			if not self.config.projectileKeepAlive then
				data.projectile:Destroy()
			end
		end)
	end
end
-- End projectile functions

function methods:handleTouched(fn)
	assert(fn, "Weapon:handleTouched - No callback function provided")

	if self.connections.handleListener then
		self.connection.handleListener:Disconnect()
	end

	self.connections.handleListener = self.handle.Touched:Connect(fn)
end

function methods:destroy()
	for _, connection in pairs(self.connections) do
		connection:Disconnect()
	end

	if self.handle and self.handle.Parent then
		self.handle:Destroy()
	end

	self.localPlayer = nil
	self.sfx = nil
	self.events = nil
	self.connections = nil
	self.lastActions = {}
end

function WeaponServer.new(config)
	assert(
		config.tool and typeof(config.tool) == "Instance" and config.tool:IsA("Tool"),
		"WeaponServer.new - Missing tool object from config"
	)

	local self = setmetatable({}, methods)

	self.config = Util.extend(
		Util.extend({}, config),
		Util.makeConfigFromValues(config.tool) -- Values inside the tool will override variables in the shared config
	)

	for k, v in pairs(DEFAULT_CONFIG) do
		if self.config[k] == nil then
			self.config[k] = v
		end
	end

	if self.config.projectileReference then
		self:setProjectileReference(self.config.projectileReference)
	end

	self.handle = config.tool:FindFirstChild("Handle")
	self.modelParts = WeaponClient.getModelParts(config.tool)

	if not self.handle then
		local toolModel = config.tool:FindFirstChildOfClass("Model")

		if toolModel then
			self.handle = toolModel:FindFirstChild("Handle")
			self.handle.Parent = config.tool

			assert(self.handle, "WeaponServer.new - Tool model must have a handle")

			self.modelParts = Util.map(toolModel:GetDescendants(), function(obj)
				if obj:IsA("BasePart") then
					Util.weld(obj, self.handle) -- Weld the part to the handle

					obj.Anchored = false
					obj.CanCollide = false

					return obj
				end

				return nil
			end)
		end
	end

	assert(self.handle, "WeaponServer.new - Missing tool handle")

	self.handle.Anchored = false
	self.handle.CanCollide = false

	self.sfx = {}
	self.events = {}
	self.connections = {}
	self.lastActions = {}

	self.remote = Instance.new("RemoteEvent")
	self.remote.Name = "Remote"
	self.remote.Parent = config.tool

	self.raycastFilter = RaycastParams.new()
	self.raycastFilter.FilterType = Enum.RaycastFilterType.Exclude

	-- Weld extra parts to the handle
	--[[for _, obj in config.tool:GetDescendants() do
		if obj:IsA("BasePart") and obj ~= self.handle then
			Util.weld(obj, self.handle)
			obj.Parent = self.handle
		end
	end]]

	-- Begin weapon configuration
	if self.config.grip then
		local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 =
			self.config.grip:GetComponents()

		self.config.tool.GripPos = Vector3.new(x, y, z)
		self.config.tool.GripRight = Vector3.new(R00, R10, R20)
		self.config.tool.GripUp = Vector3.new(R01, R11, R21)
		self.config.tool.GripForward = Vector3.new(R02, R12, R22)
	end
	-- End weapon configuration

	local animations = Instance.new("Folder")
	animations.Name = "Animations"

	Util.map(self.config.animations, function(idList, state)
		return state,
			Util.map(idList, function(id)
				Util.instance("Animation")({
					Name = id,
					AnimationId = Util.asset .. id,
					Parent = animations,
				})
			end)
	end)

	animations.Parent = self.config.tool

	-- Start listening for dispatched actions from the remote
	self.connections.remote = self.remote.OnServerEvent:Connect(function(player, action)
		assert(typeof(action) == "table", "Weapon action must be a table")

		if not self.localPlayer then
			self.localPlayer = player
			self.localHumanoid = Util.getHumanoid(player)
		end

		if self.localPlayer ~= player then
			-- A different player attempted to
			-- take control of the owner's weapon
			return player:Kick()
		elseif not Util.isAlive(self.localPlayer) then
			return
		end

		self:processAction(action)

		return nil
	end)

	task.spawn(function()
		repeat
			RunService.Heartbeat:Wait()
		until self.localPlayer and self.localHumanoid

		local function detectLocation()
			-- Mock action as if it came from the client
			-- This will prevent equip/unequip action spam
			self:processAction({
				type = config.tool:IsDescendantOf(self.localPlayer) and "WEAPON_UNEQUIP"
					or "WEAPON_EQUIP",
			})
		end

		detectLocation()
		self.connections.equipListener =
			config.tool:GetPropertyChangedSignal("Parent"):Connect(detectLocation)
	end)

	Util.set(config.tool, "Ready", true) -- TODO: Replace with config.tool:setAttribute("Ready", true)

	return self
end

return WeaponServer
