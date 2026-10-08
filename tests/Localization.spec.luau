local fs = require("@lune/fs")
local T = require("./lib/t")
local Buttons = require("../src/shared/Config/Buttons")
local Diapers = require("../src/shared/Config/Diapers")
local Tutorial = require("../src/shared/Config/Tutorial")

-- Découpe une ligne CSV : un champ qui contient une virgule est entre guillemets ("" = un guillemet).
local function cells(line: string): { string }
	local result = {}
	local field = ""
	local quoted = false
	local index = 1
	while index <= #line do
		local char = string.sub(line, index, index)
		if quoted and char == '"' and string.sub(line, index + 1, index + 1) == '"' then
			field ..= '"'
			index += 1
		elseif char == '"' then
			quoted = not quoted
		elseif char == "," and not quoted then
			table.insert(result, field)
			field = ""
		else
			field ..= char
		end
		index += 1
	end
	table.insert(result, field)
	return result
end

-- Lit Localization.csv : clé → { source, fr }.
local function load(): { [string]: { source: string, fr: string } }
	local rows = {}
	local lines = string.split(fs.readFile("src/Localization.csv"), "\n")
	T.eq(lines[1], "Key,Source,Context,Example,fr", "en-tête")
	for index = 2, #lines do
		local line = lines[index]
		if line ~= "" then
			local row = cells(line)
			T.eq(#row, 5, "5 colonnes ligne " .. index)
			T.truthy(rows[row[1]] == nil, "clé unique " .. row[1])
			rows[row[1]] = { source = row[2], fr = row[5] }
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
	T.it("traduit chaque étape du tutoriel", function()
		for _, step in Tutorial.steps do
			local row = rows["Tutorial." .. step.id]
			T.truthy(row, "ligne Tutorial." .. step.id)
			T.truthy(row.fr ~= "", "français de l'étape " .. step.id)
		end
	end)
	T.it("contient les clés utilisées par le code", function()
		for _, key in
			{
				"HUD.Income",
				"HUD.Push",
				"HUD.MyBase",
				"HUD.Rebirth",
				"Pad.Free",
				"Pad.Next",
				"Toast.NeedMore",
				"Toast.NewDiaper",
				"Toast.MegaPoop",
				"Toast.Rebirth",
				"Toast.CantRebirth",
				"Table.Title",
				"Table.Action",
				"Table.Owned",
				"Table.Wearing",
				"Table.Buy",
				"Rebirth.NeedDiaper",
				"Rebirth.NeedCoins",
				"Rebirth.Multiplier",
				"Rebirth.Reward",
				"Rebirth.Lose",
				"Rebirth.Keep",
				"Rebirth.Button",
				"Rebirth.Confirm",
				"Welcome.Title",
				"Welcome.Body",
				"Welcome.Ok",
				"Announce.Rebirth",
				"Board.Rebirths",
				"Board.Earned",
				"Board.Loading",
				"Tutorial.Done",
			}
		do
			T.truthy(rows[key], "clé " .. key)
		end
	end)
end)
