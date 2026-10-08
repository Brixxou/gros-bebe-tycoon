# Phase 0 : outillage, plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** un repo Roblox prêt à coder : outils installés, squelette synchronisé dans Studio par Rojo, tests Lune et vérifications automatiques, Studio relié à Claude Code par le MCP, jeu publié en privé.

**Architecture :** tout le jeu vit dans ce repo en fichiers Luau. Rojo les pousse dans Studio (`default.project.json`). La logique pure est testée hors de Roblox avec Lune. `scripts/check.sh` enchaîne format (StyLua), lint (Selene), types (luau-lsp avec les définitions Roblox) et tests. Le MCP intégré à Studio permet à Claude de lancer une partie de test, d'exécuter du code et de lire la console.

**Tech Stack :** Roblox Studio, Luau, Rokit 1.2.0, Rojo 7.7.1, Lune 0.10.5, StyLua 2.5.2, Selene 0.32.0, luau-lsp 1.70.1.

Spec : `docs/superpowers/specs/2026-10-08-big-baby-tycoon-design.md` (sections 11 à 13).

## Global Constraints

- Repo : `/Users/nathan/Public/dev/gros-bebe-tycoon` (branche `main`). Toutes les commandes se lancent depuis sa racine.
- Versions figées : Rokit 1.2.0, Rojo 7.7.1, Lune 0.10.5, StyLua 2.5.2, Selene 0.32.0, luau-lsp 1.70.1.
- Aucune dépendance en dehors de ProfileStore (phase 1).
- Langue du jeu : anglais (source) + français dans `src/Localization.csv`. Le mot « Cadum » n'apparaît jamais dans le jeu.
- Logique pure dans `src/shared/Logic` : aucune API Roblox, `--!strict`, `require` relatifs, testée avec Lune.
- Commentaires du code et messages de commit en français. Chaque commit se termine par la ligne `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- `scripts/check.sh` passe avant chaque commit.
- On ne modifie jamais un script dans Studio (Rojo l'écraserait) : on modifie les fichiers du repo.
- Les étapes marquées **(Nathan)** se font dans l'interface de Studio ou de Roblox avec son compte. Claude les demande et attend la confirmation.

---

### Task 1 : installer les outils (Rokit)

**Files :**
- Create : `rokit.toml`

**Interfaces :**
- Produces : les commandes `rojo`, `lune`, `stylua`, `selene` et `luau-lsp` dans `~/.rokit/bin`, aux versions de `rokit.toml`.

- [ ] **Step 1 : Installer Rokit**

```bash
mkdir -p "$TMPDIR/rokit-install" && cd "$TMPDIR/rokit-install" \
  && curl -sSfL -o rokit.zip https://github.com/rojo-rbx/rokit/releases/download/v1.2.0/rokit-1.2.0-macos-aarch64.zip \
  && unzip -o -q rokit.zip && ./rokit self-install
~/.rokit/bin/rokit --version
```

Attendu : `rokit 1.2.0`. `self-install` ajoute `. "$HOME/.rokit/env"` à `~/.zshenv`, ce qui met `~/.rokit/bin` dans le PATH des nouveaux terminaux.

- [ ] **Step 2 : Créer `rokit.toml`**

```toml
# Outils du projet, versions figées. Installer : rokit install
[tools]
rojo = "rojo-rbx/rojo@7.7.1"
lune = "lune-org/lune@0.10.5"
stylua = "JohnnyMorganz/StyLua@2.5.2"
selene = "Kampfkarren/selene@0.32.0"
luau-lsp = "JohnnyMorganz/luau-lsp@1.70.1"
```

- [ ] **Step 3 : Faire confiance aux outils et les installer**

```bash
cd /Users/nathan/Public/dev/gros-bebe-tycoon
export PATH="$HOME/.rokit/bin:$PATH"
rokit trust rojo-rbx/rojo lune-org/lune JohnnyMorganz/StyLua Kampfkarren/selene JohnnyMorganz/luau-lsp
rokit install
rojo --version; lune --version; stylua --version; selene --version; luau-lsp --version
```

Attendu : `Rojo 7.7.1`, `lune 0.10.5`, `stylua 2.5.2`, `selene 0.32.0`, `1.70.1`.

- [ ] **Step 4 : Commit**

```bash
git add rokit.toml
git commit -m "chore: outils du projet (Rokit : Rojo, Lune, StyLua, Selene, luau-lsp)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 2 : squelette du repo, tests et vérifications

