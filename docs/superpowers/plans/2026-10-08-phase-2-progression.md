# Phase 2 : progression, plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task, inline (pas de sous-agents : choix de Nathan, ils consomment trop de tokens). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** la progression au-delà de la Couche Cosmique. Le rebirth repart de zéro contre +50 % de PoopCoins pour toujours. Les classements (serveur et mondiaux, avec couronnes) montrent qui a le plus gros bébé. Les gains hors ligne accueillent le joueur qui revient, un tutoriel guide les nouveaux, et les grands rebirths sont annoncés à tout le serveur.

**Architecture :**
- **Logique pure** (`src/shared/Logic`, testée avec Lune) : rebirth, gains hors ligne, encodage des scores, étapes du tutoriel.
- **Constructeurs** (`src/shared/Builders`) : couronne, panneau de classement.
- **Services serveur** : `RebirthService`, `LeaderstatsService`, `AnnounceService`, `OfflineService`, `LeaderboardService` (OrderedDataStores, panneaux, couronnes), `TutorialService` (étapes validées côté serveur, entonnoir analytics).
- **Client** : bouton et panneau Rebirth, écran « Welcome back », bannière d'annonce, guide du tutoriel (bulle + flèche Beam). Il n'envoie qu'une intention de plus : le remote `Rebirth`.

**Tech Stack :** Luau, Rojo 7.7.1, Lune 0.10.5, ProfileStore, DataStoreService (OrderedDataStore), AnalyticsService, TextChatService, MCP de Studio.

Spec : `docs/superpowers/specs/2026-10-08-big-baby-tycoon-design.md` (sections 4, 6, 9, 11). Prérequis : phase 1 terminée (`docs/superpowers/plans/2026-10-08-phase-1-coeur.md`), sur `main`.

## Global Constraints

- Repo : `/Users/nathan/Public/dev/gros-bebe-tycoon`. Travail sur la branche `phase-2-progression` (créée depuis `main`). Toutes les commandes se lancent depuis la racine, avec `export PATH="$HOME/.rokit/bin:$PATH"`.
- Aucune dépendance en dehors de ProfileStore.
- Langue du jeu : anglais (source) + français dans `src/Localization.csv`. Le mot « Cadum » n'apparaît jamais dans le jeu. Un texte qui contient une virgule est entre guillemets dans le CSV (tâche 3).
- Logique pure dans `src/shared/Logic` : aucune API Roblox, `--!strict`, `require` relatifs, testée avec Lune.
- Le serveur décide de tout. Le client n'envoie que les remotes déclarés dans `src/shared/Net.luau`, et le serveur limite leur fréquence.
- Valeurs de la spec à respecter :
  - rebirth : il faut la Couche Cosmique (couche 10) et 30B × 1,6^R PoopCoins en poche (R = rebirths déjà faits) ;
  - le rebirth remet à zéro les PoopCoins, les boutons et les couches ; il garde les Tétines, les rebirths et les statistiques ;
  - chaque rebirth donne +50 % de PoopCoins pour toujours (multiplicateur 1 + 0,5 × R) et 25 × (nouveau R) Tétines ;
  - le bébé grossit avec les rebirths : la formule `Economy.babyScale` le fait déjà ;
  - `leaderstats` : PoopCoins (texte formaté) et Rebirths ;
  - classements mondiaux « Biggest Babies » (rebirths) et « Poop Kings » (total de PoopCoins gagnés), top 50, relus toutes les 2 min ;
  - le score d'un joueur est écrit à chaque rebirth, toutes les 5 min et à son départ ;
  - le total gagné est stocké en `floor(log10(total + 1) × 10^6)` ;
  - couronnes or, argent et bronze sur le bébé du top 3 mondial des rebirths, s'il est dans le serveur ;
  - gains hors ligne = 25 % × revenu de base/s × min(absence ; 8 h) ;
  - tutoriel pour les nouveaux joueurs seulement, avec une flèche lumineuse (Beam) et une bulle ; l'étape en cours est sauvegardée ; chaque étape part dans l'entonnoir d'onboarding des analytics ; +25 Tétines à la fin ;
  - annonce (bannière + message système dans le chat) au 10e, 25e et 50e rebirth.
- En Studio, les DataStores ont le suffixe `_Studio`.
- Commentaires du code et messages de commit en français. Chaque commit se termine par la ligne `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- `scripts/check.sh` passe avant chaque commit.
- On ne modifie jamais un script dans Studio : on modifie les fichiers, et Rojo (`rojo serve` + plugin connecté) les pousse.
- **Vérifications dans Studio** : par les outils du MCP de Studio, qui prennent tous le `studio_id` donné par `list_roblox_studios`. `execute_luau` ne renvoie que la première valeur de retour : renvoyer une seule chaîne. Les commandes de test passent par `game.ServerStorage.DebugCommands`. Ce qui touche aux DataStores (sauvegarde, classements mondiaux) demande l'accès aux API en Studio : la sortie doit afficher `[ProfileStore]: Roblox API services available`. Sinon, Nathan l'active (Game Settings > Security > « Enable Studio Access to API Services »).

---

### Task 1 : rebirth, gains hors ligne et scores des classements (logique pure)

**Files :**
- Create : `src/shared/Config/Rebirth.luau`, `src/shared/Config/Leaderboards.luau`
- Modify : `src/shared/Config/Economy.luau` (constantes des gains hors ligne)
- Create : `src/shared/Logic/Rebirth.luau`, `src/shared/Logic/Offline.luau`, `src/shared/Logic/Leaderboard.luau`
- Modify : `src/shared/Logic/Economy.luau` (multiplicateur de rebirth pris dans `Rebirth`)
- Test : `tests/Rebirth.spec.luau`, `tests/Offline.spec.luau`, `tests/Leaderboard.spec.luau`

**Interfaces :**
- Consumes : `Data` (profil), `Config/Diapers`, `Config/Economy` (phase 1).
- Produces :
  - `Config/Rebirth` : `base` (30e9), `growth` (1,6), `binkiesPerRebirth` (25), `milestones` ({ 10, 25, 50 }) ;
  - `Config/Leaderboards` : `size` (50), `refreshSeconds` (120), `writeSeconds` (300), `crownColors` (or, argent, bronze en hexadécimal) ;
  - `Config/Economy` : `offlineShare` (0,25), `offlineCapSeconds` (8 h), `offlineMinSeconds` (60) ;
  - `Rebirth.cost(rebirths)`, `Rebirth.multiplier(rebirths)`, `Rebirth.reward(rebirths)`, `Rebirth.blocker(diaper, coins, rebirths): string?` (`"diaper"`, `"poor"` ou nil), `Rebirth.apply(data): RebirthResult` avec `RebirthResult = { reason: "done" | "diaper" | "poor", rebirths, binkies }`, `Rebirth.isMilestone(rebirths)` ;
  - `Offline.gain(baseIncome, awaySeconds)` ;
  - `Leaderboard.encodeEarned(total)` et `Leaderboard.decodeEarned(score)`.

- [ ] **Step 1 : Écrire `tests/Rebirth.spec.luau`**

```lua
local T = require("./lib/t")
local Data = require("../src/shared/Logic/Data")
local Rebirth = require("../src/shared/Logic/Rebirth")

-- Un profil qui peut faire son rebirth n° rebirths + 1.
local function ready(rebirths: number)
	local data = Data.template()
	data.rebirths = rebirths
	data.buttons = 22
	data.diaper = 10
	data.coins = Rebirth.cost(rebirths)
	return data
end

T.describe("Rebirth", function()
	T.it("coûte 30B × 1,6^R", function()
		T.eq(Rebirth.cost(0), 30e9)
		T.near(Rebirth.cost(1), 48e9, 1)
		T.near(Rebirth.cost(2), 76.8e9, 1)
	end)
	T.it("multiplie les PoopCoins par 1 + 0,5 × R", function()
		T.eq(Rebirth.multiplier(0), 1)
		T.eq(Rebirth.multiplier(3), 2.5)
	end)
	T.it("donne 25 × R Tétines", function()
		T.eq(Rebirth.reward(1), 25)
		T.eq(Rebirth.reward(4), 100)
	end)
	T.it("exige la Couche Cosmique puis assez de PoopCoins", function()
		T.eq(Rebirth.blocker(9, 1e12, 0), "diaper")
		T.eq(Rebirth.blocker(10, 29e9, 0), "poor")
		T.eq(Rebirth.blocker(10, 30e9, 0), nil)
		T.eq(Rebirth.blocker(10, 30e9, 1), "poor", "le 2e rebirth coûte 48B")
	end)
	T.it("repart de zéro et garde les Tétines et les statistiques", function()
		local data = ready(1)
		data.binkies = 7
		data.totalEarned = 1e12
		local result = Rebirth.apply(data)
		T.eq(result.reason, "done")
		T.eq(result.rebirths, 2)
		T.eq(result.binkies, 50)
		T.eq(data.rebirths, 2)
		T.eq(data.binkies, 57)
		T.eq(data.coins, 0)
		T.eq(data.buttons, 0)
		T.eq(data.diaper, 1)
		T.eq(data.totalEarned, 1e12, "le total gagné est gardé")
	end)
	T.it("ne change rien si le rebirth est impossible", function()
		local data = ready(0)
		data.coins = 1
		local result = Rebirth.apply(data)
		T.eq(result.reason, "poor")
		T.eq(result.binkies, 0)
		T.eq(data.rebirths, 0)
		T.eq(data.coins, 1)
		T.eq(data.buttons, 22)
	end)
	T.it("annonce les 10e, 25e et 50e rebirths", function()
		T.eq(Rebirth.isMilestone(10), true)
		T.eq(Rebirth.isMilestone(25), true)
		T.eq(Rebirth.isMilestone(50), true)
		T.eq(Rebirth.isMilestone(11), false)
	end)
end)
```

- [ ] **Step 2 : Écrire `tests/Offline.spec.luau`**

```lua
local T = require("./lib/t")
local Offline = require("../src/shared/Logic/Offline")

T.describe("Offline", function()
	T.it("rapporte 25 % du revenu de base pendant l'absence", function()
		T.eq(Offline.gain(100, 3600), 90_000)
	end)
	T.it("plafonne l'absence à 8 h", function()
		T.eq(Offline.gain(100, 3 * 24 * 3600), 720_000)
	end)
	T.it("ne donne rien pour moins d'une minute d'absence", function()
		T.eq(Offline.gain(100, 59), 0)
		T.eq(Offline.gain(100, 60), 1_500)
	end)
end)
```

- [ ] **Step 3 : Écrire `tests/Leaderboard.spec.luau`**

```lua
local T = require("./lib/t")
local Leaderboard = require("../src/shared/Logic/Leaderboard")

T.describe("Leaderboard", function()
	T.it("encode le total gagné en entier", function()
		T.eq(Leaderboard.encodeEarned(0), 0)
		T.eq(Leaderboard.encodeEarned(9), 1_000_000)
		T.eq(Leaderboard.encodeEarned(12_345) % 1, 0)
	end)
	T.it("relit le total à 0,001 % près", function()
		for _, total in { 1234, 5.6e9, 7.8e24 } do
			local back = Leaderboard.decodeEarned(Leaderboard.encodeEarned(total))
			T.truthy(math.abs(back - total) / total < 1e-5, "écart pour " .. total)
		end
	end)
	T.it("range les gros totaux devant les petits", function()
		T.truthy(Leaderboard.encodeEarned(2e15) > Leaderboard.encodeEarned(1e15))
	end)
end)
```

- [ ] **Step 4 : Vérifier qu'ils échouent**

Run : `lune run tests`
Attendu : `error requiring module "../src/shared/Logic/Leaderboard"` (le premier spec qui manque, par ordre alphabétique) et un code de sortie non nul.

- [ ] **Step 5 : Créer `src/shared/Config/Rebirth.luau` et `src/shared/Config/Leaderboards.luau`**

`src/shared/Config/Rebirth.luau` :

```lua
--!strict
-- Rebirth (spec, section 4). Le bonus de PoopCoins (+50 % par rebirth) est dans Config/Economy.
return {
	base = 30e9, -- PoopCoins à avoir en poche pour le 1er rebirth…
	growth = 1.6, -- …multipliés par 1,6 à chaque rebirth déjà fait
	binkiesPerRebirth = 25, -- 25 × (nouveau nombre de rebirths) Tétines
	milestones = { 10, 25, 50 }, -- rebirths annoncés à tout le serveur
}
```

`src/shared/Config/Leaderboards.luau` :

```lua
--!strict
-- Classements mondiaux (spec, section 4).
return {
	size = 50, -- top 50 sur chaque panneau
	refreshSeconds = 120, -- les panneaux relisent les classements toutes les 2 min
	writeSeconds = 300, -- les scores des joueurs présents sont écrits toutes les 5 min
	crownColors = { "#FFD700", "#C0C0C0", "#CD7F32" }, -- couronnes du top 3 : or, argent, bronze
}
```

- [ ] **Step 6 : Ajouter les constantes des gains hors ligne à `src/shared/Config/Economy.luau`**

Ajouter ces trois lignes à la fin de la table, après `beltSpeed = 12, -- studs par seconde` :

```lua
	offlineShare = 0.25, -- gains hors ligne : 25 % du revenu de base…
	offlineCapSeconds = 8 * 3600, -- …pendant 8 h d'absence au plus
	offlineMinSeconds = 60, -- moins d'une minute d'absence : rien
