--!strict
-- Panneau géant d'un classement mondial : un titre et la liste défilante du top (rang, nom, score).
-- L'écran regarde vers -Z (le SurfaceGui est sur sa face avant) ; pivot au sol, au centre.
local Parts = require("./Parts")

local WIDTH = 28
local HEIGHT = 36
local LEGS = 4 -- hauteur des pieds sous l'écran
local PIXELS_PER_STUD = 25
local ROW_HEIGHT = 60 -- en pixels
local RANK_COLORS = { "#FFD700", "#E8E8E8", "#E8A06A" } -- or, argent, bronze

-- Une ligne du classement, déjà mise en forme.
export type Row = { name: string, score: string }

local Board = {}

local function surface(model: Model): SurfaceGui
	local screen = model:FindFirstChild("Screen") :: Part
	return screen:FindFirstChild("Gui") :: SurfaceGui
end

function Board.build(name: string, title: string, color: string): Model
	local model = Parts.model(name)
	local middle = LEGS + HEIGHT / 2
	for _, x in { -WIDTH / 2 + 2, WIDTH / 2 - 2 } do
		Parts.block(model, "Leg", Vector3.new(1.5, LEGS, 1.5), Vector3.new(x, LEGS / 2, 0), "#FFFFFF")
	end
	local border = Vector3.new(WIDTH + 1.6, HEIGHT + 1.6, 0.8)
	Parts.block(model, "Border", border, Vector3.new(0, middle, 0.6), "#FFFFFF")
	local size = Vector3.new(WIDTH, HEIGHT, 1)
	local screen = Parts.block(model, "Screen", size, Vector3.new(0, middle, 0), color)

	local gui = Instance.new("SurfaceGui")
	gui.Name = "Gui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = PIXELS_PER_STUD
	gui.LightInfluence = 0
	gui.Parent = screen

	local heading = Parts.label(gui, "Title", title, Enum.Font.LuckiestGuy, "#FFFFFF")
	heading.Size = UDim2.new(1, 0, 0, 120)

	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(24, 130)
	list.Size = UDim2.new(1, -48, 1, -150)
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 14
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local status = Parts.label(gui, "Status", "Loading...", Enum.Font.FredokaOne, "#FFFFFF")
	status.Position = UDim2.fromOffset(0, 150)
	status.Size = UDim2.new(1, 0, 0, 70)
	return model
end

-- Remplace les lignes du panneau ; sans ligne, il affiche « Loading... ».
function Board.render(model: Model, rows: { Row })
	local gui = surface(model)
	local list = gui:FindFirstChild("List") :: ScrollingFrame
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for rank, row in rows do
		local line = Instance.new("Frame")
		line.Name = "Row" .. rank
		line.LayoutOrder = rank
		line.BackgroundColor3 = Color3.fromHex("#FFFFFF")
		line.BackgroundTransparency = if rank % 2 == 1 then 0.85 else 1
		line.BorderSizePixel = 0
		line.Size = UDim2.new(1, -18, 0, ROW_HEIGHT)
		local rankColor = RANK_COLORS[rank] or "#FFFFFF"
		local place = Parts.label(line, "Rank", "#" .. rank, Enum.Font.LuckiestGuy, rankColor)
		place.Size = UDim2.fromScale(0.16, 1)
		local who = Parts.label(line, "Player", row.name, Enum.Font.FredokaOne, "#FFFFFF")
		who.Position = UDim2.fromScale(0.17, 0)
		who.Size = UDim2.fromScale(0.53, 1)
		who.TextXAlignment = Enum.TextXAlignment.Left
		local score = Parts.label(line, "Score", row.score, Enum.Font.LuckiestGuy, "#FFE66D")
		score.Position = UDim2.fromScale(0.7, 0)
		score.Size = UDim2.fromScale(0.3, 1)
		score.TextXAlignment = Enum.TextXAlignment.Right
		for _, label in { place, who, score } do
			label.AutoLocalize = false -- des noms et des nombres, rien à traduire
		end
		line.Parent = list
	end
	local status = gui:FindFirstChild("Status") :: TextLabel
	status.Visible = #rows == 0
end

return Board
