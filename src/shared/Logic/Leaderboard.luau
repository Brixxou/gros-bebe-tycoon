--!strict
-- Scores des classements mondiaux. Un OrderedDataStore n'accepte que des entiers, et le total de PoopCoins
-- dépasse vite 2^53 : on stocke floor(log10(total + 1) × 10^6) et on le reconvertit pour l'affichage.
local SCALE = 1e6

local Leaderboard = {}

function Leaderboard.encodeEarned(total: number): number
	return math.floor(math.log10(math.max(total, 0) + 1) * SCALE)
end

function Leaderboard.decodeEarned(score: number): number
	return 10 ^ (score / SCALE) - 1
end

return Leaderboard