```

- [ ] **Step 7 : Créer `src/shared/Logic/Rebirth.luau`**

```lua
--!strict
-- Rebirth (spec, section 4) : avec la Couche Cosmique et assez de PoopCoins en poche, on repart de zéro
-- (PoopCoins, boutons, couches) contre +50 % de PoopCoins pour toujours et des Tétines.
local Config = require("../Config/Rebirth")
local Data = require("./Data")
local Diapers = require("../Config/Diapers")
local EconomyConfig = require("../Config/Economy")

type Profile = Data.Profile

-- reason : "done" (rebirth fait), "diaper" (il manque la Couche Cosmique), "poor" (pas assez de PoopCoins).
-- rebirths : nombre de rebirths après l'appel ; binkies : Tétines gagnées.
export type RebirthResult = { reason: string, rebirths: number, binkies: number }

local Rebirth = {}

-- PoopCoins à avoir en poche quand on a déjà fait `rebirths` rebirths.
function Rebirth.cost(rebirths: number): number
	return Config.base * Config.growth ^ rebirths
end

-- Multiplicateur de PoopCoins après `rebirths` rebirths : 1 + 0,5 × R.
function Rebirth.multiplier(rebirths: number): number
	return 1 + EconomyConfig.rebirthBonus * rebirths
end

-- Tétines gagnées en atteignant `rebirths` rebirths.
function Rebirth.reward(rebirths: number): number
	return Config.binkiesPerRebirth * rebirths
end

-- Ce qui empêche le rebirth ("diaper", "poor"), ou nil s'il est possible.
function Rebirth.blocker(diaper: number, coins: number, rebirths: number): string?
	if diaper < #Diapers then
		return "diaper"
	end
	if coins < Rebirth.cost(rebirths) then
		return "poor"
	end
	return nil
end

function Rebirth.apply(data: Profile): RebirthResult
	local blocker = Rebirth.blocker(data.diaper, data.coins, data.rebirths)
	if blocker then
		return { reason = blocker, rebirths = data.rebirths, binkies = 0 }
	end
	data.rebirths += 1
	local binkies = Rebirth.reward(data.rebirths)
	data.binkies += binkies
	data.coins = 0
	data.buttons = 0
	data.diaper = 1
	return { reason = "done", rebirths = data.rebirths, binkies = binkies }
end

-- Ce rebirth est-il annoncé à tout le serveur ?
function Rebirth.isMilestone(rebirths: number): boolean
	return table.find(Config.milestones, rebirths) ~= nil
end

return Rebirth
```

- [ ] **Step 8 : Créer `src/shared/Logic/Offline.luau`**

```lua
--!strict
-- Gains hors ligne (spec, section 4) : 25 % du revenu de base pendant l'absence, plafonnée à 8 h.
local Config = require("../Config/Economy")

local Offline = {}

-- PoopCoins gagnés pendant `awaySeconds` d'absence avec ce revenu de base/s (rien sous une minute).
function Offline.gain(baseIncome: number, awaySeconds: number): number
	if awaySeconds < Config.offlineMinSeconds then
		return 0
	end
	return Config.offlineShare * baseIncome * math.min(awaySeconds, Config.offlineCapSeconds)
end

return Offline
```

- [ ] **Step 9 : Créer `src/shared/Logic/Leaderboard.luau`**

```lua
--!strict
-- Scores des classements mondiaux. Un OrderedDataStore n'accepte que des entiers, et le total de PoopCoins
-- dépasse vite 2^53 : on stocke floor(log10(total + 1) × 10^6) et on le reconvertit pour l'affichage.
local SCALE = 1e6

local Leaderboard = {}

function Leaderboard.encodeEarned(total: number): number
	return math.floor(math.log10(math.max(total, 0) + 1) * SCALE)
end

function Leaderboard.decodeEarned(score: number): number
	return 10 ^ (score / SCALE) - 1
end

return Leaderboard
```

- [ ] **Step 10 : Prendre le multiplicateur de rebirth dans `Rebirth` (`src/shared/Logic/Economy.luau`)**

Ajouter le require, rangé par ordre alphabétique après `local Diapers = require("../Config/Diapers")` :

```lua
local Rebirth = require("./Rebirth")
```

Puis, dans `Economy.baseIncome`, remplacer la ligne `* (1 + Config.rebirthBonus * input.rebirths)` par :

```lua
		* Rebirth.multiplier(input.rebirths)
```

La formule reste 1 + 0,5 × R : `tests/Economy.spec.luau` ne change pas.

- [ ] **Step 11 : Vérifier qu'ils passent**

Run : `lune run tests`
Attendu : `51 tests réussis, 0 en échec`.

- [ ] **Step 12 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `51 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 13 : Commit**

```bash
git add src/shared/Config src/shared/Logic tests
git commit -m "feat: rebirth, gains hors ligne et scores des classements (logique)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 2 : tutoriel (config et logique pure)

**Files :**
- Create : `src/shared/Config/Tutorial.luau`, `src/shared/Logic/Tutorial.luau`
- Test : `tests/Tutorial.spec.luau`

**Interfaces :**
- Consumes : `Data` (profil : `tutorial`, `buttons`, `totalClicks`, `diaper`, `binkies`).
- Produces :
  - `Config/Tutorial` : `reward` (25) et `steps: { Step }`, avec `Step = { id, goal ("buttons" | "clicks" | "diaper" | "poop"), count, target }`. `target` est le chemin de la pièce visée depuis la nursery (`"PadActive.Disk"`, `"Baby.Diaper"`, `"Potty.Sensor"`, `"ChangingTable.Top"`) ; le texte de l'étape est la clé `Tutorial.<id>` ;
  - `Tutorial.DONE` (99), `Tutorial.start(data)`, `Tutorial.step(data): Step?`, `Tutorial.isComplete(step, data, poopArrived)`, `Tutorial.advance(data, poopArrived): ({ Step }, number)` (étapes validées et Tétines de récompense, 0 si le tutoriel n'est pas fini).
- `data.tutorial` : 0 = pas commencé, 1…n = étape en cours, 99 = terminé.

- [ ] **Step 1 : Écrire `tests/Tutorial.spec.luau`**

```lua
local T = require("./lib/t")
local Data = require("../src/shared/Logic/Data")
local Tutorial = require("../src/shared/Logic/Tutorial")
local TutorialConfig = require("../src/shared/Config/Tutorial")

