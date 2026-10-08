--!strict
-- Attribue une base à chaque joueur chargé, la construit, l'y téléporte, la libère à son départ.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local MapBuilder = require(script.Parent.Parent.World.MapBuilder)
local PlotBuilder = require(script.Parent.Parent.World.PlotBuilder)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)

local PlotService = {
	built = Signal.new(), -- (player, slot) : la nursery du joueur vient d'être construite
}

local slots: { Model } = {}
local owned: { [Player]: Model } = {}

function PlotService.teleportHome(player: Player)
	local slot: Model? = owned[player]
	local character = player.Character
	if slot and character then
		character:PivotTo(PlotBuilder.spawnCFrame(slot))
	end
end

-- Met la nursery à jour d'après la sauvegarde : objets achetés, dalles, bébé.
function PlotService.refresh(player: Player)
	local slot: Model? = owned[player]
	local data = DataService.get(player)
	if slot == nil or data == nil then
		return
	end
	PlotBuilder.syncItems(slot, data.buttons)
	PlotBuilder.syncPads(slot, data.buttons)
	PlotBuilder.syncBaby(slot, data.buttons, data.diaper, data.rebirths)
end

local function assign(player: Player)
	for _, slot in slots do
		if slot:GetAttribute("OwnerUserId") == nil then
			PlotBuilder.build(slot, player.UserId)
			owned[player] = slot
			player:SetAttribute("Plot", slot.Name)
			PlotService.refresh(player)
			PlotService.built:fire(player, slot)
			PlotService.teleportHome(player)
			return
		end
	end
	player:Kick("This server is full, please join another one.")
end

local function release(player: Player)
	local slot: Model? = owned[player]
	if slot then
		owned[player] = nil
		PlotBuilder.clear(slot)
	end
end

local function watchCharacter(player: Player)
	player.CharacterAdded:Connect(function()
		task.defer(PlotService.teleportHome, player)
	end)
end

function PlotService.init()
	slots = MapBuilder.build()
end

function PlotService.start()
	DataService.loaded:connect(assign)
	DataService.released:connect(release)
	Players.PlayerAdded:Connect(watchCharacter)
	for _, player in Players:GetPlayers() do
		watchCharacter(player)
	end
end

function PlotService.get(player: Player): Model?
	return owned[player]
end

-- Joueurs qui ont une base, avec leur base.
function PlotService.owners(): { [Player]: Model }
	return owned
end

return PlotService
