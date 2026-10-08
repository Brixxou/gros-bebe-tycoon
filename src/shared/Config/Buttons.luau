--!strict
-- Les 22 boutons de la nursery, dans l'ordre d'achat (spec, section 2).
-- name : texte source anglais (traduit via Localization.csv, clé "Button.<id>").
-- rate : production de base par seconde (machines) ; bonus : bonus de PoopCoins additif (décos).
-- color / accent : couleurs du modèle en hexadécimal.

export type Button = {
	id: string,
	kind: string, -- "machine" ou "decor"
	name: string,
	price: number,
	rate: number,
	bonus: number,
	color: string,
	accent: string,
}

-- stylua: ignore
local Buttons: { Button } = {
	{ id = "milk_bottle", kind = "machine", name = "Milk Bottle", price = 0, rate = 1, bonus = 0, color = "#9AD0F5", accent = "#FFFFFF" },
	{ id = "carrot_mash", kind = "machine", name = "Carrot Mash", price = 50, rate = 3, bonus = 0, color = "#FFB347", accent = "#FF8C1A" },
	{ id = "play_mat", kind = "decor", name = "Play Mat", price = 100, rate = 0, bonus = 0.05, color = "#B5EAD7", accent = "#FFDAC1" },
	{ id = "applesauce_fountain", kind = "machine", name = "Applesauce Fountain", price = 300, rate = 8, bonus = 0, color = "#F6E27F", accent = "#C9E265" },
	{ id = "pastel_walls", kind = "decor", name = "Pastel Walls", price = 600, rate = 0, bonus = 0.05, color = "#FFD1DC", accent = "#FFFFFF" },
	{ id = "cereal_cannon", kind = "machine", name = "Cereal Cannon", price = 1_500, rate = 20, bonus = 0, color = "#F4A261", accent = "#E9C46A" },
	{ id = "crib", kind = "decor", name = "Crib", price = 3_000, rate = 0, bonus = 0.05, color = "#FFFFFF", accent = "#A0C4FF" },
	{ id = "nugget_printer", kind = "machine", name = "Nugget Printer", price = 7_500, rate = 50, bonus = 0, color = "#E76F51", accent = "#F4C430" },
	{ id = "musical_mobile", kind = "decor", name = "Musical Mobile", price = 15_000, rate = 0, bonus = 0.05, color = "#CDB4DB", accent = "#FFC8DD" },
	{ id = "spaghetti_waterfall", kind = "machine", name = "Spaghetti Waterfall", price = 40_000, rate = 125, bonus = 0, color = "#F7D794", accent = "#E63946" },
	{ id = "toy_box", kind = "decor", name = "Toy Box", price = 80_000, rate = 0, bonus = 0.05, color = "#A0C4FF", accent = "#FFADAD" },
	{ id = "pizza_launcher", kind = "machine", name = "Pizza Launcher", price = 200_000, rate = 300, bonus = 0, color = "#E63946", accent = "#F4D35E" },
	{ id = "rocking_horse", kind = "decor", name = "Rocking Horse", price = 400_000, rate = 0, bonus = 0.05, color = "#FFADAD", accent = "#FDFFB6" },
	{ id = "taco_tornado", kind = "machine", name = "Taco Tornado", price = 1_000_000, rate = 750, bonus = 0, color = "#F4D35E", accent = "#6A994E" },
	{ id = "ball_pit", kind = "decor", name = "Ball Pit", price = 2_000_000, rate = 0, bonus = 0.05, color = "#BDE0FE", accent = "#FFAFCC" },
	{ id = "bean_reactor", kind = "machine", name = "Bean Reactor", price = 5_000_000, rate = 1_800, bonus = 0, color = "#6A994E", accent = "#8D5524" },
	{ id = "slide", kind = "decor", name = "Slide", price = 10_000_000, rate = 0, bonus = 0.05, color = "#FFC8DD", accent = "#A2D2FF" },
	{ id = "cheese_volcano", kind = "machine", name = "Cheese Volcano", price = 25_000_000, rate = 4_500, bonus = 0, color = "#FFD166", accent = "#FFB703" },
	{ id = "giant_teddy", kind = "decor", name = "Giant Teddy", price = 50_000_000, rate = 0, bonus = 0.05, color = "#C68B59", accent = "#8D5524" },
	{ id = "burger_black_hole", kind = "machine", name = "Burger Black Hole", price = 125_000_000, rate = 11_000, bonus = 0, color = "#3D2C8D", accent = "#C77DFF" },
	{ id = "bouncy_castle", kind = "decor", name = "Bouncy Castle", price = 250_000_000, rate = 0, bonus = 0.05, color = "#FF6B6B", accent = "#4ECDC4" },
	{ id = "galactic_baby_food", kind = "machine", name = "Galactic Baby Food", price = 600_000_000, rate = 27_000, bonus = 0, color = "#7209B7", accent = "#4CC9F0" },
}

return Buttons
