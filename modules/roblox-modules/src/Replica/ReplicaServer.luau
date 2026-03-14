--[=[
	@class ReplicaServer
	@server
	@tag Replica

	A class for creating replicated objects.

	All state keys must be strings.
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Maid = require(script.Parent.Parent.Maid)
local ReplicaTypes = require(script.Parent.ReplicaTypes)
local Util = require(script.Parent.Parent.Util)
local t = require(script.Parent.Parent.t) :: any -- HACK: any to avoid type errors during linting

local remote: RemoteEvent = Instance.new("RemoteEvent")
remote.Name = "ReplicaEvents"
remote.Parent = script.Parent

local ReplicaServer = {}
ReplicaServer.__index = ReplicaServer

local replicas: { ReplicaServer } = {}

export type ReplicaServer = typeof(setmetatable(
	{} :: {
		replicaId: string,
		class: string,

		replicatedTo: { Player }?,
		data: ReplicaTypes.Data,

		maid: Maid.Maid,
	},
	ReplicaServer
))

--[=[
	@interface ReplicaServerConfig
	@within ReplicaServer
	.players { Player }? -- If defined, only these players will receive the replicated object
	.initialState { [string]: any }? -- The initial state of the replicated object. Keys must be strings.
]=]
export type ReplicaServerConfig = {
	players: { Player }?,
	initialData: { [string]: any }?,
	class: string,
}

-- Type checking for the constructor
local tNewReplica = t.strictInterface({
	players = t.optional(t.array(t.instanceIsA("Player"))),
	initialData = t.optional(t.table),
	class = t.string,
})

--[=[
	Get all ReplicaServer objects by their class

	@param class string -- The class of the ReplicaServer objects
	@return { ReplicaServer }
]=]
function ReplicaServer.getReplicasByClass(class: string): { ReplicaServer }
	local res: { ReplicaServer } = {}

	for _, replica: ReplicaServer in replicas do
		if replica.class == class then
			table.insert(res, replica)
		end
	end

	return res
end

--[=[
	Get a ReplicaServer object by its replicaId

	@param replicaId string -- The replicaId of the ReplicaServer object
	@return ReplicaServer?
]=]
function ReplicaServer.getReplicaById(replicaId: string): ReplicaServer?
	for _, replica: ReplicaServer in replicas do
		if replica.replicaId == replicaId then
			return replica
		end
	end

	return nil
end

--[=[
	Create a new ReplicaServer object

	@param config ReplicaServertedConfig -- Configuration for the replicated object
	@return ReplicaServer -- The new ReplicaServer object
]=]
function ReplicaServer.new(config: ReplicaServerConfig): ReplicaServer
	assert(RunService:IsServer(), "ReplicaServers can only be created on the server")
	tNewReplica(config)

	local replicaId: string = Util.randomString()

	local self = setmetatable({
		replicaId = replicaId,
		class = config.class,

		data = config.initialData or {},
		replicatedTo = config.players,

		maid = Maid.new(),
	}, ReplicaServer) :: ReplicaServer

	table.insert(replicas, self)

	self:Fire({
		type = "REPLICA_NEW",
		payload = {
			replicaId = replicaId,
			class = config.class,
			data = self.data,
		},
	} :: ReplicaTypes.InitialReplicaAction)

	self.maid:Add(function()
		self:Fire({
			type = "REPLICA_DESTROY",
			payload = {
				replicaId = replicaId,
			},
		} :: ReplicaTypes.EventData)

		for index, replica: ReplicaServer in replicas do
			if replica == self then
				table.remove(replicas, index)
				break
			end
		end
	end)

	return self
end

--[=[
	Fires an action to the appropriate clients

	@method Fire
	@within ReplicaServer
	@param action ReplicaTypes.Action -- The action to fire
]=]
function ReplicaServer.Fire(self: ReplicaServer, action: ReplicaTypes.Action)
	print("firing", action.type, action)

	if self.replicatedTo then
		for _, player in self.replicatedTo do
			remote:FireClient(player, action)
		end
	else
		remote:FireAllClients(action)
	end
end

--[=[
	Pushes the changed key to the clients

	@method Push
	@within ReplicaServer
	@param key string -- The key to push
]=]
function ReplicaServer.Push(self: ReplicaServer, key: string)
	self:Fire({
		type = "REPLICA_UPDATE",
		payload = {
			replicaId = self.replicaId,
			class = self.class,
			key = key,
			value = self.data[key],
		},
	} :: ReplicaTypes.ReplicaUpdateAction)
end

--[=[
	Sets the value of a key in the ReplicaServer object and pushes the change to the clients

	@method Set
	@within ReplicaServer
	@param key string -- The key to REPLICA_UPDATE
	@param value any -- The value to set
]=]
function ReplicaServer.Set(self: ReplicaServer, key: string, value: any)
	self.data[key] = value

	self:Push(key)
end

--[=[
	Destroys a replica object and replicates the event to clients

	@method Destroy
	@within ReplicaServer
	@tag Cleanup
]=]
function ReplicaServer.Destroy(self: ReplicaServer)
	self.maid:Clean()
end

if RunService:IsServer() then
	remote.OnServerEvent:Connect(function(player: Player, action: ReplicaTypes.Action)
		-- Detect exploiters who try to call ReplicaEvents
		if typeof(action) ~= "table" or action.type == nil then
			Players:BanAsync({
				UserIds = { player.UserId },
				PrivateReason = "Attempted to exploit the server by calling ReplicaEvents",
				PublicReason = "Attempted to exploit",
				Duration = 60 * 60 * 24 * 30,
			})
		end

		if action.type ~= "FETCH_CLASS_REPLICAS" then
			return
		end

		local res: { ReplicaTypes.ReplicaFetchPayloadItem } = {}

		for _, replica: ReplicaServer in replicas do
			if replica.class ~= action.payload then
				table.insert(
					res,
					{
						replicaId = replica.replicaId,
						class = replica.class,
						data = replica.data,
					} :: ReplicaTypes.ReplicaFetchPayloadItem
				)
			end
		end

		remote:FireClient(
			player,
			{
				type = "FETCH_CLASS_REPLICAS",
				payload = res,
			} :: ReplicaTypes.ReplicaFetchAction
		)
	end)
end

return ReplicaServer
