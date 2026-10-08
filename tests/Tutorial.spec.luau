local T = require("./lib/t")
local Data = require("../src/shared/Logic/Data")
local Tutorial = require("../src/shared/Logic/Tutorial")
local TutorialConfig = require("../src/shared/Config/Tutorial")

T.describe("Tutorial", function()
	T.it("démarre pour un profil neuf et saute pour un profil avancé", function()
		local fresh = Data.template()
		Tutorial.start(fresh)
		T.eq(fresh.tutorial, 1)
		local veteran = Data.template()
		veteran.buttons = 3
		Tutorial.start(veteran)
		T.eq(veteran.tutorial, Tutorial.DONE)
	end)
	T.it("avance quand le profil remplit l'étape", function()
		local data = Data.template()
		Tutorial.start(data)
		local completed = Tutorial.advance(data, false)
		T.eq(#completed, 0)
		data.buttons = 1
		completed = Tutorial.advance(data, false)
		T.eq(#completed, 1)
		T.eq(completed[1].id, "bottle")
		T.eq(data.tutorial, 2)
	end)
	T.it("attend un caca au pot pendant l'étape « poop »", function()
		local data = Data.template()
		data.tutorial = 2
		data.buttons = 1
		data.totalClicks = 10
		data.totalPoops = 5
		Tutorial.advance(data, false)
		T.eq(data.tutorial, 3, "les cacas d'avant ne comptent pas")
		Tutorial.advance(data, true)
		T.eq(data.tutorial, 4)
	end)
	T.it("donne 25 Tétines à la fin, une seule fois", function()
		local data = Data.template()
		data.tutorial = 5
		data.diaper = 2
		local completed, reward = Tutorial.advance(data, false)
		T.eq(completed[1].id, "camo")
		T.eq(reward, 25)
		T.eq(data.binkies, 25)
		T.eq(data.tutorial, Tutorial.DONE)
		local _, again = Tutorial.advance(data, true)
		T.eq(again, 0)
		T.eq(data.binkies, 25)
	end)
	T.it("n'utilise que des buts connus", function()
		local known = { buttons = true, clicks = true, diaper = true, poop = true }
		for _, step in TutorialConfig.steps do
			T.truthy(known[step.goal], "but " .. step.goal)
			T.truthy(step.target ~= "", "cible de " .. step.id)
		end
	end)
end)
