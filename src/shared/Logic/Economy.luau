--!strict
-- Formules de revenu (spec, section 6).
local Buttons = require("../Config/Buttons")
local Config = require("../Config/Economy")
local Diapers = require("../Config/Diapers")
local Rebirth = require("./Rebirth")

export type IncomeInput = {
	buttons: number,
	diaper: number,
	rebirths: number,
	petBonus: number, -- somme des bonus des pets équipés (0.25 = +25 %)
	doubleCoins: boolean,
	vip: boolean,
	premium: boolean,
}

local Economy = {}

-- Production de base par seconde des machines achetées.
function Economy.production(buttons: number): number
	local total = 0
	for index = 1, math.min(buttons, #Buttons) do
		total += Buttons[index].rate
	end
	return total
end

function Economy.decorMultiplier(buttons: number): number
	local bonus = 0
	for index = 1, math.min(buttons, #Buttons) do
		bonus += Buttons[index].bonus
	end
	return 1 + bonus
end

function Economy.diaperMultiplier(diaper: number): number
	return Diapers[math.clamp(diaper, 1, #Diapers)].mult
end

-- Revenu de base/s : tous les multiplicateurs permanents, sans les boosts temporaires.
function Economy.baseIncome(input: IncomeInput): number
	local multiplier = Economy.diaperMultiplier(input.diaper)
		* Economy.decorMultiplier(input.buttons)
		* Rebirth.multiplier(input.rebirths)
		* (1 + input.petBonus)
	if input.doubleCoins then
		multiplier *= Config.doubleCoins
	end
	if input.vip then
		multiplier *= Config.vipBonus
	end
	if input.premium then
		multiplier *= Config.premiumBonus
	end
	return Economy.production(input.buttons) * multiplier
end

function Economy.clickValue(income: number): number
	return math.max(Config.clickMin, Config.clickFactor * income)
end

function Economy.megaValue(income: number): number
	return math.max(Config.megaMin, Config.megaSeconds * income)
end

-- Échelle du bébé : il grossit avec les achats, les couches et les rebirths (plafond 4).
function Economy.babyScale(buttons: number, diaper: number, rebirths: number): number
	return math.min(4, (1 + 0.04 * buttons + 0.05 * (diaper - 1)) * (1 + 0.1 * rebirths))
end

return Economy
