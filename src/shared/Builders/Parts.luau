--!strict
-- Outils pour fabriquer des modèles cartoon avec des formes Roblox. Les pièces sont ancrées.

export type Props = {
	name: string?,
	shape: Enum.PartType?,
	size: Vector3,
	cframe: CFrame,
	color: string, -- hexadécimal
	material: string?, -- nom d'Enum.Material
	transparency: number?,
	collide: boolean?, -- true par défaut
}

local MATERIALS: { [string]: Enum.Material } = {
	SmoothPlastic = Enum.Material.SmoothPlastic,
	Neon = Enum.Material.Neon,
	Glass = Enum.Material.Glass,
	Foil = Enum.Material.Foil,
	ForceField = Enum.Material.ForceField,
	Fabric = Enum.Material.Fabric,
	Wood = Enum.Material.Wood,
	DiamondPlate = Enum.Material.DiamondPlate,
}

local Parts = {}

function Parts.material(name: string): Enum.Material
	return MATERIALS[name] or Enum.Material.SmoothPlastic
end

function Parts.make(parent: Instance, props: Props): Part
	local part = Instance.new("Part")
	part.Name = props.name or "Part"
	part.Shape = props.shape or Enum.PartType.Block
	part.Size = props.size
	part.CFrame = props.cframe
	part.Color = Color3.fromHex(props.color)
	part.Material = Parts.material(props.material or "SmoothPlastic")
	part.Transparency = props.transparency or 0
	part.Anchored = true
	part.CanCollide = props.collide ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Boule de diamètre `diameter` centrée en `position`.
function Parts.ball(
	parent: Instance,
	name: string,
	diameter: number,
	position: Vector3,
	color: string,
	material: string?
): Part
	return Parts.make(parent, {
		name = name,
		shape = Enum.PartType.Ball,
		size = Vector3.one * diameter,
		cframe = CFrame.new(position),
		color = color,
		material = material,
	})
end

-- Cylindre vertical (hauteur `height`, diamètre `diameter`) centré en `position`.
function Parts.cylinder(
	parent: Instance,
	name: string,
	height: number,
	diameter: number,
	position: Vector3,
	color: string,
	material: string?
): Part
	return Parts.make(parent, {
		name = name,
		shape = Enum.PartType.Cylinder,
		size = Vector3.new(height, diameter, diameter),
		cframe = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
		color = color,
		material = material,
	})
end

-- Pavé de taille `size` centré en `position`.
function Parts.block(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: string,
	material: string?
): Part
	return Parts.make(parent, {
		name = name,
		size = size,
		cframe = CFrame.new(position),
		color = color,
		material = material,
	})
end

-- Modèle vide dont le pivot est à l'origine (au sol, au centre).
function Parts.model(name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model.WorldPivot = CFrame.new()
	return model
end

-- Étiquette de texte (dans un BillboardGui ou un SurfaceGui), traduite automatiquement si le texte est
-- une source de Localization.csv.
function Parts.label(parent: Instance, name: string, text: string, font: Enum.Font, color: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = font
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = Color3.fromHex(color)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromHex("#3A2A4A")
	stroke.Parent = label
	label.Parent = parent
	return label
end

return Parts
