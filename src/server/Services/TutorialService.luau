--!strict
-- Tutoriel des nouveaux joueurs (spec, section 4). Les étapes se valident côté serveur, d'après le profil et
-- les cacas qui arrivent au pot ; le client affiche la bulle et la flèche d'après l'état (Snapshot.tutorial).
-- Chaque étape validée part dans l'entonnoir d'onboarding des analytics Roblox.
local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage.Shared.Logic.Data)
local DataService = require(script.Parent.DataService)
local Net = require(ReplicatedStorage.Shared.Net)
local ProductionService = require(script.Parent.ProductionService)
local StateService = require(script.Parent.StateService)
local Tutorial = require(ReplicatedStorage.Shared.Logic.Tutorial)

local CHECK_EVERY = 0.5 -- secondes

local TutorialService = {}

-- Valide les étapes faites. `poopArrived` : un caca du joueur vient d'arriver au pot.
function TutorialService.check(player: Player, poopArrived: boolean)
	local data = DataService.get(player)
	if data == nil then
		return
	end
	local first = data.tutorial
	local completed, reward = Tutorial.advance(data, poopArrived)
	if #completed == 0 then
		return
	end
	for offset, step in completed do
		pcall(function()
			AnalyticsService:LogOnboardingFunnelStepEvent(player, first + offset - 1, step.id)
		end)
	end
	if reward > 0 then
		Net.event("Toast"):FireClient(player, "Tutorial.Done", { reward })
	end
	StateService.markDirty(player)
end

function TutorialService.start()
	DataService.loaded:connect(function(player: Player, data: Data.Profile)
		Tutorial.start(data)
		StateService.markDirty(player)
	end)
	ProductionService.credited:connect(function(player: Player)
		TutorialService.check(player, true)
	end)
	task.spawn(function()
		while true do
			task.wait(CHECK_EVERY)
			for _, player in Players:GetPlayers() do
				TutorialService.check(player, false)
			end
		end
	end)
end

return TutorialService
