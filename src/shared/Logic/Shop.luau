--!strict
-- Achats en PoopCoins : le bouton suivant de la séquence, la couche suivante.
local Buttons = require("../Config/Buttons")
local Data = require("./Data")
local Diapers = require("../Config/Diapers")
local Wallet = require("./Wallet")

type Profile = Data.Profile

-- reason : "bought" (acheté), "poor" (il manque `missing` PoopCoins), "done" (plus rien à acheter).
export type BuyResult = { reason: string, index: number, missing: number }

local Shop = {}

local function buy(data: Profile, index: number, price: number?): BuyResult
	if price == nil then
		return { reason = "done", index = index, missing = 0 }
	end
	if not Wallet.spend(data, price) then
		return { reason = "poor", index = index, missing = price - data.coins }
	end
	return { reason = "bought", index = index, missing = 0 }
end

function Shop.buyNextButton(data: Profile): BuyResult
	local index = data.buttons + 1
	local button = Buttons[index]
	local result = buy(data, index, if button then button.price else nil)
	if result.reason == "bought" then
		data.buttons = index
	end
	return result
end

function Shop.buyNextDiaper(data: Profile): BuyResult
	local index = data.diaper + 1
	local diaper = Diapers[index]
	local result = buy(data, index, if diaper then diaper.price else nil)
	if result.reason == "bought" then
		data.diaper = index
	end
	return result
end

return Shop
