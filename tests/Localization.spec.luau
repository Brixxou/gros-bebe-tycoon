local fs = require("@lune/fs")
local T = require("./lib/t")
local Buttons = require("../src/shared/Config/Buttons")
local Diapers = require("../src/shared/Config/Diapers")

-- Lit Localization.csv (sans guillemets ni virgules dans les textes) : clé → { source, fr }.
local function load(): { [string]: { source: string, fr: string } }
	local rows = {}
	local lines = string.split(fs.readFile("src/Localization.csv"), "\n")
	T.eq(lines[1], "Key,Source,Context,Example,fr", "en-tête")
	for index = 2, #lines do
		local line = lines[index]
		if line ~= "" then
			local cells = string.split(line, ",")
			T.eq(#cells, 5, "5 colonnes ligne " .. index)
			T.truthy(rows[cells[1]] == nil, "clé unique " .. cells[1])
			rows[cells[1]] = { source = cells[2], fr = cells[5] }
		end
	end
	return rows
end

T.describe("Localization.csv", function()
	local rows = load()
	T.it("traduit chaque bouton avec son nom anglais comme source", function()
		for _, button in Buttons do
			local row = rows["Button." .. button.id]
			T.truthy(row, "ligne Button." .. button.id)
			T.eq(row.source, button.name)
			T.truthy(row.fr ~= "", "français de " .. button.id)
		end
	end)
	T.it("traduit chaque couche", function()
		for _, diaper in Diapers do
			local row = rows["Diaper." .. diaper.id]
			T.truthy(row, "ligne Diaper." .. diaper.id)
			T.eq(row.source, diaper.name)
		end
	end)
	T.it("contient les clés utilisées par le code", function()
		for _, key in
			{
				"HUD.Income",
				"HUD.Push",
				"HUD.MyBase",
				"Pad.Free",
				"Pad.Next",
				"Toast.NeedMore",
				"Toast.NewDiaper",
				"Toast.MegaPoop",
				"Table.Title",
				"Table.Action",
				"Table.Owned",
				"Table.Wearing",
				"Table.Buy",
			}
		do
			T.truthy(rows[key], "clé " .. key)
		end
	end)
end)
