--!strict
-- Achats en PoopCoins (spec, section 2) : se tenir sur la dalle active achète le bouton suivant dès qu'on a
-- assez ; la table à langer envoie BuyDiaper pour la couche suivante.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Buttons = require(ReplicatedStorage.Shared.Config.Buttons)
local DataService = require(script.Parent.DataService)
local Format = require(ReplicatedStorage.Shared.Logic.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local PlotBuilder = require(script.Parent.Parent.World.PlotBuilder)
local PlotService = require(script.Parent.PlotService)
local RateLimit = require(ReplicatedStorage.Shared.Logic.RateLimit)
local Shop = require(ReplicatedStorage.Shared.Logic.Shop)
local StateService = require(script.Parent.StateService)

local PAD_RADIUS = 4.5
local BUY_COOLDOWN = 0.6 -- pause entre deux achats quand on reste sur la dalle
local TOAST_COOLDOWN = 2.5

local ShopService = {}

local lastBuy: { [Player]: number } = {}
local lastToast: { [Player]: number } = {}
local affordable: { [Player]: boolean } = {}
local diaperLimiter = RateLimit.new(2, 2)
local toast: RemoteEvent

local function standingOnPad(player: Player, slot: Model): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return false
	end
	local offset = root.Position - PlotBuilder.padPosition(slot)
	return Vector3.new(offset.X, 0, offset.Z).Magnitude <= PAD_RADIUS and math.abs(offset.Y) < 8
end

function ShopService.buyButton(player: Player): Shop.BuyResult?
	local data = DataService.get(player)
	if data == nil then
		return nil
	end
	local result = Shop.buyNextButton(data)
	if result.reason == "bought" then
		PlotService.refresh(player)
		StateService.markDirty(player)
	end
	return result
end

function ShopService.buyDiaper(player: Player)
	if not RateLimit.allow(diaperLimiter, player, os.clock()) then
		return
	end
	local data = DataService.get(player)
	if data == nil then
		return
	end
	local result = Shop.buyNextDiaper(data)
	if result.reason == "bought" then
		PlotService.refresh(player)
		StateService.markDirty(player)
	elseif result.reason == "poor" then
		toast:FireClient(player, "Toast.NeedMore", { Format.number(result.missing) })
	end
end

local function tick()
	local now = os.clock()
	for player, slot in PlotService.owners() do
		local data = DataService.get(player)
		if data == nil then
			continue
		end
		local nextButton = Buttons[data.buttons + 1]
		local canAfford = nextButton ~= nil and data.coins >= nextButton.price
		if affordable[player] ~= canAfford then
			affordable[player] = canAfford
			PlotBuilder.setPadAffordable(slot, canAfford)
		end
		if nextButton and standingOnPad(player, slot) and now - (lastBuy[player] or 0) >= BUY_COOLDOWN then
			local result = ShopService.buyButton(player)
			if result and result.reason == "bought" then
				lastBuy[player] = now
				affordable[player] = nil -- nouvelle dalle : sa couleur sera recalculée au prochain tour
			elseif
				result
				and result.reason == "poor"
				and now - (lastToast[player] or 0) >= TOAST_COOLDOWN
			then
				lastToast[player] = now
				toast:FireClient(player, "Toast.NeedMore", { Format.number(result.missing) })
			end
		end
	end
end

function ShopService.start()
	toast = Net.event("Toast")
	Net.event("BuyDiaper").OnServerEvent:Connect(ShopService.buyDiaper)
	Players.PlayerRemoving:Connect(function(player)
		lastBuy[player] = nil
		lastToast[player] = nil
		affordable[player] = nil
		RateLimit.forget(diaperLimiter, player)
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			tick()
		end
	end)
end

return ShopService
