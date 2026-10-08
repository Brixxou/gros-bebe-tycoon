--!strict
-- Les 10 couches, achetées dans l'ordre à la table à langer (spec, section 3).
-- mult : multiplicateur de PoopCoins. Matériaux : noms d'Enum.Material.

export type Diaper = {
	id: string,
	name: string,
	mult: number,
	price: number,
	color: string,
	material: string,
	poopColor: string,
	poopMaterial: string,
}

-- stylua: ignore
local Diapers: { Diaper } = {
	{ id = "cloth", name = "Cloth", mult = 1, price = 0, color = "#FFFFFF", material = "SmoothPlastic", poopColor = "#7B4A2A", poopMaterial = "SmoothPlastic" },
	{ id = "camo", name = "Camo", mult = 2, price = 400, color = "#6B8E4E", material = "SmoothPlastic", poopColor = "#6E4B2A", poopMaterial = "SmoothPlastic" },
	{ id = "gold", name = "Gold", mult = 3.5, price = 6_000, color = "#FFD700", material = "Foil", poopColor = "#FFC300", poopMaterial = "Foil" },
	{ id = "diamond", name = "Diamond", mult = 6.5, price = 80_000, color = "#B9F2FF", material = "Glass", poopColor = "#8EE3F5", poopMaterial = "Glass" },
	{ id = "lava", name = "Lava", mult = 12, price = 1_000_000, color = "#FF5A1F", material = "Neon", poopColor = "#FF7B00", poopMaterial = "Neon" },
	{ id = "rainbow", name = "Rainbow", mult = 24, price = 12_000_000, color = "#FF5FA2", material = "SmoothPlastic", poopColor = "#FF5FA2", poopMaterial = "SmoothPlastic" },
	{ id = "neon", name = "Neon", mult = 45, price = 150_000_000, color = "#39FF14", material = "Neon", poopColor = "#39FF14", poopMaterial = "Neon" },
	{ id = "unicorn", name = "Unicorn", mult = 85, price = 2_000_000_000, color = "#E0BBE4", material = "Glass", poopColor = "#FFB7F5", poopMaterial = "Neon" },
	{ id = "galaxy", name = "Galaxy", mult = 160, price = 9_000_000_000, color = "#3A0CA3", material = "ForceField", poopColor = "#7209B7", poopMaterial = "Neon" },
	{ id = "cosmic", name = "Cosmic", mult = 300, price = 25_000_000_000, color = "#F72585", material = "Neon", poopColor = "#4CC9F0", poopMaterial = "Neon" },
}

return Diapers
