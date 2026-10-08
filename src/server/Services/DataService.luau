--!strict
-- Sauvegardes des joueurs avec ProfileStore (spec, section 11).
-- Un profil qui ne se charge pas = le joueur est renvoyé avec un message : rien n'est écrasé.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Clock = require(script.Parent.Parent.Clock)
local Data = require(ReplicatedStorage.Shared.Logic.Data)
local ProfileStore = require(script.Parent.Parent.Vendor.ProfileStore)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)

-- En Studio, une base séparée : les tests ne touchent jamais aux données des vrais joueurs.
local STORE_NAME = "Profiles_v1" .. (if RunService:IsStudio() then "_Studio" else "")

local DataService = {
	loaded = Signal.new(), -- (player, data) : profil chargé et prêt
	released = Signal.new(), -- (player) : le joueur part ; son profil va être sauvegardé une dernière fois
}

local store: any = nil
local profiles: { [Player]: any } = {}

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if profile == nil then
		if player.Parent == Players then
			player:Kick("Couldn't load your save, please rejoin.")
		end
		return
	end
	profile:AddUserId(player.UserId)
	profile:Reconcile()
	Data.migrate(profile.Data)
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick("Your save was opened on another server, please rejoin.")
	end)
	if player.Parent ~= Players then
		profile:EndSession()
		return
	end
	if profile.Data.stats.firstJoin == 0 then
		profile.Data.stats.firstJoin = Clock.now()
	end
	profiles[player] = profile
	DataService.loaded:fire(player, profile.Data)
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile == nil then
		return
	end
	profile.Data.lastSeen = Clock.now()
	DataService.released:fire(player)
	profile:EndSession()
end

function DataService.init()
	store = ProfileStore.New(STORE_NAME, Data.template())
end

function DataService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

-- Données du joueur, ou nil si son profil n'est pas (ou plus) chargé.
function DataService.get(player: Player): Data.Profile?
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

return DataService