**Files :**
- Create : `default.project.json`, `.gitignore`, `selene.toml`, `stylua.toml`, `.styluaignore`, `scripts/check.sh`
- Create : `tests/lib/t.luau`, `tests/init.luau`, `tests/Version.spec.luau`
- Create : `src/shared/Config/Game.luau`, `src/shared/Logic/Version.luau`
- Create : `src/server/init.server.luau`, `src/client/init.client.luau`, `src/Localization.csv`

**Interfaces :**
- Produces :
  - `tests/lib/t.luau` : `T.describe(name, body)`, `T.it(name, body)`, `T.eq(actual, expected, label?)`, `T.near(actual, expected, tolerance?)`, `T.truthy(value, label?)`, `T.results()` ;
  - chaque spec `tests/X.spec.luau` commence par `local T = require("./lib/t")` ;
  - `lune run tests` lance tous les `tests/*.spec.luau` et sort en code 1 si un test échoue ;
  - `Version.label(): string` renvoie `"Big Baby Tycoon v0.1.0"` ;
  - `scripts/check.sh` : format + lint + types + tests, affiche `OK`.

- [ ] **Step 1 : Créer `default.project.json` (arbre Rojo)**

```json
{
  "name": "BigBabyTycoon",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "Shared": { "$path": "src/shared" }
    },
    "ServerScriptService": {
      "Server": { "$path": "src/server" }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "Client": { "$path": "src/client" }
      }
    },
    "LocalizationService": {
      "Translations": { "$path": "src/Localization.csv" }
    },
    "Lighting": {
      "$properties": {
        "ClockTime": 14,
        "Brightness": 2.5,
        "Ambient": [0.55, 0.5, 0.6],
        "OutdoorAmbient": [0.65, 0.6, 0.7]
      }
    }
  }
}
```

- [ ] **Step 2 : Créer `.gitignore`**

```
# Fichiers générés
/build/
*.rbxl
*.rbxlx
*.rbxl.lock
*.rbxlx.lock
sourcemap.json
/.cache/
.DS_Store
```

- [ ] **Step 3 : Créer la config de StyLua et de Selene**

`stylua.toml` :

```toml
column_width = 110
line_endings = "Unix"
indent_type = "Tabs"
indent_width = 4
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
```

`.styluaignore` :

```text
src/server/Vendor/
```

`selene.toml` :

```toml
std = "roblox"
exclude = ["src/server/Vendor/*"]
```

- [ ] **Step 4 : Créer `scripts/check.sh` (puis `chmod +x scripts/check.sh`)**

```bash
#!/usr/bin/env bash
# Vérifie tout le projet : format, lint, types, tests. À lancer avant chaque commit.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"

DEFS=.cache/globalTypes.d.luau
if [ ! -f "$DEFS" ]; then
	mkdir -p .cache
	curl -sSfL -o "$DEFS" https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/1.70.1/scripts/globalTypes.d.luau
fi

echo "== format (stylua)"
stylua --check src tests
echo "== lint (selene)"
selene src tests
echo "== types (luau-lsp)"
rojo sourcemap -o sourcemap.json >/dev/null
luau-lsp analyze --platform=roblox --definitions=@roblox="$DEFS" --sourcemap=sourcemap.json \
	--ignore="**/Vendor/**" src
echo "== tests (lune)"
lune run tests
echo "OK"
```

