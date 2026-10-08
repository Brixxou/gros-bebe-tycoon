local T = require("./lib/t")
local Version = require("../src/shared/Logic/Version")

T.describe("Version", function()
	T.it("donne le nom et la version", function()
		T.eq(Version.label(), "Big Baby Tycoon v0.1.0")
	end)
end)
