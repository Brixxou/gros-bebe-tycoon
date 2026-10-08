--!strict
-- Écran de retour (spec, section 4) : « While you were away, your baby made 1.2M PoopCoins! ».
-- Le serveur a déjà crédité les PoopCoins ; l'écran l'annonce. (« Triple it » arrive en phase 3.)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Logic.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local New = require(script.Parent.New)
local Screen = require(script.Parent.Screen)
local Text = require(script.Parent.Parent.Text)
local Theme = require(script.Parent.Theme)

local WelcomePanel = {}

function WelcomePanel.start()
	local gui = Screen.create("WelcomePanel", 16)
	local frame = New("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(560, 320),
		BackgroundColor3 = Theme.colors.panel,
		Visible = false,
		Parent = gui,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 20) }),
		New(
			"UIStroke",
			{ Thickness = 5, Color = Theme.colors.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
		),
		New("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 16),
			Size = UDim2.new(1, 0, 0, 54),
			Font = Theme.fonts.title,
			Text = "Welcome back!",
			TextSize = 44,
			TextColor3 = Theme.colors.accent,
		}),
	})
	local body = New("TextLabel", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(30, 84),
		Size = UDim2.new(1, -60, 0, 120),
		Font = Theme.fonts.body,
		Text = "",
		TextSize = 30,
		TextWrapped = true,
		TextColor3 = Theme.colors.text,
		AutoLocalize = false,
		Parent = frame,
	})
	local ok = New("TextButton", {
		Name = "Ok",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(260, 70),
		BackgroundColor3 = Theme.colors.good,
		Font = Theme.fonts.title,
		Text = "Awesome!",
		TextSize = 34,
		TextColor3 = Theme.colors.white,
		Parent = frame,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 16) }),
	})
	ok.Activated:Connect(function()
		frame.Visible = false
	end)
	Net.event("WelcomeBack").OnClientEvent:Connect(function(gain: number)
		body.Text = Text.get("Welcome.Body", { Format.number(gain) })
		frame.Visible = true
	end)
end

return WelcomePanel
