--!strict
-- Libellé de version. Sert aussi à vérifier que les `require` relatifs marchent pareil dans Lune et dans Roblox.
local Game = require("../Config/Game")

local Version = {}

function Version.label(): string
	return Game.name .. " v" .. Game.version
end

return Version
