--!strict
-- Gains hors ligne (spec, section 4) : 25 % du revenu de base pendant l'absence, plafonnée à 8 h.
local Config = require("../Config/Economy")

local Offline = {}

-- PoopCoins gagnés pendant `awaySeconds` d'absence avec ce revenu de base/s (rien sous une minute).
function Offline.gain(baseIncome: number, awaySeconds: number): number
	if awaySeconds < Config.offlineMinSeconds then
		return 0
	end
	return Config.offlineShare * baseIncome * math.min(awaySeconds, Config.offlineCapSeconds)
end

return Offline