T.describe("Tutorial", function()
	T.it("démarre pour un profil neuf et saute pour un profil avancé", function()
		local fresh = Data.template()
		Tutorial.start(fresh)
		T.eq(fresh.tutorial, 1)
		local veteran = Data.template()
		veteran.buttons = 3
		Tutorial.start(veteran)
		T.eq(veteran.tutorial, Tutorial.DONE)
	end)
	T.it("avance quand le profil remplit l'étape", function()
		local data = Data.template()
		Tutorial.start(data)
		local completed = Tutorial.advance(data, false)
		T.eq(#completed, 0)
		data.buttons = 1
		completed = Tutorial.advance(data, false)
		T.eq(#completed, 1)
		T.eq(completed[1].id, "bottle")
		T.eq(data.tutorial, 2)
	end)
	T.it("attend un caca au pot pendant l'étape « poop »", function()
		local data = Data.template()
		data.tutorial = 2
		data.buttons = 1
		data.totalClicks = 10
		data.totalPoops = 5
		Tutorial.advance(data, false)
		T.eq(data.tutorial, 3, "les cacas d'avant ne comptent pas")
		Tutorial.advance(data, true)
		T.eq(data.tutorial, 4)
	end)
	T.it("donne 25 Tétines à la fin, une seule fois", function()
		local data = Data.template()
		data.tutorial = 5
		data.diaper = 2
		local completed, reward = Tutorial.advance(data, false)
		T.eq(completed[1].id, "camo")
		T.eq(reward, 25)
		T.eq(data.binkies, 25)
		T.eq(data.tutorial, Tutorial.DONE)
		local _, again = Tutorial.advance(data, true)
		T.eq(again, 0)
		T.eq(data.binkies, 25)
	end)
	T.it("n'utilise que des buts connus", function()
		local known = { buttons = true, clicks = true, diaper = true, poop = true }
		for _, step in TutorialConfig.steps do
			T.truthy(known[step.goal], "but " .. step.goal)
			T.truthy(step.target ~= "", "cible de " .. step.id)
		end
	end)
end)
```

- [ ] **Step 2 : Vérifier qu'il échoue**

Run : `lune run tests`
Attendu : `error requiring module "../src/shared/Logic/Tutorial"`.

- [ ] **Step 3 : Créer `src/shared/Config/Tutorial.luau`**

```lua
--!strict
-- Étapes du tutoriel des nouveaux joueurs (spec, section 4), dans l'ordre. Les étapes « œuf » et « pet » de
-- la spec arriveront avec les pets (phase 4), juste avant la fin.
-- goal : ce qui valide l'étape. "buttons", "clicks", "diaper" : ce compteur du profil (boutons achetés, clics,
-- couche) atteint `count` ; "poop" : un caca arrive au pot pendant l'étape.
-- target : chemin, depuis la nursery, de la pièce que montre la flèche. Texte : clé "Tutorial.<id>".

export type Step = { id: string, goal: string, count: number, target: string }

local steps: { Step } = {
	{ id = "bottle", goal = "buttons", count = 1, target = "PadActive.Disk" },
	{ id = "push", goal = "clicks", count = 10, target = "Baby.Diaper" },
	{ id = "poop", goal = "poop", count = 1, target = "Potty.Sensor" },
	{ id = "carrot", goal = "buttons", count = 2, target = "PadActive.Disk" },
	{ id = "camo", goal = "diaper", count = 2, target = "ChangingTable.Top" },
}

return {
	reward = 25, -- Tétines données à la fin du tutoriel
	steps = steps,
}
```

- [ ] **Step 4 : Créer `src/shared/Logic/Tutorial.luau`**

```lua
--!strict
-- Le tutoriel des nouveaux joueurs (spec, section 4). `data.tutorial` : 0 = pas commencé, 1…n = étape en cours
-- (index dans Config/Tutorial), Tutorial.DONE = terminé. Les étapes se valident d'après le profil ; l'étape
-- « poop » attend qu'un caca arrive au pot pendant qu'elle est affichée.
local Config = require("../Config/Tutorial")
local Data = require("./Data")

type Profile = Data.Profile

local Tutorial = {}

Tutorial.DONE = 99

-- Démarre le tutoriel d'un profil neuf ; un profil déjà avancé le saute.
function Tutorial.start(data: Profile)
	if data.tutorial == 0 then
		data.tutorial = if data.buttons == 0 and data.rebirths == 0 then 1 else Tutorial.DONE
	end
end

-- Étape en cours, ou nil (pas commencé ou terminé).
function Tutorial.step(data: Profile): Config.Step?
	return Config.steps[data.tutorial]
end

-- L'étape est-elle faite ? `poopArrived` : un caca vient d'arriver au pot.
function Tutorial.isComplete(step: Config.Step, data: Profile, poopArrived: boolean): boolean
	if step.goal == "buttons" then
		return data.buttons >= step.count
	elseif step.goal == "clicks" then
		return data.totalClicks >= step.count
	elseif step.goal == "diaper" then
		return data.diaper >= step.count
	elseif step.goal == "poop" then
		return poopArrived
	end
	return false
end

-- Valide autant d'étapes que possible. Renvoie les étapes validées, dans l'ordre, et les Tétines données
-- si le tutoriel vient de se terminer (0 sinon).
function Tutorial.advance(data: Profile, poopArrived: boolean): ({ Config.Step }, number)
	local completed = {}
	local step = Tutorial.step(data)
	while step and Tutorial.isComplete(step, data, poopArrived) do
		table.insert(completed, step)
		poopArrived = false -- un même caca ne valide qu'une étape
		data.tutorial += 1
		step = Tutorial.step(data)
	end
	if #completed > 0 and step == nil then
		data.tutorial = Tutorial.DONE
		data.binkies += Config.reward
		return completed, Config.reward
	end
	return completed, 0
end

return Tutorial
```

- [ ] **Step 5 : Vérifier qu'il passe**

Run : `lune run tests`
Attendu : `56 tests réussis, 0 en échec`.

- [ ] **Step 6 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `56 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 7 : Commit**

```bash
git add src/shared/Config/Tutorial.luau src/shared/Logic/Tutorial.luau tests/Tutorial.spec.luau
git commit -m "feat: étapes du tutoriel (logique)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 3 : traductions

**Files :**
- Modify : `src/Localization.csv` (lignes ajoutées à la fin)
- Modify : `tests/Localization.spec.luau` (remplacé en entier : champs entre guillemets, nouvelles clés, étapes du tutoriel)

**Interfaces :**
- Consumes : `Config/Buttons`, `Config/Diapers`, `Config/Tutorial`.
- Produces :
  - clés utilisées par le client et le serveur : `HUD.Rebirth`, `Toast.Rebirth` (`{1}` rebirths, `{2}` multiplicateur), `Toast.CantRebirth`, `Rebirth.NeedDiaper`, `Rebirth.NeedCoins` (`{1}` prix), `Rebirth.Multiplier` (`{1}` → `{2}`), `Rebirth.Reward` (`{1}` Tétines), `Rebirth.Lose`, `Rebirth.Keep`, `Rebirth.Button`, `Rebirth.Confirm`, `Welcome.Title`, `Welcome.Body` (`{1}` PoopCoins), `Welcome.Ok`, `Announce.Rebirth` (`{1}` nom, `{2}` rebirths), `Board.Rebirths`, `Board.Earned`, `Board.Loading`, `Tutorial.<id>` pour chaque étape (`Tutorial.push` prend `{1}` clics faits), `Tutorial.Done` (`{1}` Tétines) ;
  - sources fixes traduites automatiquement : `Rebirth`, `Welcome back!`, `Awesome!`, `Biggest Babies`, `Poop Kings`, `Loading...`.
- Un texte qui contient une virgule est entre guillemets ; `""` = un guillemet dans le texte.

- [ ] **Step 1 : Remplacer `tests/Localization.spec.luau`**

```lua
local fs = require("@lune/fs")
local T = require("./lib/t")
local Buttons = require("../src/shared/Config/Buttons")
local Diapers = require("../src/shared/Config/Diapers")
local Tutorial = require("../src/shared/Config/Tutorial")

-- Découpe une ligne CSV : un champ qui contient une virgule est entre guillemets ("" = un guillemet).
local function cells(line: string): { string }
	local result = {}
	local field = ""
	local quoted = false
	local index = 1
	while index <= #line do
		local char = string.sub(line, index, index)
		if quoted and char == '"' and string.sub(line, index + 1, index + 1) == '"' then
			field ..= '"'
			index += 1
		elseif char == '"' then
			quoted = not quoted
		elseif char == "," and not quoted then
			table.insert(result, field)
			field = ""
		else
			field ..= char
		end
		index += 1
	end
	table.insert(result, field)
	return result
end

-- Lit Localization.csv : clé → { source, fr }.
local function load(): { [string]: { source: string, fr: string } }
	local rows = {}
	local lines = string.split(fs.readFile("src/Localization.csv"), "\n")
	T.eq(lines[1], "Key,Source,Context,Example,fr", "en-tête")
	for index = 2, #lines do
		local line = lines[index]
		if line ~= "" then
			local row = cells(line)
			T.eq(#row, 5, "5 colonnes ligne " .. index)
			T.truthy(rows[row[1]] == nil, "clé unique " .. row[1])
			rows[row[1]] = { source = row[2], fr = row[5] }
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
	T.it("traduit chaque étape du tutoriel", function()
		for _, step in Tutorial.steps do
			local row = rows["Tutorial." .. step.id]
			T.truthy(row, "ligne Tutorial." .. step.id)
			T.truthy(row.fr ~= "", "français de l'étape " .. step.id)
		end
	end)
	T.it("contient les clés utilisées par le code", function()
		for _, key in
			{
				"HUD.Income",
				"HUD.Push",
				"HUD.MyBase",
				"HUD.Rebirth",
				"Pad.Free",
				"Pad.Next",
				"Toast.NeedMore",
				"Toast.NewDiaper",
				"Toast.MegaPoop",
				"Toast.Rebirth",
				"Toast.CantRebirth",
				"Table.Title",
				"Table.Action",
				"Table.Owned",
				"Table.Wearing",
				"Table.Buy",
				"Rebirth.NeedDiaper",
				"Rebirth.NeedCoins",
				"Rebirth.Multiplier",
				"Rebirth.Reward",
				"Rebirth.Lose",
				"Rebirth.Keep",
				"Rebirth.Button",
				"Rebirth.Confirm",
				"Welcome.Title",
				"Welcome.Body",
				"Welcome.Ok",
				"Announce.Rebirth",
				"Board.Rebirths",
				"Board.Earned",
				"Board.Loading",
				"Tutorial.Done",
			}
		do
			T.truthy(rows[key], "clé " .. key)
		end
	end)
end)
```

- [ ] **Step 2 : Vérifier qu'il échoue**

Run : `lune run tests`
Attendu : `55 tests réussis, 2 en échec` (étapes du tutoriel et clés manquantes).

- [ ] **Step 3 : Ajouter ces lignes à la fin de `src/Localization.csv`**

```csv
HUD.Rebirth,Rebirth,,,Rebirth
Toast.Rebirth,Rebirth #{1}! PoopCoins x{2} forever!,,,Rebirth n°{1} ! PoopCoins x{2} pour toujours !
Toast.CantRebirth,You can't rebirth yet!,,,Tu ne peux pas encore faire de rebirth !
Rebirth.NeedDiaper,Cosmic Diaper,,,Couche Cosmique
Rebirth.NeedCoins,{1} PoopCoins in your pocket,,,{1} PoopCoins en poche
Rebirth.Multiplier,PoopCoins x{1} → x{2},,,PoopCoins x{1} → x{2}
Rebirth.Reward,+{1} Binkies,,,+{1} Tétines
Rebirth.Lose,You lose: PoopCoins · buttons · diapers,,,Tu perds : PoopCoins · boutons · couches
Rebirth.Keep,You keep: Binkies · rebirths · stats,,,Tu gardes : Tétines · rebirths · stats
Rebirth.Button,REBIRTH!,,,REBIRTH !
Rebirth.Confirm,SURE? CLICK AGAIN!,,,SÛR ? CLIQUE ENCORE !
Welcome.Title,Welcome back!,,,Bon retour !
Welcome.Body,"While you were away, your baby made {1} PoopCoins!",,,"Pendant ton absence, ton bébé a fait {1} PoopCoins !"
Welcome.Ok,Awesome!,,,Génial !
Announce.Rebirth,{1} just reached {2} rebirths!,,,{1} vient d'atteindre {2} rebirths !
Board.Rebirths,Biggest Babies,,,Plus gros bébés
Board.Earned,Poop Kings,,,Rois du caca
Board.Loading,Loading...,,,Chargement...
Tutorial.bottle,Step on the glowing pad to get a Milk Bottle!,,,Monte sur la dalle lumineuse pour avoir un biberon !
Tutorial.push,Push the baby's diaper 10 times! ({1}/10),,,Appuie 10 fois sur la couche du bébé ! ({1}/10)
Tutorial.poop,Watch the poop roll into the potty!,,,Regarde le caca rouler jusqu'au pot !
Tutorial.carrot,Buy the Carrot Mash on the glowing pad!,,,Achète la purée de carottes sur la dalle lumineuse !
Tutorial.camo,Buy the Camo diaper at the Changing Table!,,,Achète la couche Camouflage à la table à langer !
Tutorial.Done,+{1} Binkies! Now make your baby the biggest in the world!,,,"+{1} Tétines ! Maintenant, fais de ton bébé le plus gros du monde !"
```

- [ ] **Step 4 : Vérifier qu'il passe**

Run : `lune run tests`
Attendu : `57 tests réussis, 0 en échec`.

- [ ] **Step 5 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `57 tests réussis, 0 en échec`, puis `OK`.

- [ ] **Step 6 : Vérifier dans Studio que Rojo lit bien les champs entre guillemets**

`execute_luau` (`datamodel_type = "Edit"`) :

```lua
for _, entry in game.LocalizationService.Translations:GetEntries() do
	if entry.Key == "Welcome.Body" then
		return entry.Source .. " | " .. tostring(entry.Values.fr)
	end
end
return "Welcome.Body absent"
```

Attendu : `While you were away, your baby made {1} PoopCoins! | Pendant ton absence, ton bébé a fait {1} PoopCoins !`.

- [ ] **Step 7 : Commit**

```bash
git add src/Localization.csv tests/Localization.spec.luau
git commit -m "feat: textes de la phase 2 en anglais et en français" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 4 : couronne et panneaux de classement (constructeurs)

**Files :**
- Create : `src/shared/Builders/Crown.luau`, `src/shared/Builders/Board.luau`
- Modify : `src/shared/Builders/Baby.luau` (`Baby.setCrown`)
- Modify : `src/server/World/MapBuilder.luau` (les deux panneaux sur la place)

**Interfaces :**
- Consumes : `Parts` (phase 1).
- Produces :
  - `Crown.build(color): Model` : anneau, 5 pointes et 5 gemmes (11 pièces), rien de touchable ; pivot au centre de sa base ;
  - `Baby.setCrown(model, color?)` : pose la couronne (couleur hexadécimale) sur la tête, à l'échelle actuelle du bébé, ou l'enlève (nil). La couronne est l'enfant `Crown` du modèle du bébé, donc elle suit `ScaleTo` ;
  - `Board.build(name, title, color): Model` : pièces `Screen` (SurfaceGui `Gui` sur la face avant, avec `Title`, la ScrollingFrame `List` et le texte `Status` « Loading... »), `Border` et deux `Leg`. Le panneau regarde vers -Z ;
  - `Board.Row = { name, score }` et `Board.render(model, rows)`, qui remplace les lignes `List.RowN` (`Rank`, `Player`, `Score`) et cache `Status` s'il y a des lignes ;
  - `workspace.Map.BoardRebirths` (« Biggest Babies ») et `workspace.Map.BoardEarned` (« Poop Kings »), de part et d'autre du chemin de la base 1, face au centre de la place.

- [ ] **Step 1 : Créer `src/shared/Builders/Crown.luau`**

```lua
--!strict
-- Couronne des 3 premiers du classement mondial des rebirths (or, argent, bronze), pour la tête du bébé.
-- Pivot au centre de sa base. Rien n'y est touchable.
local Parts = require("./Parts")

local Crown = {}

function Crown.build(color: string): Model
	local model = Parts.model("Crown")
	Parts.cylinder(model, "Ring", 1.2, 4.6, Vector3.new(0, 0.6, 0), color, "Foil")
	for index = 0, 4 do
		local angle = index * 2 * math.pi / 5
		local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * 2
		local spike = Vector3.new(0.7, 1.4, 0.7)
		Parts.block(model, "Spike" .. index, spike, offset + Vector3.new(0, 1.6, 0), color, "Foil")
		Parts.ball(model, "Gem" .. index, 0.6, offset + Vector3.new(0, 2.5, 0), "#E63946", "Neon")
	end
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		end
	end
	return model
end

return Crown
```

- [ ] **Step 2 : Ajouter la couronne au bébé (`src/shared/Builders/Baby.luau`)**

Ajouter le require avant `local Parts = require("./Parts")` :

```lua
local Crown = require("./Crown")
```

Ajouter la constante après `local DARK = "#2B2B2B"` :

```lua
local CROWN_HEIGHT = 9.9 -- à l'échelle 1 : hauteur où la couronne se pose sur la tête
```

Ajouter cette fonction juste avant `return Baby` :

```lua
-- Pose la couronne du top 3 mondial (couleur en hexadécimal) sur la tête du bébé, ou l'enlève (nil).
-- Elle fait partie du modèle : elle suit le bébé quand il grossit.
function Baby.setCrown(model: Model, color: string?)
	local existing = model:FindFirstChild("Crown")
	if existing then
		existing:Destroy()
	end
	if color == nil then
		return
	end
	local scale = model:GetScale()
	local crown = Crown.build(color)
	crown:ScaleTo(scale)
	crown:PivotTo(model:GetPivot() * CFrame.new(0, CROWN_HEIGHT * scale, -0.2 * scale))
	crown.Parent = model
end
```

- [ ] **Step 3 : Créer `src/shared/Builders/Board.luau`**

```lua
--!strict
-- Panneau géant d'un classement mondial : un titre et la liste défilante du top (rang, nom, score).
-- L'écran regarde vers -Z (le SurfaceGui est sur sa face avant) ; pivot au sol, au centre.
local Parts = require("./Parts")

local WIDTH = 28
local HEIGHT = 36
local LEGS = 4 -- hauteur des pieds sous l'écran
local PIXELS_PER_STUD = 25
local ROW_HEIGHT = 60 -- en pixels
local RANK_COLORS = { "#FFD700", "#E8E8E8", "#E8A06A" } -- or, argent, bronze

-- Une ligne du classement, déjà mise en forme.
export type Row = { name: string, score: string }

local Board = {}

local function surface(model: Model): SurfaceGui
	local screen = model:FindFirstChild("Screen") :: Part
	return screen:FindFirstChild("Gui") :: SurfaceGui
end

function Board.build(name: string, title: string, color: string): Model
	local model = Parts.model(name)
	local middle = LEGS + HEIGHT / 2
	for _, x in { -WIDTH / 2 + 2, WIDTH / 2 - 2 } do
		Parts.block(model, "Leg", Vector3.new(1.5, LEGS, 1.5), Vector3.new(x, LEGS / 2, 0), "#FFFFFF")
	end
	local border = Vector3.new(WIDTH + 1.6, HEIGHT + 1.6, 0.8)
	Parts.block(model, "Border", border, Vector3.new(0, middle, 0.6), "#FFFFFF")
	local size = Vector3.new(WIDTH, HEIGHT, 1)
	local screen = Parts.block(model, "Screen", size, Vector3.new(0, middle, 0), color)

	local gui = Instance.new("SurfaceGui")
	gui.Name = "Gui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = PIXELS_PER_STUD
	gui.LightInfluence = 0
	gui.Parent = screen

	local heading = Parts.label(gui, "Title", title, Enum.Font.LuckiestGuy, "#FFFFFF")
	heading.Size = UDim2.new(1, 0, 0, 120)

	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(24, 130)
	list.Size = UDim2.new(1, -48, 1, -150)
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 14
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local status = Parts.label(gui, "Status", "Loading...", Enum.Font.FredokaOne, "#FFFFFF")
	status.Position = UDim2.fromOffset(0, 150)
	status.Size = UDim2.new(1, 0, 0, 70)
	return model
end

-- Remplace les lignes du panneau ; sans ligne, il affiche « Loading... ».
function Board.render(model: Model, rows: { Row })
	local gui = surface(model)
	local list = gui:FindFirstChild("List") :: ScrollingFrame
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for rank, row in rows do
		local line = Instance.new("Frame")
		line.Name = "Row" .. rank
		line.LayoutOrder = rank
		line.BackgroundColor3 = Color3.fromHex("#FFFFFF")
		line.BackgroundTransparency = if rank % 2 == 1 then 0.85 else 1
		line.BorderSizePixel = 0
		line.Size = UDim2.new(1, -18, 0, ROW_HEIGHT)
		local rankColor = RANK_COLORS[rank] or "#FFFFFF"
		local place = Parts.label(line, "Rank", "#" .. rank, Enum.Font.LuckiestGuy, rankColor)
		place.Size = UDim2.fromScale(0.16, 1)
		local who = Parts.label(line, "Player", row.name, Enum.Font.FredokaOne, "#FFFFFF")
		who.Position = UDim2.fromScale(0.17, 0)
		who.Size = UDim2.fromScale(0.53, 1)
		who.TextXAlignment = Enum.TextXAlignment.Left
		local score = Parts.label(line, "Score", row.score, Enum.Font.LuckiestGuy, "#FFE66D")
		score.Position = UDim2.fromScale(0.7, 0)
		score.Size = UDim2.fromScale(0.3, 1)
		score.TextXAlignment = Enum.TextXAlignment.Right
		for _, label in { place, who, score } do
			label.AutoLocalize = false -- des noms et des nombres, rien à traduire
		end
		line.Parent = list
	end
	local status = gui:FindFirstChild("Status") :: TextLabel
	status.Visible = #rows == 0
end

return Board
```

- [ ] **Step 4 : Poser les deux panneaux sur la place (`src/server/World/MapBuilder.luau`)**

Ajouter le require avant `local Parts = require(ReplicatedStorage.Shared.Builders.Parts)` :

```lua
local Board = require(ReplicatedStorage.Shared.Builders.Board)
```

Ajouter ces constantes juste après les requires :

```lua
-- Les deux classements mondiaux, de part et d'autre du chemin de la base 1, face au centre de la place.
local BOARDS = {
	{ name = "BoardRebirths", title = "Biggest Babies", color = "#7FB3F5", angle = 30 },
	{ name = "BoardEarned", title = "Poop Kings", color = "#F5A65B", angle = -30 },
}
local BOARD_DISTANCE = 46 -- distance au centre de la place
```

Dans `MapBuilder.build`, juste après `spawn.Parent = map`, ajouter :

```lua
	for _, info in BOARDS do
		local angle = math.rad(info.angle)
		local position = Vector3.new(math.sin(angle), 0, math.cos(angle)) * BOARD_DISTANCE
		local board = Board.build(info.name, info.title, info.color)
		board:PivotTo(CFrame.lookAt(position, Vector3.zero))
		board.Parent = map
	end
```

- [ ] **Step 5 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `57 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 6 : Aperçu dans Studio (mode édition)**

`execute_luau` (`datamodel_type = "Edit"`) :

```lua
local Builders = game.ReplicatedStorage.Shared.Builders
local Baby = require(Builders.Baby)
local Board = require(Builders.Board)
local preview = Instance.new("Folder")
preview.Name = "Phase2Preview"
preview.Parent = workspace
local baby = Baby.build()
baby.Parent = preview
baby:ScaleTo(1.5)
Baby.setCrown(baby, "#FFD700")
local board = Board.build("BoardPreview", "Biggest Babies", "#7FB3F5")
board:PivotTo(CFrame.new(40, 0, 0))
board.Parent = preview
Board.render(board, {
	{ name = "brixx_lebosss", score = "12" },
	{ name = "BabyKing", score = "9" },
	{ name = "PoopMaster", score = "7" },
	{ name = "Nathan", score = "3" },
})
return #baby.Crown:GetChildren() .. " | " .. #board.Screen.Gui.List:GetChildren()
```

Attendu : `11 | 5` (11 pièces de couronne ; 4 lignes + le UIListLayout). Puis `screen_capture` avec la caméra en `(20, 18, -60)` qui regarde `(20, 14, 0)` : le bébé porte une couronne dorée sur la tête ; le panneau bleu affiche « Biggest Babies » et 4 lignes (#1 en or, #2 en argent, #3 en bronze), sans « Loading... ».

Nettoyer ensuite avec `execute_luau` (Edit) : `workspace.Phase2Preview:Destroy()`.

- [ ] **Step 7 : Vérifier les panneaux sur la place**

1. `start_stop_play` (démarrer), attendre 6 s.
2. `execute_luau` (Server) : `return tostring(workspace.Map:FindFirstChild("BoardRebirths") ~= nil) .. " | " .. tostring(workspace.Map:FindFirstChild("BoardEarned") ~= nil)`. Attendu : `true | true`.
3. `screen_capture` avec la caméra en `(0, 24, -40)` qui regarde `(0, 20, 40)` : les deux grands panneaux « Biggest Babies » (bleu) et « Poop Kings » (orange), face au centre, avec « Loading... ».
4. `start_stop_play` (arrêter).

- [ ] **Step 8 : Commit**

```bash
git add src/shared/Builders src/server/World/MapBuilder.luau
git commit -m "feat: couronne du top 3 et panneaux des classements sur la place" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 5 : rebirth, leaderstats et annonces (serveur)

**Files :**
- Modify : `src/shared/Net.luau` (remplacé en entier : remotes `Rebirth`, `WelcomeBack`, `Announce` ; champs `totalClicks`, `rebirths`, `tutorial` du Snapshot)
- Modify : `src/server/Services/StateService.luau` (`StateService.snapshot`)
- Modify : `src/server/Services/ProductionService.luau` (`ProductionService.clear`)
- Create : `src/server/Services/AnnounceService.luau`, `src/server/Services/LeaderstatsService.luau`, `src/server/Services/RebirthService.luau`
- Modify : `src/server/Services/DebugService.luau` (remplacé en entier : `setRebirths`, `info` plus complet)
- Modify : `src/server/init.server.luau` (liste des services)

**Interfaces :**
- Consumes : `Rebirth` (tâche 1) ; `DataService`, `PlotService`, `StateService`, `ProductionService`, `IncomeService`, `Net` (phase 1).
- Produces :
  - remotes `Rebirth` (client → serveur), `WelcomeBack` (serveur → client : gain, secondes d'absence ; utilisé à la tâche 6), `Announce` (serveur → tous : clé, arguments) ;
  - `Net.Snapshot` gagne `totalClicks`, `rebirths` et `tutorial` ;
  - `ProductionService.clear(player)` : détruit les cacas du joueur en route, sans les créditer ;
  - `AnnounceService.broadcast(key, args)` ;
  - `leaderstats` de chaque joueur chargé : `PoopCoins` (StringValue, texte formaté) et `Rebirths` (IntValue), mis à jour chaque seconde ;
  - `RebirthService.rebirth(player)`, branché sur le remote `Rebirth` (1 par seconde au plus), et le signal `RebirthService.done (player, rebirths)`. Toasts `Toast.Rebirth` ({ rebirths, multiplicateur }) ou `Toast.CantRebirth` ; annonce `Announce.Rebirth` ({ nom affiché, rebirths }) aux 10e, 25e et 50e ;
  - commande Debug `setRebirths(count)` ; `info()` renvoie `"<nom> : <PoopCoins> PoopCoins, <n> boutons, couche <n>, <n> rebirths, <Tétines> Tétines, <n> cacas, <n> clics, <revenu>/s, tuto <n>"`.

- [ ] **Step 1 : Remplacer `src/shared/Net.luau`**

```lua
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
```

- [ ] **Step 2 : Compléter l'état envoyé (`src/server/Services/StateService.luau`)**

Remplacer la fonction `StateService.snapshot` par :

```lua
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
```

- [ ] **Step 3 : Ajouter `ProductionService.clear` (`src/server/Services/ProductionService.luau`)**

Ajouter cette fonction juste après `ProductionService.spawn` :

```lua
-- Détruit les cacas du joueur encore en route, sans les créditer (ex. au rebirth).
function ProductionService.clear(player: Player)
	for root, poop in live do
		if poop.owner == player then
			live[root] = nil
			poop.model:Destroy()
		end
	end
end
```

- [ ] **Step 4 : Créer `src/server/Services/AnnounceService.luau`**

```lua
--!strict
-- Annonces à tout le serveur (spec, section 4) : chaque client les montre en bannière et dans le chat.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local AnnounceService = {}

-- `key` : clé de Localization.csv ; `args` : ses arguments, déjà mis en forme.
function AnnounceService.broadcast(key: string, args: { any })
	Net.event("Announce"):FireAllClients(key, args)
end

return AnnounceService
```

- [ ] **Step 5 : Créer `src/server/Services/LeaderstatsService.luau`**

```lua
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
```

- [ ] **Step 6 : Créer `src/server/Services/RebirthService.luau`**

```lua
--!strict
-- Rebirth (spec, section 4) : le joueur repart de zéro contre +50 % de PoopCoins pour toujours et des Tétines.
-- Les 10e, 25e et 50e rebirths sont annoncés à tout le serveur.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnnounceService = require(script.Parent.AnnounceService)
local DataService = require(script.Parent.DataService)
local Net = require(ReplicatedStorage.Shared.Net)
local PlotService = require(script.Parent.PlotService)
local ProductionService = require(script.Parent.ProductionService)
local RateLimit = require(ReplicatedStorage.Shared.Logic.RateLimit)
local Rebirth = require(ReplicatedStorage.Shared.Logic.Rebirth)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local StateService = require(script.Parent.StateService)

local RebirthService = {
	done = Signal.new(), -- (player, rebirths) : le joueur vient de faire un rebirth
}

local limiter = RateLimit.new(1, 1)

function RebirthService.rebirth(player: Player)
	if not RateLimit.allow(limiter, player, os.clock()) then
		return
	end
	local data = DataService.get(player)
	if data == nil then
		return
	end
	local result = Rebirth.apply(data)
	local toast = Net.event("Toast")
	if result.reason ~= "done" then
		toast:FireClient(player, "Toast.CantRebirth", {})
		return
	end
	ProductionService.clear(player) -- les cacas en route datent d'avant le rebirth
	PlotService.refresh(player)
	StateService.markDirty(player)
	toast:FireClient(player, "Toast.Rebirth", { result.rebirths, Rebirth.multiplier(result.rebirths) })
	if Rebirth.isMilestone(result.rebirths) then
		AnnounceService.broadcast("Announce.Rebirth", { player.DisplayName, result.rebirths })
	end
	RebirthService.done:fire(player, result.rebirths)
end

function RebirthService.start()
	Net.event("Rebirth").OnServerEvent:Connect(RebirthService.rebirth)
	Players.PlayerRemoving:Connect(function(player)
		RateLimit.forget(limiter, player)
	end)
end

return RebirthService
```

- [ ] **Step 7 : Remplacer `src/server/Services/DebugService.luau`**

```lua
--!strict
-- Commandes de test, en Studio uniquement. Elles passent par une BindableFunction parce que la barre de
-- commande et le MCP de Studio (execute_luau, contexte Server) ne voient pas l'état des modules du jeu :
--   game.ServerStorage.DebugCommands:Invoke("give", 1e9)
--   game.ServerStorage.DebugCommands:Invoke("setButtons", 22)
--   game.ServerStorage.DebugCommands:Invoke("setDiaper", 10)
--   game.ServerStorage.DebugCommands:Invoke("setRebirths", 9)
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
	setRebirths = function(count: number)
		local player, data = target()
		data.rebirths = count
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
			"%s : %s PoopCoins, %d boutons, couche %d, %d rebirths, %s Tétines, %d cacas, %d clics, %s/s, tuto %d",
			player.Name,
			Format.number(data.coins),
			data.buttons,
			data.diaper,
			data.rebirths,
			Format.number(data.binkies),
			data.totalPoops,
			data.totalClicks,
			Format.number(IncomeService.income(player)),
			data.tutorial
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

- [ ] **Step 8 : Ajouter les services à `src/server/init.server.luau`**

Remplacer la table `services` par :

```lua
local services: { any } = {
	require(Services.DataService),
	require(Services.PlotService),
	require(Services.IncomeService),
	require(Services.StateService),
	require(Services.ProductionService),
	require(Services.ClickService),
	require(Services.ShopService),
	require(Services.LeaderstatsService),
	require(Services.RebirthService),
	require(Services.DebugService),
}
```

`AnnounceService` n'a ni `init` ni `start` : `RebirthService` le charge.

- [ ] **Step 9 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `57 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 10 : Vérifier dans Studio**

1. `start_stop_play` (démarrer), attendre 6 s.
2. `execute_luau` (Server) :

```lua
local Debug = game.ServerStorage.DebugCommands
Debug:Invoke("reset")
Debug:Invoke("setButtons", 22)
Debug:Invoke("setDiaper", 10)
Debug:Invoke("give", 3e10)
return Debug:Invoke("info")
```

   Attendu : `… : 30B PoopCoins, 22 boutons, couche 10, 0 rebirths, 0 Tétines, …`.
3. `execute_luau` (Client) :

```lua
local heard
local connection = game.ReplicatedStorage.Remotes.Toast.OnClientEvent:Connect(function(key, args)
	heard = key .. " " .. table.concat(args, ",")
end)
game.ReplicatedStorage.Remotes.Rebirth:FireServer()
task.wait(1.2)
connection:Disconnect()
return tostring(heard)
```

   Attendu : `Toast.Rebirth 1,1.5`.
4. `execute_luau` (Server) :

```lua
task.wait(1)
local player = game.Players:GetPlayers()[1]
local nursery = workspace.Plots[player:GetAttribute("Plot")].Nursery
local stats = player.leaderstats
return game.ServerStorage.DebugCommands:Invoke("info") .. " | objets : " .. #nursery.Items:GetChildren()
	.. " | leaderstats : " .. stats.PoopCoins.Value .. " / " .. stats.Rebirths.Value
```

   Attendu : `… : 0 PoopCoins, 0 boutons, couche 1, 1 rebirths, 25 Tétines, … 0/s, tuto 0 | objets : 0 | leaderstats : 0 / 1`.
5. Le 10e rebirth est annoncé. `execute_luau` (Server) :

```lua
local Debug = game.ServerStorage.DebugCommands
Debug:Invoke("setRebirths", 9)
Debug:Invoke("setButtons", 22)
Debug:Invoke("setDiaper", 10)
Debug:Invoke("give", 3e12)
return Debug:Invoke("info")
```

   puis `execute_luau` (Client) :

```lua
local heard
local connection = game.ReplicatedStorage.Remotes.Announce.OnClientEvent:Connect(function(key, args)
	heard = key .. " " .. table.concat(args, ",")
end)
game.ReplicatedStorage.Remotes.Rebirth:FireServer()
task.wait(1.2)
connection:Disconnect()
return tostring(heard)
```

   Attendu : `Announce.Rebirth <nom affiché du joueur>,10`, et `info` (Server) indique `10 rebirths, 275 Tétines`.
6. Rebirth refusé : refaire l'étape 3 (le joueur n'a plus de boutons). Attendu : `Toast.CantRebirth ` (sans argument).
7. `get_console_output` : aucune erreur. Puis `start_stop_play` (arrêter).

- [ ] **Step 11 : Commit**

```bash
git add src/shared/Net.luau src/server
git commit -m "feat: rebirth, leaderstats et annonces aux 10e, 25e et 50e rebirths" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 6 : gains hors ligne (serveur)

**Files :**
- Create : `src/server/Services/OfflineService.luau`
- Modify : `src/server/Services/DebugService.luau` (commande `welcome`)
- Modify : `src/server/init.server.luau` (liste des services)

**Interfaces :**
- Consumes : `Offline.gain` (tâche 1), remote `WelcomeBack` (tâche 5) ; `DataService`, `IncomeService`, `StateService`, `Clock` (phase 1) ; `Wallet`.
- Produces :
  - `OfflineService.collect(player, data): number` : crédite 25 % du revenu de base × l'absence depuis `data.lastSeen` (8 h au plus), met `lastSeen` à maintenant et `pendingOffline` au gain, et envoie `WelcomeBack` (gain, secondes d'absence) si le gain est positif. Appelé à chaque chargement de profil ;
  - pendant la partie, `lastSeen` est rafraîchi toutes les 60 s (un serveur qui s'arrête net ne compte pas le jeu comme une absence) ;
  - commande Debug `welcome(seconds)` : rejoue l'arrivée comme après `seconds` secondes d'absence et renvoie le gain formaté.

- [ ] **Step 1 : Créer `src/server/Services/OfflineService.luau`**

```lua
--!strict
-- Gains hors ligne (spec, section 4) : au retour du joueur, 25 % de son revenu de base pendant l'absence
-- (8 h au plus), crédités tout de suite et montrés par l'écran « Welcome back ».
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Clock = require(script.Parent.Parent.Clock)
local Data = require(ReplicatedStorage.Shared.Logic.Data)
local DataService = require(script.Parent.DataService)
local IncomeService = require(script.Parent.IncomeService)
local Net = require(ReplicatedStorage.Shared.Net)
local Offline = require(ReplicatedStorage.Shared.Logic.Offline)
local StateService = require(script.Parent.StateService)
local Wallet = require(ReplicatedStorage.Shared.Logic.Wallet)

-- lastSeen est rafraîchi pendant la partie : si le serveur s'arrête net, le temps de jeu ne compte pas
-- comme une absence.
local SEEN_EVERY = 60

local OfflineService = {}

-- Crédite les gains de l'absence depuis data.lastSeen et prévient le joueur. Renvoie le gain.
function OfflineService.collect(player: Player, data: Data.Profile): number
	local now = Clock.now()
	local away = if data.lastSeen > 0 then now - data.lastSeen else 0
	local gain = Offline.gain(IncomeService.baseIncome(player), away)
	data.lastSeen = now
	data.pendingOffline = gain -- le gain reste « en attente » pour « Triple it » (phase 3)
	if gain > 0 then
		Wallet.earn(data, gain)
		StateService.markDirty(player)
		Net.event("WelcomeBack"):FireClient(player, gain, away)
	end
	return gain
end

function OfflineService.start()
	DataService.loaded:connect(OfflineService.collect)
	task.spawn(function()
		while true do
			task.wait(SEEN_EVERY)
			local now = Clock.now()
			for _, player in Players:GetPlayers() do
				local data = DataService.get(player)
				if data then
					data.lastSeen = now
				end
			end
		end
	end)
end

return OfflineService
```

- [ ] **Step 2 : Ajouter la commande `welcome` (`src/server/Services/DebugService.luau`)**

Dans le commentaire d'en-tête, ajouter cette ligne après celle de `setRebirths` :

```lua
--   print(game.ServerStorage.DebugCommands:Invoke("welcome", 3600)) -- gains d'une heure d'absence
```

Ajouter ces requires, rangés par ordre alphabétique : `local Clock = require(script.Parent.Parent.Clock)` juste avant `local Data = …`, et `local OfflineService = require(script.Parent.OfflineService)` juste avant `local PlotService = …`.

Ajouter cette commande dans la table `commands`, après `setRebirths` :

```lua
	-- Rejoue l'arrivée du joueur comme s'il était parti `seconds` secondes ; renvoie le gain.
	welcome = function(seconds: number): string
		local player, data = target()
		data.lastSeen = Clock.now() - seconds
		return Format.number(OfflineService.collect(player, data))
	end,
```

- [ ] **Step 3 : Ajouter le service à `src/server/init.server.luau`**

Dans la table `services`, ajouter `require(Services.OfflineService),` juste après `require(Services.RebirthService),`.

- [ ] **Step 4 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `57 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 5 : Vérifier dans Studio**

1. `start_stop_play` (démarrer), attendre 6 s.
2. `execute_luau` (Server) :

```lua
local Debug = game.ServerStorage.DebugCommands
Debug:Invoke("reset")
Debug:Invoke("setButtons", 2)
return Debug:Invoke("welcome", 3600) .. " | " .. Debug:Invoke("welcome", 30) .. " | " .. Debug:Invoke("welcome", 86400)
```

   Attendu : `3.6K | 0 | 28.8K` (revenu de base 4/s : 25 % × 4 × 3 600 ; moins d'une minute : rien ; un jour, plafonné à 8 h : 25 % × 4 × 28 800).
3. `execute_luau` (Server) : `return game.ServerStorage.DebugCommands:Invoke("info")`. Attendu : `32.4K PoopCoins` (à quelques cacas près).
4. `get_console_output` : aucune erreur. Puis `start_stop_play` (arrêter).

- [ ] **Step 6 : Commit**

```bash
git add src/server
git commit -m "feat: gains hors ligne crédités au retour du joueur" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 7 : classements mondiaux et couronnes (serveur)

**Files :**
- Create : `src/server/Services/LeaderboardService.luau`
- Modify : `src/server/Services/DebugService.luau` (commande `boards`)
- Modify : `src/server/init.server.luau` (liste des services)

**Interfaces :**
- Consumes : `Config/Leaderboards`, `Leaderboard.encodeEarned`/`decodeEarned` (tâche 1) ; `Board.render`, `Board.Row`, `Baby.setCrown`, panneaux `workspace.Map.BoardRebirths` et `BoardEarned` (tâche 4) ; `RebirthService.done` (tâche 5) ; `DataService.released`, `PlotService.owners`, `PlotService.built` (phase 1).
- Produces :
  - OrderedDataStores `Rebirths_v1` et `TotalEarned_v1` (suffixe `_Studio` en Studio), clé = UserId en texte. Un score nul n'est pas écrit ;
  - `LeaderboardService.save(player)` (bloquant) : écrit les scores d'un joueur. Appelé à chaque rebirth, toutes les 5 min pour les joueurs présents, et à son départ (scores lus avant que le profil disparaisse) ;
  - `LeaderboardService.refresh(): number` (bloquant) : relit le top 50 des deux classements, remplit les panneaux, pose les couronnes du top 3 des rebirths (et enlève les autres) sur les bébés des joueurs présents ; renvoie le nombre de panneaux relus. Appelé au démarrage puis toutes les 2 min ;
  - une base construite reçoit tout de suite la couronne de son joueur s'il est dans le top 3 ;
  - commande Debug `boards()` : écrit les scores du joueur, relit les classements et renvoie `"<n> panneaux relus"`.

- [ ] **Step 1 : Créer `src/server/Services/LeaderboardService.luau`**

```lua
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
```

- [ ] **Step 2 : Ajouter la commande `boards` (`src/server/Services/DebugService.luau`)**

Dans le commentaire d'en-tête, ajouter cette ligne après celle de `welcome` :

```lua
--   print(game.ServerStorage.DebugCommands:Invoke("boards")) -- écrit les scores et relit les classements
```

Ajouter le require `local LeaderboardService = require(script.Parent.LeaderboardService)` juste avant `local OfflineService = …`.

Ajouter cette commande dans la table `commands`, après `welcome` :

```lua
	-- Écrit les scores du joueur puis relit les classements, sans attendre les 2 min.
	boards = function(): string
		local player = target()
		LeaderboardService.save(player)
		return LeaderboardService.refresh() .. " panneaux relus"
	end,
```

- [ ] **Step 3 : Ajouter le service à `src/server/init.server.luau`**

Dans la table `services`, ajouter `require(Services.LeaderboardService),` juste après `require(Services.OfflineService),`.

- [ ] **Step 4 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `57 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 5 : Vérifier dans Studio (accès aux API nécessaire)**

1. `start_stop_play` (démarrer), attendre 8 s, puis `get_console_output`. Si la sortie affiche `Roblox API services unavailable`, s'arrêter là : demander à Nathan d'activer l'accès (Game Settings > Security > « Enable Studio Access to API Services »), puis reprendre cette étape. Attendu : `Roblox API services available`.
2. `execute_luau` (Server) :

```lua
local Debug = game.ServerStorage.DebugCommands
Debug:Invoke("reset")
Debug:Invoke("setButtons", 2)
Debug:Invoke("setRebirths", 3)
task.wait(6) -- quelques cacas arrivent : le total gagné n'est plus nul
return Debug:Invoke("boards")
```

   Attendu : `2 panneaux relus`.
3. `execute_luau` (Server) :

```lua
local rebirths = workspace.Map.BoardRebirths.Screen.Gui.List
local earned = workspace.Map.BoardEarned.Screen.Gui.List
local player = game.Players:GetPlayers()[1]
local baby = workspace.Plots[player:GetAttribute("Plot")].Nursery.Baby
return rebirths.Row1.Player.Text .. " | " .. rebirths.Row1.Score.Text .. " | " .. earned.Row1.Player.Text
	.. " | couronne : " .. tostring(baby:FindFirstChild("Crown") ~= nil)
```

   Attendu : `<nom du joueur> | 3 | <nom du joueur> | couronne : true` (seul joueur des classements `_Studio`, il est premier partout).
4. `screen_capture` avec la caméra en `(0, 24, -40)` qui regarde `(0, 20, 40)` : les panneaux affichent le joueur en #1. Puis `screen_capture` du bébé (base 1 : caméra en `(0, 14, 160)` qui regarde `(0, 10, 182)`) : une couronne dorée sur sa tête.
5. `start_stop_play` (arrêter).

- [ ] **Step 6 : Commit**

```bash
git add src/server
git commit -m "feat: classements mondiaux sur la place et couronnes du top 3" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 8 : tutoriel (serveur)

**Files :**
- Create : `src/server/Services/TutorialService.luau`
- Modify : `src/server/Services/ProductionService.luau` (signal `credited`)
- Modify : `src/server/Services/DebugService.luau` (commande `setTutorial`)
- Modify : `src/server/init.server.luau` (liste des services : version finale de la phase)

**Interfaces :**
- Consumes : `Tutorial` (tâche 2) ; `DataService`, `StateService`, `ProductionService`, `Net` (phase 1).
- Produces :
  - `ProductionService.credited (player, value)` : un caca du joueur vient d'être crédité (au pot, ou au bout de 20 s) ;
  - `TutorialService.check(player, poopArrived)` : valide les étapes faites ; chaque étape validée part dans l'entonnoir d'onboarding (`AnalyticsService:LogOnboardingFunnelStepEvent`, étapes numérotées à partir de 1) ; à la fin, toast `Tutorial.Done` ({ 25 }). Appelé toutes les 0,5 s et à chaque caca crédité ;
  - au chargement d'un profil, `Tutorial.start` : un profil neuf commence à l'étape 1, un profil déjà avancé passe à 99 ;
  - commande Debug `setTutorial(step)`.

- [ ] **Step 1 : Ajouter le signal `credited` (`src/server/Services/ProductionService.luau`)**

Ajouter le require juste après `local Poops = require(ReplicatedStorage.Shared.Logic.Poops)` :

```lua
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
```

Remplacer `local ProductionService = {}` par :

```lua
local ProductionService = {
	credited = Signal.new(), -- (player, value) : un caca du joueur vient d'être crédité
}
```

Dans la fonction `credit`, juste après `effect:FireClient(poop.owner, "credit", poop.value)`, ajouter :

```lua
		ProductionService.credited:fire(poop.owner, poop.value)
```

- [ ] **Step 2 : Créer `src/server/Services/TutorialService.luau`**

```lua
--!strict
-- Tutoriel des nouveaux joueurs (spec, section 4). Les étapes se valident côté serveur, d'après le profil et
-- les cacas qui arrivent au pot ; le client affiche la bulle et la flèche d'après l'état (Snapshot.tutorial).
-- Chaque étape validée part dans l'entonnoir d'onboarding des analytics Roblox.
local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage.Shared.Logic.Data)
local DataService = require(script.Parent.DataService)
local Net = require(ReplicatedStorage.Shared.Net)
local ProductionService = require(script.Parent.ProductionService)
local StateService = require(script.Parent.StateService)
local Tutorial = require(ReplicatedStorage.Shared.Logic.Tutorial)

local CHECK_EVERY = 0.5 -- secondes

local TutorialService = {}

-- Valide les étapes faites. `poopArrived` : un caca du joueur vient d'arriver au pot.
function TutorialService.check(player: Player, poopArrived: boolean)
	local data = DataService.get(player)
	if data == nil then
		return
	end
	local first = data.tutorial
	local completed, reward = Tutorial.advance(data, poopArrived)
	if #completed == 0 then
		return
	end
	for offset, step in completed do
		pcall(function()
			AnalyticsService:LogOnboardingFunnelStepEvent(player, first + offset - 1, step.id)
		end)
	end
	if reward > 0 then
		Net.event("Toast"):FireClient(player, "Tutorial.Done", { reward })
	end
	StateService.markDirty(player)
end

function TutorialService.start()
	DataService.loaded:connect(function(player: Player, data: Data.Profile)
		Tutorial.start(data)
		StateService.markDirty(player)
	end)
	ProductionService.credited:connect(function(player: Player)
		TutorialService.check(player, true)
	end)
	task.spawn(function()
		while true do
			task.wait(CHECK_EVERY)
			for _, player in Players:GetPlayers() do
				TutorialService.check(player, false)
			end
		end
	end)
end

return TutorialService
```

- [ ] **Step 3 : Ajouter la commande `setTutorial` (`src/server/Services/DebugService.luau`)**

Dans le commentaire d'en-tête, ajouter cette ligne après celle de `boards` :

```lua
--   game.ServerStorage.DebugCommands:Invoke("setTutorial", 1) -- relance le tutoriel (99 = terminé)
```

Ajouter cette commande dans la table `commands`, après `boards` :

```lua
	-- Met le tutoriel à l'étape `step` (1 = début, 99 = terminé).
	setTutorial = function(step: number)
		local player, data = target()
		data.tutorial = step
		changed(player)
	end,
```

- [ ] **Step 4 : Ajouter le service à `src/server/init.server.luau`**

La table `services` devient (version finale de la phase) :

```lua
local services: { any } = {
	require(Services.DataService),
	require(Services.PlotService),
	require(Services.IncomeService),
	require(Services.StateService),
	require(Services.ProductionService),
	require(Services.ClickService),
	require(Services.ShopService),
	require(Services.LeaderstatsService),
	require(Services.RebirthService),
	require(Services.OfflineService),
	require(Services.LeaderboardService),
	require(Services.TutorialService),
	require(Services.DebugService),
}
```

- [ ] **Step 5 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `57 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 6 : Vérifier dans Studio**

Ci-dessous, `PlotN` est la base du joueur (`game.Players:GetPlayers()[1]:GetAttribute("Plot")`) et `info` = `execute_luau` (Server) `return game.ServerStorage.DebugCommands:Invoke("info")`.

1. `start_stop_play` (démarrer), attendre 6 s. `execute_luau` (Server) :

```lua
local Debug = game.ServerStorage.DebugCommands
Debug:Invoke("reset")
Debug:Invoke("setTutorial", 1)
return Debug:Invoke("info") .. " | " .. game.Players:GetPlayers()[1]:GetAttribute("Plot")
```

   Attendu : `… 0 boutons, … tuto 1 | PlotN`.
2. `character_navigation` vers `game.Workspace.Plots.PlotN.Nursery.PadActive.Disk`, attendre 2 s, puis `info`. Attendu : `1 boutons`, `tuto 2`.
3. `character_navigation` vers `game.Workspace.Plots.PlotN.Nursery.Baby` (quitter la dalle), puis `execute_luau` (Client) : `for _ = 1, 10 do game.ReplicatedStorage.Remotes.Click:FireServer() task.wait(0.15) end`. Attendre 6 s (un caca arrive au pot), puis `info`. Attendu : `10 clics`, `tuto 4`.
4. `execute_luau` (Server) `game.ServerStorage.DebugCommands:Invoke("give", 50)`, puis `character_navigation` vers `…PlotN.Nursery.PadActive.Disk`, attendre 2 s, puis `info`. Attendu : `2 boutons`, `tuto 5`.
5. `character_navigation` vers `…PlotN.Nursery.ChangingTable`, puis `execute_luau` (Server) `game.ServerStorage.DebugCommands:Invoke("give", 400)`, puis `execute_luau` (Client) :

```lua
local heard
local connection = game.ReplicatedStorage.Remotes.Toast.OnClientEvent:Connect(function(key, args)
	heard = key .. " " .. table.concat(args, ",")
end)
game.ReplicatedStorage.Remotes.BuyDiaper:FireServer()
task.wait(1.5)
connection:Disconnect()
return tostring(heard)
```

   Attendu : `Tutorial.Done 25`, puis `info` : `couche 2, 0 rebirths, 25 Tétines`, `tuto 99`.
6. `get_console_output` : aucune erreur. Puis `start_stop_play` (arrêter).

- [ ] **Step 7 : Commit**

```bash
git add src/server
git commit -m "feat: tutoriel validé côté serveur, entonnoir d'onboarding et récompense" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 9 : panneau Rebirth, écran de retour et bannière (client)

**Files :**
- Create : `src/client/UI/RebirthPanel.luau`, `src/client/UI/WelcomePanel.luau`, `src/client/UI/Banner.luau`
- Modify : `src/client/UI/Theme.luau` (couleur `rebirth`), `src/client/UI/Toasts.luau` (toasts sous la bannière), `src/client/UI/Hud.luau` (bouton Rebirth)
- Modify : `src/client/init.client.luau` (remplacé en entier)

**Interfaces :**
- Consumes : remotes `Rebirth` (envoyé), `WelcomeBack` et `Announce` (reçus) ; `Snapshot.rebirths`, `diaper`, `coins` ; `Rebirth.cost`, `multiplier`, `reward`, `blocker` (tâche 1) ; clés de la tâche 3.
- Produces :
  - bouton HUD `Hud.Rebirth` (au-dessus de `Hud.MyBase`), qui ouvre `RebirthPanel` ;
  - `RebirthPanel.open()`, `RebirthPanel.close()` ; le panneau `RebirthPanel.Panel` contient les lignes `Diaper`, `Coins`, `Multiplier`, `Reward`, `Lose`, `Keep` et le bouton `Go` (premier clic : « SURE? CLICK AGAIN! » pendant 3 s ; deuxième clic : remote `Rebirth`) ;
  - `WelcomePanel.Panel` (`Title`, `Body`, bouton `Ok`), ouvert par `WelcomeBack` ;
  - `Banner.Banner` : bannière en haut pendant 5 s + message système dans le chat, pour chaque `Announce` ;
  - les toasts descendent à 220 px du haut, sous la bannière.

- [ ] **Step 1 : Ajouter la couleur du rebirth à `src/client/UI/Theme.luau`**

Dans `colors`, ajouter après `accent = Color3.fromHex("#FF8FAB"),` :

```lua
		rebirth = Color3.fromHex("#9B5DE5"),
```

- [ ] **Step 2 : Descendre les toasts sous la bannière (`src/client/UI/Toasts.luau`)**

Dans `Toasts.start`, remplacer `Position = UDim2.new(0.5, 0, 0, 150),` par :

```lua
		Position = UDim2.new(0.5, 0, 0, 220), -- sous la bannière des annonces
```

- [ ] **Step 3 : Créer `src/client/UI/RebirthPanel.luau`**

```lua
--!strict
-- Panneau Rebirth (spec, section 4) : les conditions, le multiplicateur actuel → le suivant, la récompense, ce
-- qui est perdu ou gardé. Le bouton se clique deux fois : le premier clic demande confirmation.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Diapers = require(ReplicatedStorage.Shared.Config.Diapers)
local Format = require(ReplicatedStorage.Shared.Logic.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local New = require(script.Parent.New)
local Rebirth = require(ReplicatedStorage.Shared.Logic.Rebirth)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.Parent.State)
local Text = require(script.Parent.Parent.Text)
local Theme = require(script.Parent.Theme)

local CONFIRM_SECONDS = 3

local RebirthPanel = {}

local panel: Frame? = nil
local button: TextButton? = nil
local lines: { [string]: TextLabel } = {}
local confirmUntil = 0

local function mark(ok: boolean): string
	return if ok then "✅ " else "❌ "
end

local function render()
	local snapshot = State.current
	local action = button
	if snapshot == nil or action == nil then
		return
	end
	local rebirths = snapshot.rebirths
	local cost = Rebirth.cost(rebirths)
	lines.Diaper.Text = mark(snapshot.diaper >= #Diapers) .. Text.get("Rebirth.NeedDiaper")
	lines.Coins.Text = mark(snapshot.coins >= cost) .. Text.get("Rebirth.NeedCoins", { Format.number(cost) })
	local now = tostring(Rebirth.multiplier(rebirths))
	local after = tostring(Rebirth.multiplier(rebirths + 1))
	lines.Multiplier.Text = Text.get("Rebirth.Multiplier", { now, after })
	lines.Reward.Text = Text.get("Rebirth.Reward", { Rebirth.reward(rebirths + 1) })
	local ready = Rebirth.blocker(snapshot.diaper, snapshot.coins, rebirths) == nil
	action.BackgroundColor3 = if ready then Theme.colors.good else Theme.colors.muted
	action.Text = Text.get(if os.clock() < confirmUntil then "Rebirth.Confirm" else "Rebirth.Button")
end

-- Premier clic : demande confirmation ; deuxième clic dans les 3 s : envoie le rebirth.
local function press()
	local snapshot = State.current
	if snapshot == nil or Rebirth.blocker(snapshot.diaper, snapshot.coins, snapshot.rebirths) ~= nil then
		return
	end
	if os.clock() < confirmUntil then
		confirmUntil = 0
		Net.event("Rebirth"):FireServer()
		RebirthPanel.close()
		return
	end
	confirmUntil = os.clock() + CONFIRM_SECONDS
	render()
	task.delay(CONFIRM_SECONDS, render)
end

-- Ligne de texte du panneau, remplie par render().
local function line(
	parent: Instance,
	name: string,
	y: number,
	height: number,
	font: Enum.Font,
	color: Color3
)
	lines[name] = New("TextLabel", {
		Name = name,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(30, y),
		Size = UDim2.new(1, -60, 0, height),
		Font = font,
		Text = "",
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = color,
		AutoLocalize = false,
		Parent = parent,
	})
end

function RebirthPanel.open()
	if panel then
		confirmUntil = 0
		panel.Visible = true
		render()
	end
end

function RebirthPanel.close()
	if panel then
		panel.Visible = false
	end
end

function RebirthPanel.start()
	local gui = Screen.create("RebirthPanel", 15)
	local frame = New("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(600, 560),
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
			Text = "Rebirth",
			TextSize = 44,
			TextColor3 = Theme.colors.rebirth,
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
	close.Activated:Connect(RebirthPanel.close)

	line(frame, "Diaper", 86, 40, Theme.fonts.body, Theme.colors.text)
	line(frame, "Coins", 132, 40, Theme.fonts.body, Theme.colors.text)
	line(frame, "Multiplier", 196, 52, Theme.fonts.title, Theme.colors.rebirth)
	line(frame, "Reward", 254, 40, Theme.fonts.title, Theme.colors.accent)
	line(frame, "Lose", 322, 34, Theme.fonts.body, Theme.colors.text)
	line(frame, "Keep", 362, 34, Theme.fonts.body, Theme.colors.text)
	lines.Lose.Text = Text.get("Rebirth.Lose")
	lines.Keep.Text = Text.get("Rebirth.Keep")

	local action = New("TextButton", {
		Name = "Go",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -28),
		Size = UDim2.fromOffset(360, 84),
		BackgroundColor3 = Theme.colors.muted,
		Font = Theme.fonts.title,
		Text = "",
		TextSize = 34,
		TextColor3 = Theme.colors.white,
		AutoLocalize = false,
		Parent = frame,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 18) }),
		New(
			"UIStroke",
			{ Thickness = 4, Color = Theme.colors.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
		),
	})
	action.Activated:Connect(press)
	button = action
	State.changed:connect(function()
		if frame.Visible then
			render()
		end
	end)
