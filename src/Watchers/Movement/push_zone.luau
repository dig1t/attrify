--!strict
--[[
	@class PushZone
	Pushes players in a specified direction while inside the zone.

	Attributes:
	- attr_force: number (default: 20) - Push force magnitude
	- attr_direction: Vector3 (default: 0, 0, 1) - Push direction relative to part's CFrame
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Util = require(Packages.Util)

local COLLECTION_TAG = "push_zone"
local IS_SERVER = RunService:IsServer()
local DEFAULT_FORCE = 20
local DEFAULT_DIRECTION = Vector3.new(0, 0, 1)

local PushZone: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

PushZone:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local force = object.context:GetAttribute("attr_force") :: number? or DEFAULT_FORCE
	local direction = object.context:GetAttribute("attr_direction") :: Vector3? or DEFAULT_DIRECTION

	local playersInZone: { [Player]: boolean } = {}
	local pushThread: thread?

	local function startPushLoop()
		if pushThread then
			return
		end

		pushThread = task.spawn(function()
			while true do
				local worldDirection = object.context.CFrame:VectorToWorldSpace(direction.Unit)

				for player in playersInZone do
					local character = player.Character
					if character then
						local rootPart = character:FindFirstChild("HumanoidRootPart")
						if rootPart and rootPart:IsA("BasePart") then
							rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + worldDirection * rootPart.AssemblyMass * force * 0.1
						end
					end
				end

				if next(playersInZone) == nil then
					pushThread = nil
					break
				end

				RunService.Heartbeat:Wait()
			end
		end)
	end

	local touchConnection = object.context.Touched:Connect(function(hit)
		local player = Util.getPlayerFromPart(hit)
		if player and not playersInZone[player] then
			playersInZone[player] = true
			startPushLoop()
		end
	end)

	local touchEndedConnection = object.context.TouchEnded:Connect(function(hit)
		local player = Util.getPlayerFromPart(hit)
		if player then
			playersInZone[player] = nil
		end
	end)

	object.Destroyed:Once(function()
		touchConnection:Disconnect()
		touchEndedConnection:Disconnect()
		if pushThread then
			task.cancel(pushThread)
		end
	end)
end)

return PushZone
