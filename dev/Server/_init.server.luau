local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Attrify = require(ReplicatedStorage.Attrify)

Attrify.start()

Players.PlayerAdded:Connect(function(player)
    Attrify.setPlayerCheckpoint(player, 2)
end)