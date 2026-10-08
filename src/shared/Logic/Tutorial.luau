--!strict
-- Le tutoriel des nouveaux joueurs (spec, section 4). `data.tutorial` : 0 = pas commencé, 1…n = étape en cours
-- (index dans Config/Tutorial), Tutorial.DONE = terminé. Les étapes se valident d'après le profil ; l'étape
-- « poop » attend qu'un caca arrive au pot pendant qu'elle est affichée.
local Config = require("../Config/Tutorial")
local Data = require("./Data")

type Profile = Data.Profile

local Tutorial = {}

Tutorial.DONE = 99

-- Démarre le tutoriel d'un profil neuf ; un profil déjà avancé le saute.
function Tutorial.start(data: Profile)
	if data.tutorial == 0 then
		data.tutorial = if data.buttons == 0 and data.rebirths == 0 then 1 else Tutorial.DONE
	end
end

-- Étape en cours, ou nil (pas commencé ou terminé).
function Tutorial.step(data: Profile): Config.Step?
	return Config.steps[data.tutorial]
end

-- L'étape est-elle faite ? `poopArrived` : un caca vient d'arriver au pot.
function Tutorial.isComplete(step: Config.Step, data: Profile, poopArrived: boolean): boolean
	if step.goal == "buttons" then
		return data.buttons >= step.count
	elseif step.goal == "clicks" then
		return data.totalClicks >= step.count
	elseif step.goal == "diaper" then
		return data.diaper >= step.count
	elseif step.goal == "poop" then
		return poopArrived
	end
	return false
end

-- Valide autant d'étapes que possible. Renvoie les étapes validées, dans l'ordre, et les Tétines données
-- si le tutoriel vient de se terminer (0 sinon).
function Tutorial.advance(data: Profile, poopArrived: boolean): ({ Config.Step }, number)
	local completed = {}
	local step = Tutorial.step(data)
	while step and Tutorial.isComplete(step, data, poopArrived) do
		table.insert(completed, step)
		poopArrived = false -- un même caca ne valide qu'une étape
		data.tutorial += 1
		step = Tutorial.step(data)
	end
	if #completed > 0 and step == nil then
		data.tutorial = Tutorial.DONE
		data.binkies += Config.reward
		return completed, Config.reward
	end
	return completed, 0
end

return Tutorial
