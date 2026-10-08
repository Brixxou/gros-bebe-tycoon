--!strict
-- Commandes de test, en Studio uniquement. Elles passent par une BindableFunction parce que la barre de
-- commande et le MCP de Studio (execute_luau, contexte Server) ne voient pas l'état des modules du jeu :
--   game.ServerStorage.DebugCommands:Invoke("give", 1e9)
--   game.ServerStorage.DebugCommands:Invoke("setButtons", 22)
--   game.ServerStorage.DebugCommands:Invoke("setDiaper", 10)
--   game.ServerStorage.DebugCommands:Invoke("setRebirths", 9)
--   print(game.ServerStorage.DebugCommands:Invoke("welcome", 3600)) -- gains d'une heure d'absence
--   print(game.ServerStorage.DebugCommands:Invoke("boards")) -- écrit les scores et relit les classements
--   game.ServerStorage.DebugCommands:Invoke("reset")
--   print(game.ServerStorage.DebugCommands:Invoke("info"))
-- Elles visent le premier joueur du serveur.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Clock = require(script.Parent.Parent.Clock)
local Data = require(ReplicatedStorage.Shared.Logic.Data)
local DataService = require(script.Parent.DataService)
local Format = require(ReplicatedStorage.Shared.Logic.Format)
local IncomeService = require(script.Parent.IncomeService)
local LeaderboardService = require(script.Parent.LeaderboardService)
local OfflineService = require(script.Parent.OfflineService)
local PlotService = require(script.Parent.PlotService)
local StateService = require(script.Parent.StateService)

local DebugService = {}

local function target(): (Player, Data.Profile)
	local player = Players:GetPlayers()[1]
	assert(player, "aucun joueur dans le serveur")
	local data = DataService.get(player)
	assert(data, "profil pas encore chargé")
	return player, data
end

local function changed(player: Player)
	PlotService.refresh(player)
	StateService.markDirty(player)
end

local commands: { [string]: (...any) -> ...any } = {
	give = function(coins: number)
		local player, data = target()
		data.coins += coins
		changed(player)
	end,
	setButtons = function(count: number)
		local player, data = target()
		data.buttons = count
		changed(player)
	end,
	setDiaper = function(index: number)
		local player, data = target()
		data.diaper = index
		changed(player)
	end,
	setRebirths = function(count: number)
		local player, data = target()
		data.rebirths = count
		changed(player)
	end,
	-- Rejoue l'arrivée du joueur comme s'il était parti `seconds` secondes ; renvoie le gain.
	welcome = function(seconds: number): string
		local player, data = target()
		data.lastSeen = Clock.now() - seconds
		return Format.number(OfflineService.collect(player, data))
	end,
	-- Écrit les scores du joueur puis relit les classements, sans attendre les 2 min.
	boards = function(): string
		local player = target()
		LeaderboardService.save(player)
		return LeaderboardService.refresh() .. " panneaux relus"
	end,
	-- Remet le profil à neuf.
	reset = function()
		local player, data = target()
		local profile = data :: any
		for key in profile do
			profile[key] = nil
		end
		for key, value in Data.template() :: any do
			profile[key] = value
		end
		changed(player)
	end,
	info = function(): string
		local player, data = target()
		return string.format(
			"%s : %s PoopCoins, %d boutons, couche %d, %d rebirths, %s Tétines, %d cacas, %d clics, %s/s, tuto %d",
			player.Name,
			Format.number(data.coins),
			data.buttons,
			data.diaper,
			data.rebirths,
			Format.number(data.binkies),
			data.totalPoops,
			data.totalClicks,
			Format.number(IncomeService.income(player)),
			data.tutorial
		)
	end,
}

function DebugService.start()
	if not RunService:IsStudio() then
		return
	end
	local bridge = Instance.new("BindableFunction")
	bridge.Name = "DebugCommands"
	bridge.OnInvoke = function(name: string, ...: any): ...any
		local command = commands[name]
		assert(command, "commande inconnue : " .. tostring(name))
		return command(...)
	end
	bridge.Parent = ServerStorage
end

return DebugService
