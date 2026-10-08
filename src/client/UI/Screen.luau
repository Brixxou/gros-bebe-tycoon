--!strict
-- ScreenGui mis à l'échelle de l'écran : l'interface est dessinée pour 1280 × 720 puis réduite ou agrandie.
local Players = game:GetService("Players")

local New = require(script.Parent.New)

local Screen = {}

function Screen.create(name: string, displayOrder: number): ScreenGui
	local gui = New("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		DisplayOrder = displayOrder,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	local scale = New("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function update()
		local size = camera.ViewportSize
		scale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 720), 0.55, 1.3)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	update()
	return gui
end

return Screen
