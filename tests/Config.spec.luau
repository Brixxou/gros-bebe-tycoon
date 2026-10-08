local T = require("./lib/t")
local Buttons = require("../src/shared/Config/Buttons")
local Diapers = require("../src/shared/Config/Diapers")

T.describe("Config", function()
	T.it("a 22 boutons : 12 machines et 10 décos", function()
		local machines, decors = 0, 0
		for _, button in Buttons do
			if button.kind == "machine" then
				machines += 1
				T.truthy(button.rate > 0, button.id .. " produit")
			else
				T.eq(button.kind, "decor", button.id)
				decors += 1
				T.eq(button.bonus, 0.05, button.id)
			end
		end
		T.eq(#Buttons, 22)
		T.eq(machines, 12)
		T.eq(decors, 10)
	end)
	T.it("a des identifiants uniques et des prix croissants", function()
		local seen = {}
		for index, button in Buttons do
			T.truthy(not seen[button.id], "id unique " .. button.id)
			seen[button.id] = true
			if index > 1 then
				T.truthy(button.price > Buttons[index - 1].price, "prix croissant " .. button.id)
			end
		end
		T.eq(Buttons[1].price, 0, "le biberon est gratuit")
	end)
	T.it("a 10 couches, de x1 gratuite à x300", function()
		T.eq(#Diapers, 10)
		T.eq(Diapers[1].price, 0)
		T.eq(Diapers[1].mult, 1)
		T.eq(Diapers[10].id, "cosmic")
		T.eq(Diapers[10].mult, 300)
		for index = 2, #Diapers do
			T.truthy(Diapers[index].mult > Diapers[index - 1].mult, "mult croissant")
			T.truthy(Diapers[index].price > Diapers[index - 1].price, "prix croissant")
		end
	end)
end)
