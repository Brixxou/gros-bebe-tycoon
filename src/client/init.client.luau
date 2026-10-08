--!strict
-- Point d'entrée du client.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage:WaitForChild("Remotes")

local Banner = require(script.UI.Banner)
local DiaperPanel = require(script.UI.DiaperPanel)
local Effects = require(script.Effects.Effects)
local Hud = require(script.UI.Hud)
local RebirthPanel = require(script.UI.RebirthPanel)
local State = require(script.State)
local Toasts = require(script.UI.Toasts)
local Version = require(ReplicatedStorage.Shared.Logic.Version)
local WelcomePanel = require(script.UI.WelcomePanel)

State.start()
Toasts.start()
Hud.start()
DiaperPanel.start()
RebirthPanel.start()
WelcomePanel.start()
Banner.start()
Effects.start()

print("[BigBaby] client démarré : " .. Version.label())
