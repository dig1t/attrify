--!strict
--[[
	@class PromptPart
	Adds a proximity prompt to a part.

	Attributes:
	- attr_prompt_text: string (default: "Interact") - Text shown on the prompt
	- attr_action_text: string (default: "Prompt") - Action key text
	- attr_hold_duration: number (default: 0) - Hold duration in seconds
	- attr_max_distance: number (default: 10) - Maximum activation distance
	- attr_destroy_on_trigger: boolean (default: false) - Destroy part after activation

	Fires Signal "PromptTriggered" with (player, part)
]]

local RunService = game:GetService("RunService")

local Attrify = script.Parent.Parent.Parent
local Packages = Attrify

local CollectionWatcher = require(Attrify.Modules.CollectionWatcher)
local Signal = require(Packages.Signal)

local COLLECTION_TAG = "prompt_part"
local IS_SERVER = RunService:IsServer()
local DEFAULT_PROMPT_TEXT = "Interact"
local DEFAULT_ACTION_TEXT = "Prompt"
local DEFAULT_HOLD_DURATION = 0
local DEFAULT_MAX_DISTANCE = 10
local DEFAULT_DESTROY_ON_TRIGGER = false

local PromptTriggered = Signal.new()

local PromptPart: CollectionWatcher.CollectionWatcher<BasePart> = CollectionWatcher.new(COLLECTION_TAG)

PromptPart:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
	if not IS_SERVER then
		return
	end

	local promptText = object.context:GetAttribute("attr_prompt_text") :: string? or DEFAULT_PROMPT_TEXT
	local actionText = object.context:GetAttribute("attr_action_text") :: string? or DEFAULT_ACTION_TEXT
	local holdDuration = object.context:GetAttribute("attr_hold_duration") :: number? or DEFAULT_HOLD_DURATION
	local maxDistance = object.context:GetAttribute("attr_max_distance") :: number? or DEFAULT_MAX_DISTANCE
	local destroyOnTrigger = object.context:GetAttribute("attr_destroy_on_trigger") :: boolean? or DEFAULT_DESTROY_ON_TRIGGER

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = promptText
	prompt.ActionText = actionText
	prompt.HoldDuration = holdDuration
	prompt.MaxActivationDistance = maxDistance
	prompt.Parent = object.context

	local triggerConnection = prompt.Triggered:Connect(function(player: Player)
		PromptTriggered:Fire(player, object.context)

		if destroyOnTrigger then
			object.context:Destroy()
		end
	end)

	local attributeConnection = object.context.AttributeChanged:Connect(function(attributeName)
		if attributeName == "attr_prompt_text" then
			prompt.ObjectText = object.context:GetAttribute("attr_prompt_text") :: string? or DEFAULT_PROMPT_TEXT
		elseif attributeName == "attr_action_text" then
			prompt.ActionText = object.context:GetAttribute("attr_action_text") :: string? or DEFAULT_ACTION_TEXT
		elseif attributeName == "attr_hold_duration" then
			prompt.HoldDuration = object.context:GetAttribute("attr_hold_duration") :: number? or DEFAULT_HOLD_DURATION
		elseif attributeName == "attr_max_distance" then
			prompt.MaxActivationDistance = object.context:GetAttribute("attr_max_distance") :: number? or DEFAULT_MAX_DISTANCE
		end
	end)

	object.Destroyed:Once(function()
		triggerConnection:Disconnect()
		attributeConnection:Disconnect()
		prompt:Destroy()
	end)
end)

local module = {
	watcher = PromptPart,
	PromptTriggered = PromptTriggered,
}

return module
