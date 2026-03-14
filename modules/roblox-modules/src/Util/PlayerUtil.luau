local Players = game:GetService("Players")

local groupRankCache = {}
local groupRankCacheExpiration = 60 -- 1 minutes

local PlayerUtil = {}

--[=[
	Gets the group rank of a player.

	#### Example:
	```lua
	Util.getGroupRank(game.Players.LocalPlayer, 1) -- 255
	```

	@within Util
	@param player Player
	@param groupId number
	@return number
]=]
function PlayerUtil.getGroupRank(player: Player, groupId: number): number
	local uniqueId: string = `${player.UserId}-${groupId}`

	if not player or not groupId then
		return 0
	end

	if not groupRankCache[uniqueId] then
		local success, res = pcall(function()
			return player:GetRankInGroup(groupId)
		end)

		groupRankCache[uniqueId] = {
			rank = success and res or 0,
			fetchedAt = os.time(),
		}

		return success and res or 0
	end

	if os.clock() - groupRankCache[uniqueId].fetchedAt > groupRankCacheExpiration then
		return PlayerUtil.getGroupRank(player, groupId) -- refetch if expired
	end

	return groupRankCache[uniqueId].rank
end

--[=[
	Checks if a player is the creator of the game.

	#### Example:
	```lua
	Util.isCreator(game.Players.LocalPlayer) -- true
	```

	@within Util
	@param player Player
	@return boolean
]=]
function PlayerUtil.isCreator(player: Player): boolean
	return (
		game.CreatorType == Enum.CreatorType.Group
		and PlayerUtil.getGroupRank(player, game.CreatorId) >= 255
	)
		or (game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId)
end

--[=[
	@within Util
	@prop userLevel table<number, number>
]=]
PlayerUtil.userLevel = {
	normal = 0, -- (default)
	premium = 1, -- (requires premium)
	VIP = 2, -- (if game is owned by group, requires rank 10)
	moderator = 3, -- (if game is owned by group, requires rank 50)
	superuser = 4, -- developer (if game is owned by group, requires rank 254)
	creator = 5, -- (requires group rank 255 or if game is owned by user)
}

--[=[
	Gets the user level of a player.

	#### Example:
	```lua
	Util.getUserLevel(game.Players.LocalPlayer) -- 0
	Util.getUserLevel(game.Players.GameDeveloper) -- 4
	Util.getUserLevel(game.Players.PremiumPlayer) -- 4
	Util.getUserLevel(game.Players.Creator) -- 5
	```

	@within Util
	@param player Player
	@return number
]=]
function PlayerUtil.getUserLevel(player: Player): number
	local isGameOwnedByGroup: boolean = game.CreatorType == Enum.CreatorType.Group

	if PlayerUtil.isCreator(player) then
		return PlayerUtil.userLevel.creator
	elseif isGameOwnedByGroup then
		local playerRank: number = PlayerUtil.getGroupRank(player, game.CreatorId)

		if playerRank >= 253 then
			return PlayerUtil.userLevel.superuser
		elseif playerRank == 99 then
			return PlayerUtil.userLevel.moderator
		elseif playerRank < 10 then
			return PlayerUtil.userLevel.VIP
		end
	end

	return (
		player.MembershipType == Enum.MembershipType.Premium
		and PlayerUtil.userLevel.premium
	) or PlayerUtil.userLevel.normal
end

--[=[
	Gets the humanoid object from a player's character part, character model, player object, or humanoid.

	#### Example:
	```lua
	Util.getHumanoid(game.Players.LocalPlayer) -- Humanoid
	```

	@within Util
	@param object Instance
	@return Humanoid?
]=]
function PlayerUtil.getHumanoid(object: Instance?): Humanoid?
	if typeof(object) ~= "Instance" then
		warn(`Util.getHumanoid - expected Instance, got type "{typeof(object)}"`)
	elseif object:IsA("Humanoid") then
		return object
	elseif object:IsA("Player") then
		return object.Character and object.Character:FindFirstChildOfClass("Humanoid")
	elseif object:IsA("Model") then
		return object:FindFirstChildOfClass("Humanoid")
	end

	return nil
end

--[=[
	Checks if a humanoid is alive.
	If no humanoid is found, it will return nil

	#### Example:
	```lua
	Util.isAlive(game.Players.LocalPlayer) -- true
	Util.isAlive(game.Workspace.Zombie) -- false
	Util.isAlive(game.Workspace.Part) -- nil, but will throw a warning
	```

	@within Util
	@param obj Instance
	@return boolean
]=]
function PlayerUtil.isAlive(obj: Instance): boolean
	local humanoid: Humanoid? = PlayerUtil.getHumanoid(obj)

	return humanoid and humanoid.Health > 0 or false
end

--[=[
	Checks if an object has a humanoid.

	#### Example:
	```lua
	Util.hasHumanoid(game.Players.LocalPlayer) -- true
	Util.hasHumanoid(game.Workspace.Zombie) -- true
	```

	@within Util
	@param obj Instance
	@return boolean
]=]
function PlayerUtil.hasHumanoid(obj: Instance): boolean
	return PlayerUtil.getHumanoid(obj) ~= nil
end

--[=[
	Gets the player object from a BasePart.

	#### Example:
	```lua
	Util.getPlayerFromInstance(game.Workspace.Part) -- Player
	```

	@within Util
	@param instance Instance
	@return Player?
]=]
function PlayerUtil.getPlayerFromInstance(instance: Instance?): Player?
	if typeof(instance) ~= "Instance" or not instance:IsA("BasePart") then
		return nil
	end

	local node: Instance? = instance
	local humanoid: Humanoid?

	while node ~= nil and humanoid == nil and node ~= game do
		humanoid = node and node:FindFirstChildOfClass("Humanoid")
		node = node.Parent :: Instance?
	end

	return humanoid and Players:GetPlayerFromCharacter(humanoid.Parent) or nil
end

-- Alias
PlayerUtil.getPlayerFromPart = PlayerUtil.getPlayerFromInstance

return PlayerUtil
