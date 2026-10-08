--!strict
-- Positions des éléments d'une base, relatives à son origine (au sol, au centre ; -Z regarde vers la place).

local LEFT = CFrame.Angles(0, -math.pi / 2, 0) -- regarde vers +X (vers le bébé)
local RIGHT = CFrame.Angles(0, math.pi / 2, 0) -- regarde vers -X (vers le bébé)

-- 12 emplacements de machines, de l'entrée vers le fond, en alternant gauche et droite.
local machines: { CFrame } = {}
for _, z in { -32, -20, -8, 4, 16, 28 } do
	table.insert(machines, CFrame.new(-40, 0, z) * LEFT)
	table.insert(machines, CFrame.new(40, 0, z) * RIGHT)
end

local Layout = {
	spawn = CFrame.lookAt(Vector3.new(0, 3, -48), Vector3.new(0, 3, 0)),
	baby = CFrame.new(0, 0, 12),
	beltCenter = CFrame.new(14, 0, 40), -- le tapis va de x = -6 à x = 34
	beltLength = 40,
	beltWidth = 12,
	poopSpawn = Vector3.new(-3, 10, 40),
	potty = CFrame.new(40, 0, 40),
	changingTable = CFrame.new(-24, 0, -36),
	padActive = CFrame.new(-8, 0, -38),
	padNext = CFrame.new(4, 0, -38),
	machines = machines,
	decor = {
		play_mat = CFrame.new(0, 0, 12),
		pastel_walls = CFrame.new(),
		crib = CFrame.new(-45, 0, 50),
		musical_mobile = CFrame.new(-45, 0, 50),
		toy_box = CFrame.new(-25, 0, 52),
		rocking_horse = CFrame.new(-50, 0, -48) * CFrame.Angles(0, math.rad(30), 0),
		ball_pit = CFrame.new(40, 0, -48),
		slide = CFrame.new(52, 0, 48),
		giant_teddy = CFrame.new(-53, 0, 5) * LEFT,
		bouncy_castle = CFrame.new(18, 0, -50),
	} :: { [string]: CFrame },
}

return Layout
