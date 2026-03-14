--[=[
	@class ProfileDB

	A class for managing player profiles.
	This class is used to store and retrieve player data.
	It can be used to store player data such as currency, inventory, and other player-specific data.

	Key Features:
	- Automatically loads and saves player data to the data store
	- Automatically reconciles player data with a template
	- Supports saving player data to a web API if provided
	- Session locking to prevent multiple servers from saving the same player data at the same time
	- Supports saving player data in Studio

	```lua
	local Players = game:GetService("Players")
	local ServerScriptService = game:GetService("ServerScriptService")

	local ProfileDB = require(ServerScriptService.ProfileDB)

	local ProfileDataTemplate = {
		coins = 100,
		inventory = {},
	}

	local profileDBSettings: ProfileDB.Settings = {
		mockDataStore = false,
		dataStoreName = "Profile",
		dataStoreVersion = 1,
		template = ProfileDataTemplate,
	}

	Players.PlayerAdded:Connect(function(player)
		local profile = ProfileDB.new(player.UserId, profileDBSettings)

		profile:Reconcile() -- Add any missing tables to the player's profile

		local profileData = profile:GetData()
		profileData.coins += 100 -- Add 100 coins to the player's profile

		profile:Save() -- Save the player's profile data
	end)
	```

	Need to track updates to the player's profile data?
	```lua
	profile.Changed:Connect(function(profileData)
		print("Player data was updated", profileData.data.coins)
	end)
	```

	Install with wally by adding the following to your `wally.toml`:
	```toml
	ProfileDB = "dig1t/profiledb@1.0.3"
	```
]=]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Maid = require(script.Parent.Maid)
local Signal = require(script.Parent.Signal)
local Util = require(script.Parent.Util)

local MAX_CONNECTION_ATTEMPTS: number = 3
local MAX_CONNECTION_ATTEMPT_DELAY: number = 2
local KEYS_TO_IGNORE: { string } = { -- These keys will not be saved to the data store
	"sessionStart",
}

-- The maximum time in seconds to wait for a session lock to be released before timing out
-- This is used to prevent multiple servers from saving the same player data at the same time
local SESSION_LOCK_TIMEOUT: number = 60
local SESSION_CHECK_INTERVAL: number = 8

--[=[
	ProfileData contains the player's data

	@type ProfileData { [string]: any }
	@within ProfileDB
]=]
export type ProfileData = { [string]: any }

--[=[
	ProfileMetadata contains everything that's saved to Roblox.

	The `data` table will contain the player's data.

	@interface ProfileMetadata
	@within ProfileDB

	.data ProfileData -- The player's data.
	.created number -- The time the profile was created.
	.last_seen number -- The time the player was last seen.
	.sessions number -- The number of times the player has joined the game.
	.sessionData { lastUpdate: number, jobId: string }? -- Session data for the player.
]=]
export type ProfileMetadata = {
	data: ProfileData,

	created: number,
	last_seen: number,
	sessions: number,

	sessionData: {
		lastUpdate: number,
		jobId: string,
	}?,
}

--[=[
	Template is the template for the profile data.
	It can be a table of default values or a function that returns a table of default values.

	@type Template ProfileData | (Player) -> ProfileData
	@within ProfileDB
]=]
export type Template = ProfileData | (Player) -> ProfileData

--[=[
	@interface Settings
	@within ProfileDB

	.saveToDataStore boolean -- If the mock data store should be used.
	.dataStoreName string -- The name of the data store.
	.dataStoreVersion number? -- The version of the data store.
	.apiURL string? -- If provided, this URL will be used to send saved player data to an API.
	.saveInStudio boolean? -- If the data store should be used in Studio.
	.saveInterval number -- The interval in seconds to save the player's data.
	.keysToIgnore { string }? -- The keys to ignore when saving the player's data.

	.template ProfileData | (Player?) -> ProfileData -- The template for profile data.
]=]
export type Settings = {
	saveToDataStore: boolean?,
	dataStoreName: string?,
	dataStoreVersion: number?,
	apiURL: string?,
	saveInStudio: boolean?,
	saveInterval: number?,
	keysToIgnore: { string }?,

	template: Template?,
}

