--[=[
	@interface Action
	@within Replica
	.type string -- The type of the action
	.payload any -- The data of the action
]=]
export type Action = {
	type: string,
	payload: any,
}

--[=[
	@interface ReplicaTypes
	@within Replica
	.replicaId string -- The unique identifier for the replica
	.class string -- The class of the replica
	.key string -- The key of the data that was changed
	.value any -- The new value of the data (Set to nil or leave empty to remove the key)
]=]
export type EventData = Action & {
	payload: {
		replicaId: string,
		class: string,
		key: string,
		value: any,
	},
}

export type ClientAction = Action & {
	payload: string,
}

export type InitialReplicaAction = Action & {
	payload: {
		replicaId: string,
		class: string,
		data: Data,
	},
}

export type ReplicaUpdateAction = Action & {
	payload: {
		replicaId: string,
		class: string,
		key: string,
		value: any,
	},
}

export type ReplicaFetchPayloadItem = {
	replicaId: string,
	class: string,
	data: Data,
}

export type ReplicaFetchAction = Action & {
	type: "FETCH_CLASS_REPLICAS",
	payload: { ReplicaFetchPayloadItem },
}

--[=[
	@type Data { [string]: any }
	@within Replica
]=]
export type Data = { [string]: any }

return nil
