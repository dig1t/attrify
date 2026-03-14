-- WIP module

local RunService = game:GetService("RunService")

if RunService:IsServer() then
	return require(script.WeaponServer)
else
	return require(script.WeaponClient)
end
