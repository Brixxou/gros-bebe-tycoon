--!strict
-- Effets envoyés par le serveur (Effect, Toast) et retour visuel des clics directs sur la couche du bébé.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Shared.Logic.Economy)
local FloatingText = require(script.Parent.FloatingText)
local Format = require(ReplicatedStorage.Shared.Logic.Format)
local MyPlot = require(script.Parent.Parent.MyPlot)
local Net = require(ReplicatedStorage.Shared.Net)
local Shake = require(script.Parent.Shake)
local State = require(script.Parent.Parent.State)
local Text = require(script.Parent.Parent.Text)
local Theme = require(script.Parent.Parent.UI.Theme)
local Toasts = require(script.Parent.Parent.UI.Toasts)

local Effects = {}

local hooked: ClickDetector? = nil

local function above(name: string, height: number): Vector3?
	local part = MyPlot.part(name)
	return if part then part.Position + Vector3.new(0, height, 0) else nil
end

local function onEffect(kind: string, value: number)
	if kind == "credit" then
		local position = above("Sensor", 6)
		if position then
			FloatingText.show(position, "+" .. Format.number(value), Theme.colors.coins, 34)
		end
	elseif kind == "mega" then
		Shake.play(0.5, 1.2)
		local position = above("Diaper", 10)
		if position then
			FloatingText.show(position, Text.get("Toast.MegaPoop"), Theme.colors.push, 56)
		end
	end
end

-- Clic direct sur la couche (ClickDetector) : le serveur compte le clic, le client affiche le gain prévu.
local function hookDiaper()
	local diaper = MyPlot.waitForPart("Diaper", 15)
	local detector = diaper and diaper:FindFirstChildOfClass("ClickDetector")
	if detector == nil or detector == hooked then
		return
	end
	hooked = detector
	detector.MouseClick:Connect(function()
		local snapshot = State.current
		local position = above("Diaper", 4)
		if snapshot and position then
			local gain = Economy.clickValue(snapshot.income)
			FloatingText.show(position, "+" .. Format.number(gain), Theme.colors.coins, 30)
		end
	end)
end

function Effects.start()
	Net.event("Effect").OnClientEvent:Connect(onEffect)
	Net.event("Toast").OnClientEvent:Connect(function(key: string, args: { any }?)
		Toasts.show(Text.get(key, args))
	end)
	Players.LocalPlayer:GetAttributeChangedSignal("Plot"):Connect(hookDiaper)
	task.spawn(hookDiaper)
end

return Effects
