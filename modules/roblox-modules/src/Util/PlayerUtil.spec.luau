local Players = game:GetService("Players")

local PlayerUtil = require(script.Parent.PlayerUtil)

return function()
	describe("Player Instance Util", function()
		if not Players:GetChildren()[1] then
			SKIP()
		end

		it("should return the player", function(context)
			local part = context.character:FindFirstChildWhichIsA("Part")
			local player = PlayerUtil.getPlayerFromPart(part)

			expect(player).to.equal(context.localPlayer)
		end)

		it("should not return the player", function()
			local part = Instance.new("Part")
			local player = PlayerUtil.getPlayerFromPart(part)

			expect(player).to.equal(nil)
		end)

		it("should not return a player", function()
			local player = PlayerUtil.getPlayerFromPart(nil)
			local player2 = PlayerUtil.getPlayerFromPart(Players)

			expect(player).to.equal(nil)
			expect(player2).to.equal(nil)
		end)
	end)

	describe("Character Util", function()
		it("should return a humanoid", function(context: { [any]: any })
			local humanoid = PlayerUtil.getHumanoid(context.mockCharacter)

			expect(humanoid).to.be.ok()
		end)

		it("should not return a humanoid", function()
			local humanoid = PlayerUtil.getHumanoid(Instance.new("Part"))

			expect(humanoid).to.equal(nil)
		end)

		it("should pass if a charcter is alive", function(context: { [any]: any })
			local isAlive = PlayerUtil.isAlive(context.mockCharacter)

			expect(isAlive).to.equal(true)
		end)

		it("should pass if a charcter is dead", function(context: { [any]: any })
			context.mockCharacter.Humanoid.Health = 0

			local isAlive = PlayerUtil.isAlive(context.mockCharacter)

			-- Reset the health
			context.mockCharacter.Humanoid.Health = 100

			expect(isAlive).to.equal(false)
		end)

		it("should have a humanoid", function(context: { [any]: any })
			local hasHumanoid = PlayerUtil.hasHumanoid(context.mockCharacter)

			expect(hasHumanoid).to.be.ok()
		end)
	end)
end
