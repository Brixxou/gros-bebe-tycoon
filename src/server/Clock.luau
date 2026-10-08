--!strict
-- Horloge du serveur, en secondes Unix (UTC). Tout le code serveur lit l'heure ici.
local Clock = {
	offset = 0, -- décalage en secondes (réservé aux tests en Studio)
}

function Clock.now(): number
	return os.time() + Clock.offset
end

return Clock