end

return RebirthPanel
```

- [ ] **Step 4 : Créer `src/client/UI/WelcomePanel.luau`**

```lua
--!strict
-- Écran de retour (spec, section 4) : « While you were away, your baby made 1.2M PoopCoins! ».
-- Le serveur a déjà crédité les PoopCoins ; l'écran l'annonce. (« Triple it » arrive en phase 3.)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Logic.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local New = require(script.Parent.New)
local Screen = require(script.Parent.Screen)
local Text = require(script.Parent.Parent.Text)
local Theme = require(script.Parent.Theme)

local WelcomePanel = {}

function WelcomePanel.start()
	local gui = Screen.create("WelcomePanel", 16)
	local frame = New("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(560, 320),
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
			Position = UDim2.fromOffset(0, 16),
			Size = UDim2.new(1, 0, 0, 54),
			Font = Theme.fonts.title,
			Text = "Welcome back!",
			TextSize = 44,
			TextColor3 = Theme.colors.accent,
		}),
	})
	local body = New("TextLabel", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(30, 84),
		Size = UDim2.new(1, -60, 0, 120),
		Font = Theme.fonts.body,
		Text = "",
		TextSize = 30,
		TextWrapped = true,
		TextColor3 = Theme.colors.text,
		AutoLocalize = false,
		Parent = frame,
	})
	local ok = New("TextButton", {
		Name = "Ok",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(260, 70),
		BackgroundColor3 = Theme.colors.good,
		Font = Theme.fonts.title,
		Text = "Awesome!",
		TextSize = 34,
		TextColor3 = Theme.colors.white,
		Parent = frame,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 16) }),
	})
	ok.Activated:Connect(function()
		frame.Visible = false
	end)
	Net.event("WelcomeBack").OnClientEvent:Connect(function(gain: number)
		body.Text = Text.get("Welcome.Body", { Format.number(gain) })
		frame.Visible = true
	end)
