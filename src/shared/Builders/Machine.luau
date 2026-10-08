--!strict
-- Machine à bouffe, aux couleurs de son bouton. Elle regarde vers -Z ; pivot au sol.
local Buttons = require("../Config/Buttons")
local Parts = require("./Parts")

local Machine = {}

function Machine.build(button: Buttons.Button): Model
	local model = Parts.model(button.id)
	Parts.block(model, "Base", Vector3.new(7, 1, 7), Vector3.new(0, 0.5, 0), "#FFFFFF")
	Parts.block(model, "Body", Vector3.new(6, 5, 6), Vector3.new(0, 3.5, 0), button.color)
	Parts.cylinder(model, "Hopper", 1.2, 5, Vector3.new(0, 6.6, 0), "#FFFFFF")
	Parts.ball(model, "Food", 3, Vector3.new(0, 8, 0), button.accent)
	Parts.block(model, "Chute", Vector3.new(2, 2, 3), Vector3.new(0, 4, -4.2), button.accent)
	Parts.ball(model, "LightLeft", 0.8, Vector3.new(-1.6, 5, -3.05), "#FFE66D", "Neon")
	Parts.ball(model, "LightRight", 0.8, Vector3.new(1.6, 5, -3.05), "#FFE66D", "Neon")
	return model
end

return Machine
