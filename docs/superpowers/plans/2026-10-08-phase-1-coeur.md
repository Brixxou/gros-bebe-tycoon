# Phase 1 : le cœur du jeu, plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** la boucle de jeu complète, jouable dans Studio. Chaque joueur reçoit une base. Le bébé fait des cacas qui roulent jusqu'au pot et rapportent des PoopCoins. On achète 22 boutons (machines et décos) et 10 couches, on clique sur PUSH!, et la sauvegarde garde tout.

**Architecture :**
- **Logique pure** (`src/shared/Logic`, testée avec Lune) : formules, achats, clics, modèle de sauvegarde.
- **Constructeurs** (`src/shared/Builders`) : fabriquent les modèles cartoon en formes Roblox.
- **Services serveur** (`src/server/Services`) : appliquent la logique au profil ProfileStore du joueur et envoient l'état au client.
- **Client** (`src/client`) : affiche le HUD, le panneau des couches et les effets. Il n'envoie que des intentions (remotes `Click` et `BuyDiaper`).

**Tech Stack :** Luau, Rojo 7.7.1, Lune 0.10.5, ProfileStore (commit `45c9847`), MCP de Studio.

Spec : `docs/superpowers/specs/2026-10-08-big-baby-tycoon-design.md` (sections 1 à 3, 6, 9, 11). Prérequis : phase 0 terminée (`docs/superpowers/plans/2026-10-08-phase-0-outillage.md`).

## Global Constraints

- Repo : `/Users/nathan/Public/dev/gros-bebe-tycoon`. Toutes les commandes se lancent depuis sa racine, avec `export PATH="$HOME/.rokit/bin:$PATH"`.
- Aucune dépendance en dehors de ProfileStore (copié tel quel, commit `45c9847cbcf1fc260369c50eb335aba7c35aecdd`).
- Langue du jeu : anglais (source) + français dans `src/Localization.csv`. Le mot « Cadum » n'apparaît jamais dans le jeu.
- Logique pure dans `src/shared/Logic` : aucune API Roblox, `--!strict`, `require` relatifs (`require("./X")`, `require("../Config/X")`), testée avec Lune.
- Le serveur décide de tout. Le client n'envoie que les remotes déclarés dans `src/shared/Net.luau`, et le serveur limite leur fréquence.
- Valeurs de la spec à respecter :
  - un caca toutes les 1,5 s, crédité après 20 s s'il est coincé ;
  - clic = max(1 ; 0,15 × revenu/s), méga caca tous les 50 clics = max(50 ; 10 × revenu/s) ;
  - 12 clics/s au plus ;
  - +5 % par déco ;
  - échelle du bébé = (1 + 0,04 × boutons + 0,05 × (couche − 1)) × (1 + 0,1 × rebirths), plafonnée à 4.
- Commentaires du code et messages de commit en français. Chaque commit se termine par la ligne `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- `scripts/check.sh` passe avant chaque commit.
- On ne modifie jamais un script dans Studio : on modifie les fichiers, et Rojo (`rojo serve` + plugin connecté) les pousse.
- **Vérifications dans Studio** : par les outils du MCP de Studio, qui prennent tous le `studio_id` donné par `list_roblox_studios`. On les fait partie lancée (`start_stop_play`) ; le code passé à `execute_luau` indique son `datamodel_type`. La barre de commande et le MCP ne voient pas l'état des modules du jeu : les commandes de test passent par `game.ServerStorage.DebugCommands` (tâche 8).

---

### Task 1 : formatage des nombres et signaux

**Files :**
- Create : `src/shared/Logic/Format.luau`, `src/shared/Util/Signal.luau`
- Test : `tests/Format.spec.luau`, `tests/Signal.spec.luau`

**Interfaces :**
- Produces :
  - `Format.number(value: number): string` : `1234` → `"1.2K"`, `123456` → `"123K"`, `1e15` → `"1Qa"`, au-delà des suffixes → `"1.00e+70"` ;
  - `Signal.new(): Signal`. `signal:connect(handler: (...any) -> ()): () -> ()` renvoie la fonction de déconnexion ; `signal:fire(...)` appelle les handlers tout de suite (synchrone).

- [ ] **Step 1 : Écrire les tests `tests/Format.spec.luau`**

```lua
local T = require("./lib/t")
local Format = require("../src/shared/Logic/Format")

T.describe("Format.number", function()
	T.it("garde les petits nombres entiers", function()
		T.eq(Format.number(0), "0")
		T.eq(Format.number(7.9), "7")
		T.eq(Format.number(999.99), "999")
	end)
	T.it("abrège avec une décimale sous 100", function()
		T.eq(Format.number(1000), "1K")
		T.eq(Format.number(1234), "1.2K")
		T.eq(Format.number(12345), "12.3K")
		T.eq(Format.number(1999), "1.9K")
	end)
	T.it("sans décimale à partir de 100", function()
		T.eq(Format.number(123456), "123K")
		T.eq(Format.number(999999), "999K")
	end)
	T.it("passe aux suffixes suivants", function()
		T.eq(Format.number(1e6), "1M")
		T.eq(Format.number(2.5e9), "2.5B")
		T.eq(Format.number(3e12), "3T")
		T.eq(Format.number(1e15), "1Qa")
		T.eq(Format.number(4.2e18), "4.2Qi")
	end)
	T.it("gère les négatifs et NaN", function()
		T.eq(Format.number(-1500), "-1.5K")
		T.eq(Format.number(0 / 0), "0")
	end)
	T.it("passe en notation scientifique au-delà des suffixes", function()
		T.eq(Format.number(1e70), "1.00e+70")
	end)
end)
```

- [ ] **Step 2 : Écrire les tests `tests/Signal.spec.luau`**

```lua
local T = require("./lib/t")
local Signal = require("../src/shared/Util/Signal")

T.describe("Signal", function()
	T.it("appelle les handlers avec les arguments", function()
		local signal = Signal.new()
		local received = {}
		signal:connect(function(a, b)
			table.insert(received, a .. b)
		end)
		signal:fire("x", "y")
		T.eq(received[1], "xy")
	end)
	T.it("arrête d'appeler un handler déconnecté", function()
		local signal = Signal.new()
		local count = 0
		local disconnect = signal:connect(function()
			count += 1
		end)
		signal:fire()
		disconnect()
		signal:fire()
		T.eq(count, 1)
	end)
end)
```

- [ ] **Step 3 : Vérifier qu'ils échouent**

Run : `lune run tests`
Attendu : `error requiring module "../src/shared/Logic/Format"` et un code de sortie non nul.

- [ ] **Step 4 : Créer `src/shared/Logic/Format.luau`**

```lua
--!strict
-- Affichage des gros nombres en version courte : 1.2K, 3.4M, 5.6B…

local SUFFIXES = {
	"",
	"K",
	"M",
	"B",
	"T",
	"Qa",
	"Qi",
	"Sx",
	"Sp",
	"Oc",
	"No",
	"Dc",
	"Ud",
	"Dd",
	"Td",
	"Qad",
	"Qid",
	"Sxd",
	"Spd",
	"Ocd",
	"Nod",
	"Vg",
}

local Format = {}

function Format.number(value: number): string
	if value ~= value then
		return "0"
	end
	if value < 0 then
		return "-" .. Format.number(-value)
	end
	if value < 1000 then
		return tostring(math.floor(value))
	end
	local tier = math.floor(math.log10(value) / 3)
	local scaled = value / 10 ^ (tier * 3)
	if scaled >= 1000 then -- arrondi flottant de log10 (ex. 1e15 → 14.999…)
		tier += 1
		scaled /= 1000
	elseif scaled < 1 then
		tier -= 1
		scaled *= 1000
	end
	if tier + 1 > #SUFFIXES then
		return string.format("%.2e", value)
	end
	local text
	if scaled < 100 then
		text = string.format("%.1f", math.floor(scaled * 10) / 10)
		text = (string.gsub(text, "%.0$", ""))
	else
		text = tostring(math.floor(scaled))
	end
	return text .. SUFFIXES[tier + 1]
end

return Format
```

- [ ] **Step 5 : Créer `src/shared/Util/Signal.luau`**

```lua
--!strict
-- Signal minimal : connect(handler) renvoie une fonction de déconnexion, fire(...) appelle les handlers.

export type Signal = {
	_handlers: { (...any) -> () },
	connect: (self: Signal, handler: (...any) -> ()) -> () -> (),
	fire: (self: Signal, ...any) -> (),
}

local Signal = {}

local function connect(self: Signal, handler: (...any) -> ()): () -> ()
	table.insert(self._handlers, handler)
	return function()
		local index = table.find(self._handlers, handler)
		if index then
			table.remove(self._handlers, index)
		end
	end
end

local function fire(self: Signal, ...: any)
	for _, handler in table.clone(self._handlers) do
		handler(...)
	end
end

function Signal.new(): Signal
	return {
		_handlers = {},
		connect = connect,
		fire = fire,
	}
end

return Signal
```

- [ ] **Step 6 : Vérifier qu'ils passent**

Run : `lune run tests`
Attendu : `9 tests réussis, 0 en échec`.

- [ ] **Step 7 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `9 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 8 : Commit**

```bash
git add src/shared/Logic/Format.luau src/shared/Util/Signal.luau tests/Format.spec.luau tests/Signal.spec.luau
git commit -m "feat: format des gros nombres et signaux" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 2 : contenu du jeu (config)

**Files :**
- Create : `src/shared/Config/Buttons.luau`, `src/shared/Config/Diapers.luau`, `src/shared/Config/Economy.luau`, `src/shared/Config/World.luau`
- Test : `tests/Config.spec.luau`

**Interfaces :**
- Produces :
  - `Buttons: { Button }`, les 22 boutons dans l'ordre d'achat. `Button = { id, kind ("machine" | "decor"), name (source anglaise), price, rate (production/s, 0 pour une déco), bonus (0.05 pour une déco, 0 pour une machine), color, accent (hexadécimal) }` ;
  - `Diapers: { Diaper }`, les 10 couches. `Diaper = { id, name, mult, price, color, material, poopColor, poopMaterial }` ; les matériaux sont des noms d'`Enum.Material` ;
  - `Config/Economy` : `poopInterval`, `poopSafetySeconds`, `clickFactor`, `clickMin`, `megaEvery`, `megaSeconds`, `megaMin`, `maxClicksPerSecond`, `rebirthBonus`, `doubleCoins`, `vipBonus`, `premiumBonus`, `beltSpeed` ;
  - `Config/World` : `plotCount`, `plotDistance`, `plotSize`, `plazaRadius`.

- [ ] **Step 1 : Écrire les tests `tests/Config.spec.luau`**

```lua
local T = require("./lib/t")
local Buttons = require("../src/shared/Config/Buttons")
local Diapers = require("../src/shared/Config/Diapers")

