local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

return function()
	beforeAll(function(context)
		context.mockCharacter = Players:CreateHumanoidModelFromUserId(1)
		context.localPlayer = Players:GetChildren()[1]

		-- LocalPlayer will only be present in a team create session
		if not context.localPlayer then
			return
		end

		context.character = Players:CreateHumanoidModelFromUserId(
			context.localPlayer.CharacterAppearanceId
		)
		context.character.Parent = Workspace
		context.localPlayer.Character = context.character
	end)

	afterAll(function(context)
		if not context.localPlayer then
			return
		end

		context.localPlayer.Character = nil
		context.character:Destroy()
	end)
end
