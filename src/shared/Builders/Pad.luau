--!strict
-- Dalle d'achat : un disque lumineux et une étiquette (« NEXT », nom de l'objet, prix).
local Parts = require("./Parts")

local AFFORDABLE = "#57CC99"
local TOO_EXPENSIVE = "#FF6B6B"

local Pad = {}

local function gui(model: Model): (Part, BillboardGui)
	local disk = model:FindFirstChild("Disk") :: Part
	return disk, disk:FindFirstChild("Label") :: BillboardGui
end

function Pad.build(name: string): Model
	local model = Parts.model(name)
	local disk = Parts.make(model, {
		name = "Disk",
		shape = Enum.PartType.Cylinder,
		size = Vector3.new(0.6, 8, 8),
		cframe = CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)),
		color = AFFORDABLE,
		material = "Neon",
		collide = false,
	})
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	-- Taille en studs : l'étiquette rapetisse avec la distance et ne chevauche pas celle de la dalle voisine.
	billboard.Size = UDim2.fromScale(9, 3.8)
	-- Décalage dans le repère du disque : il est couché, son axe X pointe vers le haut.
	billboard.StudsOffsetWorldSpace = Vector3.new(5, 0, 0)
	billboard.MaxDistance = 150
	billboard.Adornee = disk
	billboard.Parent = disk
	local tag = Parts.label(billboard, "Tag", "NEXT", Enum.Font.FredokaOne, "#FFFFFF")
	tag.Size = UDim2.fromScale(1, 0.25)
	local item = Parts.label(billboard, "Item", "", Enum.Font.LuckiestGuy, "#FFFFFF")
	item.Size = UDim2.fromScale(1, 0.45)
	item.Position = UDim2.fromScale(0, 0.25)
	local price = Parts.label(billboard, "Price", "", Enum.Font.FredokaOne, "#FFE66D")
	price.Size = UDim2.fromScale(1, 0.3)
	price.Position = UDim2.fromScale(0, 0.7)
	return model
end

-- Affiche un objet sur la dalle. `ghost` : aperçu du bouton suivant (transparent, avec « NEXT »).
function Pad.show(model: Model, itemName: string, priceText: string, ghost: boolean)
	local disk, billboard = gui(model)
	local item = billboard:FindFirstChild("Item") :: TextLabel
	local price = billboard:FindFirstChild("Price") :: TextLabel
	local tag = billboard:FindFirstChild("Tag") :: TextLabel
	item.Text = itemName
	price.Text = priceText
	tag.Visible = ghost
	disk.Transparency = if ghost then 0.75 else 0
	billboard.Enabled = true
end

function Pad.hide(model: Model)
	local disk, billboard = gui(model)
	disk.Transparency = 1
	billboard.Enabled = false
end

function Pad.setAffordable(model: Model, affordable: boolean)
	local disk = gui(model)
	disk.Color = Color3.fromHex(if affordable then AFFORDABLE else TOO_EXPENSIVE)
end

return Pad