local defaultSettings: Settings = {
	saveToDataStore = true,
	dataStoreName = "profiles",
	dataStoreVersion = 1,
	template = {},
	saveInterval = 60 * 4, -- Profiles save every 4 minutes by default
	keysToIgnore = {},
}

local ProfileDB = {}
ProfileDB.__index = ProfileDB

-- Check if the game is connected to the Roblox API
local connectedToRobloxAPI = game.PlaceId > 0
	and Util.attempt(function()
		local dataStore: GlobalDataStore = DataStoreService:GetDataStore("ProfileDB")

		dataStore:SetAsync("last_run", Workspace:GetServerTimeNow())
	end, MAX_CONNECTION_ATTEMPTS, MAX_CONNECTION_ATTEMPT_DELAY)

--[=[
	@prop canSaveToDataStore boolean
	@within ProfileDB

	Whether or not the game can save to the data store.
]=]
ProfileDB.canSaveToDataStore = connectedToRobloxAPI :: boolean

export type Profile = typeof(setmetatable(
	{} :: {
		_template: Template,

		dataStoreName: string,
		dataStoreVersion: number,
		-- The saveToDataStore property should determine whether the game
		-- should process business logic that requires saving to the data store
		saveToDataStore: boolean,
		saveInStudio: boolean?,
		apiURL: string?,
		saveInterval: number,
		keysToIgnore: { string },
		destroyed: boolean,
		dataFetched: boolean,

		connectedToDataStore: boolean,
		saveIntervalRunning: boolean,

		newPlayer: boolean,
		userId: number,
		sessionStart: number,

		lastSave: number,

		dataStore: GlobalDataStore,
		versionDataStore: OrderedDataStore,

		-- Signals
		Changed: Signal.Signal<ProfileData>,
		Saved: Signal.Signal<ProfileData>,

		maid: Maid.Maid,

		metadata: ProfileMetadata,

		[any]: any,
	},
	ProfileDB
))

--[=[
	Creates a new ProfileDB instance

	A settings table can be provided to configure the ProfileDB instance.

	@function new
	@within ProfileDB
	@param userId number -- The user ID of the player
	@param settings Settings? -- The settings for the profile
	@return Profile -- The new ProfileDB instance
]=]
function ProfileDB.new(userId: number, settings: Settings?): Profile
	assert(type(userId) == "number", "UserId must be a number")
	assert(settings == nil or type(settings) == "table", "Settings must be a table")

	local _settings: Settings = Util.extend({}, defaultSettings, settings)
	local player: Player? = Players:GetPlayerByUserId(userId)

	assert(
		typeof(_settings.saveToDataStore) == "boolean",
		"Settings.saveToDataStore must be a boolean"
	)
	assert(
		typeof(_settings.dataStoreName) == "string",
		"Settings.dataStoreName must be a string"
	)
	assert(
		typeof(_settings.dataStoreVersion) == "number",
		"Settings.dataStoreVersion must be a number"
	)
	assert(
		typeof(_settings.template) == "table" or typeof(_settings.template) == "function",
		"Settings.template must be a table or function"
	)
	assert(
		typeof(_settings.apiURL) == "string" or _settings.apiURL == nil,
		"Settings.apiURL must be a string or nil"
	)
	assert(
		typeof(_settings.saveInStudio) == "boolean" or _settings.saveInStudio == nil,
		"Settings.saveInStudio must be a boolean"
	)
	assert(
		typeof(_settings.saveInterval) == "number",
		"Settings.saveInterval must be a number"
	)
	assert(
		typeof(_settings.keysToIgnore) == "table" or _settings.keysToIgnore == nil,
		"Settings.keysToIgnore must be a table or nil"
	)
	assert(player, "Player must exist in the game")

	if not ProfileDB.canSaveToDataStore or userId < 0 then
		-- Using DataStores will fail in Studio,
		-- so we should disable access to data stores
		_settings.saveToDataStore = false
	end

	local self: Profile = setmetatable({}, ProfileDB) :: Profile

	self._template = if typeof(_settings.template) == "function"
		then _settings.template(player)
		else table.clone(_settings.template)

	self.connectedToDataStore = false

	self.dataStoreName = `{_settings.dataStoreName}_{userId}` :: string
	self.dataStoreVersion = _settings.dataStoreVersion :: number
	self.saveToDataStore = _settings.saveToDataStore :: boolean
	self.saveInStudio = _settings.saveInStudio :: boolean
	self.apiURL = _settings.apiURL :: string
	self.saveInterval = _settings.saveInterval :: number
	self.keysToIgnore = _settings.keysToIgnore or {} :: { string }
	self.destroyed = false
	self.dataFetched = false

	self.newPlayer = true
	self.userId = userId
	self.sessionStart = Workspace:GetServerTimeNow()

	self.lastSave = Workspace:GetServerTimeNow()

	self.Changed = Signal.new()
	self.Saved = Signal.new()

	self.maid = Maid.new()

	self.maid:Add(function()
		self.destroyed = true
	end)

	self:ConnectToDataStore()

	self.metadata = self:LoadData()

	self:StartSaveInterval()

	self.maid:Add(function()
		-- Clear session data so that the data can be loaded elsewhere
		self.metadata.sessionData = nil

		self:Save()
	end)

	return self
