--[[
	@name Weapon System Client
	@description A weapon library for quickly building weapons.
	@author dig1t
	@version 1.0.0
]]

--!nocheck

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Animation = require(script.Parent.Parent.Animation)
local Util = require(script.Parent.Parent.Util)
-- local CollectionService = require(script.Parent.Parent.CollectionService)
local CollectionService = {
	watch = function(_) end,
	getAll = function()
		return {}
	end,
} -- TODO: replace when CollectionService util is fixed

local DEFAULT_CONFIG = {
	hitscan = true, -- No projectiles will be rendered
	tracerRound = false,

	damage = 30,
	maxRange = 2048,
	rangeModifier = 0.75,
}

local passthroughObjects = CollectionService.watch("BULLET_PASSTHROUGH")

local mouse

local WeaponClient, methods = {}, {}
methods.__index = methods

function methods:setCursor(id)
	if not mouse then
		return
	end

	self.currentCursor = id and self.equipped and Util.asset .. id or ""
	mouse.Icon = self.currentCursor
end

--[[
Variable Names

string inputName (primary, secondary, fire, reload)
string eventName (InputBegan, InputEnded, TouchTap)
]]

--[[
weapon:unsetInput("primary") -- get rid of this input
weapon:unsetInputCondition("canUse") -- get rid of this condition check
]]

function methods:inCooldown(inputName): boolean
	if
		self._inputData[inputName].cooldownTime
		and self._inputData[inputName].lastEventTime
	then
		return os.clock() - self._inputData[inputName].lastEventTime
			<= self._inputData[inputName].cooldownTime
	end

	return false
end

