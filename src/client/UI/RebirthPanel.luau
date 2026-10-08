--!strict
-- Panneau Rebirth (spec, section 4) : les conditions, le multiplicateur actuel → le suivant, la récompense, ce
-- qui est perdu ou gardé. Le bouton se clique deux fois : le premier clic demande confirmation.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Diapers = require(ReplicatedStorage.Shared.Config.Diapers)
local Format = require(ReplicatedStorage.Shared.Logic.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local New = require(script.Parent.New)
local Rebirth = require(ReplicatedStorage.Shared.Logic.Rebirth)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.Parent.State)
local Text = require(script.Parent.Parent.Text)
local Theme = require(script.Parent.Theme)

local CONFIRM_SECONDS = 3

local RebirthPanel = {}

local panel: Frame? = nil
local button: TextButton? = nil
local lines: { [string]: TextLabel } = {}
local confirmUntil = 0

local function mark(ok: boolean): string
	return if ok then "✅ " else "❌ "
end

local function render()
	local snapshot = State.current
	local action = button
	if snapshot == nil or action == nil then
		return
	end
	local rebirths = snapshot.rebirths
	local cost = Rebirth.cost(rebirths)
	lines.Diaper.Text = mark(snapshot.diaper >= #Diapers) .. Text.get("Rebirth.NeedDiaper")
	lines.Coins.Text = mark(snapshot.coins >= cost) .. Text.get("Rebirth.NeedCoins", { Format.number(cost) })
	local now = tostring(Rebirth.multiplier(rebirths))
	local after = tostring(Rebirth.multiplier(rebirths + 1))
	lines.Multiplier.Text = Text.get("Rebirth.Multiplier", { now, after })
	lines.Reward.Text = Text.get("Rebirth.Reward", { Rebirth.reward(rebirths + 1) })
	local ready = Rebirth.blocker(snapshot.diaper, snapshot.coins, rebirths) == nil
	action.BackgroundColor3 = if ready then Theme.colors.good else Theme.colors.muted
	action.Text = Text.get(if os.clock() < confirmUntil then "Rebirth.Confirm" else "Rebirth.Button")
end

-- Premier clic : demande confirmation ; deuxième clic dans les 3 s : envoie le rebirth.
local function press()
	local snapshot = State.current
	if snapshot == nil or Rebirth.blocker(snapshot.diaper, snapshot.coins, snapshot.rebirths) ~= nil then
		return
	end
	if os.clock() < confirmUntil then
		confirmUntil = 0
		Net.event("Rebirth"):FireServer()
		RebirthPanel.close()
		return
	end
	confirmUntil = os.clock() + CONFIRM_SECONDS
	render()
	task.delay(CONFIRM_SECONDS, render)
end

-- Ligne de texte du panneau, remplie par render().
local function line(parent: Instance, name: string, y: number, height: number, font: Enum.Font, color: Color3)
	lines[name] = New("TextLabel", {
		Name = name,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(30, y),
		Size = UDim2.new(1, -60, 0, height),
		Font = font,
		Text = "",
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = color,
		AutoLocalize = false,
		Parent = parent,
	})
end

function RebirthPanel.open()
	if panel then
		confirmUntil = 0
		panel.Visible = true
		render()
	end
end

function RebirthPanel.close()
	if panel then
		panel.Visible = false
	end
end

function RebirthPanel.start()
	local gui = Screen.create("RebirthPanel", 15)
	local frame = New("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(600, 560),
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
			Position = UDim2.fromOffset(0, 10),
			Size = UDim2.new(1, 0, 0, 54),
			Font = Theme.fonts.title,
			Text = "Rebirth",
			TextSize = 44,
			TextColor3 = Theme.colors.rebirth,
		}),
	})
	panel = frame
	local close = New("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(48, 48),
		BackgroundColor3 = Theme.colors.accent,
		Font = Theme.fonts.title,
		Text = "X",
		TextSize = 28,
		TextColor3 = Theme.colors.white,
		AutoLocalize = false,
		Parent = frame,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
	})
	close.Activated:Connect(RebirthPanel.close)

	line(frame, "Diaper", 86, 40, Theme.fonts.body, Theme.colors.text)
	line(frame, "Coins", 132, 40, Theme.fonts.body, Theme.colors.text)
	line(frame, "Multiplier", 196, 52, Theme.fonts.title, Theme.colors.rebirth)
	line(frame, "Reward", 254, 40, Theme.fonts.title, Theme.colors.accent)
	line(frame, "Lose", 322, 34, Theme.fonts.body, Theme.colors.text)
	line(frame, "Keep", 362, 34, Theme.fonts.body, Theme.colors.text)
	lines.Lose.Text = Text.get("Rebirth.Lose")
	lines.Keep.Text = Text.get("Rebirth.Keep")

	local action = New("TextButton", {
		Name = "Go",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -28),
		Size = UDim2.fromOffset(360, 84),
		BackgroundColor3 = Theme.colors.muted,
		Font = Theme.fonts.title,
		Text = "",
		TextSize = 34,
		TextColor3 = Theme.colors.white,
		AutoLocalize = false,
		Parent = frame,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 18) }),
		New(
			"UIStroke",
			{ Thickness = 4, Color = Theme.colors.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
		),
	})
	action.Activated:Connect(press)
	button = action
	State.changed:connect(function()
		if frame.Visible then
			render()
		end
	end)
end

return RebirthPanel
