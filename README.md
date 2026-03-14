# Attrify

No-code behavior system for Roblox using CollectionService tags and attributes.

Add tags to parts and configure behavior through attributes - no scripting required for common game mechanics.

## Features

- **50 pre-built watchers** for common game mechanics
- **Zero scripting** - configure everything via attributes
- **Modular** - only use what you need
- **Type-safe** - full Luau strict mode support
- **Signals** - react to events in your own code

## Quick Example

1. Add the `attr_jump_pad` tag to any BasePart
2. Set `attr_jump_distance` attribute to `30`
3. Players touching the part will be launched!

That's it! No code needed for basic functionality.

But if you want to listen for events:
```lua
local Attrify = require(ReplicatedStorage.Packages.Attrify)

Attrify.Signals.CoinCollected:Connect(function(player, value, part)
    print(player.Name, "collected", value, "coins!")
end)
```

## Quick Start

```lua
-- Server script
local Attrify = require(ReplicatedStorage.Packages.Attrify)
Attrify.start()

-- Client script
local Attrify = require(ReplicatedStorage.Packages.Attrify)
Attrify.start()
```

## Watcher Categories

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

Source code, `.rbxl`, and `.rbxm` examples are available in [Releases](https://github.com/dig1t/attrify/releases).

## Documentation

See the [full documentation](https://firebit-dev.github.io/docs/attrify/docs/intro) for:
- Complete watcher reference
- Installation guide
- API documentation