- [ ] **Step 5 : Créer le mini framework de test `tests/lib/t.luau`**

```lua
-- Mini framework de test pour Lune : describe / it / assertions.
local T = {}

type Results = { passed: number, failed: number, failures: { string } }

local results: Results = { passed = 0, failed = 0, failures = {} }
local suite = ""

local function show(value: any): string
	if type(value) == "string" then
		return string.format("%q", value)
	end
	return tostring(value)
end

function T.describe(name: string, body: () -> ())
	local previous = suite
	suite = if previous == "" then name else previous .. " > " .. name
	body()
	suite = previous
end

function T.it(name: string, body: () -> ())
	local ok, err = pcall(body)
	if ok then
		results.passed += 1
	else
		results.failed += 1
		table.insert(results.failures, suite .. " > " .. name .. "\n    " .. tostring(err))
	end
end

function T.eq(actual: any, expected: any, label: string?)
	if actual ~= expected then
		local prefix = if label then label .. " : " else ""
		error(prefix .. "attendu " .. show(expected) .. ", obtenu " .. show(actual), 2)
	end
end

function T.near(actual: number, expected: number, tolerance: number?)
	local margin = tolerance or 1e-9
	if math.abs(actual - expected) > margin then
		error("attendu ~" .. tostring(expected) .. ", obtenu " .. tostring(actual), 2)
	end
end

function T.truthy(value: any, label: string?)
	if not value then
		error((label or "valeur") .. " devrait être vraie", 2)
	end
end

function T.results(): Results
	return results
end

return T
```

- [ ] **Step 6 : Créer le runner `tests/init.luau`**

```lua
-- Lance tous les fichiers tests/*.spec.luau : `lune run tests` depuis la racine du repo.
local fs = require("@lune/fs")
local process = require("@lune/process")
local T = require("@self/lib/t")

local names = fs.readDir("tests")
table.sort(names)
for _, name in names do
	if string.sub(name, -10) == ".spec.luau" then
		require("@self/" .. string.sub(name, 1, -6))
	end
end

local results = T.results()
for _, failure in results.failures do
	print("ÉCHEC " .. failure)
end
print(string.format("%d tests réussis, %d en échec", results.passed, results.failed))
if results.failed > 0 then
	process.exit(1)
end
```

- [ ] **Step 7 : Écrire le test qui échoue `tests/Version.spec.luau`**

```lua
local T = require("./lib/t")
local Version = require("../src/shared/Logic/Version")

T.describe("Version", function()
	T.it("donne le nom et la version", function()
		T.eq(Version.label(), "Big Baby Tycoon v0.1.0")
	end)
end)
```

- [ ] **Step 8 : Vérifier que le test échoue**

```bash
export PATH="$HOME/.rokit/bin:$PATH"; lune run tests
```

Attendu : une erreur `error requiring module "../src/shared/Logic/Version"` et un code de sortie non nul.

- [ ] **Step 9 : Écrire `src/shared/Config/Game.luau` et `src/shared/Logic/Version.luau`**

`src/shared/Config/Game.luau` :

```lua
--!strict
-- Identité du jeu.
return {
	name = "Big Baby Tycoon",
	version = "0.1.0",
}
```

`src/shared/Logic/Version.luau` :

```lua
--!strict
-- Libellé de version. Sert aussi à vérifier que les `require` relatifs marchent pareil dans Lune et dans Roblox.
local Game = require("../Config/Game")

local Version = {}

function Version.label(): string
	return Game.name .. " v" .. Game.version
end

return Version
```

- [ ] **Step 10 : Vérifier que le test passe**

```bash
export PATH="$HOME/.rokit/bin:$PATH"; lune run tests
```

Attendu : `1 tests réussis, 0 en échec`.

- [ ] **Step 11 : Créer les points d'entrée et la table de traduction**

`src/server/init.server.luau` :

