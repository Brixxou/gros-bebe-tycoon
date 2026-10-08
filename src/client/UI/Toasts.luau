--!strict
-- Messages courts en haut de l'écran, qui disparaissent seuls.
local TweenService = game:GetService("TweenService")

local New = require(script.Parent.New)
local Screen = require(script.Parent.Screen)
local Theme = require(script.Parent.Theme)

local Toasts = {}

local container: Frame? = nil

function Toasts.start()
	local gui = Screen.create("Toasts", 20)
	container = New("Frame", {
		Name = "List",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 150),
		Size = UDim2.fromOffset(560, 300),
		Parent = gui,
	}, {
		New("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

function Toasts.show(text: string)
	local list = container
	if list == nil then
		return
	end
	local label = New("TextLabel", {
		BackgroundColor3 = Theme.colors.panel,
		Size = UDim2.fromOffset(540, 46),
		Font = Theme.fonts.body,
		Text = text,
		TextSize = 24,
		TextColor3 = Theme.colors.text,
		AutoLocalize = false,
		Parent = list,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 12) }),
		New("UIStroke", {
			Thickness = 2,
			Color = Theme.colors.stroke,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	})
	task.delay(2.5, function()
		local tween = TweenService:Create(
			label,
			TweenInfo.new(0.4),
			{ BackgroundTransparency = 1, TextTransparency = 1 }
		)
		tween:Play()
		tween.Completed:Wait()
		label:Destroy()
	end)
end

return Toasts