end

return WelcomePanel
```

- [ ] **Step 5 : Créer `src/client/UI/Banner.luau`**

```lua
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
```

- [ ] **Step 6 : Ajouter le bouton Rebirth au HUD (`src/client/UI/Hud.luau`)**

Dans le commentaire d'en-tête, remplacer `-- bouton « My Base » à gauche.` par `-- boutons « Rebirth » et « My Base » à gauche.`

Ajouter le require juste après `local RateLimit = require(ReplicatedStorage.Shared.Logic.RateLimit)` :

```lua
local RebirthPanel = require(script.Parent.RebirthPanel)
```

Dans `Hud.start`, juste après `home.Activated:Connect(goHome)`, ajouter :

```lua

	local rebirth = New("TextButton", {
		Name = "Rebirth",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, -76),
		Size = UDim2.fromOffset(170, 60),
		BackgroundColor3 = Theme.colors.rebirth,
		Font = Theme.fonts.title,
		Text = "Rebirth",
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
	rebirth.Activated:Connect(RebirthPanel.open)
```

- [ ] **Step 7 : Remplacer `src/client/init.client.luau`**

```lua
--!strict
-- Point d'entrée du client.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage:WaitForChild("Remotes")

local Banner = require(script.UI.Banner)
local DiaperPanel = require(script.UI.DiaperPanel)
local Effects = require(script.Effects.Effects)
local Hud = require(script.UI.Hud)
local RebirthPanel = require(script.UI.RebirthPanel)
local State = require(script.State)
local Toasts = require(script.UI.Toasts)
local Version = require(ReplicatedStorage.Shared.Logic.Version)
local WelcomePanel = require(script.UI.WelcomePanel)

State.start()
Toasts.start()
Hud.start()
DiaperPanel.start()
RebirthPanel.start()
WelcomePanel.start()
Banner.start()
Effects.start()

print("[BigBaby] client démarré : " .. Version.label())
```

- [ ] **Step 8 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `57 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 9 : Vérifier dans Studio**

Ci-dessous, `info` = `execute_luau` (Server) `return game.ServerStorage.DebugCommands:Invoke("info")`.

1. `start_stop_play` (démarrer), attendre 6 s, puis `execute_luau` (Server) `game.ServerStorage.DebugCommands:Invoke("reset")`. `screen_capture` : un bouton violet « Rebirth » au-dessus du bouton « My Base ».
2. Écran de retour : `execute_luau` (Server) :

```lua
local Debug = game.ServerStorage.DebugCommands
Debug:Invoke("setButtons", 2)
return Debug:Invoke("welcome", 3600)
```

   Attendu : `3.6K`, et `screen_capture` : le panneau « Welcome back! » avec « While you were away, your baby made 3.6K PoopCoins! » et le bouton vert « Awesome! ». Puis `user_mouse_input` : clic sur `LocalPlayer.PlayerGui.WelcomePanel.Panel.Ok`. Le panneau se ferme.
3. Panneau Rebirth : `user_mouse_input` : clic sur `LocalPlayer.PlayerGui.Hud.Rebirth`, puis `execute_luau` (Client) :

```lua
local panel = game.Players.LocalPlayer.PlayerGui.RebirthPanel.Panel
return table.concat({
	tostring(panel.Visible),
	panel.Diaper.Text,
	panel.Coins.Text,
	panel.Multiplier.Text,
	panel.Reward.Text,
	panel.Go.Text,
}, " | ")
```

   Attendu : `true | ❌ Cosmic Diaper | ❌ 30B PoopCoins in your pocket | PoopCoins x1 → x1.5 | +25 Binkies | REBIRTH!`.
4. `execute_luau` (Server) :

```lua
local Debug = game.ServerStorage.DebugCommands
Debug:Invoke("setButtons", 22)
Debug:Invoke("setDiaper", 10)
Debug:Invoke("give", 3e10)
```

   puis relire le panneau (étape 3). Attendu : `✅ Cosmic Diaper | ✅ 30B PoopCoins in your pocket`, bouton vert. `screen_capture` du panneau.
5. `user_mouse_input` : clic sur `LocalPlayer.PlayerGui.RebirthPanel.Panel.Go`, attente 400 ms, puis relire `panel.Go.Text`. Attendu : `SURE? CLICK AGAIN!`. Nouveau clic sur `…Panel.Go` : le panneau se ferme et `screen_capture` montre le toast « Rebirth #1! PoopCoins x1.5 forever! ». `info` : `0 boutons, couche 1, 1 rebirths, 25 Tétines`.
6. Bannière : `execute_luau` (Server) :

```lua
local Debug = game.ServerStorage.DebugCommands
Debug:Invoke("setRebirths", 9)
Debug:Invoke("setButtons", 22)
Debug:Invoke("setDiaper", 10)
Debug:Invoke("give", 3e12)
```

   puis `execute_luau` (Client) : `game.ReplicatedStorage.Remotes.Rebirth:FireServer() task.wait(1) return game.Players.LocalPlayer.PlayerGui.Banner.Banner.Text`. Attendu : `📣 <nom affiché> just reached 10 rebirths!`. `screen_capture` : la bannière violette en haut ; le chat (s'il est ouvert) montre le même message système.
7. `get_console_output` : aucune erreur. Puis `start_stop_play` (arrêter).

- [ ] **Step 10 : Commit**

```bash
git add src/client
git commit -m "feat: panneau Rebirth, écran de retour et bannière des annonces" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 10 : guide du tutoriel (client)

**Files :**
- Modify : `src/client/MyPlot.luau` (`MyPlot.path`)
- Create : `src/client/UI/TutorialGuide.luau`
- Modify : `src/client/init.client.luau` (démarrer le guide)

**Interfaces :**
- Consumes : `Snapshot.tutorial` et `Snapshot.totalClicks` ; `Config/Tutorial` (étapes, cibles) ; clés `Tutorial.<id>`.
- Produces :
  - `MyPlot.path(path): BasePart?` : pièce de la nursery par son chemin (`"PadActive.Disk"`, `"Baby.Diaper"`…) ;
  - la bulle `LocalPlayer.PlayerGui.TutorialGuide.Bubble` (en bas au centre, visible pendant les étapes 1 à 5) et la flèche `TutorialBeam` (Beam), rangée dans la pièce visée, reliée à l'Attachment `TutorialFrom` du HumanoidRootPart.

- [ ] **Step 1 : Ajouter `MyPlot.path` (`src/client/MyPlot.luau`)**

Ajouter cette fonction juste avant `return MyPlot` :

```lua
-- Pièce de la nursery par son chemin depuis la nursery, ex. « PadActive.Disk » ou « Baby.Diaper ».
function MyPlot.path(path: string): BasePart?
	local slot = MyPlot.get()
	local current: Instance? = if slot then slot:FindFirstChild("Nursery") else nil
	for _, name in string.split(path, ".") do
		current = if current then current:FindFirstChild(name) else nil
	end
	return if current and current:IsA("BasePart") then current else nil
end
```

- [ ] **Step 2 : Créer `src/client/UI/TutorialGuide.luau`**

```lua
--!strict
-- Guide du tutoriel (spec, section 4) : une bulle en bas de l'écran avec la consigne de l'étape en cours, et une
-- flèche lumineuse (Beam) du personnage vers ce qu'il faut viser. L'étape vient de l'état du serveur.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MyPlot = require(script.Parent.Parent.MyPlot)
local New = require(script.Parent.New)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.Parent.State)
local Text = require(script.Parent.Parent.Text)
local Theme = require(script.Parent.Theme)
local TutorialConfig = require(ReplicatedStorage.Shared.Config.Tutorial)

local REFRESH_EVERY = 1 -- secondes : la flèche suit un personnage qui réapparaît ou une base qui se réplique

local TutorialGuide = {}

local bubble: TextLabel? = nil
local beam: Beam? = nil

local function clearBeam()
	local current = beam
	if current then
		local target = current.Attachment1
		current:Destroy()
		if target then
			target:Destroy()
		end
		beam = nil
	end
end

-- Flèche du personnage vers la pièce `path` de la nursery, refaite si la cible ou le personnage a changé.
local function pointAt(path: string)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local target = MyPlot.path(path)
	if root == nil or target == nil then
		clearBeam()
		return
	end
	local current = beam
	if current and current.Attachment0 and current.Attachment1 then
		if current.Attachment0.Parent == root and current.Attachment1.Parent == target then
			return -- déjà en place
		end
	end
	clearBeam()
	local from = root:FindFirstChild("TutorialFrom") or New("Attachment", { Name = "TutorialFrom", Parent = root })
	local to = New("Attachment", { Name = "TutorialTo", Parent = target })
	beam = New("Beam", {
		Name = "TutorialBeam",
		Attachment0 = from,
		Attachment1 = to,
		Color = ColorSequence.new(Theme.colors.coins, Theme.colors.accent),
		Transparency = NumberSequence.new(0.15),
		Width0 = 0.9,
		Width1 = 0.9,
		CurveSize0 = 6,
		CurveSize1 = -6,
		Segments = 24,
		FaceCamera = true,
		LightEmission = 1,
		LightInfluence = 0,
		Parent = target,
	})
end

local function render()
	local label = bubble
	if label == nil then
		return
	end
	local snapshot = State.current
	local step = if snapshot then TutorialConfig.steps[snapshot.tutorial] else nil
	if snapshot == nil or step == nil then
		label.Visible = false
		clearBeam()
		return
	end
	label.Text = Text.get("Tutorial." .. step.id, { math.min(snapshot.totalClicks, step.count) })
	label.Visible = true
	pointAt(step.target)
end

function TutorialGuide.start()
	local gui = Screen.create("TutorialGuide", 12)
	bubble = New("TextLabel", {
		Name = "Bubble",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(640, 70),
		BackgroundColor3 = Theme.colors.panel,
		Font = Theme.fonts.body,
		Text = "",
		TextSize = 26,
		TextWrapped = true,
		TextColor3 = Theme.colors.text,
		AutoLocalize = false,
		Visible = false,
		Parent = gui,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 16) }),
		New(
			"UIStroke",
			{ Thickness = 3, Color = Theme.colors.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
		),
		New("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
	})
	State.changed:connect(render)
	task.spawn(function()
		while true do
			render()
			task.wait(REFRESH_EVERY)
		end
	end)
