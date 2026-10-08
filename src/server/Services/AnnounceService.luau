--!strict
-- Annonces à tout le serveur (spec, section 4) : chaque client les montre en bannière et dans le chat.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local AnnounceService = {}

-- `key` : clé de Localization.csv ; `args` : ses arguments, déjà mis en forme.
function AnnounceService.broadcast(key: string, args: { any })
	Net.event("Announce"):FireAllClients(key, args)
end

return AnnounceService
