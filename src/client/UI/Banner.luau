--!strict
-- Annonces à tout le serveur (spec, section 4) : une bannière en haut de l'écran pendant 5 s et un message
-- système dans le chat.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Net = require(ReplicatedStorage.Shared.Net)
local New = require(script.Parent.New)
local Screen = require(script.Parent.Screen)
local Text = require(script.Parent.Parent.Text)
local Theme = require(script.Parent.Theme)

local SHOW_SECONDS = 5

local Banner = {}

-- Message système dans le canal général du chat, s'il existe.
local function chat(message: string)
	pcall(function()
		local channels = TextChatService:FindFirstChild("TextChannels")
		local general = channels and channels:FindFirstChild("RBXGeneral")
		if general and general:IsA("TextChannel") then
			general:DisplaySystemMessage(message)
		end
	end)
end

function Banner.start()
	local gui = Screen.create("Banner", 25)
	local label = New("TextLabel", {
		Name = "Banner",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 146),
		Size = UDim2.fromOffset(760, 64),
		BackgroundColor3 = Theme.colors.rebirth,
		Font = Theme.fonts.title,
		Text = "",
		TextScaled = true,
		TextColor3 = Theme.colors.white,
		AutoLocalize = false,
		Visible = false,
		Parent = gui,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 16) }),
		New(
			"UIStroke",
			{ Thickness = 3, Color = Theme.colors.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
		),
		New("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }),
	})
	local shownAt = 0
	Net.event("Announce").OnClientEvent:Connect(function(key: string, args: { any }?)
		local message = Text.get(key, args)
		chat(message)
		label.Text = "📣 " .. message
		label.Visible = true
		local at = os.clock()
		shownAt = at
		task.delay(SHOW_SECONDS, function()
			if shownAt == at then
				label.Visible = false -- aucune annonce plus récente entre-temps
			end
		end)
	end)
end

return Banner