T.describe("Config", function()
	T.it("a 22 boutons : 12 machines et 10 décos", function()
		local machines, decors = 0, 0
		for _, button in Buttons do
			if button.kind == "machine" then
				machines += 1
				T.truthy(button.rate > 0, button.id .. " produit")
			else
				T.eq(button.kind, "decor", button.id)
				decors += 1
				T.eq(button.bonus, 0.05, button.id)
			end
		end
		T.eq(#Buttons, 22)
		T.eq(machines, 12)
		T.eq(decors, 10)
	end)
	T.it("a des identifiants uniques et des prix croissants", function()
		local seen = {}
		for index, button in Buttons do
			T.truthy(not seen[button.id], "id unique " .. button.id)
			seen[button.id] = true
			if index > 1 then
				T.truthy(button.price > Buttons[index - 1].price, "prix croissant " .. button.id)
			end
		end
		T.eq(Buttons[1].price, 0, "le biberon est gratuit")
	end)
	T.it("a 10 couches, de x1 gratuite à x300", function()
		T.eq(#Diapers, 10)
		T.eq(Diapers[1].price, 0)
		T.eq(Diapers[1].mult, 1)
		T.eq(Diapers[10].id, "cosmic")
		T.eq(Diapers[10].mult, 300)
		for index = 2, #Diapers do
			T.truthy(Diapers[index].mult > Diapers[index - 1].mult, "mult croissant")
			T.truthy(Diapers[index].price > Diapers[index - 1].price, "prix croissant")
		end
	end)
end)
```

- [ ] **Step 2 : Vérifier qu'ils échouent**

Run : `lune run tests`
Attendu : `error requiring module "../src/shared/Config/Buttons"`.

- [ ] **Step 3 : Créer `src/shared/Config/Buttons.luau` (prix et productions de la spec, section 2)**

```lua
--!strict
-- Les 22 boutons de la nursery, dans l'ordre d'achat (spec, section 2).
-- name : texte source anglais (traduit via Localization.csv, clé "Button.<id>").
-- rate : production de base par seconde (machines) ; bonus : bonus de PoopCoins additif (décos).
-- color / accent : couleurs du modèle en hexadécimal.

export type Button = {
	id: string,
	kind: string, -- "machine" ou "decor"
	name: string,
	price: number,
	rate: number,
	bonus: number,
	color: string,
	accent: string,
}

-- stylua: ignore
local Buttons: { Button } = {
	{ id = "milk_bottle", kind = "machine", name = "Milk Bottle", price = 0, rate = 1, bonus = 0, color = "#9AD0F5", accent = "#FFFFFF" },
	{ id = "carrot_mash", kind = "machine", name = "Carrot Mash", price = 50, rate = 3, bonus = 0, color = "#FFB347", accent = "#FF8C1A" },
	{ id = "play_mat", kind = "decor", name = "Play Mat", price = 100, rate = 0, bonus = 0.05, color = "#B5EAD7", accent = "#FFDAC1" },
	{ id = "applesauce_fountain", kind = "machine", name = "Applesauce Fountain", price = 300, rate = 8, bonus = 0, color = "#F6E27F", accent = "#C9E265" },
	{ id = "pastel_walls", kind = "decor", name = "Pastel Walls", price = 600, rate = 0, bonus = 0.05, color = "#FFD1DC", accent = "#FFFFFF" },
	{ id = "cereal_cannon", kind = "machine", name = "Cereal Cannon", price = 1_500, rate = 20, bonus = 0, color = "#F4A261", accent = "#E9C46A" },
	{ id = "crib", kind = "decor", name = "Crib", price = 3_000, rate = 0, bonus = 0.05, color = "#FFFFFF", accent = "#A0C4FF" },
	{ id = "nugget_printer", kind = "machine", name = "Nugget Printer", price = 7_500, rate = 50, bonus = 0, color = "#E76F51", accent = "#F4C430" },
	{ id = "musical_mobile", kind = "decor", name = "Musical Mobile", price = 15_000, rate = 0, bonus = 0.05, color = "#CDB4DB", accent = "#FFC8DD" },
	{ id = "spaghetti_waterfall", kind = "machine", name = "Spaghetti Waterfall", price = 40_000, rate = 125, bonus = 0, color = "#F7D794", accent = "#E63946" },
	{ id = "toy_box", kind = "decor", name = "Toy Box", price = 80_000, rate = 0, bonus = 0.05, color = "#A0C4FF", accent = "#FFADAD" },
	{ id = "pizza_launcher", kind = "machine", name = "Pizza Launcher", price = 200_000, rate = 300, bonus = 0, color = "#E63946", accent = "#F4D35E" },
	{ id = "rocking_horse", kind = "decor", name = "Rocking Horse", price = 400_000, rate = 0, bonus = 0.05, color = "#FFADAD", accent = "#FDFFB6" },
	{ id = "taco_tornado", kind = "machine", name = "Taco Tornado", price = 1_000_000, rate = 750, bonus = 0, color = "#F4D35E", accent = "#6A994E" },
	{ id = "ball_pit", kind = "decor", name = "Ball Pit", price = 2_000_000, rate = 0, bonus = 0.05, color = "#BDE0FE", accent = "#FFAFCC" },
	{ id = "bean_reactor", kind = "machine", name = "Bean Reactor", price = 5_000_000, rate = 1_800, bonus = 0, color = "#6A994E", accent = "#8D5524" },
	{ id = "slide", kind = "decor", name = "Slide", price = 10_000_000, rate = 0, bonus = 0.05, color = "#FFC8DD", accent = "#A2D2FF" },
	{ id = "cheese_volcano", kind = "machine", name = "Cheese Volcano", price = 25_000_000, rate = 4_500, bonus = 0, color = "#FFD166", accent = "#FFB703" },
	{ id = "giant_teddy", kind = "decor", name = "Giant Teddy", price = 50_000_000, rate = 0, bonus = 0.05, color = "#C68B59", accent = "#8D5524" },
	{ id = "burger_black_hole", kind = "machine", name = "Burger Black Hole", price = 125_000_000, rate = 11_000, bonus = 0, color = "#3D2C8D", accent = "#C77DFF" },
	{ id = "bouncy_castle", kind = "decor", name = "Bouncy Castle", price = 250_000_000, rate = 0, bonus = 0.05, color = "#FF6B6B", accent = "#4ECDC4" },
	{ id = "galactic_baby_food", kind = "machine", name = "Galactic Baby Food", price = 600_000_000, rate = 27_000, bonus = 0, color = "#7209B7", accent = "#4CC9F0" },
}

return Buttons
```

- [ ] **Step 4 : Créer `src/shared/Config/Diapers.luau` (spec, section 3)**

```lua
--!strict
-- Les 10 couches, achetées dans l'ordre à la table à langer (spec, section 3).
-- mult : multiplicateur de PoopCoins. Matériaux : noms d'Enum.Material.

export type Diaper = {
	id: string,
	name: string,
	mult: number,
	price: number,
	color: string,
	material: string,
	poopColor: string,
	poopMaterial: string,
}

-- stylua: ignore
local Diapers: { Diaper } = {
	{ id = "cloth", name = "Cloth", mult = 1, price = 0, color = "#FFFFFF", material = "SmoothPlastic", poopColor = "#7B4A2A", poopMaterial = "SmoothPlastic" },
	{ id = "camo", name = "Camo", mult = 2, price = 400, color = "#6B8E4E", material = "SmoothPlastic", poopColor = "#6E4B2A", poopMaterial = "SmoothPlastic" },
	{ id = "gold", name = "Gold", mult = 3.5, price = 6_000, color = "#FFD700", material = "Foil", poopColor = "#FFC300", poopMaterial = "Foil" },
	{ id = "diamond", name = "Diamond", mult = 6.5, price = 80_000, color = "#B9F2FF", material = "Glass", poopColor = "#8EE3F5", poopMaterial = "Glass" },
	{ id = "lava", name = "Lava", mult = 12, price = 1_000_000, color = "#FF5A1F", material = "Neon", poopColor = "#FF7B00", poopMaterial = "Neon" },
	{ id = "rainbow", name = "Rainbow", mult = 24, price = 12_000_000, color = "#FF5FA2", material = "SmoothPlastic", poopColor = "#FF5FA2", poopMaterial = "SmoothPlastic" },
	{ id = "neon", name = "Neon", mult = 45, price = 150_000_000, color = "#39FF14", material = "Neon", poopColor = "#39FF14", poopMaterial = "Neon" },
	{ id = "unicorn", name = "Unicorn", mult = 85, price = 2_000_000_000, color = "#E0BBE4", material = "Glass", poopColor = "#FFB7F5", poopMaterial = "Neon" },
	{ id = "galaxy", name = "Galaxy", mult = 160, price = 9_000_000_000, color = "#3A0CA3", material = "ForceField", poopColor = "#7209B7", poopMaterial = "Neon" },
	{ id = "cosmic", name = "Cosmic", mult = 300, price = 25_000_000_000, color = "#F72585", material = "Neon", poopColor = "#4CC9F0", poopMaterial = "Neon" },
}

return Diapers
```

- [ ] **Step 5 : Créer `src/shared/Config/Economy.luau`**

```lua
--!strict
-- Constantes de l'économie (spec, section 6).
return {
	poopInterval = 1.5, -- secondes entre deux cacas
	poopSafetySeconds = 20, -- un caca coincé est crédité au bout de ce délai
	clickFactor = 0.15, -- un clic vaut 15 % du revenu/s…
	clickMin = 1, -- …et au moins 1
	megaEvery = 50, -- un méga caca tous les 50 clics
	megaSeconds = 10, -- un méga caca vaut 10 s de revenu…
	megaMin = 50, -- …et au moins 50
	maxClicksPerSecond = 12,
	rebirthBonus = 0.5, -- +50 % par rebirth
	doubleCoins = 2, -- pass x2 PoopCoins
	vipBonus = 1.2, -- pass VIP
	premiumBonus = 1.1, -- abonnés Roblox Premium
	beltSpeed = 12, -- studs par seconde
}
```

- [ ] **Step 6 : Créer `src/shared/Config/World.luau`**

```lua
--!strict
-- Dimensions de la map (en studs).
return {
	plotCount = 6,
	plotDistance = 170, -- distance entre le centre de la place et le centre d'une base
	plotSize = 120,
	plazaRadius = 60,
}
```

- [ ] **Step 7 : Vérifier qu'ils passent**

Run : `lune run tests`
Attendu : `12 tests réussis, 0 en échec`.

- [ ] **Step 8 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `12 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 9 : Commit**

```bash
git add src/shared/Config tests/Config.spec.luau
git commit -m "feat: contenu du jeu (22 boutons, 10 couches, constantes)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 3 : sauvegarde, porte-monnaie, revenus et cacas (logique pure)

**Files :**
- Create : `src/shared/Logic/Data.luau`, `src/shared/Logic/Wallet.luau`, `src/shared/Logic/Economy.luau`, `src/shared/Logic/Poops.luau`
- Test : `tests/Data.spec.luau`, `tests/Wallet.spec.luau`, `tests/Economy.spec.luau`, `tests/Poops.spec.luau`

**Interfaces :**
- Consumes : `Config/Buttons`, `Config/Diapers`, `Config/Economy` (tâche 2).
- Produces :
  - `Data.SCHEMA` (1), `Data.template(): Profile` (nouvelle table à chaque appel), `Data.migrate(data: Profile): Profile` ; types `Profile`, `Pet`, `Quest` (champs de la spec, section 11) ;
  - `Wallet.earn(data, amount)` ajoute à `coins` et `totalEarned` (ignore ≤ 0) ; `Wallet.spend(data, amount): boolean` ;
  - `Economy.production(buttons)`, `Economy.decorMultiplier(buttons)`, `Economy.diaperMultiplier(diaper)` ;
  - `Economy.baseIncome(input: IncomeInput): number`, avec `IncomeInput = { buttons, diaper, rebirths, petBonus, doubleCoins, vip, premium }` ;
  - `Economy.clickValue(income)`, `Economy.megaValue(income)`, `Economy.babyScale(buttons, diaper, rebirths)` ;
  - `Poops.value(income)` (revenu × 1,5), `Poops.size(value)` (1 à 4), `Poops.credit(data, value)` (gagne la valeur et compte 1 caca).

- [ ] **Step 1 : Écrire `tests/Data.spec.luau`**

```lua
local T = require("./lib/t")
local Data = require("../src/shared/Logic/Data")

T.describe("Data", function()
	T.it("donne un profil neuf au schéma courant", function()
		local data = Data.template()
		T.eq(data.schema, Data.SCHEMA)
		T.eq(data.coins, 0)
		T.eq(data.buttons, 0)
		T.eq(data.diaper, 1)
		T.eq(data.settings.autoPush, true)
		T.eq(#data.pets.owned, 0)
	end)
	T.it("donne une nouvelle table à chaque appel", function()
		local a = Data.template()
		local b = Data.template()
		a.pets.nextUid = 5
		T.eq(b.pets.nextUid, 1)
	end)
	T.it("migre un profil sans schéma vers le schéma 1", function()
		local data = Data.template()
		data.schema = 0
		Data.migrate(data)
		T.eq(data.schema, 1)
	end)
end)
```

- [ ] **Step 2 : Écrire `tests/Wallet.spec.luau`**

```lua
local T = require("./lib/t")
local Data = require("../src/shared/Logic/Data")
local Wallet = require("../src/shared/Logic/Wallet")

T.describe("Wallet", function()
	T.it("gagner ajoute aux PoopCoins et au total gagné", function()
		local data = Data.template()
		Wallet.earn(data, 120)
		T.eq(data.coins, 120)
		T.eq(data.totalEarned, 120)
	end)
	T.it("ignore les gains nuls ou négatifs", function()
		local data = Data.template()
		Wallet.earn(data, -5)
		Wallet.earn(data, 0)
		T.eq(data.coins, 0)
	end)
	T.it("dépense seulement si on a assez", function()
		local data = Data.template()
		data.coins = 100
		T.eq(Wallet.spend(data, 150), false)
		T.eq(data.coins, 100)
		T.eq(Wallet.spend(data, 100), true)
		T.eq(data.coins, 0)
		T.eq(data.totalEarned, 0, "dépenser ne touche pas au total gagné")
	end)
end)
```

- [ ] **Step 3 : Écrire `tests/Economy.spec.luau`**

```lua
local T = require("./lib/t")
local Economy = require("../src/shared/Logic/Economy")

local function input(overrides: { [string]: any }): Economy.IncomeInput
	local base: { [string]: any } = {
		buttons = 0,
		diaper = 1,
		rebirths = 0,
		petBonus = 0,
		doubleCoins = false,
		vip = false,
		premium = false,
	}
	for key, value in overrides do
		base[key] = value
	end
	return base :: any
end

T.describe("Economy", function()
	T.it("additionne la production des machines achetées", function()
		T.eq(Economy.production(0), 0)
		T.eq(Economy.production(1), 1)
		T.eq(Economy.production(2), 4)
		T.eq(Economy.production(3), 4, "la 3e est une déco")
		T.eq(Economy.production(22), 45_557)
		T.eq(Economy.production(99), 45_557, "borné au nombre de boutons")
	end)
	T.it("donne +5 % par déco achetée", function()
		T.near(Economy.decorMultiplier(2), 1)
		T.near(Economy.decorMultiplier(3), 1.05)
		T.near(Economy.decorMultiplier(22), 1.5)
	end)
	T.it("multiplie le revenu de base", function()
		T.near(Economy.baseIncome(input({ buttons = 2 })), 4)
		T.near(Economy.baseIncome(input({ buttons = 2, diaper = 3 })), 14)
		T.near(Economy.baseIncome(input({ buttons = 2, rebirths = 2 })), 8)
		T.near(Economy.baseIncome(input({ buttons = 2, petBonus = 0.25 })), 5)
		T.near(
			Economy.baseIncome(input({ buttons = 2, doubleCoins = true, vip = true, premium = true })),
			4 * 2 * 1.2 * 1.1
		)
	end)
	T.it("calcule clic et méga caca avec leurs minimums", function()
		T.eq(Economy.clickValue(0), 1)
		T.near(Economy.clickValue(100), 15)
		T.eq(Economy.megaValue(0), 50)
		T.eq(Economy.megaValue(100), 1000)
	end)
	T.it("fait grossir le bébé jusqu'à 4", function()
		T.near(Economy.babyScale(0, 1, 0), 1)
		T.near(Economy.babyScale(22, 10, 0), 1 + 0.88 + 0.45)
		T.eq(Economy.babyScale(22, 10, 20), 4)
	end)
end)
```

- [ ] **Step 4 : Écrire `tests/Poops.spec.luau`**

```lua
local T = require("./lib/t")
local Data = require("../src/shared/Logic/Data")
local Poops = require("../src/shared/Logic/Poops")

T.describe("Poops", function()
	T.it("vaut le revenu de 1,5 s", function()
		T.near(Poops.value(10), 15)
	end)
	T.it("grossit avec la valeur, entre 1 et 4", function()
		T.eq(Poops.size(0), 1)
		T.eq(Poops.size(1), 1)
		T.near(Poops.size(1000), 1.9)
		T.eq(Poops.size(1e20), 4)
	end)
	T.it("crédite les PoopCoins et compte le caca", function()
		local data = Data.template()
		Poops.credit(data, 30)
		T.eq(data.coins, 30)
		T.eq(data.totalEarned, 30)
		T.eq(data.totalPoops, 1)
	end)
end)
```

- [ ] **Step 5 : Vérifier qu'ils échouent**

Run : `lune run tests`
Attendu : `error requiring module "../src/shared/Logic/Data"`.

- [ ] **Step 6 : Créer `src/shared/Logic/Data.luau`**

```lua
--!strict
-- Modèle de la sauvegarde d'un joueur (profil ProfileStore) et ses migrations (spec, section 11).
-- Tout champ ajouté plus tard doit avoir une valeur par défaut ici : ProfileStore complète les vieux profils
-- avec Reconcile(). Les clés de tables sont des chaînes ou des listes (pas de tables à trous).

export type Pet = { uid: string, id: string }
export type Quest = { id: string, target: number, progress: number, claimed: boolean }

export type Profile = {
	schema: number,
	coins: number,
	binkies: number,
	totalEarned: number,
	totalPoops: number,
	totalClicks: number,
	rebirths: number,
	buttons: number, -- nombre de boutons achetés dans la séquence
	diaper: number, -- meilleure couche possédée (index dans Config/Diapers)
	clicksSinceMega: number,
	pets: { nextUid: number, owned: { Pet }, equipped: { string } },
	boosts: { x3Until: number },
	daily: { streak: number, lastDay: number },
	quests: { day: number, list: { Quest }, bonusClaimed: boolean },
	gifts: { day: number, playedSeconds: number, claimed: { number } },
	codes: { [string]: boolean },
	receipts: { string },
	tutorial: number, -- étape en cours, 99 = terminé
	lastSeen: number,
	pendingOffline: number,
	settings: { autoPush: boolean },
	stats: { firstJoin: number, playSeconds: number, eggsOpened: number },
}

local Data = {}

Data.SCHEMA = 1

function Data.template(): Profile
	return {
		schema = Data.SCHEMA,
		coins = 0,
		binkies = 0,
		totalEarned = 0,
		totalPoops = 0,
		totalClicks = 0,
		rebirths = 0,
		buttons = 0,
		diaper = 1,
		clicksSinceMega = 0,
		pets = { nextUid = 1, owned = {}, equipped = {} },
		boosts = { x3Until = 0 },
		daily = { streak = 0, lastDay = -1 },
		quests = { day = -1, list = {}, bonusClaimed = false },
		gifts = { day = -1, playedSeconds = 0, claimed = {} },
		codes = {},
		receipts = {},
		tutorial = 0,
		lastSeen = 0,
		pendingOffline = 0,
		settings = { autoPush = true },
		stats = { firstJoin = 0, playSeconds = 0, eggsOpened = 0 },
	}
end

-- Met un profil chargé au schéma courant. Une migration par version, dans l'ordre.
function Data.migrate(data: Profile): Profile
	if data.schema < 1 then
		data.schema = 1
	end
	return data
end

return Data
```

- [ ] **Step 7 : Créer `src/shared/Logic/Wallet.luau`**

```lua
--!strict
-- Gagner et dépenser des PoopCoins.
local Data = require("./Data")

type Profile = Data.Profile

local Wallet = {}

function Wallet.earn(data: Profile, amount: number)
	if amount <= 0 then
		return
	end
	data.coins += amount
	data.totalEarned += amount
end

function Wallet.spend(data: Profile, amount: number): boolean
	if amount < 0 or data.coins < amount then
		return false
	end
	data.coins -= amount
	return true
end

return Wallet
```

- [ ] **Step 8 : Créer `src/shared/Logic/Economy.luau`**

```lua
--!strict
-- Formules de revenu (spec, section 6).
local Buttons = require("../Config/Buttons")
local Config = require("../Config/Economy")
local Diapers = require("../Config/Diapers")

export type IncomeInput = {
	buttons: number,
	diaper: number,
	rebirths: number,
	petBonus: number, -- somme des bonus des pets équipés (0.25 = +25 %)
	doubleCoins: boolean,
	vip: boolean,
	premium: boolean,
}

local Economy = {}

-- Production de base par seconde des machines achetées.
function Economy.production(buttons: number): number
	local total = 0
	for index = 1, math.min(buttons, #Buttons) do
		total += Buttons[index].rate
	end
	return total
end

function Economy.decorMultiplier(buttons: number): number
	local bonus = 0
	for index = 1, math.min(buttons, #Buttons) do
		bonus += Buttons[index].bonus
	end
	return 1 + bonus
end

function Economy.diaperMultiplier(diaper: number): number
	return Diapers[math.clamp(diaper, 1, #Diapers)].mult
end

-- Revenu de base/s : tous les multiplicateurs permanents, sans les boosts temporaires.
function Economy.baseIncome(input: IncomeInput): number
	local multiplier = Economy.diaperMultiplier(input.diaper)
		* Economy.decorMultiplier(input.buttons)
		* (1 + Config.rebirthBonus * input.rebirths)
		* (1 + input.petBonus)
	if input.doubleCoins then
		multiplier *= Config.doubleCoins
	end
	if input.vip then
		multiplier *= Config.vipBonus
	end
	if input.premium then
		multiplier *= Config.premiumBonus
	end
	return Economy.production(input.buttons) * multiplier
end

function Economy.clickValue(income: number): number
	return math.max(Config.clickMin, Config.clickFactor * income)
end

function Economy.megaValue(income: number): number
	return math.max(Config.megaMin, Config.megaSeconds * income)
end

-- Échelle du bébé : il grossit avec les achats, les couches et les rebirths (plafond 4).
function Economy.babyScale(buttons: number, diaper: number, rebirths: number): number
	return math.min(4, (1 + 0.04 * buttons + 0.05 * (diaper - 1)) * (1 + 0.1 * rebirths))
end

return Economy
```

- [ ] **Step 9 : Créer `src/shared/Logic/Poops.luau`**

```lua
--!strict
-- Les cacas : valeur, taille, crédit au pot.
local Config = require("../Config/Economy")
local Data = require("./Data")
local Wallet = require("./Wallet")

type Profile = Data.Profile

local Poops = {}

-- Valeur d'un caca normal : le revenu de l'intervalle entre deux cacas.
function Poops.value(income: number): number
	return income * Config.poopInterval
end

-- Taille (facteur d'échelle) selon la valeur : de 1 à 4 sur une échelle logarithmique.
function Poops.size(value: number): number
	return math.clamp(1 + 0.3 * math.log10(math.max(value, 1)), 1, 4)
end

function Poops.credit(data: Profile, value: number)
	Wallet.earn(data, value)
	data.totalPoops += 1
end

return Poops
```

- [ ] **Step 10 : Vérifier qu'ils passent**

Run : `lune run tests`
Attendu : `26 tests réussis, 0 en échec`.

- [ ] **Step 11 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `26 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 12 : Commit**

```bash
git add src/shared/Logic tests
git commit -m "feat: modèle de sauvegarde, porte-monnaie, revenus et cacas" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 4 : achats, clics et limiteur de fréquence (logique pure)

**Files :**
- Create : `src/shared/Logic/Shop.luau`, `src/shared/Logic/Clicks.luau`, `src/shared/Logic/RateLimit.luau`
- Test : `tests/Shop.spec.luau`, `tests/Clicks.spec.luau`, `tests/RateLimit.spec.luau`

**Interfaces :**
- Consumes : `Data`, `Wallet`, `Economy` (tâche 3), `Config/*` (tâche 2).
- Produces :
  - `Shop.buyNextButton(data): BuyResult` et `Shop.buyNextDiaper(data): BuyResult`, avec `BuyResult = { reason: "bought" | "poor" | "done", index: number, missing: number }` ;
  - `Clicks.register(data, income): ClickResult`, avec `ClickResult = { value, mega: boolean, megaValue }`. Le méga caca n'est pas crédité ici : c'est un caca physique, crédité au pot ;
  - `RateLimit.new(rate, burst): Limiter`, `RateLimit.allow(limiter, key, now): boolean`, `RateLimit.forget(limiter, key)`.

- [ ] **Step 1 : Écrire `tests/Shop.spec.luau`**

```lua
local T = require("./lib/t")
local Data = require("../src/shared/Logic/Data")
local Shop = require("../src/shared/Logic/Shop")

T.describe("Shop", function()
	T.it("achète le biberon gratuit puis bloque faute d'argent", function()
		local data = Data.template()
		local first = Shop.buyNextButton(data)
		T.eq(first.reason, "bought")
		T.eq(data.buttons, 1)
		local second = Shop.buyNextButton(data)
		T.eq(second.reason, "poor")
		T.eq(second.missing, 50)
		T.eq(data.buttons, 1)
	end)
	T.it("débite le prix du bouton", function()
		local data = Data.template()
		data.buttons = 1
		data.coins = 80
		T.eq(Shop.buyNextButton(data).reason, "bought")
		T.eq(data.coins, 30)
		T.eq(data.buttons, 2)
	end)
	T.it("s'arrête après le 22e bouton", function()
		local data = Data.template()
		data.buttons = 22
		data.coins = 1e30
		T.eq(Shop.buyNextButton(data).reason, "done")
		T.eq(data.buttons, 22)
	end)
	T.it("achète les couches dans l'ordre", function()
		local data = Data.template()
		data.coins = 500
		T.eq(Shop.buyNextDiaper(data).reason, "bought")
		T.eq(data.diaper, 2)
		T.eq(data.coins, 100)
		local result = Shop.buyNextDiaper(data)
		T.eq(result.reason, "poor")
		T.eq(result.missing, 5_900)
		data.diaper = 10
		T.eq(Shop.buyNextDiaper(data).reason, "done")
	end)
end)
```

- [ ] **Step 2 : Écrire `tests/Clicks.spec.luau`**

```lua
local T = require("./lib/t")
local Clicks = require("../src/shared/Logic/Clicks")
local Data = require("../src/shared/Logic/Data")

T.describe("Clicks", function()
	T.it("rapporte au moins 1 et compte le clic", function()
		local data = Data.template()
		local result = Clicks.register(data, 0)
		T.eq(result.value, 1)
		T.eq(result.mega, false)
		T.eq(data.coins, 1)
		T.eq(data.totalClicks, 1)
	end)
	T.it("déclenche un méga caca au 50e clic puis repart à zéro", function()
		local data = Data.template()
		for _ = 1, 49 do
			T.eq(Clicks.register(data, 100).mega, false)
		end
		local fiftieth = Clicks.register(data, 100)
		T.eq(fiftieth.mega, true)
		T.eq(fiftieth.megaValue, 1000)
		T.eq(data.clicksSinceMega, 0)
		T.eq(Clicks.register(data, 100).mega, false)
	end)
end)
```

- [ ] **Step 3 : Écrire `tests/RateLimit.spec.luau`**

```lua
local T = require("./lib/t")
local RateLimit = require("../src/shared/Logic/RateLimit")

T.describe("RateLimit", function()
	T.it("laisse passer la rafale puis bloque", function()
		local limiter = RateLimit.new(12, 12)
		for _ = 1, 12 do
			T.eq(RateLimit.allow(limiter, "a", 0), true)
		end
		T.eq(RateLimit.allow(limiter, "a", 0), false)
	end)
	T.it("recharge avec le temps", function()
		local limiter = RateLimit.new(12, 12)
		for _ = 1, 12 do
			RateLimit.allow(limiter, "a", 0)
		end
		T.eq(RateLimit.allow(limiter, "a", 0.05), false, "0,6 jeton")
		T.eq(RateLimit.allow(limiter, "a", 0.1), true, "1,2 jeton")
	end)
	T.it("sépare les clés", function()
		local limiter = RateLimit.new(1, 1)
		T.eq(RateLimit.allow(limiter, "a", 0), true)
		T.eq(RateLimit.allow(limiter, "b", 0), true)
		T.eq(RateLimit.allow(limiter, "a", 0), false)
		RateLimit.forget(limiter, "a")
		T.eq(RateLimit.allow(limiter, "a", 0), true)
	end)
end)
```

- [ ] **Step 4 : Vérifier qu'ils échouent**

Run : `lune run tests`
Attendu : `error requiring module "../src/shared/Logic/Clicks"` (le premier spec chargé par ordre alphabétique).

- [ ] **Step 5 : Créer `src/shared/Logic/Shop.luau`**

```lua
--!strict
-- Achats en PoopCoins : le bouton suivant de la séquence, la couche suivante.
local Buttons = require("../Config/Buttons")
local Data = require("./Data")
local Diapers = require("../Config/Diapers")
local Wallet = require("./Wallet")

type Profile = Data.Profile

-- reason : "bought" (acheté), "poor" (il manque `missing` PoopCoins), "done" (plus rien à acheter).
export type BuyResult = { reason: string, index: number, missing: number }

local Shop = {}

local function buy(data: Profile, index: number, price: number?): BuyResult
	if price == nil then
		return { reason = "done", index = index, missing = 0 }
	end
	if not Wallet.spend(data, price) then
		return { reason = "poor", index = index, missing = price - data.coins }
	end
	return { reason = "bought", index = index, missing = 0 }
end

function Shop.buyNextButton(data: Profile): BuyResult
	local index = data.buttons + 1
	local button = Buttons[index]
	local result = buy(data, index, if button then button.price else nil)
	if result.reason == "bought" then
		data.buttons = index
	end
	return result
end

function Shop.buyNextDiaper(data: Profile): BuyResult
	local index = data.diaper + 1
	local diaper = Diapers[index]
	local result = buy(data, index, if diaper then diaper.price else nil)
	if result.reason == "bought" then
		data.diaper = index
	end
	return result
end

return Shop
```

- [ ] **Step 6 : Créer `src/shared/Logic/Clicks.luau`**

```lua
--!strict
-- Un clic sur la couche (PUSH!) : gain immédiat, et un méga caca tous les 50 clics.
local Config = require("../Config/Economy")
local Data = require("./Data")
local Economy = require("./Economy")
local Wallet = require("./Wallet")

type Profile = Data.Profile

-- mega : ce clic déclenche un méga caca, qui vaut megaValue une fois arrivé au pot.
export type ClickResult = { value: number, mega: boolean, megaValue: number }

local Clicks = {}

function Clicks.register(data: Profile, income: number): ClickResult
	local value = Economy.clickValue(income)
	Wallet.earn(data, value)
	data.totalClicks += 1
	data.clicksSinceMega += 1
	if data.clicksSinceMega >= Config.megaEvery then
		data.clicksSinceMega = 0
		return { value = value, mega = true, megaValue = Economy.megaValue(income) }
	end
	return { value = value, mega = false, megaValue = 0 }
end

return Clicks
```

- [ ] **Step 7 : Créer `src/shared/Logic/RateLimit.luau`**

```lua
--!strict
-- Limiteur de fréquence par seau de jetons : `rate` jetons par seconde, au plus `burst` d'avance.

export type Limiter = {
	rate: number,
	burst: number,
	buckets: { [any]: { tokens: number, at: number } },
}

local RateLimit = {}

function RateLimit.new(rate: number, burst: number): Limiter
	return { rate = rate, burst = burst, buckets = {} }
end

function RateLimit.allow(limiter: Limiter, key: any, now: number): boolean
	local bucket = limiter.buckets[key]
	if bucket == nil then
		bucket = { tokens = limiter.burst, at = now }
		limiter.buckets[key] = bucket
	end
	bucket.tokens = math.min(limiter.burst, bucket.tokens + (now - bucket.at) * limiter.rate)
	bucket.at = now
	if bucket.tokens >= 1 then
		bucket.tokens -= 1
		return true
	end
	return false
end

function RateLimit.forget(limiter: Limiter, key: any)
	limiter.buckets[key] = nil
end

return RateLimit
```

- [ ] **Step 8 : Vérifier qu'ils passent**

Run : `lune run tests`
Attendu : `35 tests réussis, 0 en échec`.

- [ ] **Step 9 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `35 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 10 : Commit**

```bash
git add src/shared/Logic tests
git commit -m "feat: achats, clics et limiteur de fréquence" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 5 : traductions

**Files :**
- Modify : `src/Localization.csv` (remplacé en entier)
- Test : `tests/Localization.spec.luau`

**Interfaces :**
- Consumes : `Config/Buttons`, `Config/Diapers`.
- Produces :
  - clés utilisées par le client : `HUD.Income` (`+{1}/s`), `Toast.NeedMore`, `Toast.NewDiaper`, `Toast.MegaPoop`, `Table.Owned`, `Table.Wearing`, `Table.Buy` (`BUY {1}`), et `Diaper.<id>` pour les noms de couches ;
  - sources fixes traduites automatiquement : `PUSH!`, `My Base`, `NEXT`, `FREE`, `Changing Table`, `Change Diaper`, et les noms des boutons et des couches.

- [ ] **Step 1 : Écrire `tests/Localization.spec.luau`**

```lua
local fs = require("@lune/fs")
local T = require("./lib/t")
local Buttons = require("../src/shared/Config/Buttons")
local Diapers = require("../src/shared/Config/Diapers")

-- Lit Localization.csv (sans guillemets ni virgules dans les textes) : clé → { source, fr }.
local function load(): { [string]: { source: string, fr: string } }
	local rows = {}
	local lines = string.split(fs.readFile("src/Localization.csv"), "\n")
	T.eq(lines[1], "Key,Source,Context,Example,fr", "en-tête")
	for index = 2, #lines do
		local line = lines[index]
		if line ~= "" then
			local cells = string.split(line, ",")
			T.eq(#cells, 5, "5 colonnes ligne " .. index)
			T.truthy(rows[cells[1]] == nil, "clé unique " .. cells[1])
			rows[cells[1]] = { source = cells[2], fr = cells[5] }
		end
	end
	return rows
end

T.describe("Localization.csv", function()
	local rows = load()
	T.it("traduit chaque bouton avec son nom anglais comme source", function()
		for _, button in Buttons do
			local row = rows["Button." .. button.id]
			T.truthy(row, "ligne Button." .. button.id)
			T.eq(row.source, button.name)
			T.truthy(row.fr ~= "", "français de " .. button.id)
		end
	end)
	T.it("traduit chaque couche", function()
		for _, diaper in Diapers do
			local row = rows["Diaper." .. diaper.id]
			T.truthy(row, "ligne Diaper." .. diaper.id)
			T.eq(row.source, diaper.name)
		end
	end)
	T.it("contient les clés utilisées par le code", function()
		for _, key in
			{
				"HUD.Income",
				"HUD.Push",
				"HUD.MyBase",
				"Pad.Free",
				"Pad.Next",
				"Toast.NeedMore",
				"Toast.NewDiaper",
				"Toast.MegaPoop",
				"Table.Title",
				"Table.Action",
				"Table.Owned",
				"Table.Wearing",
				"Table.Buy",
			}
		do
			T.truthy(rows[key], "clé " .. key)
		end
	end)
end)
```

- [ ] **Step 2 : Vérifier qu'il échoue**

Run : `lune run tests`
Attendu : `35 tests réussis, 3 en échec` (lignes `Button.…`, `Diaper.…` et clés manquantes).

- [ ] **Step 3 : Remplacer `src/Localization.csv`**

```csv
Key,Source,Context,Example,fr
Game.Title,Big Baby Tycoon,,,Big Baby Tycoon
HUD.Income,+{1}/s,,,+{1}/s
HUD.Push,PUSH!,,,POUSSE !
HUD.MyBase,My Base,,,Ma base
Pad.Free,FREE,,,GRATUIT
Pad.Next,NEXT,,,SUIVANT
Toast.NeedMore,You need {1} more PoopCoins!,,,Il te manque {1} PoopCoins !
Toast.NewDiaper,New diaper: {1}!,,,Nouvelle couche : {1} !
Toast.MegaPoop,MEGA POOP!,,,MÉGA CACA !
Table.Title,Changing Table,,,Table à langer
Table.Action,Change Diaper,,,Changer la couche
Table.Owned,Owned,,,Possédée
Table.Wearing,Wearing,,,Portée
Table.Buy,BUY {1},,,ACHETER {1}
Button.milk_bottle,Milk Bottle,,,Biberon
Button.carrot_mash,Carrot Mash,,,Purée de carottes
Button.play_mat,Play Mat,,,Tapis d'éveil
Button.applesauce_fountain,Applesauce Fountain,,,Fontaine de compote
Button.pastel_walls,Pastel Walls,,,Murs pastel
Button.cereal_cannon,Cereal Cannon,,,Canon à céréales
Button.crib,Crib,,,Berceau
Button.nugget_printer,Nugget Printer,,,Imprimante à nuggets
Button.musical_mobile,Musical Mobile,,,Mobile musical
Button.spaghetti_waterfall,Spaghetti Waterfall,,,Cascade de spaghetti
Button.toy_box,Toy Box,,,Coffre à jouets
Button.pizza_launcher,Pizza Launcher,,,Lance-pizzas
Button.rocking_horse,Rocking Horse,,,Cheval à bascule
Button.taco_tornado,Taco Tornado,,,Tornade de tacos
Button.ball_pit,Ball Pit,,,Piscine à balles
Button.bean_reactor,Bean Reactor,,,Réacteur à haricots
Button.slide,Slide,,,Toboggan
Button.cheese_volcano,Cheese Volcano,,,Volcan de fromage
Button.giant_teddy,Giant Teddy,,,Nounours géant
Button.burger_black_hole,Burger Black Hole,,,Trou noir à burgers
Button.bouncy_castle,Bouncy Castle,,,Château gonflable
Button.galactic_baby_food,Galactic Baby Food,,,Petit pot galactique
Diaper.cloth,Cloth,,,Tissu
Diaper.camo,Camo,,,Camouflage
Diaper.gold,Gold,,,Or
Diaper.diamond,Diamond,,,Diamant
Diaper.lava,Lava,,,Lave
Diaper.rainbow,Rainbow,,,Arc-en-ciel
Diaper.neon,Neon,,,Néon
Diaper.unicorn,Unicorn,,,Licorne
Diaper.galaxy,Galaxy,,,Galaxie
Diaper.cosmic,Cosmic,,,Cosmique
```

- [ ] **Step 4 : Vérifier qu'il passe**

Run : `lune run tests`
Attendu : `38 tests réussis, 0 en échec`.

- [ ] **Step 5 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `38 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 6 : Commit**

```bash
git add src/Localization.csv tests/Localization.spec.luau
git commit -m "feat: textes du jeu en anglais et en français" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 6 : modèles cartoon (constructeurs)

**Files :**
- Create : `src/shared/Builders/Parts.luau`, `Baby.luau`, `Poop.luau`, `Pad.luau`, `Machine.luau`, `Decor.luau`, `Furniture.luau` (dans `src/shared/Builders/`)

**Interfaces :**
- Consumes : `Config/Buttons`, `Config/World` (tâche 2).
- Produces : tous les modèles ont leur pivot au sol, au centre, et regardent vers -Z.
  - `Parts.make(parent, props: Props): Part`, avec `Props = { name?, shape?, size, cframe, color (hex), material? (nom), transparency?, collide? (true par défaut) }` ;
  - `Parts.ball(parent, name, diameter, position, color, material?)`, `Parts.cylinder(parent, name, height, diameter, position, color, material?)` (vertical), `Parts.block(parent, name, size, position, color, material?)` ;
  - `Parts.model(name): Model` (pivot à l'origine), `Parts.label(parent, name, text, font, color): TextLabel`, `Parts.material(name): Enum.Material` ;
  - `Baby.build(): Model` contient la pièce `Diaper` avec un `ClickDetector` (portée 80) ; `Baby.setDiaper(model, color, material)` ;
  - `Poop.build(size, color, material): (Model, Part)`. La pièce renvoyée est `Root` : boîte invisible, non ancrée, seule pièce touchable ;
  - `Pad.build(name): Model` (`Disk` > BillboardGui `Label` > TextLabels `Tag`, `Item`, `Price`) ; `Pad.show(model, itemName, priceText, ghost)`, `Pad.hide(model)`, `Pad.setAffordable(model, affordable)` ;
  - `Machine.build(button): Model`, `Decor.build(button): Model` (modèle nommé d'après `button.id`) ;
  - `Furniture.belt(length, width): Model` (pièce `Belt`, dessus à 6 studs, dans l'axe X) ;
  - `Furniture.potty(): Model` (pièce invisible `Sensor`, dossier côté +X) ;
  - `Furniture.changingTable(): Model` (pièce `Top` avec une `ProximityPrompt` qui porte l'attribut `Kind = "ChangingTable"`).

- [ ] **Step 1 : Créer `src/shared/Builders/Parts.luau`**

```lua
--!strict
-- Outils pour fabriquer des modèles cartoon avec des formes Roblox. Les pièces sont ancrées.

export type Props = {
	name: string?,
	shape: Enum.PartType?,
	size: Vector3,
	cframe: CFrame,
	color: string, -- hexadécimal
	material: string?, -- nom d'Enum.Material
	transparency: number?,
	collide: boolean?, -- true par défaut
}

local MATERIALS: { [string]: Enum.Material } = {
	SmoothPlastic = Enum.Material.SmoothPlastic,
	Neon = Enum.Material.Neon,
	Glass = Enum.Material.Glass,
	Foil = Enum.Material.Foil,
	ForceField = Enum.Material.ForceField,
	Fabric = Enum.Material.Fabric,
	Wood = Enum.Material.Wood,
	DiamondPlate = Enum.Material.DiamondPlate,
}

local Parts = {}

function Parts.material(name: string): Enum.Material
	return MATERIALS[name] or Enum.Material.SmoothPlastic
end

function Parts.make(parent: Instance, props: Props): Part
	local part = Instance.new("Part")
	part.Name = props.name or "Part"
	part.Shape = props.shape or Enum.PartType.Block
	part.Size = props.size
	part.CFrame = props.cframe
	part.Color = Color3.fromHex(props.color)
	part.Material = Parts.material(props.material or "SmoothPlastic")
	part.Transparency = props.transparency or 0
	part.Anchored = true
	part.CanCollide = props.collide ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Boule de diamètre `diameter` centrée en `position`.
function Parts.ball(
	parent: Instance,
	name: string,
	diameter: number,
	position: Vector3,
	color: string,
	material: string?
): Part
	return Parts.make(parent, {
		name = name,
		shape = Enum.PartType.Ball,
		size = Vector3.one * diameter,
		cframe = CFrame.new(position),
		color = color,
		material = material,
	})
end

-- Cylindre vertical (hauteur `height`, diamètre `diameter`) centré en `position`.
function Parts.cylinder(
	parent: Instance,
	name: string,
	height: number,
	diameter: number,
	position: Vector3,
	color: string,
	material: string?
): Part
	return Parts.make(parent, {
		name = name,
		shape = Enum.PartType.Cylinder,
		size = Vector3.new(height, diameter, diameter),
		cframe = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
		color = color,
		material = material,
	})
end

-- Pavé de taille `size` centré en `position`.
function Parts.block(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: string,
	material: string?
): Part
	return Parts.make(parent, {
		name = name,
		size = size,
		cframe = CFrame.new(position),
		color = color,
		material = material,
	})
end

-- Modèle vide dont le pivot est à l'origine (au sol, au centre).
function Parts.model(name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model.WorldPivot = CFrame.new()
	return model
end

-- Étiquette de texte (dans un BillboardGui ou un SurfaceGui), traduite automatiquement si le texte est
-- une source de Localization.csv.
function Parts.label(parent: Instance, name: string, text: string, font: Enum.Font, color: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = font
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = Color3.fromHex(color)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromHex("#3A2A4A")
	stroke.Parent = label
	label.Parent = parent
	return label
end

return Parts
```

- [ ] **Step 2 : Créer `src/shared/Builders/Baby.luau`**

```lua
--!strict
-- Le gros bébé, en boules et cylindres. Il regarde vers -Z ; pivot au sol, au centre.
-- Sa couche (« Diaper ») porte un ClickDetector : cliquer dessus = PUSH!.
local Parts = require("./Parts")

local SKIN = "#FFD6B0"
local CHEEK = "#FF9AA2"
local DARK = "#2B2B2B"

local Baby = {}

function Baby.build(): Model
	local model = Parts.model("Baby")
	Parts.ball(model, "Body", 6.4, Vector3.new(0, 3.4, 0), SKIN)
	Parts.ball(model, "Head", 5.6, Vector3.new(0, 8.2, -0.2), SKIN)
	Parts.ball(model, "EyeLeft", 0.9, Vector3.new(-1.1, 8.7, -2.6), DARK)
	Parts.ball(model, "EyeRight", 0.9, Vector3.new(1.1, 8.7, -2.6), DARK)
	Parts.ball(model, "ShineLeft", 0.3, Vector3.new(-0.95, 8.95, -3.0), "#FFFFFF")
	Parts.ball(model, "ShineRight", 0.3, Vector3.new(1.25, 8.95, -3.0), "#FFFFFF")
	Parts.ball(model, "CheekLeft", 1.2, Vector3.new(-1.9, 7.6, -2.2), CHEEK)
	Parts.ball(model, "CheekRight", 1.2, Vector3.new(1.9, 7.6, -2.2), CHEEK)
	Parts.ball(model, "Mouth", 1.0, Vector3.new(0, 7.2, -2.6), "#C9184A")
	Parts.ball(model, "Curl", 1.0, Vector3.new(0, 11.1, -0.4), "#E0A96D")
	Parts.ball(model, "ArmLeft", 2.4, Vector3.new(-3.4, 4.4, -0.6), SKIN)
	Parts.ball(model, "ArmRight", 2.4, Vector3.new(3.4, 4.4, -0.6), SKIN)
	Parts.ball(model, "LegLeft", 2.8, Vector3.new(-1.9, 1.2, -2.2), SKIN)
	Parts.ball(model, "LegRight", 2.8, Vector3.new(1.9, 1.2, -2.2), SKIN)
	local diaper = Parts.cylinder(model, "Diaper", 2.8, 6.9, Vector3.new(0, 1.9, 0), "#FFFFFF")
	Parts.ball(model, "Pin", 0.8, Vector3.new(0, 2.3, -3.4), "#FFB5C2")
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 80
	detector.Parent = diaper
	return model
end

function Baby.setDiaper(model: Model, color: string, material: string)
	local diaper = model:FindFirstChild("Diaper")
	if diaper and diaper:IsA("BasePart") then
		diaper.Color = Color3.fromHex(color)
		diaper.Material = Parts.material(material)
	end
end

return Baby
```

- [ ] **Step 3 : Créer `src/shared/Builders/Poop.luau`**

```lua
--!strict
-- Un caca façon emoji : 3 boules en spirale et 2 yeux, soudés sur une boîte de collision invisible
-- (la boîte glisse bien sur le tapis). `size` : facteur d'échelle.
local Parts = require("./Parts")

local Poop = {}

function Poop.build(size: number, color: string, material: string): (Model, Part)
	local model = Parts.model("Poop")
	local root = Parts.make(model, {
		name = "Root",
		size = Vector3.new(1.8, 1.4, 1.8) * size,
		cframe = CFrame.new(0, 0.7 * size, 0),
		color = color,
		transparency = 1,
	})
	local pieces = {
		Parts.ball(model, "Bottom", 1.8 * size, Vector3.new(0, 0.8 * size, 0), color, material),
		Parts.ball(model, "Middle", 1.3 * size, Vector3.new(0, 1.6 * size, 0), color, material),
		Parts.ball(model, "Top", 0.8 * size, Vector3.new(0, 2.2 * size, 0), color, material),
		Parts.ball(
			model,
			"EyeLeft",
			0.45 * size,
			Vector3.new(-0.3 * size, 1.7 * size, -0.55 * size),
			"#FFFFFF"
		),
		Parts.ball(
			model,
			"EyeRight",
			0.45 * size,
			Vector3.new(0.3 * size, 1.7 * size, -0.55 * size),
			"#FFFFFF"
		),
		Parts.ball(
			model,
			"PupilLeft",
			0.2 * size,
			Vector3.new(-0.3 * size, 1.7 * size, -0.76 * size),
			"#111111"
		),
		Parts.ball(
			model,
			"PupilRight",
			0.2 * size,
			Vector3.new(0.3 * size, 1.7 * size, -0.76 * size),
			"#111111"
		),
	}
	for _, piece in pieces do
		piece.CanCollide = false
		piece.CanTouch = false
		piece.CanQuery = false
		piece.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = piece
		weld.Parent = root
	end
	root.Anchored = false
	for _, piece in pieces do
		piece.Anchored = false
	end
	model.PrimaryPart = root
	return model, root
end

return Poop
```

- [ ] **Step 4 : Créer `src/shared/Builders/Pad.luau`**

```lua
--!strict
-- Dalle d'achat : un disque lumineux et une étiquette (« NEXT », nom de l'objet, prix).
local Parts = require("./Parts")

local AFFORDABLE = "#57CC99"
local TOO_EXPENSIVE = "#FF6B6B"

local Pad = {}

local function gui(model: Model): (Part, BillboardGui)
	local disk = model:FindFirstChild("Disk") :: Part
	return disk, disk:FindFirstChild("Label") :: BillboardGui
end

function Pad.build(name: string): Model
	local model = Parts.model(name)
	local disk = Parts.make(model, {
		name = "Disk",
		shape = Enum.PartType.Cylinder,
		size = Vector3.new(0.6, 8, 8),
		cframe = CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)),
		color = AFFORDABLE,
		material = "Neon",
		collide = false,
	})
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(260, 110)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	billboard.MaxDistance = 150
	billboard.Adornee = disk
	billboard.Parent = disk
	local tag = Parts.label(billboard, "Tag", "NEXT", Enum.Font.FredokaOne, "#FFFFFF")
	tag.Size = UDim2.fromScale(1, 0.25)
	local item = Parts.label(billboard, "Item", "", Enum.Font.LuckiestGuy, "#FFFFFF")
	item.Size = UDim2.fromScale(1, 0.45)
	item.Position = UDim2.fromScale(0, 0.25)
	local price = Parts.label(billboard, "Price", "", Enum.Font.FredokaOne, "#FFE66D")
	price.Size = UDim2.fromScale(1, 0.3)
	price.Position = UDim2.fromScale(0, 0.7)
	return model
end

-- Affiche un objet sur la dalle. `ghost` : aperçu du bouton suivant (transparent, avec « NEXT »).
function Pad.show(model: Model, itemName: string, priceText: string, ghost: boolean)
	local disk, billboard = gui(model)
	local item = billboard:FindFirstChild("Item") :: TextLabel
	local price = billboard:FindFirstChild("Price") :: TextLabel
	local tag = billboard:FindFirstChild("Tag") :: TextLabel
	item.Text = itemName
	price.Text = priceText
	tag.Visible = ghost
	disk.Transparency = if ghost then 0.75 else 0
	billboard.Enabled = true
end

function Pad.hide(model: Model)
	local disk, billboard = gui(model)
	disk.Transparency = 1
	billboard.Enabled = false
end

function Pad.setAffordable(model: Model, affordable: boolean)
	local disk = gui(model)
	disk.Color = Color3.fromHex(if affordable then AFFORDABLE else TOO_EXPENSIVE)
end

return Pad
```

- [ ] **Step 5 : Créer `src/shared/Builders/Machine.luau`**

```lua
--!strict
-- Machine à bouffe, aux couleurs de son bouton. Elle regarde vers -Z ; pivot au sol.
local Buttons = require("../Config/Buttons")
local Parts = require("./Parts")

local Machine = {}

function Machine.build(button: Buttons.Button): Model
	local model = Parts.model(button.id)
	Parts.block(model, "Base", Vector3.new(7, 1, 7), Vector3.new(0, 0.5, 0), "#FFFFFF")
	Parts.block(model, "Body", Vector3.new(6, 5, 6), Vector3.new(0, 3.5, 0), button.color)
	Parts.cylinder(model, "Hopper", 1.2, 5, Vector3.new(0, 6.6, 0), "#FFFFFF")
	Parts.ball(model, "Food", 3, Vector3.new(0, 8, 0), button.accent)
	Parts.block(model, "Chute", Vector3.new(2, 2, 3), Vector3.new(0, 4, -4.2), button.accent)
	Parts.ball(model, "LightLeft", 0.8, Vector3.new(-1.6, 5, -3.05), "#FFE66D", "Neon")
	Parts.ball(model, "LightRight", 0.8, Vector3.new(1.6, 5, -3.05), "#FFE66D", "Neon")
	return model
end

return Machine
```

- [ ] **Step 6 : Créer `src/shared/Builders/Decor.luau`**

```lua
--!strict
-- Les 10 décos de la nursery. Chacune est construite autour de l'origine (pivot au sol) et regarde vers -Z.
local Buttons = require("../Config/Buttons")
local Parts = require("./Parts")
local World = require("../Config/World")

type Builder = (model: Model, color: string, accent: string) -> ()

local BALL_COLORS = { "#FF6B6B", "#FFD166", "#06D6A0", "#118AB2", "#C77DFF", "#FF8FAB" }

local BUILDERS: { [string]: Builder } = {
	play_mat = function(model, color, accent)
		Parts.block(model, "Mat", Vector3.new(30, 0.2, 30), Vector3.new(0, 0.1, 0), color)
		for index, corner in
			{ Vector3.new(-9, 0, -9), Vector3.new(9, 0, -9), Vector3.new(-9, 0, 9), Vector3.new(9, 0, 9) }
		do
			Parts.block(
				model,
				"Square" .. index,
				Vector3.new(8, 0.25, 8),
				corner + Vector3.new(0, 0.12, 0),
				accent
			)
		end
	end,
	pastel_walls = function(model, color, accent)
		local half = World.plotSize / 2
		local height = 12
		Parts.block(
			model,
			"WallLeft",
			Vector3.new(1, height, World.plotSize),
			Vector3.new(-half + 0.5, height / 2, 0),
			color
		)
		Parts.block(
			model,
			"WallRight",
			Vector3.new(1, height, World.plotSize),
			Vector3.new(half - 0.5, height / 2, 0),
			color
		)
		Parts.block(
			model,
			"WallBack",
			Vector3.new(World.plotSize, height, 1),
			Vector3.new(0, height / 2, half - 0.5),
			color
		)
		Parts.block(
			model,
			"StripeLeft",
			Vector3.new(1.2, 1.2, World.plotSize),
			Vector3.new(-half + 0.5, height - 2, 0),
			accent
		)
		Parts.block(
			model,
			"StripeRight",
			Vector3.new(1.2, 1.2, World.plotSize),
			Vector3.new(half - 0.5, height - 2, 0),
			accent
		)
		Parts.block(
			model,
			"StripeBack",
			Vector3.new(World.plotSize, 1.2, 1.2),
			Vector3.new(0, height - 2, half - 0.5),
			accent
		)
	end,
	crib = function(model, color, accent)
		for index, corner in
			{
				Vector3.new(-4.6, 0, -2.6),
				Vector3.new(4.6, 0, -2.6),
				Vector3.new(-4.6, 0, 2.6),
				Vector3.new(4.6, 0, 2.6),
			}
		do
			Parts.block(
				model,
				"Post" .. index,
				Vector3.new(0.7, 7, 0.7),
				corner + Vector3.new(0, 3.5, 0),
				color
			)
		end
		Parts.block(model, "Bed", Vector3.new(9.4, 1, 5.4), Vector3.new(0, 3, 0), color)
		Parts.block(model, "Mattress", Vector3.new(9, 0.6, 5), Vector3.new(0, 3.8, 0), accent)
		Parts.block(model, "RailFront", Vector3.new(9.4, 0.4, 0.4), Vector3.new(0, 6.8, -2.6), color)
		Parts.block(model, "RailBack", Vector3.new(9.4, 0.4, 0.4), Vector3.new(0, 6.8, 2.6), color)
		for bar = -3, 3 do
			Parts.block(
				model,
				"BarFront" .. bar,
				Vector3.new(0.3, 2.8, 0.3),
				Vector3.new(bar * 1.2, 5.3, -2.6),
				color
			)
			Parts.block(
				model,
				"BarBack" .. bar,
				Vector3.new(0.3, 2.8, 0.3),
				Vector3.new(bar * 1.2, 5.3, 2.6),
				color
			)
		end
		Parts.ball(model, "Pillow", 1.6, Vector3.new(-3.2, 4.4, 0), "#FFFFFF")
	end,
	musical_mobile = function(model, color, accent)
		Parts.block(model, "Pole", Vector3.new(0.5, 18, 0.5), Vector3.new(5.5, 9, 0), "#FFFFFF")
		Parts.block(model, "Arm", Vector3.new(6, 0.4, 0.4), Vector3.new(2.5, 18, 0), "#FFFFFF")
		Parts.cylinder(model, "Hub", 0.6, 2.2, Vector3.new(0, 17.6, 0), color)
		for index, offset in
			{
				Vector3.new(1.6, 0, 0),
				Vector3.new(-1.6, 0, 0),
				Vector3.new(0, 0, 1.6),
				Vector3.new(0, 0, -1.6),
			}
		do
			Parts.block(
				model,
				"String" .. index,
				Vector3.new(0.1, 2.6, 0.1),
				offset + Vector3.new(0, 16, 0),
				"#FFFFFF"
			)
			local toyColor = if index % 2 == 0 then accent else color
			Parts.ball(model, "Toy" .. index, 1.4, offset + Vector3.new(0, 14.4, 0), toyColor, "Neon")
		end
	end,
	toy_box = function(model, color, accent)
		Parts.block(model, "Box", Vector3.new(6, 4, 4), Vector3.new(0, 2, 0), color)
		Parts.block(model, "Lid", Vector3.new(6.3, 0.6, 4.3), Vector3.new(0, 4.3, 0), accent)
		Parts.ball(model, "Ball", 1.6, Vector3.new(-1.6, 5.4, 0), "#FFD166")
		Parts.block(model, "Cube", Vector3.new(1.4, 1.4, 1.4), Vector3.new(0.3, 5.3, 0.4), "#06D6A0")
		Parts.cylinder(model, "Drum", 1, 1.6, Vector3.new(2, 5.1, -0.3), "#FF6B6B")
	end,
	rocking_horse = function(model, color, accent)
		Parts.block(model, "RockerLeft", Vector3.new(0.5, 0.5, 7), Vector3.new(-1.2, 0.25, 0), accent)
		Parts.block(model, "RockerRight", Vector3.new(0.5, 0.5, 7), Vector3.new(1.2, 0.25, 0), accent)
		for index, leg in
			{
				Vector3.new(-1.2, 0, -1.6),
				Vector3.new(1.2, 0, -1.6),
				Vector3.new(-1.2, 0, 1.6),
				Vector3.new(1.2, 0, 1.6),
			}
		do
			Parts.block(
				model,
				"Leg" .. index,
				Vector3.new(0.6, 2.6, 0.6),
				leg + Vector3.new(0, 1.8, 0),
				color
			)
		end
		Parts.block(model, "Body", Vector3.new(2.8, 2.2, 4.6), Vector3.new(0, 4, 0), color)
		Parts.block(model, "Neck", Vector3.new(1.6, 2.4, 1.6), Vector3.new(0, 5.6, -2), color)
		Parts.block(model, "Head", Vector3.new(1.8, 1.6, 2.6), Vector3.new(0, 6.8, -2.8), color)
		Parts.block(model, "Mane", Vector3.new(0.6, 2.8, 1.4), Vector3.new(0, 6.2, -1.6), accent)
		Parts.ball(model, "EyeLeft", 0.4, Vector3.new(-0.9, 7.1, -3.4), "#2B2B2B")
		Parts.ball(model, "EyeRight", 0.4, Vector3.new(0.9, 7.1, -3.4), "#2B2B2B")
		Parts.block(model, "Tail", Vector3.new(0.6, 2, 0.6), Vector3.new(0, 4.2, 2.6), accent)
	end,
	ball_pit = function(model, color, accent)
		Parts.cylinder(model, "Floor", 0.4, 14, Vector3.new(0, 0.2, 0), color)
		for side = 0, 7 do
			local angle = side * math.pi / 4
			Parts.make(model, {
				name = "Wall" .. side,
				size = Vector3.new(5.8, 2.6, 0.8),
				cframe = CFrame.Angles(0, angle, 0) * CFrame.new(0, 1.3, -6.6),
				color = accent,
			})
		end
		local random = Random.new(42)
		for index = 1, 40 do
			local angle = random:NextNumber(0, 2 * math.pi)
			local distance = random:NextNumber(0, 5.2)
			local position = Vector3.new(
				math.cos(angle) * distance,
				random:NextNumber(0.9, 2.2),
				math.sin(angle) * distance
			)
			Parts.ball(model, "Ball" .. index, 1.4, position, BALL_COLORS[(index % #BALL_COLORS) + 1])
		end
	end,
	slide = function(model, color, accent)
		Parts.block(model, "PostLeft", Vector3.new(0.5, 9, 0.5), Vector3.new(-1.6, 4.5, 4), accent)
		Parts.block(model, "PostRight", Vector3.new(0.5, 9, 0.5), Vector3.new(1.6, 4.5, 4), accent)
		for step = 1, 5 do
			Parts.block(
				model,
				"Step" .. step,
				Vector3.new(3.2, 0.3, 0.6),
				Vector3.new(0, step * 1.5, 4.4),
				"#FFFFFF"
			)
		end
		Parts.block(model, "Platform", Vector3.new(4, 0.5, 3), Vector3.new(0, 8.5, 2.6), accent)
		Parts.make(model, {
			name = "Chute",
			size = Vector3.new(3.6, 0.4, 13),
			cframe = CFrame.new(0, 4.4, -3.2) * CFrame.Angles(math.rad(-38), 0, 0),
			color = color,
		})
		Parts.make(model, {
			name = "SideLeft",
			size = Vector3.new(0.3, 0.8, 13),
			cframe = CFrame.new(-1.8, 4.9, -3.2) * CFrame.Angles(math.rad(-38), 0, 0),
			color = accent,
		})
		Parts.make(model, {
			name = "SideRight",
			size = Vector3.new(0.3, 0.8, 13),
			cframe = CFrame.new(1.8, 4.9, -3.2) * CFrame.Angles(math.rad(-38), 0, 0),
			color = accent,
		})
	end,
	giant_teddy = function(model, color, accent)
		local light = "#E8C39E"
		Parts.ball(model, "Body", 8, Vector3.new(0, 4, 0), color)
		Parts.ball(model, "Belly", 5, Vector3.new(0, 3.8, -1.9), light)
		Parts.ball(model, "Head", 6, Vector3.new(0, 10, 0), color)
		Parts.ball(model, "EarLeft", 2.4, Vector3.new(-2.4, 12.6, 0), color)
		Parts.ball(model, "EarRight", 2.4, Vector3.new(2.4, 12.6, 0), color)
		Parts.ball(model, "InnerEarLeft", 1.2, Vector3.new(-2.4, 12.6, -0.8), accent)
		Parts.ball(model, "InnerEarRight", 1.2, Vector3.new(2.4, 12.6, -0.8), accent)
		Parts.ball(model, "Muzzle", 2.6, Vector3.new(0, 9.3, -2.5), light)
		Parts.ball(model, "Nose", 0.9, Vector3.new(0, 9.8, -3.7), "#2B2B2B")
		Parts.ball(model, "EyeLeft", 0.8, Vector3.new(-1.1, 10.9, -2.6), "#2B2B2B")
		Parts.ball(model, "EyeRight", 0.8, Vector3.new(1.1, 10.9, -2.6), "#2B2B2B")
		Parts.ball(model, "ArmLeft", 3.2, Vector3.new(-4.2, 5.5, -1), color)
		Parts.ball(model, "ArmRight", 3.2, Vector3.new(4.2, 5.5, -1), color)
		Parts.ball(model, "LegLeft", 3.4, Vector3.new(-2.4, 1.6, -2.6), color)
		Parts.ball(model, "LegRight", 3.4, Vector3.new(2.4, 1.6, -2.6), color)
	end,
	bouncy_castle = function(model, color, accent)
		Parts.block(model, "Base", Vector3.new(14, 3, 14), Vector3.new(0, 1.5, 0), color)
		Parts.block(model, "Floor", Vector3.new(12, 0.6, 12), Vector3.new(0, 3.3, 0), accent)
		Parts.block(model, "WallBack", Vector3.new(14, 4, 1), Vector3.new(0, 5, 6.5), color)
		Parts.block(model, "WallLeft", Vector3.new(1, 4, 14), Vector3.new(-6.5, 5, 0), color)
		Parts.block(model, "WallRight", Vector3.new(1, 4, 14), Vector3.new(6.5, 5, 0), color)
		for index, corner in
			{ Vector3.new(-6, 0, -6), Vector3.new(6, 0, -6), Vector3.new(-6, 0, 6), Vector3.new(6, 0, 6) }
		do
			Parts.cylinder(model, "Tower" .. index, 8, 3.6, corner + Vector3.new(0, 4, 0), accent)
			Parts.ball(model, "Top" .. index, 3.8, corner + Vector3.new(0, 8.4, 0), color)
		end
	end,
}

local Decor = {}

function Decor.build(button: Buttons.Button): Model
	local builder = BUILDERS[button.id]
	assert(builder, "déco inconnue : " .. button.id)
	local model = Parts.model(button.id)
	builder(model, button.color, button.accent)
	return model
end

return Decor
```

- [ ] **Step 7 : Créer `src/shared/Builders/Furniture.luau`**

```lua
--!strict
-- Meubles fixes de la nursery : le tapis roulant, le pot géant, la table à langer.
local Parts = require("./Parts")

local Furniture = {}

-- Tapis roulant surélevé (dessus à 6 studs), dans l'axe X. La pièce « Belt » sert de convoyeur.
function Furniture.belt(length: number, width: number): Model
	local model = Parts.model("Conveyor")
	Parts.block(
		model,
		"Belt",
		Vector3.new(length, 1, width),
		Vector3.new(0, 5.5, 0),
		"#5C5470",
		"DiamondPlate"
	)
	local railZ = width / 2 + 0.3
	Parts.block(model, "RailLeft", Vector3.new(length, 1.5, 0.6), Vector3.new(0, 6.75, -railZ), "#FFD166")
	Parts.block(model, "RailRight", Vector3.new(length, 1.5, 0.6), Vector3.new(0, 6.75, railZ), "#FFD166")
	local legs = math.floor(length / 8)
	for index = 0, legs do
		local x = -length / 2 + 1 + index * (length - 2) / legs
		Parts.block(model, "Leg" .. index, Vector3.new(1, 5, 1), Vector3.new(x, 2.5, 0), "#B8A9C9")
	end
	return model
end

-- Pot géant. Le dossier est du côté +X ; la pièce invisible « Sensor » crédite les cacas qui la touchent.
function Furniture.potty(): Model
	local model = Parts.model("Potty")
	Parts.cylinder(model, "Base", 3, 10, Vector3.new(0, 1.5, 0), "#FFFFFF")
	Parts.cylinder(model, "Bowl", 1.4, 12, Vector3.new(0, 3.7, 0), "#A0E7E5")
	Parts.cylinder(model, "Hole", 0.2, 9, Vector3.new(0, 4.45, 0), "#5C3D2E")
	Parts.block(model, "Back", Vector3.new(1.6, 8, 10), Vector3.new(6.2, 6, 0), "#A0E7E5")
	Parts.ball(model, "HandleLeft", 1.4, Vector3.new(3, 5.2, -5.6), "#FFD166")
	Parts.ball(model, "HandleRight", 1.4, Vector3.new(3, 5.2, 5.6), "#FFD166")
	local sensor = Parts.block(model, "Sensor", Vector3.new(14, 10, 14), Vector3.new(0, 5, 0), "#FFFFFF")
	sensor.Transparency = 1
	sensor.CanCollide = false
	sensor.CanQuery = false
	return model
end

-- Table à langer, avec une ProximityPrompt (attribut Kind = "ChangingTable") qui ouvre le panneau des couches.
function Furniture.changingTable(): Model
	local model = Parts.model("ChangingTable")
	for index, corner in
		{
			Vector3.new(-3.6, 0, -1.8),
			Vector3.new(3.6, 0, -1.8),
			Vector3.new(-3.6, 0, 1.8),
			Vector3.new(3.6, 0, 1.8),
		}
	do
		Parts.block(model, "Leg" .. index, Vector3.new(0.8, 4, 0.8), corner + Vector3.new(0, 2, 0), "#FFFFFF")
	end
	Parts.block(model, "Shelf", Vector3.new(7.6, 0.4, 3.8), Vector3.new(0, 1.2, 0), "#FFC8DD")
	local top = Parts.block(model, "Top", Vector3.new(8.4, 1, 4.6), Vector3.new(0, 4.5, 0), "#FFC8DD")
	Parts.block(model, "Cushion", Vector3.new(7.6, 0.6, 3.8), Vector3.new(0, 5.3, 0), "#FFFFFF")
	Parts.block(model, "Diapers", Vector3.new(2, 1.2, 2), Vector3.new(-2.4, 6.2, 0), "#A0C4FF")
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Sign"
	billboard.Size = UDim2.fromOffset(240, 50)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	billboard.MaxDistance = 100
	billboard.Adornee = top
	billboard.Parent = top
	Parts.label(billboard, "Title", "Changing Table", Enum.Font.LuckiestGuy, "#FFFFFF")
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Change Diaper"
	prompt.ObjectText = "Changing Table"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Kind", "ChangingTable")
	prompt.Parent = top
	return model
end

return Furniture
```

- [ ] **Step 8 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `38 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 9 : Aperçu dans Studio (mode édition)**

Avec `rojo serve` lancé et le plugin connecté, appeler `execute_luau` avec `datamodel_type = "Edit"` :

```lua
local Builders = game.ReplicatedStorage.Shared.Builders
local Buttons = require(game.ReplicatedStorage.Shared.Config.Buttons)
local preview = Instance.new("Folder")
preview.Name = "BuilderPreview"
preview.Parent = workspace
local function put(model, x, z)
	model:PivotTo(CFrame.new(x, 0, z))
	model.Parent = preview
end
put(require(Builders.Baby).build(), 0, 0)
put(require(Builders.Furniture).potty(), 20, 0)
put(require(Builders.Furniture).changingTable(), -20, 0)
put(require(Builders.Furniture).belt(40, 12), 0, 30)
put(require(Builders.Pad).build("PadPreview"), -40, 0)
put((require(Builders.Poop).build(2, "#7B4A2A", "SmoothPlastic")), 40, 0)
for index, button in Buttons do
	local builder = if button.kind == "machine" then require(Builders.Machine) else require(Builders.Decor)
	put(builder.build(button), -170 + index * 15, -80)
end
return #preview:GetChildren()
```

Attendu : `28`. Puis `screen_capture`, avec la caméra en `(0, 70, 90)` qui regarde `(0, 0, -30)`. On doit voir le bébé (tête ronde, joues roses, couche blanche), le pot, la table à langer, le tapis, la dalle verte, un caca à yeux, et la rangée des machines et décos.

Nettoyer ensuite avec `execute_luau` (Edit) : `workspace.BuilderPreview:Destroy()`.

- [ ] **Step 10 : Commit**

```bash
git add src/shared/Builders
git commit -m "feat: modèles cartoon (bébé, cacas, dalles, machines, décos, meubles)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 7 : la map, les bases et la sauvegarde (serveur)

**Files :**
- Create : `src/shared/Net.luau`, `src/server/Clock.luau`
- Create : `src/server/Vendor/ProfileStore.luau` (téléchargé), `licenses/ProfileStore-LICENSE.txt` (téléchargé)
- Create : `src/server/World/Layout.luau`, `src/server/World/MapBuilder.luau`, `src/server/World/PlotBuilder.luau`
- Create : `src/server/Services/DataService.luau`, `src/server/Services/PlotService.luau`
- Modify : `src/server/init.server.luau` (remplacé en entier)

**Interfaces :**
- Consumes : `Buttons`, `Diapers`, `Economy` (Config), `Data`, `Economy`, `Format` (Logic), `Signal`, tous les constructeurs (tâche 6).
- Produces :
  - `Net.setup()` (serveur) et `Net.event(name): RemoteEvent`, pour les remotes `Click`, `BuyDiaper`, `State`, `Toast`, `Effect` ; le type `Net.Snapshot = { coins, binkies, totalEarned, buttons, diaper, clicksSinceMega, income, baseIncome }` ;
  - `Clock.now(): number` (secondes Unix) et `Clock.offset` ;
  - `MapBuilder.build(): { Model }` crée `workspace.Map` (sol, place, `Spawn`, chemins) et `workspace.Plots.Plot1..6`, chacun avec l'attribut `Origin` (CFrame) ;
  - `PlotBuilder.build(slot, ownerUserId)`, `clear(slot)`, `syncItems(slot, buttons)`, `syncPads(slot, buttons)`, `setPadAffordable(slot, affordable)`, `syncBaby(slot, buttons, diaper, rebirths)`, `poopSpawn(slot): CFrame`, `padPosition(slot): Vector3`, `spawnCFrame(slot): CFrame`. La nursery est le modèle `Nursery`, avec `Spawn`, `Conveyor`, `Potty`, `Baby`, `ChangingTable`, `PadActive`, `PadNext` et les dossiers `Items` et `Poops` ;
  - `DataService.get(player): Profile?`, signaux `DataService.loaded (player, data)` et `DataService.released (player)` ;
  - `PlotService.get(player): Model?`, `PlotService.owners(): { [Player]: Model }`, `PlotService.refresh(player)`, `PlotService.teleportHome(player)`, signal `PlotService.built (player, slot)`. Le joueur reçoit l'attribut `Plot` (« PlotN ») et la base l'attribut `OwnerUserId` ;
  - tout service peut exposer `init()` et `start()`, appelés dans l'ordre de la liste de `init.server.luau`.

- [ ] **Step 1 : Créer `src/shared/Net.luau`**

```lua
--!strict
-- Les RemoteEvents du jeu. Le serveur les crée au démarrage (Net.setup), le client les attend (Net.event).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	"Click", -- client → serveur : un appui sur PUSH!
	"BuyDiaper", -- client → serveur : acheter la couche suivante
	"State", -- serveur → client : état de la partie du joueur (Snapshot)
	"Toast", -- serveur → client : message court (clé de traduction, arguments)
	"Effect", -- serveur → client : effet ("credit" au pot, "mega" caca), avec une valeur
}

-- Ce que le client sait de sa partie.
export type Snapshot = {
	coins: number,
	binkies: number,
	totalEarned: number,
	buttons: number,
	diaper: number,
	clicksSinceMega: number,
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
```

- [ ] **Step 2 : Créer `src/server/Clock.luau`**

```lua
--!strict
-- Horloge du serveur, en secondes Unix (UTC). Tout le code serveur lit l'heure ici.
local Clock = {
	offset = 0, -- décalage en secondes (réservé aux tests en Studio)
}

function Clock.now(): number
	return os.time() + Clock.offset
end

return Clock
```

- [ ] **Step 3 : Copier ProfileStore et sa licence (version figée)**

```bash
SHA=45c9847cbcf1fc260369c50eb335aba7c35aecdd
mkdir -p src/server/Vendor licenses
curl -sSfL -o src/server/Vendor/ProfileStore.luau https://raw.githubusercontent.com/MadStudioRoblox/ProfileStore/$SHA/ProfileStore.luau
curl -sSfL -o licenses/ProfileStore-LICENSE.txt https://raw.githubusercontent.com/MadStudioRoblox/ProfileStore/$SHA/LICENSE
shasum -a 256 src/server/Vendor/ProfileStore.luau
```

Attendu : `ad43737203688b8e88cab34ebe8c483000c157e53bfb41e35f1b49ee89d0c95f`. On ne modifie jamais ce fichier ; StyLua, Selene et luau-lsp l'ignorent déjà.

- [ ] **Step 4 : Créer `src/server/World/Layout.luau`**

```lua
--!strict
-- Positions des éléments d'une base, relatives à son origine (au sol, au centre ; -Z regarde vers la place).

local LEFT = CFrame.Angles(0, -math.pi / 2, 0) -- regarde vers +X (vers le bébé)
local RIGHT = CFrame.Angles(0, math.pi / 2, 0) -- regarde vers -X (vers le bébé)

-- 12 emplacements de machines, de l'entrée vers le fond, en alternant gauche et droite.
local machines: { CFrame } = {}
for _, z in { -32, -20, -8, 4, 16, 28 } do
	table.insert(machines, CFrame.new(-40, 0, z) * LEFT)
	table.insert(machines, CFrame.new(40, 0, z) * RIGHT)
end

local Layout = {
	spawn = CFrame.lookAt(Vector3.new(0, 3, -48), Vector3.new(0, 3, 0)),
	baby = CFrame.new(0, 0, 12),
	beltCenter = CFrame.new(14, 0, 40), -- le tapis va de x = -6 à x = 34
	beltLength = 40,
	beltWidth = 12,
	poopSpawn = Vector3.new(-3, 10, 40),
	potty = CFrame.new(40, 0, 40),
	changingTable = CFrame.new(-24, 0, -36),
	padActive = CFrame.new(-8, 0, -38),
	padNext = CFrame.new(4, 0, -38),
	machines = machines,
	decor = {
		play_mat = CFrame.new(0, 0, 12),
		pastel_walls = CFrame.new(),
		crib = CFrame.new(-45, 0, 50),
		musical_mobile = CFrame.new(-45, 0, 50),
		toy_box = CFrame.new(-25, 0, 52),
		rocking_horse = CFrame.new(-50, 0, -48) * CFrame.Angles(0, math.rad(30), 0),
		ball_pit = CFrame.new(40, 0, -48),
		slide = CFrame.new(52, 0, 48),
		giant_teddy = CFrame.new(-53, 0, 5) * LEFT,
		bouncy_castle = CFrame.new(18, 0, -50),
	} :: { [string]: CFrame },
}

return Layout
```

- [ ] **Step 5 : Créer `src/server/World/MapBuilder.luau`**

```lua
--!strict
-- Construit la map au démarrage : sol, place centrale, point d'apparition, chemins et 6 emplacements de bases.
-- Chaque emplacement est un Model « PlotN » avec l'attribut Origin (CFrame, -Z vers la place).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Parts = require(ReplicatedStorage.Shared.Builders.Parts)
local World = require(ReplicatedStorage.Shared.Config.World)

local MapBuilder = {}

function MapBuilder.build(): { Model }
	for _, name in { "Baseplate", "SpawnLocation" } do
		local leftover = workspace:FindFirstChild(name)
		if leftover then
			leftover:Destroy()
		end
	end

	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = workspace
	Parts.block(map, "Ground", Vector3.new(900, 2, 900), Vector3.new(0, -1.4, 0), "#9BE3A0")
	Parts.cylinder(map, "Plaza", 0.4, World.plazaRadius * 2, Vector3.new(0, -0.2, 0), "#FFE5EC")

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(14, 0.2, 14)
	spawn.CFrame = CFrame.new(0, 0.1, 0)
	spawn.Color = Color3.fromHex("#FFC8DD")
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = map

	local plots = Instance.new("Folder")
	plots.Name = "Plots"
	plots.Parent = workspace

	local pathLength = World.plotDistance - World.plotSize / 2 - World.plazaRadius
	local slots = {}
	for index = 1, World.plotCount do
		local angle = (index - 1) * 2 * math.pi / World.plotCount
		local center = Vector3.new(math.sin(angle), 0, math.cos(angle)) * World.plotDistance
		local origin = CFrame.lookAt(center, Vector3.zero)

		local slot = Instance.new("Model")
		slot.Name = "Plot" .. index
		slot:SetAttribute("Origin", origin)
		Parts.make(slot, {
			name = "Floor",
			size = Vector3.new(World.plotSize, 0.4, World.plotSize),
			cframe = origin * CFrame.new(0, -0.2, 0),
			color = "#FFF1E6",
		})
		Parts.make(map, {
			name = "Path" .. index,
			size = Vector3.new(10, 0.3, pathLength + 2),
			cframe = origin * CFrame.new(0, -0.25, -(World.plotSize / 2 + pathLength / 2)),
			color = "#FFDAC1",
		})
		slot.Parent = plots
		table.insert(slots, slot)
	end
	return slots
end

return MapBuilder
```

- [ ] **Step 6 : Créer `src/server/World/PlotBuilder.luau`**

```lua
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
```

- [ ] **Step 7 : Créer `src/server/Services/DataService.luau`**

```lua
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
```

- [ ] **Step 8 : Créer `src/server/Services/PlotService.luau`**

```lua
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
```

- [ ] **Step 9 : Remplacer `src/server/init.server.luau`**

```lua
--!strict
-- Point d'entrée du serveur : crée les remotes, puis initialise et démarre les services dans l'ordre.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Version = require(ReplicatedStorage.Shared.Logic.Version)

Net.setup()

local Services = script.Services
local services: { any } = {
	require(Services.DataService),
	require(Services.PlotService),
}

for _, service in services do
	if service.init then
		service.init()
	end
end
for _, service in services do
	if service.start then
		service.start()
	end
end

print("[BigBaby] serveur démarré : " .. Version.label())
```

- [ ] **Step 10 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `38 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 11 : Vérifier dans Studio**

1. `start_stop_play` (démarrer), attendre 6 s, puis `get_console_output`. Attendu : `[ProfileStore]: Roblox API services available - data will be saved` et `[BigBaby] serveur démarré : Big Baby Tycoon v0.1.0`, sans erreur.
2. `execute_luau` (`datamodel_type = "Server"`) :

```lua
local player = game.Players:GetPlayers()[1]
local plot = workspace.Plots:FindFirstChild(player:GetAttribute("Plot"))
local spawn = (plot:GetAttribute("Origin") * CFrame.new(0, 3, -48)).Position
local nursery = plot.Nursery
return player:GetAttribute("Plot"), plot:GetAttribute("OwnerUserId") == player.UserId,
	nursery.PadActive.Disk.Label.Item.Text, nursery.PadNext.Disk.Label.Item.Text,
	(player.Character:GetPivot().Position - spawn).Magnitude < 10
```

   Attendu : `Plot1`, `true`, `Milk Bottle`, `Carrot Mash`, `true`.
3. `screen_capture` : la base avec le bébé au centre, le tapis surélevé, le pot au bout, la table à langer, la dalle verte « Milk Bottle / FREE » et la dalle transparente « NEXT / Carrot Mash ».
4. `start_stop_play` (arrêter).

- [ ] **Step 12 : Commit**

```bash
git add src/shared/Net.luau src/server licenses
git commit -m "feat: map, bases attribuées, nursery et sauvegarde ProfileStore" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 8 : revenu, cacas et commandes de test (serveur)

**Files :**
- Create : `src/server/Services/IncomeService.luau`, `src/server/Services/StateService.luau`, `src/server/Services/ProductionService.luau`, `src/server/Services/DebugService.luau`
- Modify : `src/server/init.server.luau` (remplacé en entier)

**Interfaces :**
- Consumes : `DataService`, `PlotService`, `PlotBuilder`, `Net` (tâche 7) ; `Economy`, `Poops`, `Format`, `Data` (Logic) ; `Poop` (constructeur).
- Produces :
  - `IncomeService.baseIncome(player): number` et `IncomeService.income(player): number` (identiques tant qu'aucun boost n'existe) ;
  - `StateService.markDirty(player)` et `StateService.snapshot(player): Net.Snapshot?`. L'état part sur le remote `State`, 5 fois par seconde au plus ;
  - `ProductionService.spawn(player, value: number, mega: boolean)`. Le crédit au pot envoie `Effect` (`"credit"`, valeur) au propriétaire ;
  - en Studio seulement, `game.ServerStorage.DebugCommands` (BindableFunction), avec les commandes `give(coins)`, `setButtons(count)`, `setDiaper(index)`, `reset()` et `info(): string`.

- [ ] **Step 1 : Créer `src/server/Services/IncomeService.luau`**

```lua
--!strict
-- Revenu de chaque joueur (spec, section 6), calculé à partir de sa sauvegarde.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local Economy = require(ReplicatedStorage.Shared.Logic.Economy)

local IncomeService = {}

-- Revenu de base/s : multiplicateurs permanents (couche, décos, rebirths).
function IncomeService.baseIncome(player: Player): number
	local data = DataService.get(player)
	if data == nil then
		return 0
	end
	return Economy.baseIncome({
		buttons = data.buttons,
		diaper = data.diaper,
		rebirths = data.rebirths,
		petBonus = 0,
		doubleCoins = false,
		vip = false,
		premium = false,
	})
end

-- Revenu/s : revenu de base × multiplicateurs temporaires (aucun boost n'existe encore).
function IncomeService.income(player: Player): number
	return IncomeService.baseIncome(player)
end

return IncomeService
```

- [ ] **Step 2 : Créer `src/server/Services/StateService.luau`**

```lua
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
		buttons = data.buttons,
		diaper = data.diaper,
		clicksSinceMega = data.clicksSinceMega,
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
```

- [ ] **Step 3 : Créer `src/server/Services/ProductionService.luau`**

```lua
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
```

- [ ] **Step 4 : Créer `src/server/Services/DebugService.luau`**

```lua
--!strict
-- Commandes de test, en Studio uniquement. Elles passent par une BindableFunction parce que la barre de
-- commande et le MCP de Studio (execute_luau, contexte Server) ne voient pas l'état des modules du jeu :
--   game.ServerStorage.DebugCommands:Invoke("give", 1e9)
--   game.ServerStorage.DebugCommands:Invoke("setButtons", 22)
--   game.ServerStorage.DebugCommands:Invoke("setDiaper", 10)
--   game.ServerStorage.DebugCommands:Invoke("reset")
--   print(game.ServerStorage.DebugCommands:Invoke("info"))
-- Elles visent le premier joueur du serveur.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Data = require(ReplicatedStorage.Shared.Logic.Data)
local DataService = require(script.Parent.DataService)
local Format = require(ReplicatedStorage.Shared.Logic.Format)
local IncomeService = require(script.Parent.IncomeService)
local PlotService = require(script.Parent.PlotService)
local StateService = require(script.Parent.StateService)

local DebugService = {}

local function target(): (Player, Data.Profile)
	local player = Players:GetPlayers()[1]
	assert(player, "aucun joueur dans le serveur")
	local data = DataService.get(player)
	assert(data, "profil pas encore chargé")
	return player, data
end

local function changed(player: Player)
	PlotService.refresh(player)
	StateService.markDirty(player)
end

local commands: { [string]: (...any) -> ...any } = {
	give = function(coins: number)
		local player, data = target()
		data.coins += coins
		changed(player)
	end,
	setButtons = function(count: number)
		local player, data = target()
		data.buttons = count
		changed(player)
	end,
	setDiaper = function(index: number)
		local player, data = target()
		data.diaper = index
		changed(player)
	end,
	-- Remet le profil à neuf.
	reset = function()
		local player, data = target()
		local profile = data :: any
		for key in profile do
			profile[key] = nil
		end
		for key, value in Data.template() :: any do
			profile[key] = value
		end
		changed(player)
	end,
	info = function(): string
		local player, data = target()
		return string.format(
			"%s : %s PoopCoins, %d boutons, couche %d, %d cacas, %d clics, %s/s",
			player.Name,
			Format.number(data.coins),
			data.buttons,
			data.diaper,
			data.totalPoops,
			data.totalClicks,
			Format.number(IncomeService.income(player))
		)
	end,
}

function DebugService.start()
	if not RunService:IsStudio() then
		return
	end
	local bridge = Instance.new("BindableFunction")
	bridge.Name = "DebugCommands"
	bridge.OnInvoke = function(name: string, ...: any): ...any
		local command = commands[name]
		assert(command, "commande inconnue : " .. tostring(name))
		return command(...)
	end
	bridge.Parent = ServerStorage
end

return DebugService
```

- [ ] **Step 5 : Remplacer `src/server/init.server.luau`**

```lua
--!strict
-- Point d'entrée du serveur : crée les remotes, puis initialise et démarre les services dans l'ordre.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Version = require(ReplicatedStorage.Shared.Logic.Version)

Net.setup()

local Services = script.Services
local services: { any } = {
	require(Services.DataService),
	require(Services.PlotService),
	require(Services.IncomeService),
	require(Services.StateService),
	require(Services.ProductionService),
	require(Services.DebugService),
}

for _, service in services do
	if service.init then
		service.init()
	end
end
for _, service in services do
	if service.start then
		service.start()
	end
end

print("[BigBaby] serveur démarré : " .. Version.label())
```

- [ ] **Step 6 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `38 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 7 : Vérifier dans Studio**

1. `start_stop_play` (démarrer), attendre 6 s.
2. `execute_luau` (Server) :

```lua
local Debug = game.ServerStorage.DebugCommands
Debug:Invoke("reset")
Debug:Invoke("setButtons", 2)
task.wait(8)
return Debug:Invoke("info")
```

   Attendu : `… : N PoopCoins, 2 boutons, couche 1, M cacas, 0 clics, 4/s`, avec M ≥ 2 et N > 0. Les cacas mettent environ 4 s à rouler jusqu'au pot.
3. `screen_capture` sur le tapis : des cacas marron à yeux roulent vers le pot.
4. `get_console_output` : aucune erreur. Un avertissement sur la file du remote `State` est normal tant que le client (tâche 10) n'écoute pas encore.
5. `start_stop_play` (arrêter).

- [ ] **Step 8 : Commit**

```bash
git add src/server
git commit -m "feat: revenu, cacas qui roulent jusqu'au pot, état envoyé au client, commandes Debug" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 9 : clics PUSH! et achats (serveur)

**Files :**
- Create : `src/server/Services/ClickService.luau`, `src/server/Services/ShopService.luau`
- Modify : `src/server/init.server.luau` (remplacé en entier : version finale de la phase)

**Interfaces :**
- Consumes : `DataService`, `PlotService`, `PlotBuilder`, `IncomeService`, `StateService`, `ProductionService`, `Net` (tâches 7 et 8) ; `Clicks`, `Shop`, `RateLimit`, `Format` (Logic).
- Produces :
  - `ClickService.click(player)` est branché sur le remote `Click` et sur le `ClickDetector` de la couche. Un méga caca envoie `Effect` (`"mega"`, valeur) ;
  - `ShopService.buyButton(player): BuyResult?` : se tenir sur `PadActive` (rayon 4,5 studs) achète le bouton suivant dès qu'on a assez, avec 0,6 s d'écart entre deux achats ;
  - `ShopService.buyDiaper(player)` est branché sur le remote `BuyDiaper` (2 par seconde au plus) ;
  - le toast `Toast` (`"Toast.NeedMore"`, { manque formaté }) quand il manque des PoopCoins.

- [ ] **Step 1 : Créer `src/server/Services/ClickService.luau`**

```lua
--!strict
-- Les clics sur la couche (PUSH!) : gain immédiat, méga caca tous les 50 clics (spec, section 3).
-- Deux entrées : le remote Click (bouton PUSH! du HUD) et le ClickDetector de la couche du bébé.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Clicks = require(ReplicatedStorage.Shared.Logic.Clicks)
local Config = require(ReplicatedStorage.Shared.Config.Economy)
local DataService = require(script.Parent.DataService)
local IncomeService = require(script.Parent.IncomeService)
local Net = require(ReplicatedStorage.Shared.Net)
local PlotService = require(script.Parent.PlotService)
local ProductionService = require(script.Parent.ProductionService)
local RateLimit = require(ReplicatedStorage.Shared.Logic.RateLimit)
local StateService = require(script.Parent.StateService)

local ClickService = {}

local limiter = RateLimit.new(Config.maxClicksPerSecond, Config.maxClicksPerSecond)
local effect: RemoteEvent

function ClickService.click(player: Player)
	if not RateLimit.allow(limiter, player, os.clock()) then
		return
	end
	local data = DataService.get(player)
	if data == nil then
		return
	end
	local result = Clicks.register(data, IncomeService.income(player))
	StateService.markDirty(player)
	if result.mega then
		ProductionService.spawn(player, result.megaValue, true)
		effect:FireClient(player, "mega", result.megaValue)
	end
end

local function onPlotBuilt(player: Player, slot: Model)
	local diaper = slot:FindFirstChild("Diaper", true)
	local detector = diaper and diaper:FindFirstChildOfClass("ClickDetector")
	if detector then
		detector.MouseClick:Connect(function(clicker: Player)
			if clicker == player then
				ClickService.click(player)
			end
		end)
	end
end

function ClickService.start()
	effect = Net.event("Effect")
	Net.event("Click").OnServerEvent:Connect(ClickService.click)
	PlotService.built:connect(onPlotBuilt)
	Players.PlayerRemoving:Connect(function(player)
		RateLimit.forget(limiter, player)
	end)
end

return ClickService
```

- [ ] **Step 2 : Créer `src/server/Services/ShopService.luau`**

```lua
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
```

- [ ] **Step 3 : Remplacer `src/server/init.server.luau`**

```lua
--!strict
-- Point d'entrée du serveur : crée les remotes, puis initialise et démarre les services dans l'ordre.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Version = require(ReplicatedStorage.Shared.Logic.Version)

Net.setup()

local Services = script.Services
local services: { any } = {
	require(Services.DataService),
	require(Services.PlotService),
	require(Services.IncomeService),
	require(Services.StateService),
	require(Services.ProductionService),
	require(Services.ClickService),
	require(Services.ShopService),
	require(Services.DebugService),
}

for _, service in services do
	if service.init then
		service.init()
	end
end
for _, service in services do
	if service.start then
		service.start()
	end
end

print("[BigBaby] serveur démarré : " .. Version.label())
```

- [ ] **Step 4 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `38 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 5 : Vérifier dans Studio**

1. `start_stop_play` (démarrer), attendre 6 s, puis `execute_luau` (Server) :

```lua
local Debug = game.ServerStorage.DebugCommands
Debug:Invoke("reset")
Debug:Invoke("give", 1000)
return game.Players:GetPlayers()[1]:GetAttribute("Plot")
```

   Attendu : le nom de la base, par exemple `Plot1` (noté `PlotN` ci-dessous).
2. `character_navigation` vers `workspace.Plots.PlotN.Nursery.PadActive.Disk`, puis attendre 5 s sur la dalle.
3. `execute_luau` (Server) : `return game.ServerStorage.DebugCommands:Invoke("info")`. Attendu : au moins 4 boutons (biberon, purée, tapis d'éveil, fontaine de compote), et les machines et le tapis d'éveil visibles dans la base.
4. `execute_luau` (`datamodel_type = "Client"`) :
   `for _ = 1, 50 do game.ReplicatedStorage.Remotes.Click:FireServer() task.wait(0.1) end`
   puis `info` (Server). Attendu : `50 clics`. `screen_capture` juste après : un gros caca (méga caca) sur le tapis.
5. Couche : `execute_luau` (Server) `game.ServerStorage.DebugCommands:Invoke("give", 500)`, puis (Client) `game.ReplicatedStorage.Remotes.BuyDiaper:FireServer()`, puis `info` (Server). Attendu : `couche 2`, et la couche du bébé passe au vert camouflage.
6. `start_stop_play` (arrêter).

- [ ] **Step 6 : Commit**

```bash
git add src/server
git commit -m "feat: clics PUSH!, méga caca, achats sur la dalle et couches" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 10 : HUD, panneau des couches et effets (client)

**Files :**
- Create : `src/client/State.luau`, `src/client/MyPlot.luau`, `src/client/Text.luau`
- Create : `src/client/UI/Theme.luau`, `New.luau`, `Screen.luau`, `Toasts.luau`, `Hud.luau`, `DiaperPanel.luau` (dans `src/client/UI/`)
- Create : `src/client/Effects/FloatingText.luau`, `Shake.luau`, `Effects.luau` (dans `src/client/Effects/`)
- Modify : `src/client/init.client.luau` (remplacé en entier)

**Interfaces :**
- Consumes :
  - remotes `State`, `Toast`, `Effect` (reçus), `Click`, `BuyDiaper` (envoyés) ;
  - attribut `Plot` du joueur ; pièces `Spawn`, `Diaper`, `Sensor` et prompt `Kind = "ChangingTable"` de la nursery ;
  - `Economy.clickValue`, `Format.number`, `RateLimit`, `Signal`, `Config/Diapers` ;
  - clés de `Localization.csv` (tâche 5).
- Produces :
  - `State.current: Snapshot?` et `State.changed (snapshot, previous)` ;
  - `MyPlot.get(): Model?`, `MyPlot.part(name): BasePart?`, `MyPlot.waitForPart(name, timeout): BasePart?` ;
  - `Text.get(key, args?): string` ;
  - `New(className, props, children?)` ;
  - `Screen.create(name, displayOrder): ScreenGui`, dessiné pour 1280 × 720 puis mis à l'échelle de l'écran ;
  - `Toasts.show(text)` ;
  - `FloatingText.show(position, text, color, textSize)` ;
  - `Shake.play(duration, magnitude)`.

- [ ] **Step 1 : Créer `src/client/State.luau`**

```lua
--!strict
-- Dernier état de la partie reçu du serveur, et signal de changement.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)

local State = {
	current = nil :: Net.Snapshot?,
	changed = Signal.new(), -- (snapshot, previous)
}

function State.start()
	Net.event("State").OnClientEvent:Connect(function(snapshot: Net.Snapshot)
		local previous = State.current
		State.current = snapshot
		State.changed:fire(snapshot, previous)
	end)
end

return State
```

- [ ] **Step 2 : Créer `src/client/MyPlot.luau`**

```lua
--!strict
-- La base du joueur local (le serveur met son nom dans l'attribut « Plot » du joueur).
local Players = game:GetService("Players")

local MyPlot = {}

function MyPlot.get(): Model?
	local name = Players.LocalPlayer:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	if type(name) ~= "string" or plots == nil then
		return nil
	end
	local slot = plots:FindFirstChild(name)
	return if slot and slot:IsA("Model") then slot else nil
end

-- Cherche une pièce de la nursery par son nom (ex. « Diaper », « Sensor », « Spawn »).
function MyPlot.part(name: string): BasePart?
	local slot = MyPlot.get()
	local found = slot and slot:FindFirstChild(name, true)
	return if found and found:IsA("BasePart") then found else nil
end

-- Attend que la nursery soit répliquée puis renvoie la pièce (ou nil après `timeout` secondes).
function MyPlot.waitForPart(name: string, timeout: number): BasePart?
	local deadline = os.clock() + timeout
	while os.clock() < deadline do
		local part = MyPlot.part(name)
		if part then
			return part
		end
		task.wait(0.2)
	end
	return nil
end

return MyPlot
```

- [ ] **Step 3 : Créer `src/client/Text.luau`**

```lua
--!strict
-- Textes traduits (Localization.csv) : Text.get("Toast.NeedMore", { "1.2K" }).
-- Une clé absente renvoie la clé elle-même, pour repérer l'oubli tout de suite.
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")

local translator: Translator? = nil
local ok, result = pcall(function()
	return LocalizationService:GetTranslatorForPlayerAsync(Players.LocalPlayer)
end)
if ok then
	translator = result
end

local Text = {}

function Text.get(key: string, args: { any }?): string
	local current = translator
	if current then
		local success, text = pcall(function()
			return current:FormatByKey(key, args or {})
		end)
		if success then
			return text
		end
	end
	return key
end

return Text
```

- [ ] **Step 4 : Créer `src/client/UI/Theme.luau`**

```lua
--!strict
-- Couleurs et polices de l'interface.
return {
	colors = {
		panel = Color3.fromHex("#FFF6FB"),
		text = Color3.fromHex("#3A2A4A"),
		stroke = Color3.fromHex("#3A2A4A"),
		coins = Color3.fromHex("#FFE66D"),
		good = Color3.fromHex("#57CC99"),
		muted = Color3.fromHex("#B8A9C9"),
		push = Color3.fromHex("#FF9F1C"),
		accent = Color3.fromHex("#FF8FAB"),
		white = Color3.fromHex("#FFFFFF"),
	},
	fonts = {
		title = Enum.Font.LuckiestGuy,
		body = Enum.Font.FredokaOne,
	},
}
```

- [ ] **Step 5 : Créer `src/client/UI/New.luau`**

```lua
--!strict
-- Crée une instance avec ses propriétés et ses enfants : New("TextLabel", { Text = "…" }, { enfants… }).
-- La propriété Parent est appliquée en dernier.
local function New(className: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(className) :: any
	for key, value in props do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	if props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

return New
```

- [ ] **Step 6 : Créer `src/client/UI/Screen.luau`**

```lua
--!strict
-- ScreenGui mis à l'échelle de l'écran : l'interface est dessinée pour 1280 × 720 puis réduite ou agrandie.
local Players = game:GetService("Players")

local New = require(script.Parent.New)

local Screen = {}

function Screen.create(name: string, displayOrder: number): ScreenGui
	local gui = New("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		DisplayOrder = displayOrder,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	local scale = New("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function update()
		local size = camera.ViewportSize
		scale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 720), 0.55, 1.3)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	update()
	return gui
end

return Screen
```

- [ ] **Step 7 : Créer `src/client/UI/Toasts.luau`**

```lua
--!strict
-- Messages courts en haut de l'écran, qui disparaissent seuls.
local TweenService = game:GetService("TweenService")

local New = require(script.Parent.New)
local Screen = require(script.Parent.Screen)
local Theme = require(script.Parent.Theme)

local Toasts = {}

local container: Frame? = nil

function Toasts.start()
	local gui = Screen.create("Toasts", 20)
	container = New("Frame", {
		Name = "List",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 150),
		Size = UDim2.fromOffset(560, 300),
		Parent = gui,
	}, {
		New("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

function Toasts.show(text: string)
	local list = container
	if list == nil then
		return
	end
	local label = New("TextLabel", {
		BackgroundColor3 = Theme.colors.panel,
		Size = UDim2.fromOffset(540, 46),
		Font = Theme.fonts.body,
		Text = text,
		TextSize = 24,
		TextColor3 = Theme.colors.text,
		AutoLocalize = false,
		Parent = list,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 12) }),
		New("UIStroke", {
			Thickness = 2,
			Color = Theme.colors.stroke,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	})
	task.delay(2.5, function()
		local tween = TweenService:Create(
			label,
			TweenInfo.new(0.4),
			{ BackgroundTransparency = 1, TextTransparency = 1 }
		)
		tween:Play()
		tween.Completed:Wait()
		label:Destroy()
	end)
end

return Toasts
```

- [ ] **Step 8 : Créer `src/client/UI/Hud.luau`**

```lua
--!strict
-- HUD : PoopCoins, revenu et Tétines en haut ; bouton PUSH! en bas à droite (au-dessus du saut mobile) ;
-- bouton « My Base » à gauche.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config.Economy)
local Economy = require(ReplicatedStorage.Shared.Logic.Economy)
local Format = require(ReplicatedStorage.Shared.Logic.Format)
local MyPlot = require(script.Parent.Parent.MyPlot)
local Net = require(ReplicatedStorage.Shared.Net)
local New = require(script.Parent.New)
local RateLimit = require(ReplicatedStorage.Shared.Logic.RateLimit)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.Parent.State)
local Text = require(script.Parent.Parent.Text)
local Theme = require(script.Parent.Theme)

local Hud = {}

local limiter = RateLimit.new(Config.maxClicksPerSecond, Config.maxClicksPerSecond)

local function stroke(thickness: number): Instance
	return New("UIStroke", { Thickness = thickness, Color = Theme.colors.stroke })
end

local function label(props: { [string]: any }): any
	props.BackgroundTransparency = 1
	props.AutoLocalize = false
	return New("TextLabel", props, { stroke(3) })
end

local function goHome()
	local spawn = MyPlot.part("Spawn")
	local character = Players.LocalPlayer.Character
	if spawn and character then
		character:PivotTo(spawn.CFrame)
	end
end

-- Petit « +X » qui monte au-dessus du bouton PUSH!.
local function popText(parent: Instance, text: string)
	local pop = label({
		Size = UDim2.fromOffset(200, 40),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, math.random(-30, 30), 0, -6),
		Font = Theme.fonts.title,
		Text = text,
		TextSize = 30,
		TextColor3 = Theme.colors.coins,
		Parent = parent,
	})
	local info = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService
		:Create(pop, info, { Position = pop.Position - UDim2.fromOffset(0, 70), TextTransparency = 1 })
		:Play()
	task.delay(0.8, function()
		pop:Destroy()
	end)
end

function Hud.start()
	local gui = Screen.create("Hud", 10)

	local top = New("Frame", {
		Name = "Top",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(520, 130),
		Parent = gui,
	})
	local coins = label({
		Name = "Coins",
		Size = UDim2.new(1, 0, 0, 62),
		Font = Theme.fonts.title,
		Text = "💩 0",
		TextSize = 56,
		TextColor3 = Theme.colors.coins,
		Parent = top,
	})
	local income = label({
		Name = "Income",
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 0, 30),
		Font = Theme.fonts.body,
		Text = "",
		TextSize = 28,
		TextColor3 = Theme.colors.white,
		Parent = top,
	})
	local binkies = label({
		Name = "Binkies",
		Position = UDim2.fromOffset(0, 94),
		Size = UDim2.new(1, 0, 0, 28),
		Font = Theme.fonts.body,
		Text = "🍼 0",
		TextSize = 24,
		TextColor3 = Theme.colors.accent,
		Parent = top,
	})

	local push = New("TextButton", {
		Name = "Push",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -230),
		Size = UDim2.fromOffset(170, 170),
		BackgroundColor3 = Theme.colors.push,
		Font = Theme.fonts.title,
		Text = "PUSH!",
		TextSize = 44,
		TextColor3 = Theme.colors.white,
		AutoButtonColor = true,
		Parent = gui,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		New(
			"UIStroke",
			{ Thickness = 5, Color = Theme.colors.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
		),
	})
	local pushScale = New("UIScale", { Parent = push })
	push.Activated:Connect(function()
		if not RateLimit.allow(limiter, "push", os.clock()) then
			return
		end
		Net.event("Click"):FireServer()
		pushScale.Scale = 0.9
		TweenService:Create(pushScale, TweenInfo.new(0.15), { Scale = 1 }):Play()
		local snapshot = State.current
		if snapshot then
			popText(push, "+" .. Format.number(Economy.clickValue(snapshot.income)))
		end
	end)

	local home = New("TextButton", {
		Name = "MyBase",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		Size = UDim2.fromOffset(170, 60),
		BackgroundColor3 = Theme.colors.accent,
		Font = Theme.fonts.title,
		Text = "My Base",
		TextSize = 28,
		TextColor3 = Theme.colors.white,
		Parent = gui,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 14) }),
		New(
			"UIStroke",
			{ Thickness = 4, Color = Theme.colors.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
		),
	})
	home.Activated:Connect(goHome)

	State.changed:connect(function(snapshot: Net.Snapshot)
		coins.Text = "💩 " .. Format.number(snapshot.coins)
		income.Text = Text.get("HUD.Income", { Format.number(snapshot.income) })
		binkies.Text = "🍼 " .. Format.number(snapshot.binkies)
	end)
end

return Hud
```

- [ ] **Step 9 : Créer `src/client/UI/DiaperPanel.luau`**

```lua
--!strict
-- Panneau de la table à langer : les 10 couches, et le bouton pour acheter la suivante.
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Diapers = require(ReplicatedStorage.Shared.Config.Diapers)
local Format = require(ReplicatedStorage.Shared.Logic.Format)
local MyPlot = require(script.Parent.Parent.MyPlot)
local Net = require(ReplicatedStorage.Shared.Net)
local New = require(script.Parent.New)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.Parent.State)
local Text = require(script.Parent.Parent.Text)
local Theme = require(script.Parent.Theme)
local Toasts = require(script.Parent.Toasts)

type Row = { status: TextLabel, buy: TextButton }

local DiaperPanel = {}

local panel: Frame? = nil
local rows: { Row } = {}

local function render()
	local snapshot = State.current
	if snapshot == nil then
		return
	end
	for index, diaper in Diapers do
		local row = rows[index]
		local isNext = index == snapshot.diaper + 1
		row.buy.Visible = isNext
		row.status.Visible = not isNext
		if index < snapshot.diaper then
			row.status.Text = Text.get("Table.Owned")
		elseif index == snapshot.diaper then
			row.status.Text = Text.get("Table.Wearing")
		elseif isNext then
			row.buy.Text = Text.get("Table.Buy", { Format.number(diaper.price) })
			row.buy.BackgroundColor3 = if snapshot.coins >= diaper.price
				then Theme.colors.good
				else Theme.colors.muted
		else
			row.status.Text = "🔒 " .. Format.number(diaper.price)
		end
	end
end

local function buildRow(list: Instance, index: number): Row
	local diaper = Diapers[index]
	local row = New("Frame", {
		Name = "Row" .. index,
		LayoutOrder = index,
		BackgroundColor3 = Theme.colors.white,
		Size = UDim2.new(1, -12, 0, 52),
		Parent = list,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 10) }),
		New("Frame", {
			Name = "Swatch",
			BackgroundColor3 = Color3.fromHex(diaper.color),
			Position = UDim2.fromOffset(10, 8),
			Size = UDim2.fromOffset(36, 36),
		}, {
			New("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			New("UIStroke", { Thickness = 2, Color = Theme.colors.stroke }),
		}),
		New("TextLabel", {
			Name = "DiaperName",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(56, 0),
			Size = UDim2.fromScale(0.45, 1),
			Font = Theme.fonts.title,
			Text = diaper.name,
			TextSize = 26,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.colors.text,
		}),
		New("TextLabel", {
			Name = "Mult",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.fromScale(0.15, 1),
			Font = Theme.fonts.body,
			Text = "x" .. tostring(diaper.mult),
			TextSize = 24,
			TextColor3 = Theme.colors.text,
			AutoLocalize = false,
		}),
	})
	local status = New("TextLabel", {
		Name = "Status",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(170, 40),
		Font = Theme.fonts.body,
		Text = "",
		TextSize = 22,
		TextColor3 = Theme.colors.text,
		AutoLocalize = false,
		Parent = row,
	})
	local buy = New("TextButton", {
		Name = "Buy",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(170, 40),
		BackgroundColor3 = Theme.colors.good,
		Font = Theme.fonts.title,
		Text = "",
		TextSize = 20,
		TextColor3 = Theme.colors.white,
		AutoLocalize = false,
		Visible = false,
		Parent = row,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 10) }),
	})
	buy.Activated:Connect(function()
		Net.event("BuyDiaper"):FireServer()
	end)
	return { status = status, buy = buy }
end

function DiaperPanel.open()
	if panel then
		panel.Visible = true
		render()
	end
end

function DiaperPanel.close()
	if panel then
		panel.Visible = false
	end
end

function DiaperPanel.start()
	local gui = Screen.create("DiaperPanel", 15)
	local frame = New("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(600, 640),
		BackgroundColor3 = Theme.colors.panel,
		Visible = false,
		Parent = gui,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 20) }),
		New(
			"UIStroke",
			{ Thickness = 5, Color = Theme.colors.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
		),
		New("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 10),
			Size = UDim2.new(1, 0, 0, 54),
			Font = Theme.fonts.title,
			Text = "Changing Table",
			TextSize = 42,
			TextColor3 = Theme.colors.accent,
		}),
	})
	panel = frame
	local close = New("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(48, 48),
		BackgroundColor3 = Theme.colors.accent,
		Font = Theme.fonts.title,
		Text = "X",
		TextSize = 28,
		TextColor3 = Theme.colors.white,
		AutoLocalize = false,
		Parent = frame,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
	})
	close.Activated:Connect(DiaperPanel.close)
	local list = New("ScrollingFrame", {
		Name = "List",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 76),
		Size = UDim2.new(1, -24, 1, -88),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8,
		Parent = frame,
	}, {
		New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for index = 1, #Diapers do
		rows[index] = buildRow(list, index)
	end

	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
		local slot = MyPlot.get()
		if prompt:GetAttribute("Kind") == "ChangingTable" and slot and prompt:IsDescendantOf(slot) then
			DiaperPanel.open()
		end
	end)
	State.changed:connect(function(snapshot: Net.Snapshot, previous: Net.Snapshot?)
		render()
		if previous and snapshot.diaper > previous.diaper then
			local name = Text.get("Diaper." .. Diapers[snapshot.diaper].id)
			Toasts.show(Text.get("Toast.NewDiaper", { name }))
		end
	end)
end

return DiaperPanel
```

- [ ] **Step 10 : Créer `src/client/Effects/FloatingText.luau`**

```lua
--!strict
-- Texte qui monte et s'efface au-dessus d'un point du monde (« +1.2K »). Visible seulement par ce joueur.
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.UI.Theme)

local FloatingText = {}

function FloatingText.show(position: Vector3, text: string, color: Color3, textSize: number)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.CFrame = CFrame.new(position)

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(320, 80)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Adornee = anchor
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Theme.fonts.title
	label.Text = text
	label.TextColor3 = color
	label.TextSize = textSize
	label.AutoLocalize = false
	label.Parent = billboard

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Theme.colors.stroke
	stroke.Parent = label

	anchor.Parent = workspace
	local info = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(billboard, info, { StudsOffsetWorldSpace = Vector3.new(0, 6, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	task.delay(1.2, function()
		anchor:Destroy()
	end)
end

return FloatingText
```

- [ ] **Step 11 : Créer `src/client/Effects/Shake.luau`**

```lua
--!strict
-- Tremblement de la caméra (méga caca), qui s'atténue sur `duration` secondes.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shake = {}

function Shake.play(duration: number, magnitude: number)
	local character = Players.LocalPlayer.Character
	local found = character and character:FindFirstChildOfClass("Humanoid")
	if found == nil then
		return
	end
	local humanoid: Humanoid = found
	local started = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - started
		if elapsed >= duration then
			humanoid.CameraOffset = Vector3.zero
			connection:Disconnect()
			return
		end
		local strength = magnitude * (1 - elapsed / duration)
		humanoid.CameraOffset =
			Vector3.new((math.random() - 0.5) * strength, (math.random() - 0.5) * strength, 0)
	end)
end

return Shake
```

- [ ] **Step 12 : Créer `src/client/Effects/Effects.luau`**

```lua
--!strict
-- Effets envoyés par le serveur (Effect, Toast) et retour visuel des clics directs sur la couche du bébé.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Shared.Logic.Economy)
local FloatingText = require(script.Parent.FloatingText)
local Format = require(ReplicatedStorage.Shared.Logic.Format)
local MyPlot = require(script.Parent.Parent.MyPlot)
local Net = require(ReplicatedStorage.Shared.Net)
local Shake = require(script.Parent.Shake)
local State = require(script.Parent.Parent.State)
local Text = require(script.Parent.Parent.Text)
local Theme = require(script.Parent.Parent.UI.Theme)
local Toasts = require(script.Parent.Parent.UI.Toasts)

local Effects = {}

local hooked: ClickDetector? = nil

local function above(name: string, height: number): Vector3?
	local part = MyPlot.part(name)
	return if part then part.Position + Vector3.new(0, height, 0) else nil
end

local function onEffect(kind: string, value: number)
	if kind == "credit" then
		local position = above("Sensor", 6)
		if position then
			FloatingText.show(position, "+" .. Format.number(value), Theme.colors.coins, 34)
		end
	elseif kind == "mega" then
		Shake.play(0.5, 1.2)
		local position = above("Diaper", 10)
		if position then
			FloatingText.show(position, Text.get("Toast.MegaPoop"), Theme.colors.push, 56)
		end
	end
end

-- Clic direct sur la couche (ClickDetector) : le serveur compte le clic, le client affiche le gain prévu.
local function hookDiaper()
	local diaper = MyPlot.waitForPart("Diaper", 15)
	local detector = diaper and diaper:FindFirstChildOfClass("ClickDetector")
	if detector == nil or detector == hooked then
		return
	end
	hooked = detector
	detector.MouseClick:Connect(function()
		local snapshot = State.current
		local position = above("Diaper", 4)
		if snapshot and position then
			local gain = Economy.clickValue(snapshot.income)
			FloatingText.show(position, "+" .. Format.number(gain), Theme.colors.coins, 30)
		end
	end)
end

function Effects.start()
	Net.event("Effect").OnClientEvent:Connect(onEffect)
	Net.event("Toast").OnClientEvent:Connect(function(key: string, args: { any }?)
		Toasts.show(Text.get(key, args))
	end)
	Players.LocalPlayer:GetAttributeChangedSignal("Plot"):Connect(hookDiaper)
	task.spawn(hookDiaper)
end

return Effects
```

- [ ] **Step 13 : Remplacer `src/client/init.client.luau`**

```lua
--!strict
-- Point d'entrée du client.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage:WaitForChild("Remotes")

local DiaperPanel = require(script.UI.DiaperPanel)
local Effects = require(script.Effects.Effects)
local Hud = require(script.UI.Hud)
local State = require(script.State)
local Toasts = require(script.UI.Toasts)
local Version = require(ReplicatedStorage.Shared.Logic.Version)

State.start()
Toasts.start()
Hud.start()
DiaperPanel.start()
Effects.start()

print("[BigBaby] client démarré : " .. Version.label())
```

- [ ] **Step 14 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `38 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 15 : Vérifier dans Studio**

1. `start_stop_play` (démarrer), attendre 6 s, puis `get_console_output`. Attendu : `[BigBaby] client démarré : Big Baby Tycoon v0.1.0`, sans erreur. Ci-dessous, `<joueur>` est le nom du joueur de test (`game.Players:GetPlayers()[1].Name`).
2. `execute_luau` (Server) : `game.ServerStorage.DebugCommands:Invoke("reset")`, puis `screen_capture`. On voit en haut `💩 0` et le revenu, le bouton orange rond `PUSH!` en bas à droite et le bouton `My Base` à gauche.
3. `user_mouse_input` : 5 clics sur l'instance `Players.<joueur>.PlayerGui.Hud.Push`. Attendu : `+1` qui monte au-dessus du bouton, puis `info` (Server) indique `5 clics`.
4. `execute_luau` (Server) `game.ServerStorage.DebugCommands:Invoke("give", 500)`. Puis `character_navigation` vers la `ChangingTable` de la base et `user_keyboard_input` touche `E`. Attendu (`screen_capture`) : le panneau « Changing Table » avec 10 couches ; Cloth « Wearing », Camo avec un bouton vert « BUY 400 ».
5. `user_mouse_input` : clic sur `Players.<joueur>.PlayerGui.DiaperPanel.Panel.List.Row2.Buy`. Attendu : le toast « New diaper: Camo! », Camo passe à « Wearing ».
6. `character_navigation` vers `workspace.Map.Spawn`, puis clic sur `Players.<joueur>.PlayerGui.Hud.MyBase`. Attendu : le personnage revient devant sa base.
7. (Nathan, facultatif) Dans Studio, Test > Player Emulator > langue Français, puis Play : les textes passent en français (« POUSSE ! », « Ma base », « Table à langer »).
8. `start_stop_play` (arrêter).

- [ ] **Step 16 : Commit**

```bash
git add src/client
git commit -m "feat: HUD (PoopCoins, PUSH!, My Base), panneau des couches et effets" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 11 : partie complète, sauvegarde et CLAUDE.md

**Files :**
- Modify : `CLAUDE.md` (remplacé en entier)

**Interfaces :**
- Consumes : tout ce qui précède.
- Produces : le critère de fin de la phase 1 (spec, section 13) : « on joue du biberon à la Couche Cosmique (avec Debug), on quitte, on revient, tout est là ».

- [ ] **Step 1 : Jouer du biberon à la Couche Cosmique**

1. `start_stop_play` (démarrer), attendre 6 s.
2. `execute_luau` (Server) :

```lua
local Debug = game.ServerStorage.DebugCommands
Debug:Invoke("reset")
Debug:Invoke("give", 1e12)
```
3. `character_navigation` vers la `PadActive` de la base, puis attendre sur la dalle, en vérifiant `info` toutes les 10 s, jusqu'à `22 boutons` (22 achats à 0,6 s d'écart, soit environ 15 s).
4. Acheter les 9 couches, avec `execute_luau` (Client) :

```lua
for _ = 1, 9 do
	game.ReplicatedStorage.Remotes.BuyDiaper:FireServer()
	task.wait(0.6)
end
```

5. `info` (Server). Attendu : `22 boutons, couche 10`. `screen_capture` : la nursery complète, avec les murs pastel, les 12 machines, les 10 décos, un gros bébé à la couche cosmique rose néon et des cacas cyan néon.

- [ ] **Step 2 : Quitter et revenir**

1. `start_stop_play` (arrêter), puis `start_stop_play` (démarrer), attendre 8 s.
2. `info` (Server). Attendu : toujours `22 boutons, couche 10`, avec les PoopCoins restants. La base reconstruite montre tous les objets.
3. `start_stop_play` (arrêter).

- [ ] **Step 3 : Mettre `CLAUDE.md` à jour (phase 1)**

````markdown
# Big Baby Tycoon : contexte projet pour Claude Code

## Objectif
Jeu Roblox goofy de Nathan : un tycoon où l'on élève un gros bébé. Il mange (machines à bouffe), fait des cacas cartoon qui roulent jusqu'au pot et rapportent des PoopCoins ; les PoopCoins achètent des machines, des décos et des couches de plus en plus légendaires, jusqu'à la Couche Cosmique et au rebirth. But : un jeu qui accroche et qui rapporte des Robux (game passes + produits répétables), convertis en euros par le DevEx.

- Spec (source de vérité du design) : `docs/superpowers/specs/2026-10-08-big-baby-tycoon-design.md`
- Plans d'implémentation : `docs/superpowers/plans/` (un par phase)
- Jeu en anglais (langue source) avec traduction française ; « Cadum » est une marque déposée : jamais dans le jeu.

## Stack
- Roblox (Luau). Tout le jeu est du code dans ce repo, synchronisé dans Studio par **Rojo** (`default.project.json`). La map est générée par code au démarrage du serveur.
- Outils figés dans `rokit.toml` (installés par Rokit dans `~/.rokit/bin`) : Rojo, Lune (exécute les tests hors de Roblox), StyLua (format), Selene (lint), luau-lsp (types, avec les définitions Roblox).
- Sauvegardes : ProfileStore (loleris), copié tel quel dans `src/server/Vendor/` (licence Apache 2.0 dans `licenses/`).
- Aucune autre dépendance.

## Arborescence
```
default.project.json     arbre Rojo : shared → ReplicatedStorage.Shared, server → ServerScriptService.Server,
                         client → StarterPlayerScripts.Client, Localization.csv → LocalizationService
rokit.toml               versions des outils
scripts/check.sh         format + lint + types + tests (à lancer avant chaque commit)
src/shared/Config/       contenu et chiffres (données pures) : Buttons, Diapers, Economy, World, Game
src/shared/Logic/        logique pure testée (aucune API Roblox) : Format, Data, Wallet, Economy, Poops, Shop,
                         Clicks, RateLimit, Version
src/shared/Builders/     modèles cartoon en formes Roblox : Parts (outils), Baby, Poop, Pad, Machine, Decor, Furniture
src/shared/Net.luau      les RemoteEvents (noms) et le type Snapshot
src/shared/Util/Signal   signal minimal
src/server/init.server   crée les remotes, init puis start des services dans l'ordre
src/server/Services/     DataService (ProfileStore), PlotService (bases), IncomeService (revenu), StateService
                         (envoi de l'état), ProductionService (cacas), ClickService (PUSH!), ShopService (dalles,
                         couches), DebugService (commandes Studio)
src/server/World/        Layout (positions dans une base), MapBuilder (map), PlotBuilder (nursery)
src/server/Clock.luau    heure du serveur
src/client/              init.client, State (dernier état reçu), MyPlot (base du joueur), Text (traductions),
                         UI/ (Theme, New, Screen, Toasts, Hud, DiaperPanel), Effects/ (FloatingText, Shake, Effects)
src/Localization.csv     textes : Key, Source (anglais), fr
tests/                   specs Lune (*.spec.luau), runner tests/init.luau, mini framework tests/lib/t.luau
```

## Règles
1. **Le serveur décide de tout.** Le client n'envoie que des intentions (remotes de `Net.luau`) et affiche. Le serveur valide tout : propriétaire de la base, argent, fréquence (`RateLimit`), type et taille des arguments.
2. **Logique pure dans `src/shared/Logic`** : aucune API Roblox, `--!strict`, testée avec Lune. Entre modules purs, `require` par chemin relatif (`require("./Format")`, `require("../Config/Buttons")`), sans fichier `init`, pour que le même code se charge dans Lune et dans Roblox. Le code Roblox charge les modules par instance (`require(ReplicatedStorage.Shared.Logic.Format)`). **Effets de bord dans les Services.**
3. **Contenu et chiffres uniquement dans `src/shared/Config`.**
4. **Compat des sauvegardes** : tout champ ajouté au profil a une valeur par défaut dans `Data.template()` (ProfileStore complète les vieux profils avec `Reconcile`) ; tout changement de forme passe par une migration dans `Data.migrate`, testée. Clés de tables = chaînes ou listes. On ne joue jamais avec un profil non chargé.
5. **Textes** : l'anglais est la source. Un texte fixe est une `Source` de `src/Localization.csv`, traduite automatiquement par Roblox (noms, libellés). Un texte dynamique passe par `Text.get(clé, args)` côté client, avec `AutoLocalize = false`. Chaque nouveau texte = une ligne dans le CSV avec le français (`tests/Localization.spec.luau` vérifie les noms et les clés).
6. **Performance** : au plus 1 caca physique toutes les 1,5 s par base (+ méga cacas), possédés par le serveur ; les joueurs ne les touchent pas (groupes de collision) ; les effets visuels sont côté client.
7. **Heure** : `Clock.now()` côté serveur ; les fonctions pures reçoivent l'heure en paramètre.
8. **Pas de hasard payant** (à partir de la phase 3) : rien d'acheté en Robux ne donne de Tétines ni ne change les chances des œufs.
9. **Achats Robux** (phase 3) : idempotents, accordés seulement une fois le profil sauvegardé.
10. **Ne jamais modifier un script dans Studio** (ni par le MCP de Studio) : Rojo l'écraserait. On modifie les fichiers du repo.

## Commandes
```bash
rokit install                                  # outils de rokit.toml (une fois par machine)
scripts/check.sh                               # format + lint + types + tests : avant chaque commit
lune run tests                                 # tests seuls
stylua src tests                               # reformater
rojo serve                                     # synchro live vers Studio (plugin Rojo > Connect)
rojo build -o build/BigBabyTycoon.rbxlx        # fichier de place
```
Les outils sont dans `~/.rokit/bin` (ajouté au PATH par `~/.zshenv` ; `scripts/check.sh` l'ajoute aussi).

Tester dans Studio : `rojo serve`, plugin Rojo > Connect, puis Play. Commandes de test (Studio seulement, contexte Server : barre de commande ou MCP de Studio `execute_luau`). Elles passent par une BindableFunction, car la barre de commande et le MCP ne voient pas l'état des modules du jeu :
```lua
local Debug = game.ServerStorage.DebugCommands
Debug:Invoke("give", 1e9) ; Debug:Invoke("setButtons", 22) ; Debug:Invoke("setDiaper", 10)
Debug:Invoke("reset") ; print(Debug:Invoke("info"))
```

Pièges :
- Sans accès aux API (jeu non publié, ou « Enable Studio Access to API Services » désactivé), ProfileStore tourne en mémoire et ne sauvegarde rien : la sortie affiche « Roblox API services unavailable ».
- En Studio, la base de données s'appelle `Profiles_v1_Studio` : les tests ne touchent jamais aux vrais joueurs.
- Un `require` par chaîne n'attend pas la réplication : le client attend `game.Loaded` avant de charger ses modules.
- `-- stylua: ignore` garde les tables de contenu (Buttons, Diapers) sur une ligne par entrée.

## État actuel
**Phase 1 (le cœur)** : map (place centrale + 6 bases générées par code), une base attribuée à chaque joueur, bébé qui grossit, 22 boutons achetés en se tenant sur la dalle (12 machines, 10 décos), cacas physiques sur le tapis jusqu'au pot, clic PUSH! (bouton ou couche) et méga caca tous les 50 clics, 10 couches à la table à langer, sauvegarde ProfileStore, HUD (PoopCoins, revenu, Tétines, PUSH!, My Base), traductions françaises, commandes Debug en Studio. 38 tests Lune.

Prochaine étape : phase 2 (rebirth, classements, gains hors ligne, tutoriel, annonces), avec son propre plan.

## Phases (spec, section 13)
0 Outillage · 1 Le cœur (bases, bébé, cacas, clic, couches, sauvegarde, HUD) · 2 Progression (rebirth, classements, hors ligne, tuto) · 3 Monétisation · 4 Pets · 5 Rétention · 6 Finition et lancement.
````

- [ ] **Step 4 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `38 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 5 : Commit**

```bash
git add CLAUDE.md
git commit -m "docs: CLAUDE.md à jour pour la phase 1" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

## Hors de cette phase

Ces éléments de la spec viennent dans les phases suivantes, chacune avec son plan :
- rebirth, classements, gains hors ligne, tutoriel, annonces (phase 2) ;
- boutique Robux, passes (Auto Push, x2…), boosts, raccourci vers les packs dans le toast « You need X more » (phase 3) ;
- pets et œufs (phase 4) ;
- coffre quotidien, quêtes, cadeaux, codes, events, commande Debug « avancer l'horloge » (phase 5) ;
- sons (prouts, *plop*…), musique, arcs de bouffe, animations du bébé (balancement, clignement, rire), machines aux formes uniques, couche arc-en-ciel qui change de couleur, simulateur d'économie et test d'équilibrage (phase 6).

## Phase 1 terminée quand

- `scripts/check.sh` affiche `OK` (38 tests) ;
- dans Studio : une base est attribuée et construite, les cacas roulent jusqu'au pot et rapportent, PUSH! et le méga caca marchent, les 22 boutons et les 10 couches s'achètent, le HUD et le panneau des couches s'affichent ;
- après avoir quitté et relancé la partie, la progression est intacte.