end

function ProfileDB.StartSaveInterval(self: Profile)
	if self.saveIntervalRunning or not self.saveToDataStore then
		return
	end

	self.saveIntervalRunning = true

	-- self.maid:Task(function()
	-- 	repeat
	-- 		local start = os.clock()

	-- 		while os.clock() - start < ServerConfig.database.saveInterval and player and player.Parent do
	-- 			task.wait(60)
	-- 		end

	-- 		if player and player.Parent then
	-- 			server:localCall("PROFILE_SAVE", player)
	-- 		end
	-- 	until not player or not player.Parent
	-- end)

	self.maid:Task(RunService.Stepped:Connect(function()
		local now = Workspace:GetServerTimeNow()

		if now - self.lastSave >= self.saveInterval then
			self:Save()
		end
	end))
end

--[=[
	Returns the template given in the constructor

	@method GetTemplate
	@within ProfileDB
	@return ProfileData -- The template provided in the constructor or the result of the template function if the template is a function
]=]
function ProfileDB.GetTemplate(self: Profile): ProfileData
	return if typeof(self._template) == "function"
		then self._template(Players:GetUserByUserId(self.userId))
		else table.clone(self._template) :: ProfileData
end

function ProfileDB.ConnectToDataStore(self: Profile): boolean
	if self.connectedToDataStore then
		return true
	elseif not self.saveToDataStore then
		return false
	end

	if RunService:IsStudio() and not self.saveInStudio then
		self.saveToDataStore = false
		return false
	end

	-- Load the profile data store
	local dbSuccess, dataStore: GlobalDataStore = Util.attempt(function()
		return DataStoreService:GetDataStore(self.dataStoreName, self.dataStoreVersion)
	end, MAX_CONNECTION_ATTEMPTS, MAX_CONNECTION_ATTEMPT_DELAY)

	-- Load the version data store
	local versionDBSuccess, versionDataStore: OrderedDataStore = Util.attempt(function()
		return DataStoreService:GetOrderedDataStore(
			self.dataStoreName,
			self.dataStoreVersion
		)
	end, MAX_CONNECTION_ATTEMPTS, MAX_CONNECTION_ATTEMPT_DELAY)

	if dbSuccess and versionDBSuccess then
		self.dataStore = dataStore
		self.versionDataStore = versionDataStore
		self.connectedToDataStore = true

		return true
	end

	self.saveToDataStore = false

	return false