function methods:_onInputEvent(eventName, ...)
	local inputNameChecksPassed = {}

	for inputName, callback in pairs(self._eventHooks[eventName] or {}) do
		local inCooldown = self:inCooldown(inputName)
		local conditionCheck = not inCooldown and callback(...)

		if conditionCheck then -- Condition check passed (controller buttons pressed, keyboard button pressed, etc.)
			conditionCheck = not self._inputData[inputName].condition and true
				or self._inputData[inputName].condition(...)

			if conditionCheck then
				inputNameChecksPassed[#inputNameChecksPassed + 1] = inputName
			end
		end

		if not conditionCheck and self._inputData[inputName].onError then
			self._inputData[inputName].onError()
		end
	end

	for _, inputName in pairs(inputNameChecksPassed) do
		if self._inputData[inputName] then
			self._inputData[inputName].lastEventTime = os.clock()

			if self._inputData[inputName].callback then
				self._inputData[inputName].callback(...) -- Call the callback for the input, if any are listening
			end
		end
	end
end

function methods:setInput(inputName, data)
	assert(inputName, "Missing input name")
	assert(typeof(data) == "table", "Missing data table")
	assert(Util.tableLength(data) > 0, "No events to watch")
	assert(
		not self._inputData[inputName],
		string.format("Input %s already exists", inputName)
	)

	for eventName, condition in pairs(data) do
		assert(
			UserInputService[eventName],
			string.format("%s is not a valid UserInputType", eventName)
		)

		-- Start listing to eventName (InputBegan, InputEnded, etc.)
		if self.equipped and not self._connections[eventName] then
			self._connections[eventName] = UserInputService[eventName]:Connect(
				function(...)
					self:_onInputEvent(eventName, ...)
				end
			)
		end

		if not self._eventHooks[eventName] then
			self._eventHooks[eventName] = {}
		end

		self._eventHooks[eventName][inputName] = condition
	end

	self._inputData[inputName] = {
		listeners = data,
	}
end

function methods:setInputCondition(inputName, condition)
	assert(self._inputData[inputName], "Not a valid input type")

	self._inputData[inputName].condition = condition
end

function methods:onInputAttempt(inputName, callback)
	assert(self._inputData[inputName], "Not a valid input type")
	assert(typeof(callback) == "function", "Not a valid callback type")

	self._inputData[inputName].onError = callback
end

function methods:unsetInputCondition(inputName)
	assert(self._inputData[inputName], "Not a valid input type")

	self._inputData[inputName].condition = nil
end

function methods:onInput(inputName, callback)
	assert(self._inputData[inputName], "Not a valid input type")
	assert(typeof(callback) == "function", "Not a valid callback type")

	self._inputData[inputName].callback = callback
end

function methods:unwatchInput(inputName)
	assert(self._inputData[inputName], "Not a valid input type")

	self._inputData[inputName].callback = nil
end

function methods:setInputCooldown(inputName, cooldownTime)
	assert(
		self._inputData[inputName],
		string.format("Input %s does not exist", inputName)
	)

	self._inputData[inputName].cooldownTime = cooldownTime
end

function methods:getInputCooldownTime(inputName)
	return self._inputData[inputName] and self._inputData[inputName].cooldownTime or 0
end

function methods:bindActionToInput(actionType, inputName)
	assert(actionType, "Missing action type")
	assert(self._inputData[inputName], "Not a valid input type")

	if not self._inputData[inputName].actionBindings then
		self._inputData[inputName].actionBindings = {}
	end

	self._inputData[inputName].actionBindings[actionType] = true
end

-- Plays a random animation of the given state
-- Unless its a looped animation, it will yield until the animation finishes
function methods:playAnimation(state, loop)
	self:stopAnimation()

	if not self.animations or not self.animations[state] then
		return
	end

	self.currentTrack = Util.tableRandom(self.animations[state])

	if self.currentTrack then
		local equipTime = self.equipped

		self.currentTrackLooper = loop
				and self.currentTrack.Stopped:Connect(function()
					if self.currentTrack and self.equipped == equipTime then -- Make sure the weapon wasn't re-equipped
						self.currentTrack:Play()
					end
				end)
			or nil

		self.currentTrack:Play()

		if not loop then
			self.currentTrack.Stopped:Wait()
		end
	end
end

function methods:stopAnimation()
	if self.currentTrackLooper and self.currentTrackLooper.Connected then
		self.currentTrackLooper:Disconnect()
		self.currentTrackLooper = nil
	end

	if self.currentTrack and self.currentTrack.IsPlaying then
		self.currentTrack:Stop()
		self.currentTrack = nil
	end
end

function methods:getTargetPosition()
	return (mouse and mouse.Hit.Position)
		or (
			self.localHumanoid
			and self.localHumanoid.Parent
			and self.localHumanoid.TargetPoint
		)
end

function methods:shoot()
	local origin = self.localPlayer.Character and self.localPlayer.Character.PrimaryPart

	if not origin then
		return
	end

	local target = self:getTargetPosition()
	local direction = (target - origin.Position).Unit

	origin = origin.CFrame * CFrame.new(0, 1.5, 0)

	self.remote:FireServer({
		type = "WEAPON_SHOOT",
		payload = {
			target = target,
			origin = origin,
		},
	})

	-- Fire local tracer
	if not self.config.projectileReference and not self.config.useModelAsProjectile then
		return
	end

	if self.config.hitscan then
		local hit = self:raycast(origin, direction)

		self:fireTracer({
			origin = origin,
			direction = direction,
			projectile = WeaponClient.getProjectile({
				handle = self.handle,
				projectileReference = self.config.projectileReference,
				useModelAsProjectile = self.config.useModelAsProjectile,
				modelParts = self.modelParts,
			}),
			projectileWeldToHit = self.config.projectileWeldToHit,
			projectileRotation = self.config.projectileRotation,
			distance = (hit.Position and (origin.Position - hit.Position).Magnitude)
				or self.config.maxRange
				or 2048,
			velocity = self.config.projectileVelocity or 16,
			localTracer = true,
		})
	else
		print("render projectile locally")
		-- render local projectile
	end
end

function methods:raycast(origin, direction, maxRange)
	return Workspace:Raycast(
		origin.Position,
		(direction and direction or origin.LookVector) * (maxRange or 2048),
		self.raycastFilter
	) or {}
end

function WeaponClient.getModelParts(tool)
	return Util.map(tool:GetDescendants(), function(obj)
		return obj:IsA("BasePart") and obj.Name ~= "Handle" and obj or nil
	end)
end

function WeaponClient.getProjectile(data)
	assert(
		data and typeof(data) == "table",
		"WeaponClient.getProjectile - Missing data table"
	)
	assert(data.handle, "WeaponClient.getProjectile - Missing weapon handle")

	local modelParts = data.modelParts
		or (data.tool and WeaponClient.getModelParts(data.tool))
		or {}
	local projectile

	if not data.useModelAsProjectile then
		assert(
			data.projectileReference,
			"WeaponClient.fireTracer - Missing projectile reference"
		)

		projectile = data.projectileReference:Clone()
	elseif #modelParts == 0 then
		projectile = data.handle:Clone()
	else -- Model extras exist
		local handleClone = data.handle:Clone()
		projectile = Instance.new("Model")
		handleClone.Parent = projectile
		projectile.PrimaryPart = handleClone
		projectile.Name = "Projectile"

		for _, part in pairs(modelParts) do
			if part.Parent then
				part:Clone().Parent = projectile
			end
		end

		Util.clearWelds(projectile)
	end

	return projectile
end

function methods:fireTracer(data)
	assert(data and typeof(data) == "table", "WeaponClient.fireTracer - Missing data")

	if not self.localPlayer.Character and data.localTracer then
		return
	end

	data.velocity = data.velocity or 16

	if not data.origin then
		warn("WeaponClient:fireTracer - Missing origin")
		return
	end

	local newTracer = data.localTracer and data.projectile
		or WeaponClient.getProjectile({
			handle = data.handle,
			projectileReference = data.projectileReference,
			useModelAsProjectile = data.useModelAsProjectile,
			-- Avoid unnecessary processing by passing self.modelParts
			modelParts = data.localTracer and self.modelParts or data.modelParts,
		})

	local tracer = newTracer

	if newTracer:IsA("Model") then
		if not newTracer.PrimaryPart then
			warn(
				"WeaponClient.fireTracer - Projectile model must have a PrimaryPart defined"
			)
			return
		end

		tracer = newTracer.PrimaryPart

		Animation.prepareAnimatedModel(newTracer)
	end

	newTracer.Parent = Workspace.CurrentCamera

	self.raycastFilter.FilterDescendantsInstances = Util.extend(
		data.localTracer and { self.localPlayer.Character, newTracer } or { newTracer },
		passthroughObjects:getAll()
	)

	local originPosition = CFrame.lookAt(
		data.origin.Position,
		data.origin.Position + data.direction
	) * CFrame.new(0, 0, -tracer.Size.Z)
	local rotation = data.projectileRotation or CFrame.new()
	local start = os.clock()

	task.spawn(function()
		local prevCFrame = originPosition
		local hit

		repeat
			RunService.Heartbeat:Wait()

			prevCFrame = prevCFrame * CFrame.new(0, 0, -data.velocity)
			tracer.CFrame = prevCFrame * rotation

			local raycastTest = self:raycast(prevCFrame, data.direction, data.velocity)

			if raycastTest.Instance then
				hit = raycastTest
			end
		until hit
			or not tracer.Parent
			or not newTracer.Parent
			or (data.origin.Position - prevCFrame.Position - Vector3.new(
					0,
					0,
					-data.velocity
				)).Magnitude
				> data.distance

		if tracer.Parent and newTracer.Parent then
			if data.projectileWeldToHit and hit then
				tracer.CFrame = CFrame.lookAt(hit.Position, hit.Position + data.direction)
					* rotation -- Place tracer at intersection

				Util.weld(tracer, hit.Instance)

				for _, part in
					pairs(
						newTracer:IsA("Model") and newTracer:GetChildren()
							or { newTracer }
					)
				do
					part.Anchored = false
				end

				Debris:AddItem(
					newTracer,
					(data.projectileLife or 10) - (os.clock() - start) + 0.001
				) -- TODO: Replace with a better debris collector
			else
				newTracer:Destroy()
			end
		end
	end)
end

function WeaponClient.watch()
	local self = setmetatable({}, methods)

	while not Players.LocalPlayer.Character or not Players.LocalPlayer.Character.Parent do
		RunService.RenderStepped:Wait()
	end

	self.watching = true

	self.localPlayer = Players.LocalPlayer

	self.raycastFilter = RaycastParams.new()
	self.raycastFilter.FilterType = Enum.RaycastFilterType.Exclude

	self.remote = Util.waitForChild(ReplicatedStorage, "WeaponRemote")

	self.remote.OnClientEvent:Connect(function(action)
		assert(
			action and typeof(action) == "table",
			"WeaponClient.watch - Missing action"
		)
		assert(action.type, "WeaponClient.watch - Missing action type")
		assert(action.payload, "WeaponClient.watch - Missing action payload")

		if action.type == "WEAPON_TRACER" then
			self:fireTracer(action.payload)
		end
	end)
end

function WeaponClient.new(config)
	assert(config.tool, "Missing tool object from config")
	assert(config.tool:WaitForChild("Handle"), "Missing tool handle")

	local self = setmetatable({}, methods)

	self._connections = {}
	self._inputData = {}
	self._eventHooks = {}
	self._actionBindings = {}

	self.config =
		Util.extend(Util.extend({}, config), Util.makeConfigFromValues(config.tool))

	for k, v in pairs(DEFAULT_CONFIG) do
		if self.config[k] == nil then
			self.config[k] = v
		end
	end

	while
		not Players.LocalPlayer.Character
		or not Players.LocalPlayer.Character.Parent
		or not config.tool:FindFirstChild("Ready")
	do
		RunService.RenderStepped:Wait()
	end

	self.localPlayer = Players.LocalPlayer
	self.localCharacter = self.localPlayer.Character
		or self.localPlayer.CharacterAdded:Wait()
	self.localHumanoid = self.localCharacter:WaitForChild("Humanoid")
	self.remote = config.tool:WaitForChild("Remote")
	self.handle = config.tool.Handle
	self.modelParts = WeaponClient.getModelParts(config.tool)

	self.raycastFilter = RaycastParams.new()
	self.raycastFilter.FilterType = Enum.RaycastFilterType.Exclude

	config.tool.Equipped:Connect(function()
		if not Util.isAlive(self.localHumanoid) then
			return
		end

		mouse = Players.LocalPlayer:GetMouse()

		--[[if mouse then
			self._connections[#self._connections + 1] = mouse.Move:Connect(function()
				if not self.equipped then
					return
				end

				if mouse.Target and mouse.Target.Parent and (
					mouse.Target.Parent:FindFirstChild("Humanoid") or mouse.Target.Parent.Parent:FindFirstChild("Humanoid")
				) then
					self:setCursor(config.cursor.target)
					return
				end

				self:setCursor(config.cursor.normal)
			end)
		end]]

		for _inputName, data in pairs(self._inputData) do
			for eventName, _condition in pairs(data.listeners) do
				-- Start listing to eventName (InputBegan, InputEnded, etc.)
				if not self._connections[eventName] then
					self._connections[eventName] = UserInputService[eventName]:Connect(
						function(...)
							self:_onInputEvent(eventName, ...)
						end
					)
				end
			end
		end

		local actionId = Util.randomString(4)

		self.currentActionId = actionId
		self.equipped = os.clock()

		self:setCursor(config.cursor.normal)

		if Util.isAlive(self.localHumanoid) then
			self:playAnimation(config.state.equip)

			if self.currentActionId == actionId and self.equipped then
				self:playAnimation(config.state.hold, true) -- If there is a hold animation, play and loop it
			end
		end
	end)

	config.tool.Unequipped:Connect(function()
		-- Unhook all connections
		for eventName, connection in pairs(self._connections) do
			if connection.Connected then
				connection:Disconnect()
			end

			self._connections[eventName] = nil
		end

		self.equipped = false

		self:stopAnimation()
		-- maid:clean()

		self:setCursor()
	end)

	config.tool:WaitForChild("Animations")

	-- Load animations
	self.animations = Util.map(config.animations, function(idList, state)
		return state,
			Util.map(idList, function(id)
				return self.localHumanoid:LoadAnimation(
					config.tool.Animations:WaitForChild(id)
				)
			end)
	end)

	self.remote:FireServer({
		type = "WEAPON_INIT",
	})

	self.remote.OnClientEvent:Connect(function(action)
		if typeof(action) ~= "table" or not action.type then
			return
		end

		-- An action was dispatched to the weapon server
		-- remotely,
		if action.type == "WEAPON_REMOTE_ACTION" then
			local actionType = action.payload and action.payload.actionType

			if not actionType then
				return
			end

			local actionId = Util.randomString(4)
			self.currentActionId = actionId

			self:playAnimation(action.payload.actionType)

			if self.currentActionId == actionId and self.equipped then
				self:playAnimation("WEAPON_HOLD", true)
			end
		end
	end)

	return self
end

return WeaponClient
