--!strict
-- Un caca façon emoji : 3 boules en spirale et 2 yeux, soudés sur une boîte de collision invisible
-- (la boîte glisse bien sur le tapis). `size` : facteur d'échelle.
local Parts = require("./Parts")

local Poop = {}

function Poop.build(size: number, color: string, material: string): (Model, Part)
	local model = Parts.model("Poop")
	local root = Parts.make(model, {
		name = "Root",
		size = Vector3.new(1.8, 1.4, 1.8) * size,
		cframe = CFrame.new(0, 0.7 * size, 0),
		color = color,
		transparency = 1,
	})
	local pieces = {
		Parts.ball(model, "Bottom", 1.8 * size, Vector3.new(0, 0.8 * size, 0), color, material),
		Parts.ball(model, "Middle", 1.3 * size, Vector3.new(0, 1.6 * size, 0), color, material),
		Parts.ball(model, "Top", 0.8 * size, Vector3.new(0, 2.2 * size, 0), color, material),
		Parts.ball(
			model,
			"EyeLeft",
			0.45 * size,
			Vector3.new(-0.3 * size, 1.7 * size, -0.55 * size),
			"#FFFFFF"
		),
		Parts.ball(
			model,
			"EyeRight",
			0.45 * size,
			Vector3.new(0.3 * size, 1.7 * size, -0.55 * size),
			"#FFFFFF"
		),
		Parts.ball(
			model,
			"PupilLeft",
			0.2 * size,
			Vector3.new(-0.3 * size, 1.7 * size, -0.76 * size),
			"#111111"
		),
		Parts.ball(
			model,
			"PupilRight",
			0.2 * size,
			Vector3.new(0.3 * size, 1.7 * size, -0.76 * size),
			"#111111"
		),
	}
	for _, piece in pieces do
		piece.CanCollide = false
		piece.CanTouch = false
		piece.CanQuery = false
		piece.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = piece
		weld.Parent = root
	end
	root.Anchored = false
	for _, piece in pieces do
		piece.Anchored = false
	end
	model.PrimaryPart = root
	return model, root
end

return Poop