end

--[=[
	Fetches the last version from the version history data store

	@method GetLastVersion
	@within ProfileDB
	@return (boolean, string?) -- Whether or not the fetch was successful and the last version if successful
]=]
function ProfileDB.GetLastVersion(self: Profile): (boolean, string?)
	-- Fetch the last version from the version data store
	-- This should fail if the fetch failed or is empty
	local success: boolean, profileVersion: string? = Util.attempt(function()
		local fetch: { any } =
			self.versionDataStore:GetSortedAsync(false, 1):GetCurrentPage()

		return if fetch[1] and fetch[1].value then tostring(fetch[1].value) else nil
	end, MAX_CONNECTION_ATTEMPTS, MAX_CONNECTION_ATTEMPT_DELAY)

	return success, profileVersion
end

--[=[
	Creates a new profile data object

	@method GetNewData
	@within ProfileDB
	@return ProfileMetadata -- A new profile data object
]=]
function ProfileDB.GetNewData(self: Profile): ProfileMetadata
	local now: number = Workspace:GetServerTimeNow()

	return {
		data = self:GetTemplate(),
		created = now,
		last_seen = now,
		sessions = 1,
	}
end

--[=[
	Fetches the latest player metadata from the data store

	@private
	@method LoadData
	@within ProfileDB
	@return ProfileMetadata -- The player's metadata or a new profile data object if the player is new
]=]
function ProfileDB.LoadData(self: Profile): ProfileMetadata
	if self.dataFetched then
		return self.metadata
	end

	local newData: ProfileMetadata = self:GetNewData()

	if not self.saveToDataStore then
		return newData
	end

	local startedLoadingAt: number = Workspace:GetServerTimeNow()

	local function inSessionLockCooldown(): boolean
		return Workspace:GetServerTimeNow() - startedLoadingAt < SESSION_LOCK_TIMEOUT
	end

	while not self.destroyed do
		-- Fetch the last saved version from the version data store
		local profileVersionSuccess: boolean, profileVersion: string? =
			self:GetLastVersion()

		-- Could not fetch the last version from the version data store
		-- Fall back to the template data with disabled saving
		if not profileVersionSuccess or not profileVersion or self.destroyed then
			-- Only enable saving if the version fetch was successful
			-- This would mean the player is new.
			-- Dont save if the ProfileDB instance was destroyed (player left)
			if self.destroyed or (self.saveToDataStore and not profileVersionSuccess) then
				self.saveToDataStore = false
			end

			self.dataFetched = true

			return newData
		end

		-- Fetch the player's profile data from the data store
		local success, profileData: ProfileMetadata? = Util.attempt(function()
			-- Never use cache when fetching player data
			local getOptions: DataStoreGetOptions = Instance.new("DataStoreGetOptions")
			getOptions.UseCache = false

			return self.dataStore:GetAsync(profileVersion, getOptions)
		end, MAX_CONNECTION_ATTEMPTS, MAX_CONNECTION_ATTEMPT_DELAY)

		local decodedData: ProfileMetadata? = profileData
			and HttpService:JSONDecode(profileData)

		if
			self.destroyed
			or not success
			or not decodedData
			or typeof(decodedData) ~= "table"
		then
			-- Could not fetch the player's data
			-- Fall back to the template data with disabled saving
			self.saveToDataStore = false
			self.dataFetched = true

			return newData
		end

		-- Unlock session if:
		-- - The last update time is greater than the time the player started loading (the player has been away from the game for some time)
		-- - The session lock cooldown has expired (force session unlock)

		if
			decodedData.sessionData
			and decodedData.sessionData.lastUpdate < SESSION_LOCK_TIMEOUT
			and inSessionLockCooldown()
		then
			-- Session is still locked, delay and repeat the loop
			task.wait(SESSION_CHECK_INTERVAL)
			continue
		end

		-- Set new session data and save it
		-- to prevent other servers from saving the player's data
		-- preventing data loss, exploits, and overwrites
		decodedData.sessionData = {
			lastUpdate = Workspace:GetServerTimeNow(),
			jobId = game.JobId,
		}

		self.metadata = decodedData
		self.metadata.sessions += 1 -- Increment the session count

		self.newPlayer = false -- Mark the profile as not new
		self.dataFetched = true

		self:Save()

		return decodedData
	end

	-- Disable saving to the data store if the profile failed to load so that
	-- we don't lose the player's data or overwrite it with the template
	self.saveToDataStore = false

	return newData
