--!strict
-- La base du joueur local (le serveur met son nom dans l'attribut « Plot » du joueur).
local Players = game:GetService("Players")

local MyPlot = {}

function MyPlot.get(): Model?
	local name = Players.LocalPlayer:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	if type(name) ~= "string" or plots == nil then
		return nil
	end
	local slot = plots:FindFirstChild(name)
	return if slot and slot:IsA("Model") then slot else nil
end

-- Cherche une pièce de la nursery par son nom (ex. « Diaper », « Sensor », « Spawn »).
function MyPlot.part(name: string): BasePart?
	local slot = MyPlot.get()
	local found = slot and slot:FindFirstChild(name, true)
	return if found and found:IsA("BasePart") then found else nil
end

-- Attend que la nursery soit répliquée puis renvoie la pièce (ou nil après `timeout` secondes).
function MyPlot.waitForPart(name: string, timeout: number): BasePart?
	local deadline = os.clock() + timeout
	while os.clock() < deadline do
		local part = MyPlot.part(name)
		if part then
			return part
		end
		task.wait(0.2)
	end
	return nil
end

-- Pièce de la nursery par son chemin depuis la nursery, ex. « PadActive.Disk » ou « Baby.Diaper ».
function MyPlot.path(path: string): BasePart?
	local slot = MyPlot.get()
	local current: Instance? = if slot then slot:FindFirstChild("Nursery") else nil
	for _, name in string.split(path, ".") do
		current = if current then current:FindFirstChild(name) else nil
	end
	return if current and current:IsA("BasePart") then current else nil
end

return MyPlot
