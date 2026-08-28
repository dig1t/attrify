---
sidebar_position: 1
---

# Introduction

**Attrify** lets you add game mechanics to your Roblox game without writing code.

You put a tag (a label) on a part, and Attrify makes that part do something: spin, damage players, hand out coins, open like a door. To change how the behavior works, you set attributes (settings on the part) in the Properties panel in Roblox Studio.

## Try it

1. Add the `attr_coin` tag to any BasePart
2. Set the `attr_value` attribute to `30`
3. Play the game and touch the part. You get 30 coins!

That's the whole setup for most watchers.

If you want your own code to react when something happens, connect to a signal:
```lua
local Attrify = require(ReplicatedStorage.Packages.Attrify)

Attrify.Signals.CoinCollected:Connect(function(player, value, part)
    print(player.Name, "collected", value, "coins!") -- Prints "Player collected 30 coins!"
end)
```

## What you get

- **50 ready-made behaviors** (called watchers) for things games need all the time
- **No scripting required** - everything is set up with tags and attributes
- **Use only what you need** - watchers only run when you tag something with them
- **Works with typed Luau** - if you do write code, the types are all there
- **Signals** - your own code can react when things happen in the game

## Watcher categories

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

## How it works

Attrify uses Roblox's CollectionService to watch for tagged parts. When you add a tag like `attr_jump_pad` to a part, Attrify notices and turns that part into a jump pad. It reads the part's attributes to know how the jump pad should behave.

```
[Part with "attr_jump_pad" tag]
    └── attr_jump_distance = 20
    └── attr_cooldown = 1
    └── attr_push_relative_to_object = true
```

With these settings, players who touch the part get launched 20 studs, and the pad waits 1 second before it can launch the same player again.

## Next steps

- [Installation](./installation) - Add Attrify to your project
- [Watcher Reference](./reference) - Browse all 50 watchers and their settings
