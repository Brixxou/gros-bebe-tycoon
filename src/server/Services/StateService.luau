--!strict
-- Envoie à chaque joueur l'état de sa partie (Net.Snapshot) quand il change, au plus 5 fois par seconde.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local IncomeService = require(script.Parent.IncomeService)
local Net = require(ReplicatedStorage.Shared.Net)

local StateService = {}

local dirty: { [Player]: boolean } = {}

function StateService.markDirty(player: Player)
	dirty[player] = true
end

function StateService.snapshot(player: Player): Net.Snapshot?
	local data = DataService.get(player)
	if data == nil then
		return nil
	end
	return {
		coins = data.coins,
		binkies = data.binkies,
		totalEarned = data.totalEarned,
		totalClicks = data.totalClicks,
		buttons = data.buttons,
		diaper = data.diaper,
		rebirths = data.rebirths,
		clicksSinceMega = data.clicksSinceMega,
		tutorial = data.tutorial,
		income = IncomeService.income(player),
		baseIncome = IncomeService.baseIncome(player),
	}
end

function StateService.start()
	local remote = Net.event("State")
	DataService.loaded:connect(StateService.markDirty)
	DataService.released:connect(function(player: Player)
		dirty[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(0.2)
			for player in dirty do
				dirty[player] = nil
				local snapshot = StateService.snapshot(player)
				if snapshot then
					remote:FireClient(player, snapshot)
				end
			end
		end
	end)
end

return StateService
