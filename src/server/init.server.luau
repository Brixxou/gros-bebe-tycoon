--!strict
-- Point d'entrée du serveur : crée les remotes, puis initialise et démarre les services dans l'ordre.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Version = require(ReplicatedStorage.Shared.Logic.Version)

Net.setup()

local Services = script.Services
local services: { any } = {
	require(Services.DataService),
	require(Services.PlotService),
}

for _, service in services do
	if service.init then
		service.init()
	end
end
for _, service in services do
	if service.start then
		service.start()
	end
end

print("[BigBaby] serveur démarré : " .. Version.label())