end

--[=[
	Returns whether or not the profile was saved

	@method Save
	@within ProfileDB
	@param releaseSession boolean? -- Whether or not to release the session lock
	@return boolean -- Whether or not the profile was saved
]=]
function ProfileDB.Save(self: Profile, releaseSession: boolean?): boolean
	self.lastSave = Workspace:GetServerTimeNow()

	if not self.saveToDataStore then
		return true
	end

	self.metadata.last_seen = Workspace:GetServerTimeNow() -- Update the last seen time

	-- `self.metadata` will be formatted to be saved to the data store
	local serializedData: { [any]: any } = {}

	for key: string, value: any in pairs(self.metadata) do
		if
			not table.find(KEYS_TO_IGNORE, key) and not table.find(self.keysToIgnore, key)
		then
			serializedData[key] = value
		end
	end

	-- Allow another server to load and save the player's data
	if releaseSession then
		serializedData.sessionData = nil
	end

	local saveString: string? = HttpService:JSONEncode(serializedData)

	if not saveString then
		return false
	end

	local newVersion = self.lastSave
	local newVersionString = tostring(newVersion)

	local profileSaveSuccess: boolean = Util.attempt(function()
		self.dataStore:SetAsync(newVersionString, saveString, { self.userId })
	end, MAX_CONNECTION_ATTEMPTS, MAX_CONNECTION_ATTEMPT_DELAY)

	if not profileSaveSuccess then
		return false
	end

	-- Save new record of the newly saved profile version
	-- This will be retrieved next time the player joins
	-- Then it will be used to fetch the version from profileDB
	local versionSaveSuccess: boolean = Util.attempt(function()
		self.versionDataStore:SetAsync(newVersionString, newVersion)
	end, MAX_CONNECTION_ATTEMPTS, MAX_CONNECTION_ATTEMPT_DELAY)

	if not versionSaveSuccess then
		-- Don't save the player's data if the version record failed to save.
		-- This will prevent developer products from being lost.
		self.saveToDataStore = false

		return false
	end

	-- Send the player's data to the API if an API URL is provided
	-- This will not return false if the API request fails
	-- because the player's data is already saved to the data store
	if self.apiURL then
		pcall(HttpService.PostAsync, HttpService, self.apiURL, saveString)
	end

	self.Saved:Fire(self.metadata.data)

	return true
end

--[=[
	Reconciles the profile data with the template provided in the constructor

	@method Reconcile
	@within ProfileDB
]=]
function ProfileDB.Reconcile(self: Profile)
	if not self.saveToDataStore then
		return
	end

	local addedKeys: boolean = false

	local template = self:GetTemplate()

	-- Add any tables that were missing from the saved profile
	-- Example: the developers added a trading system and now the profile
	-- does not have a trade_history table. The below loop will insert
	-- a blank trade_history table from the default profile constructor
	for key: string, value: any in pairs(template) do
		if self.metadata.data[key] == nil then
			self.metadata.data[key] = value
			addedKeys = true
		end
	end

	if addedKeys then
		self.Changed:Fire(self.metadata.data)
	end
end

--[=[
	Resets the profile data to the template provided in the constructor

	@method Reset
	@within ProfileDB
]=]
function ProfileDB.Reset(self: Profile)
	self.metadata = self:GetNewData()
	self.Changed:Fire(self.metadata.data)
