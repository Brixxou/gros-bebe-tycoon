--!strict
-- Les RemoteEvents du jeu. Le serveur les crée au démarrage (Net.setup), le client les attend (Net.event).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	"Click", -- client → serveur : un appui sur PUSH!
	"BuyDiaper", -- client → serveur : acheter la couche suivante
	"Rebirth", -- client → serveur : faire un rebirth
	"State", -- serveur → client : état de la partie du joueur (Snapshot)
	"Toast", -- serveur → client : message court (clé de traduction, arguments)
	"Effect", -- serveur → client : effet ("credit" au pot, "mega" caca), avec une valeur
	"WelcomeBack", -- serveur → client : gains hors ligne crédités (PoopCoins, secondes d'absence)
	"Announce", -- serveur → tous : annonce (clé de traduction, arguments)
}

-- Ce que le client sait de sa partie.
export type Snapshot = {
	coins: number,
	binkies: number,
	totalEarned: number,
	totalClicks: number,
	buttons: number,
	diaper: number,
	rebirths: number,
	clicksSinceMega: number,
	tutorial: number, -- étape du tutoriel (0 = pas commencé, 99 = terminé)
	income: number,
	baseIncome: number,
}

local Net = {}

function Net.setup()
	assert(RunService:IsServer(), "Net.setup est réservé au serveur")
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in NAMES do
		if folder:FindFirstChild(name) == nil then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
end

function Net.event(name: string): RemoteEvent
	assert(table.find(NAMES, name), "remote inconnu : " .. name)
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	return folder:WaitForChild(name) :: RemoteEvent
end

return Net
