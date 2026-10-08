--!strict
-- Classement du serveur, dans la liste des joueurs (spec, section 4) : PoopCoins (texte formaté) et Rebirths.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local Format = require(ReplicatedStorage.Shared.Logic.Format)

local UPDATE_EVERY = 1 -- secondes

local LeaderstatsService = {}

local function create(player: Player)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local coins = Instance.new("StringValue")
	coins.Name = "PoopCoins"
	coins.Value = "0"
	coins.Parent = folder
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = folder
	folder.Parent = player
end

local function update(player: Player)
	local data = DataService.get(player)
	local folder = player:FindFirstChild("leaderstats")
	if data == nil or folder == nil then
		return
	end
	local coins = folder:FindFirstChild("PoopCoins") :: StringValue
	local rebirths = folder:FindFirstChild("Rebirths") :: IntValue
	coins.Value = Format.number(data.coins)
	rebirths.Value = data.rebirths
end

function LeaderstatsService.start()
	DataService.loaded:connect(create)
	task.spawn(function()
		while true do
			task.wait(UPDATE_EVERY)
			for _, player in Players:GetPlayers() do
				update(player)
			end
		end
	end)
end

return LeaderstatsService
