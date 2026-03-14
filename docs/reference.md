---
sidebar_position: 3
---

# Watcher Reference

Quick reference for all Attrify watchers and their attributes.

## Feature Navigation

[Animation](#animation) | [Collect](#collect) | [Combat](#combat) | [Constraint](#constraint) | [Destruction](#destruction) | [Door](#door) | [Interaction](#interaction) | [Movement](#movement) | [Obby](#obby) | [Sound](#sound) | [Visual](#visual)

---

## Animation

Animation watchers run on the **client** and handle visual movement effects.

### Bobber
**Tag:** `attr_bobber` | **Runs on:** Client

Floats an object up and down continuously.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_bob_height` | number | 2 | Maximum bob distance in studs |
| `attr_bob_speed` | number | 1 | Cycles per second |

---

### Elevator
**Tag:** `attr_elevator` | **Runs on:** Client

Multi-floor elevator that moves between stops.

**Requires:** `Stop1`, `Stop2`, `Stop3`... Attachments for floor positions

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_move_time` | number | 2 | Time to move between floors |
| `attr_wait_time` | number | 3 | Time to wait at each floor |

---

### Moving Platform
**Tag:** `attr_moving_platform` | **Runs on:** Client

Moves a platform between two attachment points.

**Requires:** `Point1` and `Point2` Attachments

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_studs_per_second` | number | 1 | Movement speed |
| `attr_wait_time` | number | 1 | Time to wait at each end |

---

### Orbiter
**Tag:** `attr_orbiter` | **Runs on:** Client

Orbits an object around a center point.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_orbit_radius` | number | 5 | Radius of the orbit in studs |
| `attr_orbit_speed` | number | 1 | Rotations per second |
| `attr_center_name` | string | — | Name of part to orbit around (optional) |

---

### Shaker
**Tag:** `attr_shaker` | **Runs on:** Client

Applies a vibration/jitter effect to an object.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_intensity` | number | 0.2 | Maximum shake offset in studs |
| `attr_speed` | number | 20 | Shake frequency |

---

### Spinner
**Tag:** `attr_spinner` | **Runs on:** Client

Continuously rotates a Model or BasePart around a specified axis.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_seconds_per_round` | number | 2.5 | Time for 360° rotation |
| `attr_axis` | Vector3 | (0, 1, 0) | Rotation axis |

---

### Swing Part
**Tag:** `attr_swing_part` | **Runs on:** Client

Swings a Model or BasePart like a pendulum.

*Make sure to edit the part's "PivotOffset" so it swings from that pivot.*

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_seconds_per_cycle` | number | 2.5 | Time for a full swing cycle |
| `attr_swing_angle` | number | 30 | Maximum swing angle in degrees |
| `attr_axis` | Vector3 | (0, 0, 1) | Swing axis |

---

### Thwomp
**Tag:** `attr_thwomp` | **Runs on:** Client

Smash/crusher behavior that drops down and rises back up.

**Requires:** `Floor` Attachment for the target drop position

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_animation_time` | number | 1 | Time to animate up/down |
| `attr_time_on_floor` | number | 1 | Time to stay at floor position |
| `attr_time_between_drops` | number | 1 | Wait time before dropping again |

---

## Collect

Collectible watchers run on the **server** (with optional client visuals) and fire signals when collected.

### Coin
**Tag:** `attr_coin` | **Runs on:** Server + Client

Currency collectible that players can pick up. Spins on the client.

**Signal:** `CoinCollected(player, value, part)`

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_value` | number | 1 | Coin value |
| `attr_respawn_time` | number | 10 | Time before respawning (0 = no respawn) |
| `attr_spin_speed` | number | 90 | Degrees per second to spin (client-side) |
| `attr_spin_axis` | Vector3 | (0, 1, 0) | Axis to spin around (client-side) |

---

### Collectible
**Tag:** `attr_collectible` | **Runs on:** Server

Generic collectible item that can be picked up by players.

**Signal:** `CollectibleCollected(player, type, value, part)`

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_type` | string | "generic" | Type of collectible |
| `attr_value` | any | — | Value of the collectible |
| `attr_respawn_time` | number | 10 | Time before respawning (0 = no respawn) |

---

## Combat

Combat watchers run on the **server** and handle damage/healing.

### Damage Zone
**Tag:** `attr_damage_zone` | **Runs on:** Server

Continuously damages players while they remain inside the zone.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_damage_rate` | number | 1 | Time between damage ticks (seconds) |
| `attr_damage_amount` | number | 10 | Damage dealt per tick |

---

### Heal Part
**Tag:** `attr_heal_part` | **Runs on:** Server

Heals players on touch.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_heal_amount` | number | 25 | Amount of health to restore |
| `attr_cooldown` | number | 3 | Cooldown between heals per player |

---

### Heal Zone
**Tag:** `attr_heal_zone` | **Runs on:** Server

Continuously heals players while they remain inside the zone.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_heal_rate` | number | 1 | Time between heal ticks (seconds) |
| `attr_heal_amount` | number | 5 | Health restored per tick |

---

### Kill Part
**Tag:** `attr_kill_part` | **Runs on:** Server

Damages or kills players on touch.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_damage` | number | 100 | Amount of damage to deal |
| `attr_cooldown` | number | 3 | Cooldown between damage per player |

---

## Constraint

Constraint watchers run on the **server** and create physics constraints.

### Hinge Part
**Tag:** `attr_hinge_part` | **Runs on:** Server

Creates a hinge constraint on this part.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_target_name` | string | **required** | Name of the target part to hinge to |
| `attr_hinge_axis` | Vector3 | (0, 1, 0) | Axis of rotation |
| `attr_motor_enabled` | boolean | false | Enable motor rotation |
| `attr_motor_speed` | number | 45 | Motor rotation speed (degrees/second) |

---

### Rope Part
**Tag:** `attr_rope_part` | **Runs on:** Server

Creates a rope constraint between this part and a target.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_target_name` | string | **required** | Name of the target part |
| `attr_length` | number | 10 | Rope length in studs |

---

## Destruction

Destruction watchers run on the **server** and handle breaking/respawning.

### Breakable
**Tag:** `attr_breakable` | **Runs on:** Server

Part that can be destroyed by taking damage.

**Signal:** `PartBroken(part)`

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_health` | number | 100 | Part health |
| `attr_respawn_time` | number | 10 | Time before respawning (0 = no respawn) |

*Set `attr_current_health` attribute to deal damage to the part.*

---

### Respawner
**Tag:** `attr_respawner` | **Runs on:** Server

Automatically respawns a part after it's destroyed.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_respawn_time` | number | 5 | Time before respawning |

---

## Door

Door watchers run on the **client** and handle automatic doors.

### Auto Door
**Tag:** `attr_auto_door` | **Runs on:** Client

Auto-opening door that slides open when a player approaches.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_open_offset` | Vector3 | (0, 5, 0) | How far the door moves when open |
| `attr_open_time` | number | 0.5 | Time to open/close |
| `attr_trigger_distance` | number | 10 | Distance to trigger opening |

---

### Sliding Panel
**Tag:** `attr_sliding_panel` | **Runs on:** Client

Panel that slides open when triggered.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_slide_offset` | Vector3 | (5, 0, 0) | How far the panel slides |
| `attr_slide_time` | number | 0.5 | Time to slide open/close |
| `attr_trigger_distance` | number | 10 | Distance to trigger |

---

### Swing Gate
**Tag:** `attr_swing_gate` | **Runs on:** Client

Rotating gate that swings open when triggered.

*Make sure to edit the part's "PivotOffset" so it swings from that pivot.*

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_open_angle` | number | 90 | Angle to rotate when open |
| `attr_open_time` | number | 0.5 | Time to open/close |
| `attr_trigger_distance` | number | 10 | Distance to trigger opening |
| `attr_axis` | Vector3 | (0, 1, 0) | Rotation axis |

---

## Interaction

Interaction watchers run on the **server** and handle player input.

### Button
**Tag:** `attr_button` | **Runs on:** Server

Touch-activated button with optional cooldown.

**Signal:** `ButtonPressed(player, part)`

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_cooldown` | number | 1 | Cooldown between activations |

---

### Clickable
**Tag:** `attr_clickable` | **Runs on:** Server

Adds a ClickDetector to a part.

**Signal:** `Clicked(player, part)`

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_max_distance` | number | 32 | Maximum click distance |

---

### Prompt Part
**Tag:** `attr_prompt_part` | **Runs on:** Server

Adds a proximity prompt to a part.

**Signal:** `PromptTriggered(player, part)`

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_prompt_text` | string | "Interact" | Text shown on the prompt |
| `attr_action_text` | string | "Prompt" | Action key text |
| `attr_hold_duration` | number | 0 | Hold duration in seconds |
| `attr_max_distance` | number | 10 | Maximum activation distance |
| `attr_destroy_on_trigger` | boolean | false | Destroy part after activation |

---

## Movement

Movement watchers handle player physics and typically run on the **server**.

### Conveyor
**Tag:** `attr_conveyor` | **Runs on:** Server

Moves players and parts along the conveyor direction.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_speed` | number | 10 | Conveyor speed in studs/second |
| `attr_direction` | Vector3 | (0, 0, -1) | Direction relative to part's CFrame |

---

### Gravity Zone
**Tag:** `attr_gravity_zone` | **Runs on:** Server

Applies custom gravity to players while inside the zone.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_gravity_force` | number | 50 | Gravity force (positive = down, negative = up) |

---

### Jump Pad
**Tag:** `attr_jump_pad` | **Runs on:** Server

Launches players into the air on touch.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_jump_distance` | number | 20 | Target studs distance to launch |
| `attr_cooldown` | number | 1 | Cooldown between launches per player |
| `attr_push_relative_to_object` | boolean | true | Push relative to object's up vector |

---

### Push Zone
**Tag:** `attr_push_zone` | **Runs on:** Server

Pushes players in a specified direction while inside the zone.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_force` | number | 20 | Push force magnitude |
| `attr_direction` | Vector3 | (0, 0, 1) | Push direction relative to part's CFrame |

---

### Slow Zone
**Tag:** `attr_slow_zone` | **Runs on:** Server

Slows player movement while inside the zone.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_multiplier` | number | 0.5 | Speed multiplier (0.5 = 50% speed) |

---

### Speed Boost
**Tag:** `attr_speed_boost` | **Runs on:** Server

Temporarily increases player walk speed when touched.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_multiplier` | number | 2 | Speed multiplier |
| `attr_duration` | number | 5 | Duration of the boost in seconds |
| `attr_cooldown` | number | 10 | Cooldown before player can get another boost |

---

### Speed Zone
**Tag:** `attr_speed_zone` | **Runs on:** Server

Increases player movement speed while inside the zone.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_multiplier` | number | 1.5 | Speed multiplier (1.5 = 150% speed) |

---

### Teleporter
**Tag:** `attr_teleporter` | **Runs on:** Server

Teleports players between two parts within a Model.

**Structure:**
- Model (tagged with `attr_teleporter`)
  - `From`: BasePart - Entry point
  - `To`: BasePart - Exit point

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_cooldown` | number | 1 | Cooldown between teleports per player |
| `attr_one_way` | boolean | false | If true, only "From" teleports to "To" |
| `attr_teleport_offset` | Vector3 | (0, 0, 0) | Offset applied when teleporting |

---

## Obby

Obby watchers handle obstacle course mechanics.

### Crumbling Part
**Tag:** `attr_crumbling_part` | **Runs on:** Client

Platform that crumbles after being stood on.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_crumble_delay` | number | 1 | Time before crumbling after touch |
| `attr_respawn_time` | number | 5 | Time before respawning (0 = no respawn) |

---

### Cycling Kill Part
**Tag:** `attr_cycling_kill_part` | **Runs on:** Server + Client

Kill part that cycles between active and inactive states. Only damages players when visible/active.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_active_time` | number | 2 | Time the part is active (visible and deadly) |
| `attr_inactive_time` | number | 2 | Time the part is inactive (hidden and safe) |
| `attr_delay` | number | 0 | Initial delay before starting cycle |
| `attr_damage` | number | 100 | Amount of damage to deal |
| `attr_cooldown` | number | 1 | Cooldown between damage applications per player |

---

### Cycling Platform
**Tag:** `attr_cycling_platform` | **Runs on:** Client

Platform that cycles between visible and hidden states.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_visible_time` | number | 2 | Time the platform is visible |
| `attr_hidden_time` | number | 2 | Time the platform is hidden |
| `attr_delay` | number | 0 | Initial delay before starting cycle |

---

### Fading Part
**Tag:** `attr_fading_part` | **Runs on:** Server or Client

Part that fades out when touched and optionally reappears after a delay.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_fade_time` | number | 1 | Time to fade in/out |
| `attr_respawn_time` | number | 3 | Time before fading back in (0 = no respawn) |
| `attr_cooldown` | number | 0 | Cooldown after reappearing before can trigger again |
| `attr_per_player` | boolean | false | If true, runs client-side (per-player state) |

---

### Checkpoint
**Tag:** `checkpoint` | **Runs on:** Server + Client

Checkpoint system for obby games with persistence support. Players can only progress forward one checkpoint at a time.

**Signals:**
- `PlayerReachedCheckpoint(player, checkpointNumber)`
- `PlayerSpawnedAtCheckpoint(player, checkpointNumber)`

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_checkpoint_number` | number | **required** | Checkpoint number (1 and up) |
| `attr_checkpoint_effect` | boolean | true | Show visual effect on reach |

**API Methods:**
- `getCheckpointPart(checkpointNumber)` - Get the part for a checkpoint number
- `getTotalCheckpoints()` - Get total number of checkpoints
- `getPlayerCheckpoint(player)` - Get player's current checkpoint
- `setPlayerCheckpoint(player, checkpointNumber)` - Set player's checkpoint and teleport if character exists
- `spawnPlayerAtCheckpoint(player, checkpointNumber)` - Spawn player at checkpoint
- `getSpawnCFrame(checkpointNumber)` - Get spawn CFrame for a checkpoint

---

### Spawn Point
**Tag:** `spawn_point` | **Runs on:** Server

Spawn point locations for the checkpoint system. Multiple spawn points per checkpoint are supported (random selection).

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_checkpoint_number` | number | **required** | Associated checkpoint number |
| `attr_spawn_offset` | Vector3 | (0, 3, 0) | Offset from part center |

---

## Sound

Sound watchers run on the **client** and handle audio.

### Ambient Sound
**Tag:** `attr_ambient_sound` | **Runs on:** Client

Plays an ambient looping sound.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_sound_id` | string | **required** | Asset ID of the sound |
| `attr_volume` | number | 0.5 | Sound volume |
| `attr_range` | number | 50 | Maximum audible distance |

---

### Proximity Sound
**Tag:** `attr_proximity_sound` | **Runs on:** Client

Plays a sound when a player comes within range.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_sound_id` | string | **required** | Asset ID of the sound |
| `attr_volume` | number | 0.5 | Sound volume |
| `attr_range` | number | 20 | Trigger distance |
| `attr_cooldown` | number | 5 | Minimum time between plays |

---

### Touch Sound
**Tag:** `attr_touch_sound` | **Runs on:** Client

Plays a sound when a player touches the part.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_sound_id` | string | **required** | Asset ID of the sound |
| `attr_volume` | number | 0.5 | Sound volume |
| `attr_cooldown` | number | 0.5 | Minimum time between plays |

---

## Visual

Visual watchers run on the **client** and handle visual effects.

### Beamer
**Tag:** `attr_beamer` | **Runs on:** Client

Creates a beam between this part and a target part.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_target_name` | string | **required** | Name of the target part |
| `attr_beam_color` | Color3 | white | Color of the beam |
| `attr_width` | number | 1 | Width of the beam |

---

### Billboard
**Tag:** `attr_billboard` | **Runs on:** Client

Adds a BillboardGui with text above a part.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_text` | string | "" | Text to display |
| `attr_text_color` | Color3 | white | Text color |
| `attr_text_size` | number | 24 | Text size |
| `attr_offset` | number | 3 | Offset above the part |

---

### Color Cycler
**Tag:** `attr_color_cycler` | **Runs on:** Client

Cycles a part through rainbow colors.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_cycle_speed` | number | 1 | Full cycles per second |

---

### Fader
**Tag:** `attr_fader` | **Runs on:** Client

Pulses a part's transparency between min and max values.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_min_transparency` | number | 0 | Minimum transparency |
| `attr_max_transparency` | number | 0.8 | Maximum transparency |
| `attr_fade_speed` | number | 1 | Fade cycles per second |

---

### Flickerer
**Tag:** `attr_flickerer` | **Runs on:** Client

Makes a part flicker on and off randomly.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_flicker_speed` | number | 10 | Average flickers per second |
| `attr_flicker_chance` | number | 0.3 | Chance to be "off" (0-1) |

---

### Glowing
**Tag:** `attr_glowing` | **Runs on:** Client

Adds a neon glow effect to a part.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_glow_color` | Color3 | — | Color of the glow (defaults to part color) |
| `attr_brightness` | number | 1 | PointLight brightness |

---

### Pulser
**Tag:** `attr_pulser` | **Runs on:** Client

Pulses a part's size between min and max scale.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_min_scale` | number | 0.8 | Minimum size multiplier |
| `attr_max_scale` | number | 1.2 | Maximum size multiplier |
| `attr_pulse_speed` | number | 1 | Pulse cycles per second |

---

### Spotlighter
**Tag:** `attr_spotlighter` | **Runs on:** Client

Adds a spotlight to a part.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_range` | number | 16 | Light range |
| `attr_angle` | number | 90 | Spotlight angle in degrees |
| `attr_light_color` | Color3 | white | Color of the light |
| `attr_brightness` | number | 1 | Light brightness |

---

### Trail
**Tag:** `attr_trail` | **Runs on:** Client

Adds a trail effect to a part.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `attr_trail_color` | Color3 | white | Color of the trail |
| `attr_lifetime` | number | 1 | Trail lifetime in seconds |
| `attr_width` | number | 1 | Trail width |
| `attr_axis` | Vector3 | (0, 1, 0) | Axis for trail attachments |