end

return TutorialGuide
```

- [ ] **Step 3 : Démarrer le guide (`src/client/init.client.luau`)**

Ajouter le require juste après `local Toasts = require(script.UI.Toasts)` :

```lua
local TutorialGuide = require(script.UI.TutorialGuide)
```

et l'appel `TutorialGuide.start()` juste après `Banner.start()`.

- [ ] **Step 4 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `57 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 5 : Vérifier dans Studio (un nouveau joueur suit le tutoriel)**

Ci-dessous, `PlotN` est la base du joueur et `guide` = `execute_luau` (Client) :

```lua
local player = game.Players.LocalPlayer
local bubble = player.PlayerGui.TutorialGuide.Bubble
local beam = workspace:FindFirstChild("TutorialBeam", true)
return tostring(bubble.Visible) .. " | " .. bubble.Text .. " | " .. (if beam then beam.Parent:GetFullName() else "pas de flèche")
```

1. `start_stop_play` (démarrer), attendre 6 s. `execute_luau` (Server) :

```lua
local Debug = game.ServerStorage.DebugCommands
Debug:Invoke("reset")
Debug:Invoke("setTutorial", 1)
return game.Players:GetPlayers()[1]:GetAttribute("Plot")
```

   Attendre 1 s, puis `guide`. Attendu : `true | Step on the glowing pad to get a Milk Bottle! | Workspace.Plots.PlotN.Nursery.PadActive.Disk`. `screen_capture` : la bulle en bas et une flèche lumineuse jaune-rose du personnage vers la dalle.
