--!strict
-- Point d'entrée du client.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Version = require(ReplicatedStorage.Shared.Logic.Version)

print("[BigBaby] client démarré : " .. Version.label())
