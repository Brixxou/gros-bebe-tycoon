--!strict
-- Un clic sur la couche (PUSH!) : gain immédiat, et un méga caca tous les 50 clics.
local Config = require("../Config/Economy")
local Data = require("./Data")
local Economy = require("./Economy")
local Wallet = require("./Wallet")

type Profile = Data.Profile

-- mega : ce clic déclenche un méga caca, qui vaut megaValue une fois arrivé au pot.
export type ClickResult = { value: number, mega: boolean, megaValue: number }

local Clicks = {}

function Clicks.register(data: Profile, income: number): ClickResult
	local value = Economy.clickValue(income)
	Wallet.earn(data, value)
	data.totalClicks += 1
	data.clicksSinceMega += 1
	if data.clicksSinceMega >= Config.megaEvery then
		data.clicksSinceMega = 0
		return { value = value, mega = true, megaValue = Economy.megaValue(income) }
	end
	return { value = value, mega = false, megaValue = 0 }
end

return Clicks
