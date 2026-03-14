--[=[
	@class ReplicaClient
	@client
	@tag Replica

	A class for receiving replicated objects from the server.
]=]

local RunService = game:GetService("RunService")

local ReplicaTypes = require(script.Parent.ReplicaTypes)
local Signal = require(script.Parent.Parent.Signal)

local remote: RemoteEvent

local ReplicaClient = {}
ReplicaClient.__index = ReplicaClient

-- Replicated replcia objects
local replicas: { ReplicaClient } = {}
local signals = {} :: { [string]: Signal.Signal<ReplicaClient> }

export type ReplicaClient = typeof(setmetatable(
	{} :: {
		replicaId: string,
		class: string,

		data: ReplicaTypes.Data,

		keyChangedSignals: { [string]: { Signal.Signal<any> } },

		Changed: Signal.Signal<ReplicaTypes.Data>,
	},
	ReplicaClient
))

-- Used to create a new ReplicaClient object
local function newReplicaClient(
	existingReplica: ReplicaTypes.ReplicaFetchPayloadItem
): ReplicaClient
	assert(RunService:IsClient(), "ReplicaClient can only be used on the client")
	assert(existingReplica, "Expected existing replica")

	local self = setmetatable({
		replicaId = existingReplica.replicaId,
		class = existingReplica.class,
		data = existingReplica.data or {},

		keyChangedSignals = {},

		Changed = Signal.new(),
	}, ReplicaClient) :: ReplicaClient

	table.insert(replicas, self)

	if signals[self.class] then
		signals[self.class]:Fire(self)
	end

	return self
end

--[=[
	Returns a Signal that fires when a key in the replica is updated

	Usage:
	```lua
	local replica = ReplicaClient.getReplicaById("replicaId")

	replica:GetKeyChangedSignal("key"):Connect(function(value)
		print("Key changed:", value)
	end)
	```

	@method GetKeyChangedSignal
	@within ReplicaClient
	@param key string -- The key to get the value of
	@return Signal.Signal<ReplicaClient>
]=]
function ReplicaClient.GetKeyChangedSignal(
	self: ReplicaClient,
	key: string
): Signal.Signal<ReplicaClient>
	assert(RunService:IsClient(), "ReplicaClient can only be used on the client")
	assert(type(key) == "string", "Expected string for key")

	local signal = Signal.new()

	if not self.keyChangedSignals[key] then
		self.keyChangedSignals[key] = {}
	end

	table.insert(self.keyChangedSignals[key], signal)

	return signal
end

--[=[
	Gets an existing replica

	@param replicaId string -- The id of the replica to get
	@return ReplicaClient?
]=]
function ReplicaClient.getReplicaById(replicaId: string): ReplicaClient?
	for _, replica in replicas do
		if replica.replicaId == replicaId then
			return replica
		end
	end

	return nil
end

--[=[
	Starts listening for new replicated objects of the specified class

	Use `fireForExisting` to fire the signal for all existing replicas of the specified class.

	@param class string -- Configuration for the replicated object
	@param fireForExisting boolean? -- If true, fire the signal for all existing replicas
	@return Signal.Signal<ReplicaClient> -- The signal that is fired when a new replica is added
]=]
function ReplicaClient.getReplicaAddedSignal(
	class: string,
	fireForExisting: boolean? -- If true, fire the signal for all existing replicas
): Signal.Signal<ReplicaClient>
	assert(RunService:IsClient(), "ReplicaClient can only be used on the client")
	assert(type(class) == "string", "Expected string for class")
	assert(
		type(fireForExisting) == "boolean" or fireForExisting == nil,
		"Expected boolean or nil for fireForExisting"
	)

	-- Call the server to fetch all replicas of class
	remote:FireServer({ type = "FETCH_CLASS_REPLICAS", payload = class })

	-- Create a new listener signal if it doesn't exist
	if not signals[class] then
		signals[class] = Signal.new()
	end

	local newSignal: Signal.Signal<ReplicaClient> = Signal.new()

	signals[class].onDestroy = function()
		signals[class] = nil
	end

	signals[class]:Connect(function(replica: ReplicaClient)
		newSignal:Fire(replica)
	end)

	if fireForExisting then
		-- Fire the signal for any existing replicas
		for _, replica in replicas do
			if replica.class == class then
				newSignal:Fire(replica)
			end
		end
	end

	return newSignal
end

if RunService:IsClient() then
	remote = script.Parent:WaitForChild("ReplicaEvents", 8)

	remote.OnClientEvent:Connect(function(action: ReplicaTypes.Action)
		print("recevied from server", action.type)

		if action.type == "FETCH_CLASS_REPLICAS" then
			assert(not replicas[action.payload.replicaId], "Replica already exists")

			-- Create new replica instances for each existing replica
			for _, existingReplica: ReplicaTypes.ReplicaFetchPayloadItem in action.payload do
				newReplicaClient(existingReplica)
			end
		elseif action.type == "REPLICA_NEW" then
			-- Does the replica already exist?
			for _, replica: ReplicaClient in replicas do
				if replica.replicaId == action.payload.replicaId then
					return
				end
			end

			-- Create a new replica instance
			newReplicaClient(action.payload :: ReplicaTypes.ReplicaFetchPayloadItem)
		elseif action.type == "REPLICA_UPDATE" then
			local replica = ReplicaClient.getReplicaById(action.payload.replicaId)

			if not replica then
				return
			end

			replica.data[action.payload.key] = action.payload.value

			replica.Changed:Fire(replica.data)

			if replica.keyChangedSignals[action.payload.key] then
				for _, signal in replica.keyChangedSignals[action.payload.key] do
					signal:Fire(action.payload.value)
				end
			end

			-- FIRE ANY ATTACHED SIGNALS THAT LISTEN FOR THE REPLICA_UPDATE KEY
		elseif action.type == "REPLICA_DESTROY" then
			local replica = ReplicaClient.getReplicaById(action.payload.replicaId)

			if not replica then
				return
			end

			for index, child: ReplicaClient in replicas do
				if child == replica then
					-- if child.Destroying then
					-- 	child.Destroying:Fire()
					-- end

					table.remove(replicas, index)
					break
				end
			end
		end
	end)
end

return ReplicaClient
