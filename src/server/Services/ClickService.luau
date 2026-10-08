--!strict
-- Les clics sur la couche (PUSH!) : gain immédiat, méga caca tous les 50 clics (spec, section 3).
-- Deux entrées : le remote Click (bouton PUSH! du HUD) et le ClickDetector de la couche du bébé.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Clicks = require(ReplicatedStorage.Shared.Logic.Clicks)
local Config = require(ReplicatedStorage.Shared.Config.Economy)
local DataService = require(script.Parent.DataService)
local IncomeService = require(script.Parent.IncomeService)
local Net = require(ReplicatedStorage.Shared.Net)
local PlotService = require(script.Parent.PlotService)
local ProductionService = require(script.Parent.ProductionService)
local RateLimit = require(ReplicatedStorage.Shared.Logic.RateLimit)
local StateService = require(script.Parent.StateService)

local ClickService = {}

local limiter = RateLimit.new(Config.maxClicksPerSecond, Config.maxClicksPerSecond)
local effect: RemoteEvent

function ClickService.click(player: Player)
	if not RateLimit.allow(limiter, player, os.clock()) then
		return
	end
	local data = DataService.get(player)
	if data == nil then
		return
	end
	local result = Clicks.register(data, IncomeService.income(player))
	StateService.markDirty(player)
	if result.mega then
		ProductionService.spawn(player, result.megaValue, true)
		effect:FireClient(player, "mega", result.megaValue)
	end
end

local function onPlotBuilt(player: Player, slot: Model)
	local diaper = slot:FindFirstChild("Diaper", true)
	local detector = diaper and diaper:FindFirstChildOfClass("ClickDetector")
	if detector then
		detector.MouseClick:Connect(function(clicker: Player)
			if clicker == player then
				ClickService.click(player)
			end
		end)
	end
end

function ClickService.start()
	effect = Net.event("Effect")
	Net.event("Click").OnServerEvent:Connect(ClickService.click)
	PlotService.built:connect(onPlotBuilt)
	Players.PlayerRemoving:Connect(function(player)
		RateLimit.forget(limiter, player)
	end)
end

return ClickService
