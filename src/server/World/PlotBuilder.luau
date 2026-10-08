--!strict
-- Construit et met à jour la nursery d'une base (spec, section 2). Les positions viennent de Layout.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Baby = require(Shared.Builders.Baby)
local Buttons = require(Shared.Config.Buttons)
local Config = require(Shared.Config.Economy)
local Decor = require(Shared.Builders.Decor)
local Diapers = require(Shared.Config.Diapers)
local Economy = require(Shared.Logic.Economy)
local Format = require(Shared.Logic.Format)
local Furniture = require(Shared.Builders.Furniture)
local Layout = require(script.Parent.Layout)
local Machine = require(Shared.Builders.Machine)
local Pad = require(Shared.Builders.Pad)
local Parts = require(Shared.Builders.Parts)

local PlotBuilder = {}

local function origin(slot: Model): CFrame
	return slot:GetAttribute("Origin") :: CFrame
end

local function nursery(slot: Model): Model
	return slot:FindFirstChild("Nursery") :: Model
end

local function place(model: Model, parent: Instance, cframe: CFrame)
	model:PivotTo(cframe)
	model.Parent = parent
end

local function priceText(price: number): string
	return if price == 0 then "FREE" else "💩 " .. Format.number(price)
end

-- Construit les éléments fixes de la nursery et marque la base comme occupée.
function PlotBuilder.build(slot: Model, ownerUserId: number)
	local base = origin(slot)
	local root = Parts.model("Nursery")

	Parts.make(root, {
		name = "Spawn",
		size = Vector3.new(4, 1, 4),
		cframe = base * Layout.spawn,
		color = "#FFFFFF",
		transparency = 1,
		collide = false,
	})

	local conveyor = Furniture.belt(Layout.beltLength, Layout.beltWidth)
	place(conveyor, root, base * Layout.beltCenter)
	local belt = conveyor:FindFirstChild("Belt") :: Part
	belt.AssemblyLinearVelocity = belt.CFrame.XVector * Config.beltSpeed

	place(Furniture.potty(), root, base * Layout.potty)
	place(Baby.build(), root, base * Layout.baby)
	place(Furniture.changingTable(), root, base * Layout.changingTable)
	place(Pad.build("PadActive"), root, base * Layout.padActive)
	place(Pad.build("PadNext"), root, base * Layout.padNext)

	local items = Instance.new("Folder")
	items.Name = "Items"
	items.Parent = root
	local poops = Instance.new("Folder")
	poops.Name = "Poops"
	poops.Parent = root

	root.Parent = slot
	slot:SetAttribute("OwnerUserId", ownerUserId)
end

-- Vide la base et la rend libre.
function PlotBuilder.clear(slot: Model)
	local root = slot:FindFirstChild("Nursery")
	if root then
		root:Destroy()
	end
	slot:SetAttribute("OwnerUserId", nil)
end

-- Machines et décos achetées : ajoute celles qui manquent, retire celles en trop.
function PlotBuilder.syncItems(slot: Model, buttons: number)
	local base = origin(slot)
	local items = nursery(slot):FindFirstChild("Items") :: Folder
	local machineIndex = 0
	for index, button in Buttons do
		local isMachine = button.kind == "machine"
		if isMachine then
			machineIndex += 1
		end
		local existing = items:FindFirstChild(button.id)
		if index <= buttons and existing == nil then
			if isMachine then
				place(Machine.build(button), items, base * Layout.machines[machineIndex])
			else
				local placement = Layout.decor[button.id]
				assert(placement, "pas de place pour la déco " .. button.id)
				place(Decor.build(button), items, base * placement)
			end
		elseif index > buttons and existing then
			existing:Destroy()
		end
	end
end

-- Dalle active = bouton suivant ; dalle « NEXT » = celui d'après.
function PlotBuilder.syncPads(slot: Model, buttons: number)
	local root = nursery(slot)
	local active = root:FindFirstChild("PadActive") :: Model
	local following = root:FindFirstChild("PadNext") :: Model
	local current = Buttons[buttons + 1]
	local after = Buttons[buttons + 2]
	if current then
		Pad.show(active, current.name, priceText(current.price), false)
	else
		Pad.hide(active)
	end
	if after then
		Pad.show(following, after.name, priceText(after.price), true)
	else
		Pad.hide(following)
	end
end

function PlotBuilder.setPadAffordable(slot: Model, affordable: boolean)
	Pad.setAffordable(nursery(slot):FindFirstChild("PadActive") :: Model, affordable)
end

-- Couleur de la couche et taille du bébé.
function PlotBuilder.syncBaby(slot: Model, buttons: number, diaper: number, rebirths: number)
	local baby = nursery(slot):FindFirstChild("Baby") :: Model
	local look = Diapers[diaper]
	Baby.setDiaper(baby, look.color, look.material)
	local scale = Economy.babyScale(buttons, diaper, rebirths)
	if math.abs(baby:GetScale() - scale) > 1e-3 then
		baby:ScaleTo(scale)
	end
end

function PlotBuilder.poopSpawn(slot: Model): CFrame
	return origin(slot) * CFrame.new(Layout.poopSpawn)
end

function PlotBuilder.padPosition(slot: Model): Vector3
	return (origin(slot) * Layout.padActive).Position
end

function PlotBuilder.spawnCFrame(slot: Model): CFrame
	return origin(slot) * Layout.spawn
end

return PlotBuilder
