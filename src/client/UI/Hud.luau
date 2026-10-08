--!strict
-- HUD : PoopCoins, revenu et Tétines en haut ; bouton PUSH! en bas à droite (au-dessus du saut mobile) ;
-- bouton « My Base » à gauche.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config.Economy)
local Economy = require(ReplicatedStorage.Shared.Logic.Economy)
local Format = require(ReplicatedStorage.Shared.Logic.Format)
local MyPlot = require(script.Parent.Parent.MyPlot)
local Net = require(ReplicatedStorage.Shared.Net)
local New = require(script.Parent.New)
local RateLimit = require(ReplicatedStorage.Shared.Logic.RateLimit)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.Parent.State)
local Text = require(script.Parent.Parent.Text)
local Theme = require(script.Parent.Theme)

local Hud = {}

local limiter = RateLimit.new(Config.maxClicksPerSecond, Config.maxClicksPerSecond)

local function stroke(thickness: number): Instance
	return New("UIStroke", { Thickness = thickness, Color = Theme.colors.stroke })
end

local function label(props: { [string]: any }): any
	props.BackgroundTransparency = 1
	props.AutoLocalize = false
	return New("TextLabel", props, { stroke(3) })
end

local function goHome()
	local spawn = MyPlot.part("Spawn")
	local character = Players.LocalPlayer.Character
	if spawn and character then
		character:PivotTo(spawn.CFrame)
	end
end

-- Petit « +X » qui monte au-dessus du bouton PUSH!.
local function popText(parent: Instance, text: string)
	local pop = label({
		Size = UDim2.fromOffset(200, 40),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, math.random(-30, 30), 0, -6),
		Font = Theme.fonts.title,
		Text = text,
		TextSize = 30,
		TextColor3 = Theme.colors.coins,
		Parent = parent,
	})
	local info = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService
		:Create(pop, info, { Position = pop.Position - UDim2.fromOffset(0, 70), TextTransparency = 1 })
		:Play()
	task.delay(0.8, function()
		pop:Destroy()
	end)
end

function Hud.start()
	local gui = Screen.create("Hud", 10)

	local top = New("Frame", {
		Name = "Top",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(520, 130),
		Parent = gui,
	})
	local coins = label({
		Name = "Coins",
		Size = UDim2.new(1, 0, 0, 62),
		Font = Theme.fonts.title,
		Text = "💩 0",
		TextSize = 56,
		TextColor3 = Theme.colors.coins,
		Parent = top,
	})
	local income = label({
		Name = "Income",
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 0, 30),
		Font = Theme.fonts.body,
		Text = "",
		TextSize = 28,
		TextColor3 = Theme.colors.white,
		Parent = top,
	})
	local binkies = label({
		Name = "Binkies",
		Position = UDim2.fromOffset(0, 94),
		Size = UDim2.new(1, 0, 0, 28),
		Font = Theme.fonts.body,
		Text = "🍼 0",
		TextSize = 24,
		TextColor3 = Theme.colors.accent,
		Parent = top,
	})

	local push = New("TextButton", {
		Name = "Push",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -230),
		Size = UDim2.fromOffset(170, 170),
		BackgroundColor3 = Theme.colors.push,
		Font = Theme.fonts.title,
		Text = "PUSH!",
		TextSize = 44,
		TextColor3 = Theme.colors.white,
		AutoButtonColor = true,
		Parent = gui,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		New(
			"UIStroke",
			{ Thickness = 5, Color = Theme.colors.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
		),
	})
	local pushScale = New("UIScale", { Parent = push })
	push.Activated:Connect(function()
		if not RateLimit.allow(limiter, "push", os.clock()) then
			return
		end
		Net.event("Click"):FireServer()
		pushScale.Scale = 0.9
		TweenService:Create(pushScale, TweenInfo.new(0.15), { Scale = 1 }):Play()
		local snapshot = State.current
		if snapshot then
			popText(push, "+" .. Format.number(Economy.clickValue(snapshot.income)))
		end
	end)

	local home = New("TextButton", {
		Name = "MyBase",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		Size = UDim2.fromOffset(170, 60),
		BackgroundColor3 = Theme.colors.accent,
		Font = Theme.fonts.title,
		Text = "My Base",
		TextSize = 28,
		TextColor3 = Theme.colors.white,
		Parent = gui,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 14) }),
		New(
			"UIStroke",
			{ Thickness = 4, Color = Theme.colors.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
		),
	})
	home.Activated:Connect(goHome)

	State.changed:connect(function(snapshot: Net.Snapshot)
		coins.Text = "💩 " .. Format.number(snapshot.coins)
		income.Text = Text.get("HUD.Income", { Format.number(snapshot.income) })
		binkies.Text = "🍼 " .. Format.number(snapshot.binkies)
	end)
end

return Hud
