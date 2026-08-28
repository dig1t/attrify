---
sidebar_position: 2
---

# Installation

## Setup

Roblox games run code in two places: the **server** (the computer running the game for everyone) and the **client** (each player's own device). Attrify needs to be started in both places, because some watchers run on the server (like kill parts) and some run on the client (like spinning decorations). You don't have to think about which is which. Each watcher picks the right place on its own.

### Server script

```lua
-- ServerScriptService/Server.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Attrify = require(ReplicatedStorage.Packages.Attrify)

Attrify.start()
```

### Client script

```lua
-- ReplicatedFirst/Client.client.luau (or StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Attrify = require(ReplicatedStorage.Packages.Attrify)

Attrify.start()
```

## Using watchers

Once Attrify is started, add tags to your parts:

1. Select a part in Roblox Studio
2. Open the **Tag Editor** (View → Tag Editor)
3. Add a tag like `attr_jump_pad` or `attr_spinner`
4. Change the part's attributes in the **Properties** panel to tweak how it behaves

### Tag naming

Most watcher tags start with `attr_`:
- `attr_spinner` - Spinner watcher
- `attr_jump_pad` - Jump Pad watcher
- `attr_coin` - Coin watcher

A couple don't (like `checkpoint` and `spawn_point`), so check the [Watcher Reference](./reference) for the exact tag name.

## Listening to events

Some watchers fire signals when something happens, so your own code can react:

```lua
local Attrify = require(ReplicatedStorage.Packages.Attrify)
Attrify.start()

-- Runs every time a player collects a coin
Attrify.Signals.CoinCollected:Connect(function(player, value, part)
    -- Award coins to the player
    print(player.Name, "collected", value, "coins!")
end)

-- Runs every time a player presses a button
Attrify.Signals.ButtonPressed:Connect(function(player, part)
    -- Trigger your game logic
    print(player.Name, "pressed button:", part.Name)
end)
```

### Available signals

| Signal | Parameters | Fires when |
|--------|------------|------------|
| `CoinCollected` | player, value, part | A player picks up a coin |
| `CollectibleCollected` | player, type, amount, part | A player picks up a collectible |
| `PromptTriggered` | player, part | A player uses a proximity prompt |
| `Clicked` | player, part | A player clicks a clickable part |
| `ButtonPressed` | player, part | A player touches a button |
| `PartBroken` | part | A breakable part gets destroyed |
