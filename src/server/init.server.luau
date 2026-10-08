--!strict
-- Point d'entrée du serveur.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Version = require(ReplicatedStorage.Shared.Logic.Version)

print("[BigBaby] serveur démarré : " .. Version.label())
