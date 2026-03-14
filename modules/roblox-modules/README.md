# roblox-modules

A comprehensive collection of utility modules and libraries for Roblox game development.

[![CI](https://github.com/dig1t/roblox-modules/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/dig1t/roblox-modules/actions/workflows/ci.yml)

## Installation

### Using Wally (Recommended)

**Available modules:**
```toml
Animation = "dig1t/animation@1.0.7"
Badge = "dig1t/badge@1.0.4"
Cache = "dig1t/cache@1.0.9"
GamePass = "dig1t/gamepass@1.0.8"
Maid = "dig1t/maid@1.0.8"
Palette = "dig1t/palette@1.0.1"
ProfileDB = "dig1t/profiledb@1.0.3"
Promise = "dig1t/promise@1.1.3"
Ragdoll = "dig1t/ragdoll@1.0.4"
ReactUtil = "dig1t/react-util@1.0.6"
Replica = "dig1t/replica@1.0.3"
Signal = "dig1t/signal@1.0.0"
State = "dig1t/state@1.1.2"
Trash = "dig1t/trash@1.0.3"
Util = "dig1t/util@1.0.16"
```

Use version ^1.0 on any module to use its latest version.

## Core Utilities
- Util [`dig1t/util@1.0.16`](https://dig1t.github.io/roblox-modules/api/Util) - General utility functions for common game development tasks
- Promise [`dig1t/promise@1.1.3`](https://dig1t.github.io/roblox-modules/api/Promise) - A Promise implementation for asynchronous operations
- Signal [`dig1t/signal@1.0.0`](https://dig1t.github.io/roblox-modules/api/Signal) - Event handling system similar to BindableEvents
- Maid [`dig1t/maid@1.0.8`](https://dig1t.github.io/roblox-modules/api/Maid) - Utility for managing the lifetime of objects, connections, and callbacks
- Cache [`dig1t/cache@1.0.9`](https://dig1t.github.io/roblox-modules/api/Cache) - Memory cache system for storing and retrieving data
- Trash [`dig1t/trash@1.0.3`](https://dig1t.github.io/roblox-modules/api/Trash) - Garbage collection utility

## Game Systems
- Animation [`dig1t/animation@1.0.7`](https://dig1t.github.io/roblox-modules/api/Animation) - Animation management utilities
- Badge [`dig1t/badge@1.0.4`](https://dig1t.github.io/roblox-modules/api/Badge) - Badge awarding system
- GamePass [`dig1t/gamepass@1.0.8`](https://dig1t.github.io/roblox-modules/api/GamePass) - Game Pass verification and management
- ProfileDB [`dig1t/profiledb@1.0.3`](https://dig1t.github.io/roblox-modules/api/ProfileDB) - Player data persistence system
- Ragdoll [`dig1t/ragdoll@1.0.4`](https://dig1t.github.io/roblox-modules/api/Ragdoll) - Character ragdoll physics system
- Replica [`dig1t/replica@1.0.3`](https://dig1t.github.io/roblox-modules/api/Replica) - Server-client data replication
- State [`dig1t/state@1.1.2`](https://dig1t.github.io/roblox-modules/api/State) - State management system
- Weapon - Modular weapon system with client/server implementation (WIP)

## UI & Visuals
- Palette [`dig1t/palette@1.0.1`](https://dig1t.github.io/roblox-modules/api/Palette) - Color picker that uses the Material color system

## Usage Examples

### Util

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Util = require(ReplicatedStorage.Packages.Util)

-- Player touch detection
local touchPart: BasePart = workspace:WaitForChild("Plate")
local connection = Util.onPlayerTouch(touchPart, function(player: Player)
    print(player.Name .. " touched the part!")

    if connection then
        connection:Disconnect()
    end
end)
```

### Promise

```lua
local Promise = require(ReplicatedStorage.Packages.Promise)

-- Create and use a promise
local myPromise: Promise.Promise = Promise.new(function(resolve, reject)
    -- Async operation
    local success = pcall(function()
        -- Simulate some work
        task.wait(2)
        print("Data loaded successfully")
    end)

    if success then
        resolve(data)
    else
        reject(error)
    end
end)

myPromise:andThen(function(result)
    print("Success:", result)
end):catch(function(err)
    warn("Error:", err)
end)
```

### Maid

```lua
local Maid = require(ReplicatedStorage.Packages.Maid)

local myMaid = Maid.new()

-- Add tasks to be cleaned up later
myMaid:Add(workspace.ChildAdded:Connect(function() end))
myMaid:Add(function() print("Cleanup!") end)

-- Clean up all tasks
myMaid:Clean()
```

### Palette

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Palette = require(ReplicatedStorage.Packages.Palette)

-- Get a specific color
local blueColor = Palette.get("blue", 500)
print(blueColor) -- Color3 value
```

### Cache

```lua
local Cache = require(ReplicatedStorage.Packages.Cache)

local myCache = Cache.new()

-- Store and retrieve data
myCache:Set("playerStats", { coins = 100, level = 5 })
local stats = myCache:Get("playerStats")
print(stats.coins) -- 100
```

## Types Support

All modules include type definitions for Luau's type checking system. You can import types directly:

```lua
local Promise = require(ReplicatedStorage.Packages.Promise)

type Promise = Promise.Promise

local myPromise: Promise = Promise.new(function(resolve)
    resolve(true)
end)
```
