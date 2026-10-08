--!strict
-- Rebirth (spec, section 4) : avec la Couche Cosmique et assez de PoopCoins en poche, on repart de zéro
-- (PoopCoins, boutons, couches) contre +50 % de PoopCoins pour toujours et des Tétines.
local Config = require("../Config/Rebirth")
local Data = require("./Data")
local Diapers = require("../Config/Diapers")
local EconomyConfig = require("../Config/Economy")

type Profile = Data.Profile

-- reason : "done" (rebirth fait), "diaper" (il manque la Couche Cosmique), "poor" (pas assez de PoopCoins).
-- rebirths : nombre de rebirths après l'appel ; binkies : Tétines gagnées.
export type RebirthResult = { reason: string, rebirths: number, binkies: number }

local Rebirth = {}

-- PoopCoins à avoir en poche quand on a déjà fait `rebirths` rebirths.
function Rebirth.cost(rebirths: number): number
	return Config.base * Config.growth ^ rebirths
end

-- Multiplicateur de PoopCoins après `rebirths` rebirths : 1 + 0,5 × R.
function Rebirth.multiplier(rebirths: number): number
	return 1 + EconomyConfig.rebirthBonus * rebirths
end

-- Tétines gagnées en atteignant `rebirths` rebirths.
function Rebirth.reward(rebirths: number): number
	return Config.binkiesPerRebirth * rebirths
end

-- Ce qui empêche le rebirth ("diaper", "poor"), ou nil s'il est possible.
function Rebirth.blocker(diaper: number, coins: number, rebirths: number): string?
	if diaper < #Diapers then
		return "diaper"
	end
	if coins < Rebirth.cost(rebirths) then
		return "poor"
	end
	return nil
end

function Rebirth.apply(data: Profile): RebirthResult
	local blocker = Rebirth.blocker(data.diaper, data.coins, data.rebirths)
	if blocker then
		return { reason = blocker, rebirths = data.rebirths, binkies = 0 }
	end
	data.rebirths += 1
	local binkies = Rebirth.reward(data.rebirths)
	data.binkies += binkies
	data.coins = 0
	data.buttons = 0
	data.diaper = 1
	return { reason = "done", rebirths = data.rebirths, binkies = binkies }
end

-- Ce rebirth est-il annoncé à tout le serveur ?
function Rebirth.isMilestone(rebirths: number): boolean
	return table.find(Config.milestones, rebirths) ~= nil
end

return Rebirth
