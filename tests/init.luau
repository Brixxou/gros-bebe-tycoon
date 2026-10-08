-- Lance tous les fichiers tests/*.spec.luau : `lune run tests` depuis la racine du repo.
local fs = require("@lune/fs")
local process = require("@lune/process")
local T = require("@self/lib/t")

local names = fs.readDir("tests")
table.sort(names)
for _, name in names do
	if string.sub(name, -10) == ".spec.luau" then
		require("@self/" .. string.sub(name, 1, -6))
	end
end

local results = T.results()
for _, failure in results.failures do
	print("ÉCHEC " .. failure)
end
print(string.format("%d tests réussis, %d en échec", results.passed, results.failed))
if results.failed > 0 then
	process.exit(1)
end
