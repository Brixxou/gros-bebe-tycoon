--!strict
-- Le gros bébé, en boules et cylindres. Il regarde vers -Z ; pivot au sol, au centre.
-- Sa couche (« Diaper ») porte un ClickDetector : cliquer dessus = PUSH!.
local Parts = require("./Parts")

local SKIN = "#FFD6B0"
local CHEEK = "#FF9AA2"
local DARK = "#2B2B2B"

local Baby = {}

function Baby.build(): Model
	local model = Parts.model("Baby")
	Parts.ball(model, "Body", 6.4, Vector3.new(0, 3.4, 0), SKIN)
	Parts.ball(model, "Head", 5.6, Vector3.new(0, 8.2, -0.2), SKIN)
	Parts.ball(model, "EyeLeft", 0.9, Vector3.new(-1.1, 8.7, -2.6), DARK)
	Parts.ball(model, "EyeRight", 0.9, Vector3.new(1.1, 8.7, -2.6), DARK)
	Parts.ball(model, "ShineLeft", 0.3, Vector3.new(-0.95, 8.95, -3.0), "#FFFFFF")
	Parts.ball(model, "ShineRight", 0.3, Vector3.new(1.25, 8.95, -3.0), "#FFFFFF")
	Parts.ball(model, "CheekLeft", 1.2, Vector3.new(-1.9, 7.6, -2.2), CHEEK)
	Parts.ball(model, "CheekRight", 1.2, Vector3.new(1.9, 7.6, -2.2), CHEEK)
	Parts.ball(model, "Mouth", 1.0, Vector3.new(0, 7.2, -2.6), "#C9184A")
	Parts.ball(model, "Curl", 1.0, Vector3.new(0, 11.1, -0.4), "#E0A96D")
	Parts.ball(model, "ArmLeft", 2.4, Vector3.new(-3.4, 4.4, -0.6), SKIN)
	Parts.ball(model, "ArmRight", 2.4, Vector3.new(3.4, 4.4, -0.6), SKIN)
	Parts.ball(model, "LegLeft", 2.8, Vector3.new(-1.9, 1.2, -2.2), SKIN)
	Parts.ball(model, "LegRight", 2.8, Vector3.new(1.9, 1.2, -2.2), SKIN)
	local diaper = Parts.cylinder(model, "Diaper", 2.8, 6.9, Vector3.new(0, 1.9, 0), "#FFFFFF")
	Parts.ball(model, "Pin", 0.8, Vector3.new(0, 2.3, -3.4), "#FFB5C2")
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 80
	detector.Parent = diaper
	return model
end

function Baby.setDiaper(model: Model, color: string, material: string)
	local diaper = model:FindFirstChild("Diaper")
	if diaper and diaper:IsA("BasePart") then
		diaper.Color = Color3.fromHex(color)
		diaper.Material = Parts.material(material)
	end
end

return Baby
