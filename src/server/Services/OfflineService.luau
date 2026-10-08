--!strict
-- Gains hors ligne (spec, section 4) : au retour du joueur, 25 % de son revenu de base pendant l'absence
-- (8 h au plus), crédités tout de suite et montrés par l'écran « Welcome back ».
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Clock = require(script.Parent.Parent.Clock)
local Data = require(ReplicatedStorage.Shared.Logic.Data)
local DataService = require(script.Parent.DataService)
local IncomeService = require(script.Parent.IncomeService)
local Net = require(ReplicatedStorage.Shared.Net)
local Offline = require(ReplicatedStorage.Shared.Logic.Offline)
local StateService = require(script.Parent.StateService)
local Wallet = require(ReplicatedStorage.Shared.Logic.Wallet)

-- lastSeen est rafraîchi pendant la partie : si le serveur s'arrête net, le temps de jeu ne compte pas
-- comme une absence.
local SEEN_EVERY = 60

local OfflineService = {}

-- Crédite les gains de l'absence depuis data.lastSeen et prévient le joueur. Renvoie le gain.
function OfflineService.collect(player: Player, data: Data.Profile): number
	local now = Clock.now()
	local away = if data.lastSeen > 0 then now - data.lastSeen else 0
	local gain = Offline.gain(IncomeService.baseIncome(player), away)
	data.lastSeen = now
	data.pendingOffline = gain -- le gain reste « en attente » pour « Triple it » (phase 3)
	if gain > 0 then
		Wallet.earn(data, gain)
		StateService.markDirty(player)
		Net.event("WelcomeBack"):FireClient(player, gain, away)
	end
	return gain
end

function OfflineService.start()
	DataService.loaded:connect(OfflineService.collect)
	task.spawn(function()
		while true do
			task.wait(SEEN_EVERY)
			local now = Clock.now()
			for _, player in Players:GetPlayers() do
				local data = DataService.get(player)
				if data then
					data.lastSeen = now
				end
			end
		end
	end)
end

return OfflineService
