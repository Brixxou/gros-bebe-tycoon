--!strict
-- Revenu de chaque joueur (spec, section 6), calculé à partir de sa sauvegarde.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local Economy = require(ReplicatedStorage.Shared.Logic.Economy)

local IncomeService = {}

-- Revenu de base/s : multiplicateurs permanents (couche, décos, rebirths).
function IncomeService.baseIncome(player: Player): number
	local data = DataService.get(player)
	if data == nil then
		return 0
	end
	return Economy.baseIncome({
		buttons = data.buttons,
		diaper = data.diaper,
		rebirths = data.rebirths,
		petBonus = 0,
		doubleCoins = false,
		vip = false,
		premium = false,
	})
end

-- Revenu/s : revenu de base × multiplicateurs temporaires (aucun boost n'existe encore).
function IncomeService.income(player: Player): number
	return IncomeService.baseIncome(player)
end

return IncomeService
