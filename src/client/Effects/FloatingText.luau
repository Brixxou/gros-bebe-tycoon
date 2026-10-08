--!strict
-- Texte qui monte et s'efface au-dessus d'un point du monde (« +1.2K »). Visible seulement par ce joueur.
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.UI.Theme)

local FloatingText = {}

function FloatingText.show(position: Vector3, text: string, color: Color3, textSize: number)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.CFrame = CFrame.new(position)

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(320, 80)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Adornee = anchor
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Theme.fonts.title
	label.Text = text
	label.TextColor3 = color
	label.TextSize = textSize
	label.AutoLocalize = false
	label.Parent = billboard

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Theme.colors.stroke
	stroke.Parent = label

	anchor.Parent = workspace
	local info = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(billboard, info, { StudsOffsetWorldSpace = Vector3.new(0, 6, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	task.delay(1.2, function()
		anchor:Destroy()
	end)
end

return FloatingText
