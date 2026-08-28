# Attrify

Attrify lets you add game mechanics to your Roblox game without writing code.

Here's how it works: you put a tag (a label) on a part, and Attrify makes that part do something. Want a jump pad? Tag a part with `attr_jump_pad` and it becomes one. Want to change how high it launches players? Set an attribute (a setting on the part) in the Properties panel. No scripts needed.

## What you get

- **50 ready-made behaviors** (called watchers) for things games need all the time: coins, kill parts, moving platforms, doors, checkpoints, and more
- **No scripting required** - everything is set up with tags and attributes in Roblox Studio
- **Use only what you need** - watchers only run when you tag something with them
- **Works with typed Luau** - if you do write code, the types are all there
- **Signals** - if you want your own code to react when something happens (like a coin being collected), you can

## Try it

1. Add the `attr_jump_pad` tag to any BasePart
2. Set the `attr_jump_distance` attribute to `30`
3. Play the game and touch the part. You get launched!

That's the whole setup for most watchers.

If you want your own code to react to events, connect to a signal:
```lua
local Attrify = require(ReplicatedStorage.Packages.Attrify)

Attrify.Signals.CoinCollected:Connect(function(player, value, part)
    print(player.Name, "collected", value, "coins!")
end)
```

## Getting started

Install with [Wally](https://wally.run) by adding it to your `wally.toml`:

```toml
[dependencies]
attrify = "dig1t/attrify@1.0.0"
```

Attrify needs one line of code on the server and one on the client. After that, everything is tags and attributes.

```lua
-- Server script
local Attrify = require(ReplicatedStorage.Packages.Attrify)
Attrify.start()

-- Client script
local Attrify = require(ReplicatedStorage.Packages.Attrify)
Attrify.start()
```

## All 50 watchers

| Category | Count | Watchers |
|----------|-------|----------|
| **Animation** | 8 | `attr_bobber`, `attr_elevator`, `attr_moving_platform`, `attr_orbiter`, `attr_shaker`, `attr_spinner`, `attr_swing_part`, `attr_thwomp` |
| **Collect** | 2 | `attr_coin`, `attr_collectible` |
| **Combat** | 4 | `attr_damage_zone`, `attr_heal_part`, `attr_heal_zone`, `attr_kill_part` |
| **Constraint** | 2 | `attr_hinge_part`, `attr_rope_part` |
| **Destruction** | 2 | `attr_breakable`, `attr_respawner` |
| **Door** | 3 | `attr_auto_door`, `attr_sliding_panel`, `attr_swing_gate` |
| **Interaction** | 3 | `attr_button`, `attr_clickable`, `attr_prompt_part` |
| **Movement** | 8 | `attr_conveyor`, `attr_gravity_zone`, `attr_jump_pad`, `attr_push_zone`, `attr_slow_zone`, `attr_speed_boost`, `attr_speed_zone`, `attr_teleporter` |
| **Obby** | 6 | `checkpoint`, `spawn_point`, `attr_crumbling_part`, `attr_cycling_kill_part`, `attr_cycling_platform`, `attr_fading_part` |
| **Sound** | 3 | `attr_ambient_sound`, `attr_proximity_sound`, `attr_touch_sound` |
| **Visual** | 9 | `attr_beamer`, `attr_billboard`, `attr_color_cycler`, `attr_fader`, `attr_flickerer`, `attr_glowing`, `attr_pulser`, `attr_spotlighter`, `attr_trail` |

## Examples

Source code, `.rbxl`, and `.rbxm` examples are in [Releases](https://github.com/dig1t/attrify/releases).

## Documentation

The [full documentation](https://firebit-dev.github.io/docs/attrify/docs/intro) covers:
- Every watcher and its settings
- How to install Attrify
- The API for writing your own code around it
