local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")

local Cache = require(script.Parent.Cache)

local badges = {}

--[=[
	@class Badge

	Badge management class for awarding badges to players.

	Use the `Badge.add` method to add badges to the cache.

	Example:
	```lua
	-- Setup
	local Badge = require(game.ReplicatedStorage.Packages.Badge)

	Badge.add("BadgeName", 999999999)

	-- Server
	local hasBadge = Badge.has(player, "BadgeName")

	print(`Player has badge: {hasBadge}!`)

	if not hasBadge then
		Badge.award(player, "BadgeName")
	end
	```

	Install with wally by adding the following to your `wally.toml`:
	```toml
	Badge = "dig1t/badge@1.0.4"
	```
]=]
local Badge = {}
local cache = Cache.new()

--[=[
	Adds a badge to the cache.

	```lua
	Badge.add("BadgeName", 999999999)
	```

	@param name string -- The name of the badge.
	@param badgeId number -- The id of the badge.
]=]
function Badge.add(name: string, badgeId: number)
	assert(name, "Badge.add - Missing badge name")
	assert(badgeId, "Badge.add - Missing badge id")

	badges[name] = badgeId
end

--[=[
	Checks if a player has a badge.

	```lua
	local hasBadge = Badge.has(player, "BadgeName")
	```

	@param player Player | number -- The player or userId to check.
	@param badgeName string -- The name of the badge.
	@return boolean -- Whether the player has the badge or not.
]=]
function Badge.has(player: Player | number, badgeName: string): boolean?
	assert(
		typeof(player) == "number" or player:IsA("Player"),
		"Badge.has - Invalid player"
	)
	assert(typeof(badgeName) == "string", "Badge.has - Invalid badge name")
	assert(badges[badgeName], `Badge.has - {badgeName} badge does not exist`)

	local _player: Player = typeof(player) == "number"
			and Players:GetPlayerByUserId(player)
		or player
	local userId: number = _player.UserId

	local cacheKey: string = `${userId}-${badgeName}`
	local cachedResult: boolean? = cache:Get(cacheKey)

	if cachedResult == nil then
		cachedResult = BadgeService:UserHasBadgeAsync(userId, badges[badgeName])
		cache:Set(cacheKey, cachedResult)
	end

	return cachedResult
end

--[=[
	Awards a badge to a player.

	```lua
	local awarded: boolean = Badge.award(player, "BadgeName")

	if not awarded then
		print("Failed to award badge!")
	end

	print("Badge awarded!")
	```

	@param player Player | number -- The player or userId to award the badge to.
	@param badgeName string -- The name of the badge.
	@return boolean -- Whether the badge was awarded or not. If the badge was already awarded, this will return true.
]=]
function Badge.award(player: Player | number, badgeName: string): boolean
	assert(
		typeof(player) == "number" or player:IsA("Player"),
		"Badge.award - Invalid player"
	)
	assert(typeof(badgeName) == "string", "Badge.award - Invalid badge name")

	local _player: Player = typeof(player) == "number"
			and Players:GetPlayerByUserId(player)
		or player
	local userId: number = _player.UserId

	if Badge.has(userId, badgeName) then
		return true
	end

	local success =
		pcall(BadgeService.AwardBadge, BadgeService, userId, badges[badgeName])

	if success then
		cache:Set(`${userId}-${badgeName}`, true)

		return true
	end

	return false
end

return Badge
