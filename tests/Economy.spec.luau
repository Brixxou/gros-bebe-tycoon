local T = require("./lib/t")
local Economy = require("../src/shared/Logic/Economy")

local function input(overrides: { [string]: any }): Economy.IncomeInput
	local base: { [string]: any } = {
		buttons = 0,
		diaper = 1,
		rebirths = 0,
		petBonus = 0,
		doubleCoins = false,
		vip = false,
		premium = false,
	}
	for key, value in overrides do
		base[key] = value
	end
	return base :: any
end

T.describe("Economy", function()
	T.it("additionne la production des machines achetées", function()
		T.eq(Economy.production(0), 0)
		T.eq(Economy.production(1), 1)
		T.eq(Economy.production(2), 4)
		T.eq(Economy.production(3), 4, "la 3e est une déco")
		T.eq(Economy.production(22), 45_557)
		T.eq(Economy.production(99), 45_557, "borné au nombre de boutons")
	end)
	T.it("donne +5 % par déco achetée", function()
		T.near(Economy.decorMultiplier(2), 1)
		T.near(Economy.decorMultiplier(3), 1.05)
		T.near(Economy.decorMultiplier(22), 1.5)
	end)
	T.it("multiplie le revenu de base", function()
		T.near(Economy.baseIncome(input({ buttons = 2 })), 4)
		T.near(Economy.baseIncome(input({ buttons = 2, diaper = 3 })), 14)
		T.near(Economy.baseIncome(input({ buttons = 2, rebirths = 2 })), 8)
		T.near(Economy.baseIncome(input({ buttons = 2, petBonus = 0.25 })), 5)
		T.near(
			Economy.baseIncome(input({ buttons = 2, doubleCoins = true, vip = true, premium = true })),
			4 * 2 * 1.2 * 1.1
		)
	end)
	T.it("calcule clic et méga caca avec leurs minimums", function()
		T.eq(Economy.clickValue(0), 1)
		T.near(Economy.clickValue(100), 15)
		T.eq(Economy.megaValue(0), 50)
		T.eq(Economy.megaValue(100), 1000)
	end)
	T.it("fait grossir le bébé jusqu'à 4", function()
		T.near(Economy.babyScale(0, 1, 0), 1)
		T.near(Economy.babyScale(22, 10, 0), 1 + 0.88 + 0.45)
		T.eq(Economy.babyScale(22, 10, 20), 4)
	end)
end)
