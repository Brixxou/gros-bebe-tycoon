--!strict
-- Guide du tutoriel (spec, section 4) : une bulle en bas de l'écran avec la consigne de l'étape en cours, et une
-- flèche lumineuse (Beam) du personnage vers ce qu'il faut viser. L'étape vient de l'état du serveur.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MyPlot = require(script.Parent.Parent.MyPlot)
local New = require(script.Parent.New)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.Parent.State)
local Text = require(script.Parent.Parent.Text)
local Theme = require(script.Parent.Theme)
local TutorialConfig = require(ReplicatedStorage.Shared.Config.Tutorial)

local REFRESH_EVERY = 1 -- secondes : la flèche suit un personnage qui réapparaît ou une base qui se réplique

local TutorialGuide = {}

local bubble: TextLabel? = nil
local beam: Beam? = nil

local function clearBeam()
	local current = beam
	if current then
		local target = current.Attachment1
		current:Destroy()
		if target then
			target:Destroy()
		end
		beam = nil
	end
end

-- Flèche du personnage vers la pièce `path` de la nursery, refaite si la cible ou le personnage a changé.
local function pointAt(path: string)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local target = MyPlot.path(path)
	if root == nil or target == nil then
		clearBeam()
		return
	end
	local current = beam
	if current and current.Attachment0 and current.Attachment1 then
		if current.Attachment0.Parent == root and current.Attachment1.Parent == target then
			return -- déjà en place
		end
	end
	clearBeam()
	local from = root:FindFirstChild("TutorialFrom")
		or New("Attachment", { Name = "TutorialFrom", Parent = root })
	local to = New("Attachment", { Name = "TutorialTo", Parent = target })
	-- Flèche droite : une courbe suivrait l'axe X de chaque Attachment, qui pointe vers le haut sur une pièce
	-- couchée (la dalle) et plongerait dans le sol. Lumière non additive pour rester visible sur le sol clair.
	beam = New("Beam", {
		Name = "TutorialBeam",
		Attachment0 = from,
		Attachment1 = to,
		Color = ColorSequence.new(Theme.colors.push, Theme.colors.accent),
		Transparency = NumberSequence.new(0.1),
		Width0 = 1.2,
		Width1 = 1.2,
		Segments = 12,
		FaceCamera = true,
		LightEmission = 0.3,
		LightInfluence = 0,
		Parent = target,
	})
end

local function render()
	local label = bubble
	if label == nil then
		return
	end
	local snapshot = State.current
	local step = if snapshot then TutorialConfig.steps[snapshot.tutorial] else nil
	if snapshot == nil or step == nil then
		label.Visible = false
		clearBeam()
		return
	end
	label.Text = Text.get("Tutorial." .. step.id, { math.min(snapshot.totalClicks, step.count) })
	label.Visible = true
	pointAt(step.target)
end

function TutorialGuide.start()
	local gui = Screen.create("TutorialGuide", 12)
	bubble = New("TextLabel", {
		Name = "Bubble",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(640, 70),
		BackgroundColor3 = Theme.colors.panel,
		Font = Theme.fonts.body,
		Text = "",
		TextSize = 26,
		TextWrapped = true,
		TextColor3 = Theme.colors.text,
		AutoLocalize = false,
		Visible = false,
		Parent = gui,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 16) }),
		New(
			"UIStroke",
			{ Thickness = 3, Color = Theme.colors.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
		),
		New("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
	})
	State.changed:connect(render)
	task.spawn(function()
		while true do
			render()
			task.wait(REFRESH_EVERY)
		end
	end)
end

return TutorialGuide
