--!strict
-- Construit la map au démarrage : sol, place centrale, point d'apparition, chemins et 6 emplacements de bases.
-- Chaque emplacement est un Model « PlotN » avec l'attribut Origin (CFrame, -Z vers la place).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Parts = require(ReplicatedStorage.Shared.Builders.Parts)
local World = require(ReplicatedStorage.Shared.Config.World)

local MapBuilder = {}

function MapBuilder.build(): { Model }
	for _, name in { "Baseplate", "SpawnLocation" } do
		local leftover = workspace:FindFirstChild(name)
		if leftover then
			leftover:Destroy()
		end
	end

	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = workspace
	Parts.block(map, "Ground", Vector3.new(900, 2, 900), Vector3.new(0, -1.4, 0), "#9BE3A0")
	Parts.cylinder(map, "Plaza", 0.4, World.plazaRadius * 2, Vector3.new(0, -0.2, 0), "#FFE5EC")

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(14, 0.2, 14)
	spawn.CFrame = CFrame.new(0, 0.1, 0)
	spawn.Color = Color3.fromHex("#FFC8DD")
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = map

	local plots = Instance.new("Folder")
	plots.Name = "Plots"
	plots.Parent = workspace

	local pathLength = World.plotDistance - World.plotSize / 2 - World.plazaRadius
	local slots = {}
	for index = 1, World.plotCount do
		local angle = (index - 1) * 2 * math.pi / World.plotCount
		local center = Vector3.new(math.sin(angle), 0, math.cos(angle)) * World.plotDistance
		local origin = CFrame.lookAt(center, Vector3.zero)

		local slot = Instance.new("Model")
		slot.Name = "Plot" .. index
		slot:SetAttribute("Origin", origin)
		Parts.make(slot, {
			name = "Floor",
			size = Vector3.new(World.plotSize, 0.4, World.plotSize),
			cframe = origin * CFrame.new(0, -0.2, 0),
			color = "#FFF1E6",
		})
		Parts.make(map, {
			name = "Path" .. index,
			size = Vector3.new(10, 0.3, pathLength + 2),
			cframe = origin * CFrame.new(0, -0.25, -(World.plotSize / 2 + pathLength / 2)),
			color = "#FFDAC1",
		})
		slot.Parent = plots
		table.insert(slots, slot)
	end
	return slots
end

return MapBuilder
