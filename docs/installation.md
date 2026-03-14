---
sidebar_position: 2
---

# Installation

## Setup

Attrify needs to be started on both server and client. Each watcher automatically determines whether it should run on server or client.

### Server Script

```lua
-- ServerScriptService/Server.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Attrify = require(ReplicatedStorage.Packages.Attrify)

Attrify.start()
```

### Client Script

```lua
-- ReplicatedFirst/Client.client.luau (or StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Attrify = require(ReplicatedStorage.Packages.Attrify)

Attrify.start()
```

## Using Watchers

Once attrify is started, simply add tags to your parts:

1. Select a part in Roblox Studio
2. Open the **Tag Editor** (View → Tag Editor)
3. Add a tag like `attr_jump_pad` or `attr_spinner`
4. Configure attributes in the **Properties** panel

### Tag Naming

Most watchers use the `attr_` prefix for their tags:
- `attr_spinner` - Spinner watcher
- `attr_jump_pad` - Jump Pad watcher (note: some use underscore naming)
- `attr_coin` - Coin watcher

Check the [Watcher Reference](./reference) for the exact tag name for each watcher.

## Listening to Events

Many watchers fire signals that you can listen to:

```lua
local Attrify = require(ReplicatedStorage.Packages.Attrify)
Attrify.start()

-- Listen for coin collection
Attrify.Signals.CoinCollected:Connect(function(player, value, part)
    -- Award coins to player
    print(player.Name, "collected", value, "coins!")
end)

-- Listen for button presses
Attrify.Signals.ButtonPressed:Connect(function(player, part)
    -- Trigger game logic
    print(player.Name, "pressed button:", part.Name)
end)
```

### Available Signals

| Signal | Parameters | Description |
|--------|------------|-------------|
| `CoinCollected` | player, value, part | Coin was collected |
| `CollectibleCollected` | player, type, amount, part | Collectible was picked up |
| `PromptTriggered` | player, part | Proximity prompt was triggered |
| `Clicked` | player, part | Clickable part was clicked |
| `ButtonPressed` | player, part | Button was touched |
| `PartBroken` | part | Breakable part was destroyed |
