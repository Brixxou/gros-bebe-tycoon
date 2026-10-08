--!strict
-- Les 10 décos de la nursery. Chacune est construite autour de l'origine (pivot au sol) et regarde vers -Z.
local Buttons = require("../Config/Buttons")
local Parts = require("./Parts")
local World = require("../Config/World")

type Builder = (model: Model, color: string, accent: string) -> ()

local BALL_COLORS = { "#FF6B6B", "#FFD166", "#06D6A0", "#118AB2", "#C77DFF", "#FF8FAB" }

local BUILDERS: { [string]: Builder } = {
	play_mat = function(model, color, accent)
		Parts.block(model, "Mat", Vector3.new(30, 0.2, 30), Vector3.new(0, 0.1, 0), color)
		for index, corner in
			{ Vector3.new(-9, 0, -9), Vector3.new(9, 0, -9), Vector3.new(-9, 0, 9), Vector3.new(9, 0, 9) }
		do
			Parts.block(
				model,
				"Square" .. index,
				Vector3.new(8, 0.25, 8),
				corner + Vector3.new(0, 0.12, 0),
				accent
			)
		end
	end,
	pastel_walls = function(model, color, accent)
		local half = World.plotSize / 2
		local height = 12
		Parts.block(
			model,
			"WallLeft",
			Vector3.new(1, height, World.plotSize),
			Vector3.new(-half + 0.5, height / 2, 0),
			color
		)
		Parts.block(
			model,
			"WallRight",
			Vector3.new(1, height, World.plotSize),
			Vector3.new(half - 0.5, height / 2, 0),
			color
		)
		Parts.block(
			model,
			"WallBack",
			Vector3.new(World.plotSize, height, 1),
			Vector3.new(0, height / 2, half - 0.5),
			color
		)
		Parts.block(
			model,
			"StripeLeft",
			Vector3.new(1.2, 1.2, World.plotSize),
			Vector3.new(-half + 0.5, height - 2, 0),
			accent
		)
		Parts.block(
			model,
			"StripeRight",
			Vector3.new(1.2, 1.2, World.plotSize),
			Vector3.new(half - 0.5, height - 2, 0),
			accent
		)
		Parts.block(
			model,
			"StripeBack",
			Vector3.new(World.plotSize, 1.2, 1.2),
			Vector3.new(0, height - 2, half - 0.5),
			accent
		)
	end,
	crib = function(model, color, accent)
		for index, corner in
			{
				Vector3.new(-4.6, 0, -2.6),
				Vector3.new(4.6, 0, -2.6),
				Vector3.new(-4.6, 0, 2.6),
				Vector3.new(4.6, 0, 2.6),
			}
		do
			Parts.block(
				model,
				"Post" .. index,
				Vector3.new(0.7, 7, 0.7),
				corner + Vector3.new(0, 3.5, 0),
				color
			)
		end
		Parts.block(model, "Bed", Vector3.new(9.4, 1, 5.4), Vector3.new(0, 3, 0), color)
		Parts.block(model, "Mattress", Vector3.new(9, 0.6, 5), Vector3.new(0, 3.8, 0), accent)
		Parts.block(model, "RailFront", Vector3.new(9.4, 0.4, 0.4), Vector3.new(0, 6.8, -2.6), color)
		Parts.block(model, "RailBack", Vector3.new(9.4, 0.4, 0.4), Vector3.new(0, 6.8, 2.6), color)
		for bar = -3, 3 do
			Parts.block(
				model,
				"BarFront" .. bar,
				Vector3.new(0.3, 2.8, 0.3),
				Vector3.new(bar * 1.2, 5.3, -2.6),
				color
			)
			Parts.block(
				model,
				"BarBack" .. bar,
				Vector3.new(0.3, 2.8, 0.3),
				Vector3.new(bar * 1.2, 5.3, 2.6),
				color
			)
		end
		Parts.ball(model, "Pillow", 1.6, Vector3.new(-3.2, 4.4, 0), "#FFFFFF")
	end,
	musical_mobile = function(model, color, accent)
		Parts.block(model, "Pole", Vector3.new(0.5, 18, 0.5), Vector3.new(5.5, 9, 0), "#FFFFFF")
		Parts.block(model, "Arm", Vector3.new(6, 0.4, 0.4), Vector3.new(2.5, 18, 0), "#FFFFFF")
		Parts.cylinder(model, "Hub", 0.6, 2.2, Vector3.new(0, 17.6, 0), color)
		for index, offset in
			{
				Vector3.new(1.6, 0, 0),
				Vector3.new(-1.6, 0, 0),
				Vector3.new(0, 0, 1.6),
				Vector3.new(0, 0, -1.6),
			}
		do
			Parts.block(
				model,
				"String" .. index,
				Vector3.new(0.1, 2.6, 0.1),
				offset + Vector3.new(0, 16, 0),
				"#FFFFFF"
			)
			local toyColor = if index % 2 == 0 then accent else color
			Parts.ball(model, "Toy" .. index, 1.4, offset + Vector3.new(0, 14.4, 0), toyColor, "Neon")
		end
	end,
	toy_box = function(model, color, accent)
		Parts.block(model, "Box", Vector3.new(6, 4, 4), Vector3.new(0, 2, 0), color)
		Parts.block(model, "Lid", Vector3.new(6.3, 0.6, 4.3), Vector3.new(0, 4.3, 0), accent)
		Parts.ball(model, "Ball", 1.6, Vector3.new(-1.6, 5.4, 0), "#FFD166")
		Parts.block(model, "Cube", Vector3.new(1.4, 1.4, 1.4), Vector3.new(0.3, 5.3, 0.4), "#06D6A0")
		Parts.cylinder(model, "Drum", 1, 1.6, Vector3.new(2, 5.1, -0.3), "#FF6B6B")
	end,
	rocking_horse = function(model, color, accent)
		Parts.block(model, "RockerLeft", Vector3.new(0.5, 0.5, 7), Vector3.new(-1.2, 0.25, 0), accent)
		Parts.block(model, "RockerRight", Vector3.new(0.5, 0.5, 7), Vector3.new(1.2, 0.25, 0), accent)
		for index, leg in
			{
				Vector3.new(-1.2, 0, -1.6),
				Vector3.new(1.2, 0, -1.6),
				Vector3.new(-1.2, 0, 1.6),
				Vector3.new(1.2, 0, 1.6),
			}
		do
			Parts.block(
				model,
				"Leg" .. index,
				Vector3.new(0.6, 2.6, 0.6),
				leg + Vector3.new(0, 1.8, 0),
				color
			)
		end
		Parts.block(model, "Body", Vector3.new(2.8, 2.2, 4.6), Vector3.new(0, 4, 0), color)
		Parts.block(model, "Neck", Vector3.new(1.6, 2.4, 1.6), Vector3.new(0, 5.6, -2), color)
		Parts.block(model, "Head", Vector3.new(1.8, 1.6, 2.6), Vector3.new(0, 6.8, -2.8), color)
		Parts.block(model, "Mane", Vector3.new(0.6, 2.8, 1.4), Vector3.new(0, 6.2, -1.6), accent)
		Parts.ball(model, "EyeLeft", 0.4, Vector3.new(-0.9, 7.1, -3.4), "#2B2B2B")
		Parts.ball(model, "EyeRight", 0.4, Vector3.new(0.9, 7.1, -3.4), "#2B2B2B")
		Parts.block(model, "Tail", Vector3.new(0.6, 2, 0.6), Vector3.new(0, 4.2, 2.6), accent)
	end,
	ball_pit = function(model, color, accent)
		Parts.cylinder(model, "Floor", 0.4, 14, Vector3.new(0, 0.2, 0), color)
		for side = 0, 7 do
			local angle = side * math.pi / 4
			Parts.make(model, {
				name = "Wall" .. side,
				size = Vector3.new(5.8, 2.6, 0.8),
				cframe = CFrame.Angles(0, angle, 0) * CFrame.new(0, 1.3, -6.6),
				color = accent,
			})
		end
		local random = Random.new(42)
		for index = 1, 40 do
			local angle = random:NextNumber(0, 2 * math.pi)
			local distance = random:NextNumber(0, 5.2)
			local position = Vector3.new(
				math.cos(angle) * distance,
				random:NextNumber(0.9, 2.2),
				math.sin(angle) * distance
			)
			Parts.ball(model, "Ball" .. index, 1.4, position, BALL_COLORS[(index % #BALL_COLORS) + 1])
		end
	end,
	slide = function(model, color, accent)
		Parts.block(model, "PostLeft", Vector3.new(0.5, 9, 0.5), Vector3.new(-1.6, 4.5, 4), accent)
		Parts.block(model, "PostRight", Vector3.new(0.5, 9, 0.5), Vector3.new(1.6, 4.5, 4), accent)
		for step = 1, 5 do
			Parts.block(
				model,
				"Step" .. step,
				Vector3.new(3.2, 0.3, 0.6),
				Vector3.new(0, step * 1.5, 4.4),
				"#FFFFFF"
			)
		end
		Parts.block(model, "Platform", Vector3.new(4, 0.5, 3), Vector3.new(0, 8.5, 2.6), accent)
		Parts.make(model, {
			name = "Chute",
			size = Vector3.new(3.6, 0.4, 13),
			cframe = CFrame.new(0, 4.4, -3.2) * CFrame.Angles(math.rad(-38), 0, 0),
			color = color,
		})
		Parts.make(model, {
			name = "SideLeft",
			size = Vector3.new(0.3, 0.8, 13),
			cframe = CFrame.new(-1.8, 4.9, -3.2) * CFrame.Angles(math.rad(-38), 0, 0),
			color = accent,
		})
		Parts.make(model, {
			name = "SideRight",
			size = Vector3.new(0.3, 0.8, 13),
			cframe = CFrame.new(1.8, 4.9, -3.2) * CFrame.Angles(math.rad(-38), 0, 0),
			color = accent,
		})
	end,
	giant_teddy = function(model, color, accent)
		local light = "#E8C39E"
		Parts.ball(model, "Body", 8, Vector3.new(0, 4, 0), color)
		Parts.ball(model, "Belly", 5, Vector3.new(0, 3.8, -1.9), light)
		Parts.ball(model, "Head", 6, Vector3.new(0, 10, 0), color)
		Parts.ball(model, "EarLeft", 2.4, Vector3.new(-2.4, 12.6, 0), color)
		Parts.ball(model, "EarRight", 2.4, Vector3.new(2.4, 12.6, 0), color)
		Parts.ball(model, "InnerEarLeft", 1.2, Vector3.new(-2.4, 12.6, -0.8), accent)
		Parts.ball(model, "InnerEarRight", 1.2, Vector3.new(2.4, 12.6, -0.8), accent)
		Parts.ball(model, "Muzzle", 2.6, Vector3.new(0, 9.3, -2.5), light)
		Parts.ball(model, "Nose", 0.9, Vector3.new(0, 9.8, -3.7), "#2B2B2B")
		Parts.ball(model, "EyeLeft", 0.8, Vector3.new(-1.1, 10.9, -2.6), "#2B2B2B")
		Parts.ball(model, "EyeRight", 0.8, Vector3.new(1.1, 10.9, -2.6), "#2B2B2B")
		Parts.ball(model, "ArmLeft", 3.2, Vector3.new(-4.2, 5.5, -1), color)
		Parts.ball(model, "ArmRight", 3.2, Vector3.new(4.2, 5.5, -1), color)
		Parts.ball(model, "LegLeft", 3.4, Vector3.new(-2.4, 1.6, -2.6), color)
		Parts.ball(model, "LegRight", 3.4, Vector3.new(2.4, 1.6, -2.6), color)
	end,
	bouncy_castle = function(model, color, accent)
		Parts.block(model, "Base", Vector3.new(14, 3, 14), Vector3.new(0, 1.5, 0), color)
		Parts.block(model, "Floor", Vector3.new(12, 0.6, 12), Vector3.new(0, 3.3, 0), accent)
		Parts.block(model, "WallBack", Vector3.new(14, 4, 1), Vector3.new(0, 5, 6.5), color)
		Parts.block(model, "WallLeft", Vector3.new(1, 4, 14), Vector3.new(-6.5, 5, 0), color)
		Parts.block(model, "WallRight", Vector3.new(1, 4, 14), Vector3.new(6.5, 5, 0), color)
		for index, corner in
			{ Vector3.new(-6, 0, -6), Vector3.new(6, 0, -6), Vector3.new(-6, 0, 6), Vector3.new(6, 0, 6) }
		do
			Parts.cylinder(model, "Tower" .. index, 8, 3.6, corner + Vector3.new(0, 4, 0), accent)
			Parts.ball(model, "Top" .. index, 3.8, corner + Vector3.new(0, 8.4, 0), color)
		end
	end,
}

local Decor = {}

function Decor.build(button: Buttons.Button): Model
	local builder = BUILDERS[button.id]
	assert(builder, "déco inconnue : " .. button.id)
	local model = Parts.model(button.id)
	builder(model, button.color, button.accent)
	return model
end

return Decor