```lua
--!strict
-- Point d'entrée du serveur.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Version = require(ReplicatedStorage.Shared.Logic.Version)

print("[BigBaby] serveur démarré : " .. Version.label())
```

`src/client/init.client.luau` :

```lua
--!strict
-- Point d'entrée du client.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Version = require(ReplicatedStorage.Shared.Logic.Version)

print("[BigBaby] client démarré : " .. Version.label())
```

`src/Localization.csv` :

```csv
Key,Source,Context,Example,fr
Game.Title,Big Baby Tycoon,,,Big Baby Tycoon
```

- [ ] **Step 12 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `1 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 13 : Construire le fichier de place**

```bash
export PATH="$HOME/.rokit/bin:$PATH"; mkdir -p build && rojo build -o build/BigBabyTycoon.rbxlx
```

Attendu : `Built project to BigBabyTycoon.rbxlx` (le dossier `build/` est ignoré par git).

- [ ] **Step 14 : Commit**

```bash
git add default.project.json .gitignore selene.toml stylua.toml .styluaignore scripts tests src
git commit -m "chore: squelette Rojo, tests Lune et vérifications (scripts/check.sh)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 3 : Studio, Rojo et MCP (avec Nathan)

**Files :** aucun.

**Interfaces :**
- Produces :
  - le jeu « Big Baby Tycoon » publié **en privé**, avec l'accès Studio aux API activé (les DataStores marchent en Studio) ;
  - le plugin Rojo connecté à `rojo serve` ;
  - les outils MCP de Studio disponibles dans Claude Code. Chaque appel prend un `studio_id`, donné par `list_roblox_studios`. Les outils utilisés ensuite : `start_stop_play`, `get_studio_state`, `execute_luau` (avec `datamodel_type` = `Edit`, `Server` ou `Client`), `get_console_output`, `screen_capture`, `script_read`, `character_navigation`, `user_mouse_input`, `user_keyboard_input`.

- [ ] **Step 1 (Nathan) : Installer Roblox Studio**

Télécharger Studio depuis https://create.roblox.com (bouton « Start Creating »), l'installer dans `/Applications`, l'ouvrir et se connecter avec son compte Roblox.

- [ ] **Step 2 : Installer le plugin Rojo dans Studio**

```bash
export PATH="$HOME/.rokit/bin:$PATH"; rojo plugin install
```

Attendu : pas d'erreur. Après un redémarrage de Studio, l'onglet Plugins contient « Rojo ».

- [ ] **Step 3 (Nathan) : Ouvrir la place et la publier en privé**

1. Lancer `open build/BigBabyTycoon.rbxlx` : la place s'ouvre dans Studio.
2. File > Publish to Roblox As… > nouvelle expérience nommée « Big Baby Tycoon ». Elle reste privée tant qu'on ne la rend pas publique.
3. File > Game Settings > Security : activer « Enable Studio Access to API Services », puis Save.
4. Dans le Creator Dashboard (create.roblox.com) > Big Baby Tycoon > Places > la place : régler la taille de serveur (« Server Size ») à 6 joueurs.

- [ ] **Step 4 : Lancer la synchro Rojo**

```bash
export PATH="$HOME/.rokit/bin:$PATH"; rojo serve
```

À lancer en arrière-plan (il tourne pendant toute la session). Attendu : `Rojo server listening` avec le port `34872`.

- [ ] **Step 5 (Nathan) : Connecter Rojo et activer le MCP de Studio**

1. Plugins > Rojo > Connect (adresse `localhost`, port `34872`). Avec `rojo serve` lancé, le plugin propose aussi « Connect » dans une notification en bas à droite.
2. Bouton Assistant (icône atome, en haut à droite) > … > Settings > MCP Servers : activer « Enable Studio as MCP server ».
3. Claude déclare le serveur dans le projet : `claude mcp add --scope project Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP` (fichier `.mcp.json`, à commiter).
4. Ouvrir une nouvelle session Claude Code dans ce dossier : les serveurs MCP ne se chargent qu'au démarrage d'une session.

