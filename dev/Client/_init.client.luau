if not game:IsLoaded() then
    game.Loaded:Wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Attrify = require(ReplicatedStorage.Attrify)

Attrify.start()
