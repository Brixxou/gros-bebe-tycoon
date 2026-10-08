--!strict
-- Tremblement de la caméra (méga caca), qui s'atténue sur `duration` secondes.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shake = {}

function Shake.play(duration: number, magnitude: number)
	local character = Players.LocalPlayer.Character
	local found = character and character:FindFirstChildOfClass("Humanoid")
	if found == nil then
		return
	end
	local humanoid: Humanoid = found
	local started = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - started
		if elapsed >= duration then
			humanoid.CameraOffset = Vector3.zero
			connection:Disconnect()
			return
		end
		local strength = magnitude * (1 - elapsed / duration)
		humanoid.CameraOffset =
			Vector3.new((math.random() - 0.5) * strength, (math.random() - 0.5) * strength, 0)
	end)
end

return Shake
