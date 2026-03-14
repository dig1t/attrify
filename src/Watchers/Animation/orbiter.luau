--!strict
--[[
	@class Orbiter
	Orbits an object around a center point.

	Attributes:
	- attr_orbit_radius: number (default: 5) - Radius of the orbit in studs
	- attr_orbit_speed: number (default: 1) - Rotations per second
	- attr_center_name: string (optional) - Name of part to orbit around (defaults to original position)
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "orbiter"
local IS_CLIENT = RunService:IsClient()
local DEFAULT_ORBIT_RADIUS = 5
local DEFAULT_ORBIT_SPEED = 1

local Orbiter: CollectionWatcher.CollectionWatcher<Model | BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Orbiter:RegisterHandler(function(object: CollectionWatcher.CollectionObject<Model | BasePart>)
	if not IS_CLIENT then
		return
	end

	local orbitRadius = object.context:GetAttribute("attr_orbit_radius") :: number? or DEFAULT_ORBIT_RADIUS
	local orbitSpeed = object.context:GetAttribute("attr_orbit_speed") :: number? or DEFAULT_ORBIT_SPEED
	local centerName = object.context:GetAttribute("attr_center_name") :: string?

	local originalPivot = object.context:GetPivot()
	local centerPosition = originalPivot.Position

	if centerName then
		local centerPart = workspace:FindFirstChild(centerName, true)
		if centerPart and centerPart:IsA("BasePart") then
			centerPosition = centerPart.Position
		end
	end

	local elapsedTime = 0

	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not object.context or not object.context.Parent then
			return
		end

		elapsedTime += deltaTime

		local angle = elapsedTime * orbitSpeed * math.pi * 2
		local offsetX = math.cos(angle) * orbitRadius
		local offsetZ = math.sin(angle) * orbitRadius

		local newPosition = centerPosition + Vector3.new(offsetX, 0, offsetZ)
		object.context:PivotTo(CFrame.new(newPosition) * originalPivot.Rotation)
	end)

	object.Destroyed:Once(function()
		if connection.Connected then
			connection:Disconnect()
		end
	end)
end)

return Orbiter
