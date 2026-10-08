--!strict
-- Étapes du tutoriel des nouveaux joueurs (spec, section 4), dans l'ordre. Les étapes « œuf » et « pet » de
-- la spec arriveront avec les pets (phase 4), juste avant la fin.
-- goal : ce qui valide l'étape. "buttons", "clicks", "diaper" : ce compteur du profil (boutons achetés, clics,
-- couche) atteint `count` ; "poop" : un caca arrive au pot pendant l'étape.
-- target : chemin, depuis la nursery, de la pièce que montre la flèche. Texte : clé "Tutorial.<id>".

export type Step = { id: string, goal: string, count: number, target: string }

local steps: { Step } = {
	{ id = "bottle", goal = "buttons", count = 1, target = "PadActive.Disk" },
	{ id = "push", goal = "clicks", count = 10, target = "Baby.Diaper" },
	{ id = "poop", goal = "poop", count = 1, target = "Potty.Sensor" },
	{ id = "carrot", goal = "buttons", count = 2, target = "PadActive.Disk" },
	{ id = "camo", goal = "diaper", count = 2, target = "ChangingTable.Top" },
}

return {
	reward = 25, -- Tétines données à la fin du tutoriel
	steps = steps,
}