2. `character_navigation` vers `game.Workspace.Plots.PlotN.Nursery.PadActive.Disk`, attendre 2 s, puis vers `…PlotN.Nursery.Baby`, puis `guide`. Attendu : `Push the baby's diaper 10 times! (0/10)`, flèche dans `…Baby.Diaper`.
3. `user_mouse_input` : 10 clics sur `LocalPlayer.PlayerGui.Hud.Push` (150 ms entre les clics), puis `guide`. Attendu : `Watch the poop roll into the potty!`, flèche dans `…Potty.Sensor` (ou déjà l'étape suivante si un caca est arrivé). `screen_capture`.
4. Attendre 6 s, puis `guide`. Attendu : `Buy the Carrot Mash on the glowing pad!`, flèche dans `…PadActive.Disk`.
5. `execute_luau` (Server) `game.ServerStorage.DebugCommands:Invoke("give", 50)`, `character_navigation` vers `…PadActive.Disk`, attendre 2 s, puis `guide`. Attendu : `Buy the Camo diaper at the Changing Table!`, flèche dans `…ChangingTable.Top`.
6. `character_navigation` vers `…PlotN.Nursery.ChangingTable`, `execute_luau` (Server) `game.ServerStorage.DebugCommands:Invoke("give", 400)`, `user_keyboard_input` touche `E`, puis `user_mouse_input` : clic sur `LocalPlayer.PlayerGui.DiaperPanel.Panel.List.Row2.Buy`. Attendu (`screen_capture`) : le toast « +25 Binkies! Now make your baby the biggest in the world! » et « 🍼 25 » dans le HUD ; puis `guide` : `false | … | pas de flèche`.
7. `get_console_output` : aucune erreur. Puis `start_stop_play` (arrêter).

- [ ] **Step 6 : Commit**

```bash
git add src/client
git commit -m "feat: guide du tutoriel (bulle et flèche lumineuse)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 11 : partie complète, sauvegarde et CLAUDE.md

**Files :**
- Modify : `CLAUDE.md` (remplacé en entier)

**Interfaces :**
- Consumes : tout ce qui précède.
- Produces : le critère de fin de la phase 2 (spec, section 13) : « un nouveau joueur suit le tuto ; un rebirth marche ; les panneaux affichent des scores ». La tâche 10 a joué le tutoriel et la tâche 9 le rebirth ; il reste les panneaux et la sauvegarde.

- [ ] **Step 1 : Vérifier l'accès aux API**

`start_stop_play` (démarrer), attendre 8 s, `get_console_output`. Attendu : `[ProfileStore]: Roblox API services available - data will be saved`. Sinon, s'arrêter et demander à Nathan d'activer l'accès (Game Settings > Security > « Enable Studio Access to API Services »).

- [ ] **Step 2 : Les panneaux affichent des scores**

Si la tâche 7 n'a pas pu faire son étape 5 faute d'accès aux API, la faire maintenant. Sinon, `execute_luau` (Server) `return game.ServerStorage.DebugCommands:Invoke("boards")`. Attendu : `2 panneaux relus`, et `screen_capture` (caméra en `(0, 24, -40)` qui regarde `(0, 20, 40)`) : le joueur figure sur les deux panneaux, et son bébé a sa couronne s'il est dans le top 3.

- [ ] **Step 3 : Quitter et revenir**

1. `execute_luau` (Server) :

```lua
local Debug = game.ServerStorage.DebugCommands
Debug:Invoke("setTutorial", 99)
Debug:Invoke("setRebirths", 2)
Debug:Invoke("setButtons", 22)
Debug:Invoke("setDiaper", 10)
return Debug:Invoke("info")
```

   Noter les nombres.
2. `start_stop_play` (arrêter), attendre 70 s (plus d'une minute d'absence), puis `start_stop_play` (démarrer), attendre 8 s.
3. `info` (Server). Attendu : toujours `22 boutons, couche 10, 2 rebirths`, les mêmes Tétines, `tuto 99`, et plus de PoopCoins qu'avant (gains hors ligne d'environ 70 s). `screen_capture` : l'écran « Welcome back! » et la base reconstruite avec tous ses objets.
4. `start_stop_play` (arrêter).

- [ ] **Step 4 : Mettre `CLAUDE.md` à jour (phase 2)**

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
src/shared/Config/       contenu et chiffres (données pures) : Buttons, Diapers, Economy, World, Game, Rebirth,
                         Leaderboards, Tutorial
src/shared/Logic/        logique pure testée (aucune API Roblox) : Format, Data, Wallet, Economy, Poops, Shop,
                         Clicks, RateLimit, Rebirth, Offline, Leaderboard, Tutorial, Version
src/shared/Builders/     modèles cartoon en formes Roblox : Parts (outils), Baby, Poop, Pad, Machine, Decor,
                         Furniture, Crown, Board
src/shared/Net.luau      les RemoteEvents (noms) et le type Snapshot
src/shared/Util/Signal   signal minimal
src/server/init.server   crée les remotes, init puis start des services dans l'ordre
src/server/Services/     DataService (ProfileStore), PlotService (bases), IncomeService (revenu), StateService
                         (envoi de l'état), ProductionService (cacas), ClickService (PUSH!), ShopService (dalles,
                         couches), LeaderstatsService, RebirthService, AnnounceService, OfflineService (gains hors
                         ligne), LeaderboardService (classements mondiaux, couronnes), TutorialService, DebugService
src/server/World/        Layout (positions dans une base), MapBuilder (map, panneaux), PlotBuilder (nursery)
src/server/Clock.luau    heure du serveur
src/client/              init.client, State (dernier état reçu), MyPlot (base du joueur), Text (traductions),
                         UI/ (Theme, New, Screen, Toasts, Hud, DiaperPanel, RebirthPanel, WelcomePanel, Banner,
                         TutorialGuide), Effects/ (FloatingText, Shake, Effects)
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
mkdir -p build && rojo build -o build/BigBabyTycoon.rbxlx   # fichier de place
```
Les outils sont dans `~/.rokit/bin` (ajouté au PATH par `~/.zshenv` ; `scripts/check.sh` l'ajoute aussi).

Tester dans Studio : `rojo serve`, plugin Rojo > Connect, puis Play. Commandes de test (Studio seulement, contexte Server : barre de commande ou MCP de Studio `execute_luau`). Elles passent par une BindableFunction, car la barre de commande et le MCP ne voient pas l'état des modules du jeu :
```lua
local Debug = game.ServerStorage.DebugCommands
Debug:Invoke("give", 1e9) ; Debug:Invoke("setButtons", 22) ; Debug:Invoke("setDiaper", 10)
Debug:Invoke("setRebirths", 9) ; Debug:Invoke("setTutorial", 1) ; Debug:Invoke("reset")
print(Debug:Invoke("welcome", 3600)) ; print(Debug:Invoke("boards")) ; print(Debug:Invoke("info"))
```

Pièges :
- Sans accès aux API (jeu non publié, ou « Enable Studio Access to API Services » désactivé), ProfileStore tourne en mémoire et ne sauvegarde rien : la sortie affiche « Roblox API services unavailable ». Les classements mondiaux restent alors sur « Loading... ».
- En Studio, les DataStores ont le suffixe `_Studio` (`Profiles_v1_Studio`, `Rebirths_v1_Studio`, `TotalEarned_v1_Studio`) : les tests ne touchent jamais aux vrais joueurs.
- Un `require` par chaîne n'attend pas la réplication : le client attend `game.Loaded` avant de charger ses modules.
- `-- stylua: ignore` garde les tables de contenu (Buttons, Diapers) sur une ligne par entrée.
- Dans `Localization.csv`, un texte qui contient une virgule est entre guillemets (`""` = un guillemet).
- MCP de Studio : le serveur est déclaré dans `.mcp.json` (commande `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`). Dans Studio, l'activer une fois : bouton Assistant (icône atome, en haut à droite) > … > Settings > MCP Servers > « Enable Studio as MCP server ». Une session Claude Code ne charge les serveurs MCP qu'à son démarrage. `execute_luau` ne renvoie que la première valeur de retour : renvoyer une seule chaîne.
- Le plugin Rojo vient du Creator Store (Rojo Foundation) ; il propose « Connect » dès que `rojo serve` tourne. Il lui faut la permission « Script Injection » (Plugins > Manage Plugins) : sans elle, la sortie affiche « Plugin "Rojo" was denied script injection permission » et les scripts ne se mettent plus à jour.
- `StudsOffsetWorldSpace` d'un BillboardGui suit le repère de son Adornee, pas celui du monde : sur une pièce couchée (cylindre tourné), « vers le haut » n'est plus l'axe Y (voir `Builders/Pad.luau`).

## État actuel
**Phase 2 (progression)** : rebirth (Couche Cosmique + 30B × 1,6^R PoopCoins en poche ; +50 % de PoopCoins pour toujours et 25 × R Tétines), leaderstats, classements mondiaux « Biggest Babies » et « Poop Kings » sur la place (top 50, couronnes du top 3), gains hors ligne avec l'écran « Welcome back », tutoriel des nouveaux joueurs (bulle + flèche, 5 étapes, +25 Tétines), annonces des 10e, 25e et 50e rebirths. 57 tests Lune.

Phase 1 (le cœur) : map, bases, bébé, 22 boutons, cacas, PUSH! et méga caca, 10 couches, sauvegarde, HUD, traductions, commandes Debug.

Prochaine étape : phase 3 (monétisation), avec son propre plan. Nathan crée d'abord les 4 passes et les 6 produits dans le Creator Dashboard.

## Phases (spec, section 13)
0 Outillage · 1 Le cœur (bases, bébé, cacas, clic, couches, sauvegarde, HUD) · 2 Progression (rebirth, classements, hors ligne, tuto) · 3 Monétisation · 4 Pets · 5 Rétention · 6 Finition et lancement.
````

- [ ] **Step 5 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `57 tests réussis, 0 en échec`, puis `OK`.

- [ ] **Step 6 : Commit**

```bash
git add CLAUDE.md
git commit -m "docs: CLAUDE.md à jour pour la phase 2" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

## Hors de cette phase

Ces éléments de la spec viennent dans les phases suivantes, chacune avec son plan :
- l'écran de retour propose « Triple it », le panneau Rebirth rappelle le pass x2 PoopCoins, l'annonce de la Pluie de caca (phase 3) ;
- les étapes « ouvre ton premier œuf » et « équipe ton pet » du tutoriel, à insérer avant la fin dans `Config/Tutorial` ; le déblocage de l'Œuf du Parc (2 rebirths) et de l'Œuf Cosmique (5) ; l'annonce des pets légendaires et Secret ; le texte « You keep » qui cite les pets et les passes (phase 4) ;
- confettis et *whoosh* au rebirth, analytics au-delà de l'entonnoir du tutoriel (phase 6).

## Phase 2 terminée quand

- `scripts/check.sh` affiche `OK` (57 tests) ;
- dans Studio : un nouveau joueur suit le tutoriel jusqu'au bout (+25 Tétines) ; un rebirth marche depuis le panneau (base vidée, x1.5, +25 Tétines, leaderstats) ; le 10e rebirth est annoncé (bannière + chat) ; l'écran « Welcome back » montre les gains hors ligne ; les panneaux de la place affichent des scores et le top 3 a sa couronne ;
- après avoir quitté et relancé la partie, la progression est intacte (phase 1 comprise).
