--!strict
-- Gagner et dépenser des PoopCoins.
local Data = require("./Data")

type Profile = Data.Profile

local Wallet = {}

function Wallet.earn(data: Profile, amount: number)
	if amount <= 0 then
		return
	end
	data.coins += amount
	data.totalEarned += amount
end

function Wallet.spend(data: Profile, amount: number): boolean
	if amount < 0 or data.coins < amount then
		return false
	end
	data.coins -= amount
	return true
end

return Wallet
