--!strict
-- Meubles fixes de la nursery : le tapis roulant, le pot géant, la table à langer.
local Parts = require("./Parts")

local Furniture = {}

-- Tapis roulant surélevé (dessus à 6 studs), dans l'axe X. La pièce « Belt » sert de convoyeur.
function Furniture.belt(length: number, width: number): Model
	local model = Parts.model("Conveyor")
	Parts.block(
		model,
		"Belt",
		Vector3.new(length, 1, width),
		Vector3.new(0, 5.5, 0),
		"#5C5470",
		"DiamondPlate"
	)
	local railZ = width / 2 + 0.3
	Parts.block(model, "RailLeft", Vector3.new(length, 1.5, 0.6), Vector3.new(0, 6.75, -railZ), "#FFD166")
	Parts.block(model, "RailRight", Vector3.new(length, 1.5, 0.6), Vector3.new(0, 6.75, railZ), "#FFD166")
	local legs = math.floor(length / 8)
	for index = 0, legs do
		local x = -length / 2 + 1 + index * (length - 2) / legs
		Parts.block(model, "Leg" .. index, Vector3.new(1, 5, 1), Vector3.new(x, 2.5, 0), "#B8A9C9")
	end
	return model
end

-- Pot géant. Le dossier est du côté +X ; la pièce invisible « Sensor » crédite les cacas qui la touchent.
function Furniture.potty(): Model
	local model = Parts.model("Potty")
	Parts.cylinder(model, "Base", 3, 10, Vector3.new(0, 1.5, 0), "#FFFFFF")
	Parts.cylinder(model, "Bowl", 1.4, 12, Vector3.new(0, 3.7, 0), "#A0E7E5")
	Parts.cylinder(model, "Hole", 0.2, 9, Vector3.new(0, 4.45, 0), "#5C3D2E")
	Parts.block(model, "Back", Vector3.new(1.6, 8, 10), Vector3.new(6.2, 6, 0), "#A0E7E5")
	Parts.ball(model, "HandleLeft", 1.4, Vector3.new(3, 5.2, -5.6), "#FFD166")
	Parts.ball(model, "HandleRight", 1.4, Vector3.new(3, 5.2, 5.6), "#FFD166")
	local sensor = Parts.block(model, "Sensor", Vector3.new(14, 10, 14), Vector3.new(0, 5, 0), "#FFFFFF")
	sensor.Transparency = 1
	sensor.CanCollide = false
	sensor.CanQuery = false
	return model
end

-- Table à langer, avec une ProximityPrompt (attribut Kind = "ChangingTable") qui ouvre le panneau des couches.
function Furniture.changingTable(): Model
	local model = Parts.model("ChangingTable")
	for index, corner in
		{
			Vector3.new(-3.6, 0, -1.8),
			Vector3.new(3.6, 0, -1.8),
			Vector3.new(-3.6, 0, 1.8),
			Vector3.new(3.6, 0, 1.8),
		}
	do
		Parts.block(model, "Leg" .. index, Vector3.new(0.8, 4, 0.8), corner + Vector3.new(0, 2, 0), "#FFFFFF")
	end
	Parts.block(model, "Shelf", Vector3.new(7.6, 0.4, 3.8), Vector3.new(0, 1.2, 0), "#FFC8DD")
	local top = Parts.block(model, "Top", Vector3.new(8.4, 1, 4.6), Vector3.new(0, 4.5, 0), "#FFC8DD")
	Parts.block(model, "Cushion", Vector3.new(7.6, 0.6, 3.8), Vector3.new(0, 5.3, 0), "#FFFFFF")
	Parts.block(model, "Diapers", Vector3.new(2, 1.2, 2), Vector3.new(-2.4, 6.2, 0), "#A0C4FF")
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Sign"
	billboard.Size = UDim2.fromOffset(240, 50)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	billboard.MaxDistance = 100
	billboard.Adornee = top
	billboard.Parent = top
	Parts.label(billboard, "Title", "Changing Table", Enum.Font.LuckiestGuy, "#FFFFFF")
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Change Diaper"
	prompt.ObjectText = "Changing Table"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Kind", "ChangingTable")
	prompt.Parent = top
	return model
end

return Furniture
