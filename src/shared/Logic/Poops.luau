--!strict
-- Les cacas : valeur, taille, crédit au pot.
local Config = require("../Config/Economy")
local Data = require("./Data")
local Wallet = require("./Wallet")

type Profile = Data.Profile

local Poops = {}

-- Valeur d'un caca normal : le revenu de l'intervalle entre deux cacas.
function Poops.value(income: number): number
	return income * Config.poopInterval
end

-- Taille (facteur d'échelle) selon la valeur : de 1 à 4 sur une échelle logarithmique.
function Poops.size(value: number): number
	return math.clamp(1 + 0.3 * math.log10(math.max(value, 1)), 1, 4)
end

function Poops.credit(data: Profile, value: number)
	Wallet.earn(data, value)
	data.totalPoops += 1
end

return Poops
