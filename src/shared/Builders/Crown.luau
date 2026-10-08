--!strict
-- Couronne des 3 premiers du classement mondial des rebirths (or, argent, bronze), pour la tête du bébé.
-- Pivot au centre de sa base. Rien n'y est touchable.
local Parts = require("./Parts")

local Crown = {}

function Crown.build(color: string): Model
	local model = Parts.model("Crown")
	Parts.cylinder(model, "Ring", 1.2, 4.6, Vector3.new(0, 0.6, 0), color, "Foil")
	for index = 0, 4 do
		local angle = index * 2 * math.pi / 5
		local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * 2
		local spike = Vector3.new(0.7, 1.4, 0.7)
		Parts.block(model, "Spike" .. index, spike, offset + Vector3.new(0, 1.6, 0), color, "Foil")
		Parts.ball(model, "Gem" .. index, 0.6, offset + Vector3.new(0, 2.5, 0), "#E63946", "Neon")
	end
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		end
	end
	return model
end

return Crown
