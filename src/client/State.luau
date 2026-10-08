--!strict
-- Dernier état de la partie reçu du serveur, et signal de changement.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)

local State = {
	current = nil :: Net.Snapshot?,
	changed = Signal.new(), -- (snapshot, previous)
}

function State.start()
	Net.event("State").OnClientEvent:Connect(function(snapshot: Net.Snapshot)
		local previous = State.current
		State.current = snapshot
		State.changed:fire(snapshot, previous)
	end)
end

return State
