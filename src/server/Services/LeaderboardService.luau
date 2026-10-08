--!strict
-- Classements mondiaux (spec, section 4) : « Biggest Babies » (rebirths) et « Poop Kings » (total de PoopCoins
-- gagnés depuis le début). Les scores sont écrits à chaque rebirth, toutes les 5 min et au départ du joueur ;
-- les panneaux de la place relisent le top 50 toutes les 2 min. Les 3 premiers en rebirths ont une couronne
-- sur leur bébé s'ils sont dans le serveur. Un échec garde la dernière liste affichée et réessaie au cycle suivant.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Baby = require(ReplicatedStorage.Shared.Builders.Baby)
local Board = require(ReplicatedStorage.Shared.Builders.Board)
local Config = require(ReplicatedStorage.Shared.Config.Leaderboards)
local Data = require(ReplicatedStorage.Shared.Logic.Data)
local DataService = require(script.Parent.DataService)
local Format = require(ReplicatedStorage.Shared.Logic.Format)
local Leaderboard = require(ReplicatedStorage.Shared.Logic.Leaderboard)
local PlotService = require(script.Parent.PlotService)
local RebirthService = require(script.Parent.RebirthService)

-- En Studio, des classements séparés : les tests ne touchent jamais aux vrais scores.
local SUFFIX = if RunService:IsStudio() then "_Studio" else ""

type Ranking = {
	storeName: string,
	board: string, -- nom du panneau dans workspace.Map
	crowned: boolean, -- ce classement donne les couronnes du top 3
	score: (data: Data.Profile) -> number, -- entier écrit dans l'OrderedDataStore
	show: (score: number) -> string, -- texte affiché sur le panneau
	store: OrderedDataStore?,
}

local LeaderboardService = {}

local rankings: { Ranking } = {
	{
		storeName = "Rebirths_v1",
		board = "BoardRebirths",
		crowned = true,
		score = function(data)
			return data.rebirths
		end,
		show = function(score)
			return Format.number(score)
		end,
	},
	{
		storeName = "TotalEarned_v1",
		board = "BoardEarned",
		crowned = false,
		score = function(data)
			return Leaderboard.encodeEarned(data.totalEarned)
		end,
		show = function(score)
			return Format.number(Leaderboard.decodeEarned(score))
		end,
	},
}
local names: { [number]: string } = {} -- UserId → nom, pour ne pas le redemander
local crowns: { [number]: string } = {} -- UserId → couleur de sa couronne

local function nameOf(userId: number): string
	local known = names[userId]
	if known then
		return known
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if not ok then
		return "#" .. userId
	end
	names[userId] = name
	return name
end

-- Scores d'un joueur, lus tout de suite : son profil peut disparaître juste après.
local function scoresOf(player: Player): { number }?
	local data = DataService.get(player)
	if data == nil then
		return nil
	end
	local scores = {}
	for index, ranking in rankings do
		scores[index] = ranking.score(data)
	end
	return scores
end

-- Écrit des scores (appel bloquant). Un score nul n'est pas écrit.
local function write(userId: number, scores: { number })
	for index, ranking in rankings do
		local store = ranking.store
		local score = scores[index]
		if store and score > 0 then
			local ok, problem = pcall(function()
				store:SetAsync(tostring(userId), score)
			end)
			if not ok and RunService:IsStudio() then
				warn("[Leaderboards] écriture impossible : " .. tostring(problem))
			end
		end
	end
end

local function crown(player: Player, slot: Model)
	local nursery = slot:FindFirstChild("Nursery")
	local baby = nursery and nursery:FindFirstChild("Baby")
	if baby and baby:IsA("Model") then
		Baby.setCrown(baby, crowns[player.UserId])
	end
end

-- Relit le top d'un classement et remplit son panneau. Renvoie les UserId dans l'ordre, ou nil si la lecture
-- a échoué (le panneau garde alors sa dernière liste).
local function read(ranking: Ranking, store: OrderedDataStore, board: Model): { number }?
	local ok, page = pcall(function()
		return store:GetSortedAsync(false, Config.size):GetCurrentPage()
	end)
	if not ok then
		return nil
	end
	local rows: { Board.Row } = {}
	local top = {}
	for _, entry in page do
		local userId = tonumber(entry.key) or 0
		table.insert(rows, { name = nameOf(userId), score = ranking.show(entry.value) })
		table.insert(top, userId)
	end
	Board.render(board, rows)
	return top
end

-- Écrit tout de suite les scores d'un joueur (appel bloquant).
function LeaderboardService.save(player: Player)
	local scores = scoresOf(player)
	if scores then
		write(player.UserId, scores)
	end
end

-- Relit les classements, met les panneaux et les couronnes à jour. Renvoie le nombre de panneaux relus.
function LeaderboardService.refresh(): number
	local map = workspace:FindFirstChild("Map")
	local done = 0
	for _, ranking in rankings do
		local store = ranking.store
		local board = map and map:FindFirstChild(ranking.board)
		if store and board and board:IsA("Model") then
			local top = read(ranking, store, board)
			if top then
				done += 1
				if ranking.crowned then
					table.clear(crowns)
					for rank = 1, math.min(3, #top) do
						crowns[top[rank]] = Config.crownColors[rank]
					end
					for player, slot in PlotService.owners() do
						crown(player, slot)
					end
				end
			end
		end
	end
	return done
end

function LeaderboardService.init()
	for _, ranking in rankings do
		local ok, store = pcall(function()
			return DataStoreService:GetOrderedDataStore(ranking.storeName .. SUFFIX)
		end)
		ranking.store = if ok then store else nil
	end
end

function LeaderboardService.start()
	RebirthService.done:connect(function(player: Player)
		task.spawn(LeaderboardService.save, player)
	end)
	DataService.released:connect(function(player: Player)
		local scores = scoresOf(player)
		if scores then
			task.spawn(write, player.UserId, scores)
		end
	end)
	PlotService.built:connect(crown)
	task.spawn(function()
		while true do
			LeaderboardService.refresh()
			task.wait(Config.refreshSeconds)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.writeSeconds)
			for _, player in Players:GetPlayers() do
				LeaderboardService.save(player)
			end
		end
	end)
end

return LeaderboardService
