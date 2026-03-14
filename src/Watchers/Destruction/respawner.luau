--!strict
--[[
	@class Respawner
	Automatically respawns a part after it's destroyed.

	Attributes:
	- attr_respawn_time: number (default: 5) - Time before respawning
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)

local COLLECTION_TAG = "respawner"
local IS_SERVER = RunService:IsServer()
local DEFAULT_RESPAWN_TIME = 5

local Respawner: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

Respawner:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local respawnTime = object.context:GetAttribute("attr_respawn_time") :: number? or DEFAULT_RESPAWN_TIME
	local clone = object.context:Clone()

	object.context.Destroying:Connect(function()
		local parent = object.context.Parent
		task.delay(respawnTime, function()
			if object.context and object.context.Parent then
				object.context:Destroy()
			end

			clone.Parent = parent
		end)
	end)
end)

return Respawner