- [ ] **Step 6 : Vérifier le jeu dans Studio par le MCP**

1. `list_roblox_studios` → noter le `studio_id` de la place Big Baby Tycoon.
2. `start_stop_play` (démarrer), attendre 5 s, puis `get_console_output`.
   Attendu : `[BigBaby] serveur démarré : Big Baby Tycoon v0.1.0` et `[BigBaby] client démarré : Big Baby Tycoon v0.1.0`. Ces lignes prouvent que les `require` relatifs (`require("../Config/Game")`) marchent dans Roblox comme dans Lune.
3. `start_stop_play` (arrêter).

- [ ] **Step 7 : Vérifier que Rojo pousse bien les fichiers**

1. Ajouter la ligne `-- synchro` à la fin de `src/shared/Config/Game.luau`.
2. `script_read` sur `ReplicatedStorage.Shared.Config.Game` : la dernière ligne est `-- synchro`.
3. Annuler : `git checkout src/shared/Config/Game.luau`.

### Task 4 : CLAUDE.md du repo

**Files :**
- Create : `CLAUDE.md`

**Interfaces :**
- Produces : le contexte projet que chaque session Claude Code charge (objectif, règles, commandes, pièges). La phase 1 le complète dans sa dernière tâche.

- [ ] **Step 1 : Créer `CLAUDE.md`**

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
- Sauvegardes : ProfileStore (loleris), copié tel quel dans `src/server/Vendor/` à la phase 1 (licence Apache 2.0 dans `licenses/`).
- Aucune autre dépendance.

## Arborescence
```
default.project.json     arbre Rojo : src/shared → ReplicatedStorage.Shared, src/server → ServerScriptService.Server,
                         src/client → StarterPlayerScripts.Client, src/Localization.csv → LocalizationService
rokit.toml               versions des outils
scripts/check.sh         format + lint + types + tests (à lancer avant chaque commit)
src/shared/Config/Game   identité du jeu (nom, version)
src/shared/Logic/Version libellé de version ; vérifie que les require relatifs marchent dans Lune et dans Roblox
src/server/init.server   point d'entrée du serveur
src/client/init.client   point d'entrée du client
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

Tester dans Studio : `rojo serve`, plugin Rojo > Connect, puis Play.

Pièges :
- Sans accès aux API (jeu non publié, ou « Enable Studio Access to API Services » désactivé), ProfileStore tourne en mémoire et ne sauvegarde rien : la sortie affiche « Roblox API services unavailable ».
- Un `require` par chaîne n'attend pas la réplication : le client attend `game.Loaded` avant de charger ses modules.

## État actuel
Phase 0 (outillage) : outils, squelette, Studio relié par Rojo et par le MCP, jeu publié en privé. Prochaine étape : phase 1 (le cœur du jeu).

## Phases (spec, section 13)
0 Outillage · 1 Le cœur (bases, bébé, cacas, clic, couches, sauvegarde, HUD) · 2 Progression (rebirth, classements, hors ligne, tuto) · 3 Monétisation · 4 Pets · 5 Rétention · 6 Finition et lancement.
````

- [ ] **Step 2 : Lancer toutes les vérifications**

```bash
scripts/check.sh
```

Attendu : `0 errors`, `0 warnings` pour Selene, aucune erreur de type, `1 tests réussis, 0 en échec`, puis `OK`. Si StyLua signale une différence de format, lancer `stylua src tests` puis relancer.

- [ ] **Step 3 : Commit**

```bash
git add CLAUDE.md
git commit -m "docs: CLAUDE.md du projet (règles, commandes, pièges)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

## Phase 0 terminée quand

- `scripts/check.sh` affiche `OK` ;
- dans Studio, la partie de test affiche les deux lignes `[BigBaby] … démarré` ;
- une modification d'un fichier apparaît dans Studio ;
- le jeu est publié en privé avec l'accès aux API activé.