end

--[=[
	Returns the value at the given path in the profile data

	Not providing a path will return the entire profile data table

	@method Get
	@within ProfileDB
	@param path string? -- The path to the value
	@return any -- The value at the given path or nil if the value does not exist
]=]
function ProfileDB.Get(self: Profile, path: string?): any
	assert(path == nil or typeof(path) == "string", "A path must be a string")

	return if path == nil
		then self.metadata.data
		else Util.treePath(self.metadata.data, path, ".")
end

function ProfileDB.GetData(self: Profile): ProfileData
	return self.metadata.data
end

function ProfileDB.GetMultiple(self: Profile, data: { string }): { [string]: any }
	assert(data, "Data must be provided")
	assert(typeof(data) == "table", "Data must be a table")

	local values: { [string]: any } = {}

	for _, path: string in data do
		values[path] = self:Get(path)
	end

	return values
end

--[=[
	Sets the value at the given path in the profile data.

	If nil is provided as the value, the key will be removed from the path.

	If you want to insert a value into a table, you can use "++" as the last key in the path.

	Example:
	```lua
	profile:Set("purchases.++", "dev_product_receipt_12345")
	```

	Need to store unique data in a table?
	```lua
	profile:Set("inventory.weapons.++", {
		uniqueWeaponId = "weapon_12345",
		skin = "RARE_SKIN_ID",
	})
	```

	If the weapon were to be sold or removed, you can remove it by finding its index.
	```lua
	for index, weapon in profile:Get("inventory.weapons") do
		if weapon.uniqueWeaponId == "weapon_12345" then
			profile:Set("inventory.weapons.--", index)
			break
		end
	end
	```

	@method Set
	@within ProfileDB
	@param path string -- The path to the value
	@param value any -- The value to set
	@param skipUpdate boolean? -- Whether or not to skip firing the Changed signal
	@return boolean -- Whether or not the value was set
]=]
function ProfileDB.Set(
	self: Profile,
	path: string,
	value: any,
	skipUpdate: boolean?
): boolean
	assert(path, "A path must be provided")
	assert(type(path) == "string", "Path must be a string")

	local split = string.split(path, ".")
	local lastKey = typeof(split[#split]) == "number" and tonumber(split[#split])
		or split[#split]

	if split[1] == "" then
		return false
	end

	if #split == 1 then
		self.metadata.data[path] = value
		self.Changed:Fire(self.metadata.data)
		return true
	end

	-- Concat string without the last key
	local parentPath: string? = table.concat(split, ".", 1, #split - 1)

	if not parentPath then
		return false
	end

	local node: { [any]: any }? = Util.treePath(self.metadata.data, parentPath, ".")

	if typeof(node) ~= "table" then
		return false
	end

	-- Successfully passed checks and set the new value
	if lastKey == "++" then
		if value == nil then
			-- Cannot insert nil into a table
			return false
		end

		table.insert(node, value)
	elseif lastKey == "--" then
		local index: number? = typeof(value) == "number" and value or tonumber(value)

		if not index then
			-- Could not get an index to remove
			return false
		end

		table.remove(node, value)
	elseif value == nil then
		node[lastKey] = value
	end

	if not skipUpdate then
		self.Changed:Fire(self.metadata.data)
	end

	return true
end

--[=[
	Sets multiple values in the profile data.

	@method SetMultiple
	@within ProfileDB
	@param data { [string]: any } -- The data paths to set
	@return { string } -- The keys that were updated
]=]
function ProfileDB.SetMultiple(self: Profile, data: { [string]: any }): { string }
	assert(data, "Data must be provided")
	assert(typeof(data) == "table", "Data must be a table")

	local updatedKeys: { string } = {}

	for path: string, value: any in pairs(data) do
		local success: boolean = self:Set(path, value, true)

		if success then
			table.insert(updatedKeys, path)
		end
	end

	if #updatedKeys > 0 then
		self.Changed:Fire(self.metadata.data)
	end

	return updatedKeys
end

--[=[
	Unsets the value at the given path in the profile data.

	Alias for `profile:Set(path, nil)`.

	@method Unset
	@within ProfileDB
	@param path string -- The path to the value
	@return boolean -- Whether or not the value was unset
]=]
function ProfileDB.Unset(self: Profile, path: string): boolean
	return self:Set(path, nil)
end

--[=[
	Unsets multiple values in the profile data.

	@method UnsetMultiple
	@within ProfileDB
	@param data { string } -- The data paths to unset
	@return { string } -- The keys that were removed
]=]
function ProfileDB.UnsetMultiple(self: Profile, data: { string }): { string }
	assert(data, "Data must be provided")
	assert(typeof(data) == "table", "Data must be a table")

	local removedKeys: { string } = {}

	for _, path: string in data do
		local success: boolean = self:Set(path, nil, true)

		if success then
			table.insert(removedKeys, path)
		end
	end

	if #removedKeys > 0 then
		self.Changed:Fire(self.metadata.data)
	end

	return removedKeys
end

--[=[
	Inserts a number indexed value into a table at the given path.

	Example
	```lua
	print(profile.metadata.data.inventory) -- { "item_12345", "item_67890" }

	profile:Insert("inventory", "item_54321")

	print(profile.metadata.data.inventory) -- { "item_12345", "item_67890", "item_54321" }
	```

	Need to insert it into a nested table?
	```lua
	print(profile.metadata.data.inventory.weapons) -- { "weapon_12345", "weapon_67890" }

	profile:Insert("inventory.weapons", "weapon_54321")

	print(profile.metadata.data.inventory) -- { "weapon_12345", "weapon_67890", "weapon_54321" }
	```

	@method Insert
	@within ProfileDB
	@param path string -- The path to the table
	@param value any -- The value to insert
	@param skipUpdate boolean? -- Whether or not to skip firing the Changed signal
	@return boolean -- Whether or not the value was inserted
]=]
function ProfileDB.Insert(
	self: Profile,
	path: string,
	value: any,
	skipUpdate: boolean?
): boolean
	assert(path, "A path must be provided")
	assert(type(path) == "string", "Path must be a string")

	local split = string.split(path, ".")
	local lastKey = split[#split]

	if split[1] == "" then
		return false
	end

	if #split == 1 then
		-- Cannot insert into the root of the profile data

		return false
	end

	-- Concat string without the last key
	local parentPath: string? = table.concat(split, ".", 1, #split - 1)

	if not parentPath then
		return false
	end

	local node: { [any]: any }? = Util.treePath(self.metadata.data, parentPath, ".")

	if typeof(node) ~= "table" then
		return false
	end

	if typeof(node[lastKey]) ~= "table" then
		return false
	end

	-- Successfully passed checks and inserted the new value
	table.insert(node[lastKey], value)

	if not skipUpdate then
		self.Changed:Fire(self.metadata.data)
	end

	return true
end

--[=[
	Inserts multiple values into a table at the given path.

	@method InsertMultiple
	@within ProfileDB
	@param path string -- The path to the table
	@param data { any } -- The values to insert
	@return { string } -- The keys that were updated
]=]
function ProfileDB.InsertMultiple(self: Profile, data: { any }): { string }
	assert(data, "Data must be provided")
	assert(typeof(data) == "table", "Data must be a table")

	local removedKeys: { string } = {}

	for _, path: string in data do
		local success: boolean = self:Set(path, nil, true)

		if success then
			table.insert(removedKeys, path)
		end
	end

	if #removedKeys > 0 then
		self.Changed:Fire(self.metadata.data)
	end

	return removedKeys
end

--[=[
	This method will remove a value from a table.

	Example
	```lua
	print(profile.metadata.data) -- { inventory = { "item_12345", "item_67890" } }

	profile:RemoveValue("inventory", "item_12345")

	print(profile.metadata.data) -- { inventory = { "item_67890" } }
	```

	@method RemoveValue
	@within ProfileDB
	@param path string -- The path to the table
	@param value any -- The value to remove
	@param skipUpdate boolean? -- Whether or not to skip firing the Changed signal
	@return boolean -- Whether or not the value was removed
]=]
function ProfileDB.RemoveValue(
	self: Profile,
	path: string,
	value: any,
	skipUpdate: boolean?
): boolean
	assert(path, "A path must be provided")
	assert(type(path) == "string", "Path must be a string")

	local split = string.split(path, ".")
	local lastKey = split[#split]

	if split[1] == "" then
		return false
	end

	if #split == 1 then
		-- Cannot remove from the root of the profile data

		return false
	end

	-- Concat string without the last key
	local parentPath: string? = table.concat(split, ".", 1, #split - 1)

	if not parentPath then
		return false
	end

	local node: { [any]: any }? = Util.treePath(self.metadata.data, parentPath, ".")

	if typeof(node) ~= "table" then
		return false
	end

	if typeof(node[lastKey]) ~= "table" then
		return false
	end

	local index: number? = table.find(node[lastKey], value)

	if not index then
		return false
	end

	-- Successfully passed checks and removed the value
	table.remove(node[lastKey], index)

	if not skipUpdate then
		self.Changed:Fire(self.metadata.data)
	end

	return true
end

--[=[
	Removes multiple values from a table at the given path.

	@method RemoveMultiple
	@within ProfileDB
	@param path string -- The path to the table
	@param data { [string]: any } -- The path and values to remove
	@return { string } -- The keys that were removed
]=]
function ProfileDB.RemoveValues(self: Profile, data: { [string]: any }): { string }
	assert(data, "Data must be provided")
	assert(typeof(data) == "table", "Data must be a table")

	local removedKeys: { string } = {}

	for path: string, value: any in pairs(data) do
		local success: boolean = self:RemoveValue(path, value, true)

		if success then
			table.insert(removedKeys, path)
		end
	end

	if #removedKeys > 0 then
		self.Changed:Fire(self.metadata.data)
	end

	return removedKeys
end

--[=[
	Increments the value at the given path in the profile data.

	@method Increment
	@within ProfileDB
	@param path string -- The path to the value
	@param value number -- The value to increment by
	@return boolean -- Whether or not the value was incremented
]=]
function ProfileDB.Increment(self: Profile, path: string, value: number): boolean
	assert(path, "A path must be provided")
	assert(type(path) == "string", "Path must be a string")
	assert(value, "A value must be provided")
	assert(type(value) == "number", "Value must be a number")

	local currentValue: number = self:Get(path)

	if currentValue == nil then
		warn(`{path} does not exist in the profile data`)
		return false
	end

	if typeof(currentValue) ~= "number" then
		warn("Existing value must be a number")
		return false
	end

	return self:Set(path, currentValue + value)
end

--[=[
	Updates the profile data using a callback function.

	This method can be dangerous and destructive if used incorrectly.
	For example yielding in the callback function can cause data loss.

	Example
	```lua
	profile:SetData(function(data: ProfileDB.ProfileMetadata)
		data.coins = 100
	end)
	```

	@method SetData
	@within ProfileDB
	@param callback (ProfileMetadata) -> () -- The callback to update the profile data
	@return boolean -- Whether or not the data was updated
]=]
function ProfileDB.SetData(self: Profile, callback: (ProfileMetadata) -> ()): boolean
	local successful = pcall(callback, self.metadata.data)

	if not successful then
		return false
	end

	self.Changed:Fire(self.metadata.data)

	return true
end

--[=[
	Destroys the profile and disconnects all events.

	@method Destroy
	@within ProfileDB
	@tag Cleanup
]=]
function ProfileDB.Destroy(self: Profile)
	self.maid:Destroy()
end

return ProfileDB
