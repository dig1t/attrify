--!strict
--[[
	@class Types
	Shared type definitions for Attrify watchers.
]]

local CollectionWatcher = require(script.Parent.Modules.CollectionWatcher)

export type CollectionWatcher<T> = CollectionWatcher.CollectionWatcher<T>
export type CollectionObject<T> = CollectionWatcher.CollectionObject<T>

export type WatcherModule = {
	watcher: CollectionWatcher<any>,
	tag: string,
}

-- Checkpoint data for ProfileDB persistence
export type CheckpointData = {
	current: number,
	highest: number,
	firstJoinAt: number,
	lastCheckpointAt: number,
}

-- Checkpoint metadata
export type CheckpointInfo = {
	number: number,
	part: BasePart,
	spawnCFrame: CFrame?,
}

-- Player checkpoint state snapshot
export type PlayerCheckpointState = {
	currentCheckpoint: number,
	highestCheckpoint: number,
	totalCheckpoints: number,
}

return nil
