--!strict
-- Panneau de la table à langer : les 10 couches, et le bouton pour acheter la suivante.
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Diapers = require(ReplicatedStorage.Shared.Config.Diapers)
local Format = require(ReplicatedStorage.Shared.Logic.Format)
local MyPlot = require(script.Parent.Parent.MyPlot)
local Net = require(ReplicatedStorage.Shared.Net)
local New = require(script.Parent.New)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.Parent.State)
local Text = require(script.Parent.Parent.Text)
local Theme = require(script.Parent.Theme)
local Toasts = require(script.Parent.Toasts)

type Row = { status: TextLabel, buy: TextButton }

local DiaperPanel = {}

local panel: Frame? = nil
local rows: { Row } = {}

local function render()
	local snapshot = State.current
	if snapshot == nil then
		return
	end
	for index, diaper in Diapers do
		local row = rows[index]
		local isNext = index == snapshot.diaper + 1
		row.buy.Visible = isNext
		row.status.Visible = not isNext
		if index < snapshot.diaper then
			row.status.Text = Text.get("Table.Owned")
		elseif index == snapshot.diaper then
			row.status.Text = Text.get("Table.Wearing")
		elseif isNext then
			row.buy.Text = Text.get("Table.Buy", { Format.number(diaper.price) })
			row.buy.BackgroundColor3 = if snapshot.coins >= diaper.price
				then Theme.colors.good
				else Theme.colors.muted
		else
			row.status.Text = "🔒 " .. Format.number(diaper.price)
		end
	end
end

local function buildRow(list: Instance, index: number): Row
	local diaper = Diapers[index]
	local row = New("Frame", {
		Name = "Row" .. index,
		LayoutOrder = index,
		BackgroundColor3 = Theme.colors.white,
		Size = UDim2.new(1, -12, 0, 52),
		Parent = list,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 10) }),
		New("Frame", {
			Name = "Swatch",
			BackgroundColor3 = Color3.fromHex(diaper.color),
			Position = UDim2.fromOffset(10, 8),
			Size = UDim2.fromOffset(36, 36),
		}, {
			New("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			New("UIStroke", { Thickness = 2, Color = Theme.colors.stroke }),
		}),
		New("TextLabel", {
			Name = "DiaperName",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(56, 0),
			Size = UDim2.fromScale(0.45, 1),
			Font = Theme.fonts.title,
			Text = diaper.name,
			TextSize = 26,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.colors.text,
		}),
		New("TextLabel", {
			Name = "Mult",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.fromScale(0.15, 1),
			Font = Theme.fonts.body,
			Text = "x" .. tostring(diaper.mult),
			TextSize = 24,
			TextColor3 = Theme.colors.text,
			AutoLocalize = false,
		}),
	})
	local status = New("TextLabel", {
		Name = "Status",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(170, 40),
		Font = Theme.fonts.body,
		Text = "",
		TextSize = 22,
		TextColor3 = Theme.colors.text,
		AutoLocalize = false,
		Parent = row,
	})
	local buy = New("TextButton", {
		Name = "Buy",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(170, 40),
		BackgroundColor3 = Theme.colors.good,
		Font = Theme.fonts.title,
		Text = "",
		TextSize = 20,
		TextColor3 = Theme.colors.white,
		AutoLocalize = false,
		Visible = false,
		Parent = row,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 10) }),
	})
	buy.Activated:Connect(function()
		Net.event("BuyDiaper"):FireServer()
	end)
	return { status = status, buy = buy }
end

function DiaperPanel.open()
	if panel then
		panel.Visible = true
		render()
	end
end

function DiaperPanel.close()
	if panel then
		panel.Visible = false
	end
end

function DiaperPanel.start()
	local gui = Screen.create("DiaperPanel", 15)
	local frame = New("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(600, 640),
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
			Text = "Changing Table",
			TextSize = 42,
			TextColor3 = Theme.colors.accent,
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
	close.Activated:Connect(DiaperPanel.close)
	local list = New("ScrollingFrame", {
		Name = "List",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 76),
		Size = UDim2.new(1, -24, 1, -88),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8,
		Parent = frame,
	}, {
		New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for index = 1, #Diapers do
		rows[index] = buildRow(list, index)
	end

	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
		local slot = MyPlot.get()
		if prompt:GetAttribute("Kind") == "ChangingTable" and slot and prompt:IsDescendantOf(slot) then
			DiaperPanel.open()
		end
	end)
	State.changed:connect(function(snapshot: Net.Snapshot, previous: Net.Snapshot?)
		render()
		if previous and snapshot.diaper > previous.diaper then
			local name = Text.get("Diaper." .. Diapers[snapshot.diaper].id)
			Toasts.show(Text.get("Toast.NewDiaper", { name }))
		end
	end)
end

return DiaperPanel
