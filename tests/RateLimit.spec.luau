local T = require("./lib/t")
local RateLimit = require("../src/shared/Logic/RateLimit")

T.describe("RateLimit", function()
	T.it("laisse passer la rafale puis bloque", function()
		local limiter = RateLimit.new(12, 12)
		for _ = 1, 12 do
			T.eq(RateLimit.allow(limiter, "a", 0), true)
		end
		T.eq(RateLimit.allow(limiter, "a", 0), false)
	end)
	T.it("recharge avec le temps", function()
		local limiter = RateLimit.new(12, 12)
		for _ = 1, 12 do
			RateLimit.allow(limiter, "a", 0)
		end
		T.eq(RateLimit.allow(limiter, "a", 0.05), false, "0,6 jeton")
		T.eq(RateLimit.allow(limiter, "a", 0.1), true, "1,2 jeton")
	end)
	T.it("sépare les clés", function()
		local limiter = RateLimit.new(1, 1)
		T.eq(RateLimit.allow(limiter, "a", 0), true)
		T.eq(RateLimit.allow(limiter, "b", 0), true)
		T.eq(RateLimit.allow(limiter, "a", 0), false)
		RateLimit.forget(limiter, "a")
		T.eq(RateLimit.allow(limiter, "a", 0), true)
	end)
end)
