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
mkdir -p build && rojo build -o build/BigBabyTycoon.rbxlx   # fichier de place
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
- MCP de Studio : le serveur est déclaré dans `.mcp.json` (commande `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`). Dans Studio, l'activer une fois : bouton Assistant (icône atome, en haut à droite) > … > Settings > MCP Servers > « Enable Studio as MCP server ». Une session Claude Code ne charge les serveurs MCP qu'à son démarrage. `execute_luau` ne renvoie que la première valeur de retour : renvoyer une seule chaîne.
- Le plugin Rojo vient du Creator Store (Rojo Foundation) ; il propose « Connect » dès que `rojo serve` tourne. Il lui faut la permission « Script Injection » (Plugins > Manage Plugins) : sans elle, la sortie affiche « Plugin "Rojo" was denied script injection permission » et les scripts ne se mettent plus à jour.
- `StudsOffsetWorldSpace` d'un BillboardGui suit le repère de son Adornee, pas celui du monde : sur une pièce couchée (cylindre tourné), « vers le haut » n'est plus l'axe Y (voir `Builders/Pad.luau`).

## État actuel
**Phase 1 (le cœur)** : map (place centrale + 6 bases générées par code), une base attribuée à chaque joueur, bébé qui grossit, 22 boutons achetés en se tenant sur la dalle (12 machines, 10 décos), cacas physiques sur le tapis jusqu'au pot, clic PUSH! (bouton ou couche) et méga caca tous les 50 clics, 10 couches à la table à langer, sauvegarde ProfileStore, HUD (PoopCoins, revenu, Tétines, PUSH!, My Base), traductions françaises, commandes Debug en Studio. 38 tests Lune.

Prochaine étape : phase 2 (rebirth, classements, gains hors ligne, tutoriel, annonces), avec son propre plan.

## Phases (spec, section 13)
0 Outillage · 1 Le cœur (bases, bébé, cacas, clic, couches, sauvegarde, HUD) · 2 Progression (rebirth, classements, hors ligne, tuto) · 3 Monétisation · 4 Pets · 5 Rétention · 6 Finition et lancement.
