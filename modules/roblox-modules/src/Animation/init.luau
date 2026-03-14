local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Maid = require(script.Parent.Maid)
local Promise = require(script.Parent.Promise)
local Util = require(script.Parent.Util)

local DEFAULT_TWEEN_TIME = 0.2

--[=[
	@class Animation

	Animation library for animating instances.

	Install with wally by adding the following to your `wally.toml`:
	```toml
	Animation = "dig1t/animation@1.0.7"
	```
]=]
local Animation = {}

--[=[
	The default animation configuration.

	Example:
	```lua
	Animation.setDefaultConfig({
		tweenInfo = TweenInfo.new(1),
		start = {
			Transparency = 1
		},
		goal = {
			Transparency = 0
		}
	})

	Animation.weldModel(model)

	-- Animate the model
	Animation.animate({
		source = model.PrimaryPart,
	})
	```

	@prop defaultConfig AnimationConfig
	@within Animation
]=]
Animation.defaultConfig = {}

--[=[
	Animation configuration.

	Warning: setting loop, reverse, or delay will overwrite tweenInfo if it's defined.

	@interface AnimationConfig
	@within Animation
	.source Instance -- The instance to animate
	.start { [string]: any }? -- Starting properties (this will overwrite the current properties)
	.goal { [string]: any } -- Properties to animate to
	.tweenInfo TweenInfo? -- TweenInfo for the animation
	.frameCallback () -> ()? -- Callback that runs on each RunService step
	.stopped (Enum.PlaybackState) -> ()? -- Callback for when the animation is stopped
	.await boolean? -- Wait for the animation to complete
	.loop number? -- Times to loop the animation
	.reverse boolean? -- Reverse the animation after it's done
	.delay number? -- Delay before starting the animation
]=]
export type AnimationConfig = {
	source: Instance,
	start: { [string]: any }?,
	goal: { [string]: any },
	tweenInfo: TweenInfo?,
	frameCallback: () -> ()?,
	stopped: (Enum.PlaybackState) -> ()?,
	await: boolean?,
	loop: number?,
	reverse: boolean?,
	delay: number?,
}

--[=[
	Welds all descendant parts to the primary part.

	This requires the model to have a PrimaryPart set.

	@param model Model -- The model to prepare
]=]
function Animation.weldModel(model)
	if not model.PrimaryPart then
		return
	end

	model.PrimaryPart.Anchored = true

	for _, part in model:GetDescendants() do
		if part ~= model.PrimaryPart and part:IsA("BasePart") then
			Util.weld(part, model.PrimaryPart)
			part.Anchored = false
		end
	end
end

--[=[
	Sets the default animation configuration.

	@param config AnimationConfig -- The default animation configuration
]=]
function Animation.setDefaultConfig(config: AnimationConfig)
	assert(
		config and typeof(config) == "table",
		"Table must be passed to set the default animation config"
	)

	Animation.defaultConfig = config
end

--[=[
	Animates an instance and returns a promise.

	@param config AnimationConfig -- The animation configuration
	@return Promise.Promise
]=]
function Animation.promise(config: AnimationConfig): Promise.Promise
	if config.await then
		Animation.play(config)

		return Promise.resolve(Enum.PlaybackState.Completed)
	end

	return Promise.new(function(resolve)
		config.await = true

		Animation.play(config)

		resolve(Enum.PlaybackState.Completed)
	end)
end

--[=[
	Animates an instance.

	@param config AnimationConfig -- The animation configuration
	@return Tween -- The tween instance
]=]
function Animation.play(config: AnimationConfig): Tween
	local tween: Tween = Animation.new(config)

	if not config.await then
		tween:Play()
	end

	return tween
end

--[=[
	Animates multiple instances and returns a promise.

	@param instances { Instance } -- The instances to animate
	@param config AnimationConfig -- The animation configuration
	@return Promise.Promise
]=]
function Animation.promiseAll(
	instances: { Instance },
	config: AnimationConfig
): Promise.Promise
	local promises = {}

	for _, instance in instances do
		local newConfig = table.clone(config)
		newConfig.source = instance

		table.insert(promises, Animation.promise(newConfig))
	end

	return Promise.all(promises)
end

--[=[
	Constructs a tween

	@param config AnimationConfig -- The animation configuration
	@return Tween -- The tween instance
]=]
function Animation.new(config: AnimationConfig): (Tween, Promise.Promise?)
	assert(config and typeof(config) == "table", "Missing animation configuration")
	assert(typeof(config.source) == "Instance", "Missing instance to animate")
	assert(
		typeof(config.start) == "table" or config.start == nil,
		"Start properties must be a table"
	)
	assert(typeof(config.goal) == "table", "Goal properties must be a table")
	assert(
		typeof(config.tweenInfo) == "TweenInfo" or config.tweenInfo == nil,
		"tweenInfo must be a TweenInfo type"
	)
	assert(
		typeof(config.frameCallback) == "function" or config.frameCallback == nil,
		"frameCallback must be a function"
	)
	assert(
		typeof(config.stopped) == "function" or config.stopped == nil,
		"stopped must be a function"
	)
	assert(
		typeof(config.await) == "boolean" or config.await == nil,
		"await must be a boolean"
	)
	assert(typeof(config.loop) == "number" or config.loop == nil, "loop must be a number")
	assert(
		typeof(config.reverse) == "boolean" or config.reverse == nil,
		"reverse must be a boolean"
	)
	assert(
		typeof(config.delay) == "number" or config.delay == nil,
		"delay must be a number"
	)

	local tweenInfo = config.tweenInfo or TweenInfo.new(DEFAULT_TWEEN_TIME)

	if config.loop then
		tweenInfo.RepeatCount = config.loop
	end

	if config.reverse then
		tweenInfo.Reverses = true
	end

	if config.delay then
		tweenInfo.DelayTime = config.delay
	end

	-- Place default values
	for k, v in pairs(Animation.defaultConfig) do
		if config[k] == nil then
			config[k] = v
		end
	end

	if config.start then
		local source = (config.source :: any) :: { [any]: any }

		for property, value in pairs(config.start) do
			-- Safely set the new property
			pcall(function()
				source[property] = value
			end)
		end
	end

	local newTween = TweenService:Create(config.source, config.tweenInfo, config.goal)

	local maid = Maid.new()

	if config.frameCallback then
		maid:Task(RunService.Stepped:Connect(config.frameCallback))
	end

	if config.stopped then
		maid:Task(newTween.Completed:Connect(config.stopped))
	end

	newTween.Completed:Once(function()
		task.wait()
		maid:Destroy()
	end)

	if config.await then
		newTween:Play()

		if newTween.PlaybackState == Enum.PlaybackState.Completed then
			return newTween
		end

		newTween.Completed:Wait()
	end

	return newTween
end

return Animation
