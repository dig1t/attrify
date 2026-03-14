---
sidebar_position: 1
---

# Introduction

**Attrify** is a no-code behavior system for Roblox using CollectionService tags and attributes. Add tags to parts and configure behavior through attributes - no scripting required for common game mechanics.

## Quick Example

1. Add the `attr_coin` tag to any BasePart
2. Set `attr_value` attribute to `30`
3. Players touching the part will be awarded 30 coins!

That's it! No code needed for basic functionality.
But if you want to react to events:
```lua
local Attrify = require(ReplicatedStorage.Packages.Attrify)

Attrify.Signals.CoinCollected:Connect(function(player, value, part)
    print(player.Name, "collected", value, "coins!") -- Expect "Player collected 30 coins!"
end)
```

## Features

- **50 pre-built watchers** for common game mechanics
- **Zero scripting** - configure everything via attributes
- **Modular** - only use what you need
- **Type-safe** - full Luau strict mode support
- **Signals** - react to events in your own code

## Watcher Categories

- Animation
- Movement
- Visual
- Combat
- Interaction
- Door
- Obby
- Sound
- Collect
- Destruction
- Constraint

## How It Works

attrify uses Roblox's CollectionService to watch for tagged instances. When you add a tag like `attr_jump_pad` to a part, attrify automatically applies the behavior and reads configuration from the part's attributes.

```
[Part with "attr_jump_pad" tag]
    └── attr_jump_distance = 20
    └── attr_cooldown = 1
    └── attr_push_relative_to_object = true
```

The watcher reads these attributes and applies the jump pad behavior - launching players upward when they touch the part.

## Next Steps

- [Installation](./installation) - Add attrify to your project
- [Watcher Reference](./reference) - Browse all 48 watchers
