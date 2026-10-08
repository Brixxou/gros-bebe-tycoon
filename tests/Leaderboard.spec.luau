local T = require("./lib/t")
local Leaderboard = require("../src/shared/Logic/Leaderboard")

T.describe("Leaderboard", function()
	T.it("encode le total gagné en entier", function()
		T.eq(Leaderboard.encodeEarned(0), 0)
		T.eq(Leaderboard.encodeEarned(9), 1_000_000)
		T.eq(Leaderboard.encodeEarned(12_345) % 1, 0)
	end)
	T.it("relit le total à 0,001 % près", function()
		for _, total in { 1234, 5.6e9, 7.8e24 } do
			local back = Leaderboard.decodeEarned(Leaderboard.encodeEarned(total))
			T.truthy(math.abs(back - total) / total < 1e-5, "écart pour " .. total)
		end
	end)
	T.it("range les gros totaux devant les petits", function()
		T.truthy(Leaderboard.encodeEarned(2e15) > Leaderboard.encodeEarned(1e15))
	end)
end)
