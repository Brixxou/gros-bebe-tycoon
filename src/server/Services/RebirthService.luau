--!strict
-- Rebirth (spec, section 4) : le joueur repart de zéro contre +50 % de PoopCoins pour toujours et des Tétines.
-- Les 10e, 25e et 50e rebirths sont annoncés à tout le serveur.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnnounceService = require(script.Parent.AnnounceService)
local DataService = require(script.Parent.DataService)
local Net = require(ReplicatedStorage.Shared.Net)
local PlotService = require(script.Parent.PlotService)
local ProductionService = require(script.Parent.ProductionService)
local RateLimit = require(ReplicatedStorage.Shared.Logic.RateLimit)
local Rebirth = require(ReplicatedStorage.Shared.Logic.Rebirth)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local StateService = require(script.Parent.StateService)

local RebirthService = {
	done = Signal.new(), -- (player, rebirths) : le joueur vient de faire un rebirth
}

local limiter = RateLimit.new(1, 1)

function RebirthService.rebirth(player: Player)
	if not RateLimit.allow(limiter, player, os.clock()) then
		return
	end
	local data = DataService.get(player)
	if data == nil then
		return
	end
	local result = Rebirth.apply(data)
	local toast = Net.event("Toast")
	if result.reason ~= "done" then
		toast:FireClient(player, "Toast.CantRebirth", {})
		return
	end
	ProductionService.clear(player) -- les cacas en route datent d'avant le rebirth
	PlotService.refresh(player)
	StateService.markDirty(player)
	toast:FireClient(player, "Toast.Rebirth", { result.rebirths, Rebirth.multiplier(result.rebirths) })
	if Rebirth.isMilestone(result.rebirths) then
		AnnounceService.broadcast("Announce.Rebirth", { player.DisplayName, result.rebirths })
	end
	RebirthService.done:fire(player, result.rebirths)
end

function RebirthService.start()
	Net.event("Rebirth").OnServerEvent:Connect(RebirthService.rebirth)
	Players.PlayerRemoving:Connect(function(player)
		RateLimit.forget(limiter, player)
	end)
end

return RebirthService
