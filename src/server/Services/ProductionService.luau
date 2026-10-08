--!strict
-- Les cacas (spec, section 3) : un toutes les 1,5 s par base, ils roulent jusqu'au pot qui crédite leur valeur.
-- Un caca coincé est crédité au bout de 20 s. Les joueurs passent à travers les cacas (groupes de collision).
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config.Economy)
local DataService = require(script.Parent.DataService)
local Diapers = require(ReplicatedStorage.Shared.Config.Diapers)
local IncomeService = require(script.Parent.IncomeService)
local Net = require(ReplicatedStorage.Shared.Net)
local PlotBuilder = require(script.Parent.Parent.World.PlotBuilder)
local PlotService = require(script.Parent.PlotService)
local Poop = require(ReplicatedStorage.Shared.Builders.Poop)
local Poops = require(ReplicatedStorage.Shared.Logic.Poops)
local StateService = require(script.Parent.StateService)

local MEGA_SCALE = 1.6
local MAX_SIZE = 6.4 -- au-delà, le caca ne tient plus sur le tapis

type LivePoop = { model: Model, owner: Player, value: number, expires: number }

local ProductionService = {}

local live: { [BasePart]: LivePoop } = {}
local timers: { [Player]: number } = {}
local effect: RemoteEvent

local function credit(root: BasePart)
	local poop = live[root]
	if poop == nil then
		return
	end
	live[root] = nil
	local data = DataService.get(poop.owner)
	if data then
		Poops.credit(data, poop.value)
		StateService.markDirty(poop.owner)
		effect:FireClient(poop.owner, "credit", poop.value)
	end
	poop.model:Destroy()
end

-- Fait tomber un caca de valeur `value` sur le tapis du joueur.
function ProductionService.spawn(player: Player, value: number, mega: boolean)
	local slot = PlotService.get(player)
	local data = DataService.get(player)
	local nursery = slot and slot:FindFirstChild("Nursery")
	if slot == nil or data == nil or nursery == nil then
		return
	end
	local look = Diapers[data.diaper]
	local size = math.min(MAX_SIZE, Poops.size(value) * (if mega then MEGA_SCALE else 1))
	local model, root = Poop.build(size, look.poopColor, look.poopMaterial)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Poops"
		end
	end
	model:PivotTo(PlotBuilder.poopSpawn(slot))
	model.Parent = nursery:FindFirstChild("Poops")
	root:SetNetworkOwner(nil)
	live[root] =
		{ model = model, owner = player, value = value, expires = os.clock() + Config.poopSafetySeconds }
end

-- Détruit les cacas du joueur encore en route, sans les créditer (ex. au rebirth).
function ProductionService.clear(player: Player)
	for root, poop in live do
		if poop.owner == player then
			live[root] = nil
			poop.model:Destroy()
		end
	end
end

local function onCharacter(character: Model)
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Players"
		end
	end
	character.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") then
			part.CollisionGroup = "Players"
		end
	end)
end

local function watchPlayer(player: Player)
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		onCharacter(player.Character)
	end
end

local function onPlotBuilt(player: Player, slot: Model)
	local sensor = slot:FindFirstChild("Sensor", true)
	if sensor and sensor:IsA("BasePart") then
		sensor.Touched:Connect(function(hit: BasePart)
			local poop = live[hit]
			if poop and poop.owner == player then
				credit(hit)
			end
		end)
	end
end

local function step(dt: number)
	for player in PlotService.owners() do
		local elapsed = (timers[player] or 0) + dt
		if elapsed >= Config.poopInterval then
			elapsed -= Config.poopInterval
			local income = IncomeService.income(player)
			if income > 0 then
				ProductionService.spawn(player, Poops.value(income), false)
			end
		end
		timers[player] = elapsed
	end
	local now = os.clock()
	for root, poop in live do
		if root.Parent == nil then
			live[root] = nil -- base libérée : le caca a été détruit avec elle
		elseif now >= poop.expires then
			credit(root)
		end
	end
end

function ProductionService.init()
	PhysicsService:RegisterCollisionGroup("Poops")
	PhysicsService:RegisterCollisionGroup("Players")
	PhysicsService:CollisionGroupSetCollidable("Poops", "Players", false)
end

function ProductionService.start()
	effect = Net.event("Effect")
	PlotService.built:connect(onPlotBuilt)
	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		timers[player] = nil
	end)
	RunService.Heartbeat:Connect(step)
end

return ProductionService
