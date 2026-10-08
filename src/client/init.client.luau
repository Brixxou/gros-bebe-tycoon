--!strict
-- Point d'entrée du client.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage:WaitForChild("Remotes")

local DiaperPanel = require(script.UI.DiaperPanel)
local Effects = require(script.Effects.Effects)
local Hud = require(script.UI.Hud)
local State = require(script.State)
local Toasts = require(script.UI.Toasts)
local Version = require(ReplicatedStorage.Shared.Logic.Version)

State.start()
Toasts.start()
Hud.start()
DiaperPanel.start()
Effects.start()

print("[BigBaby] client démarré : " .. Version.label())
