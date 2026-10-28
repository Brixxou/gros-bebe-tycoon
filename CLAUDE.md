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
0. **Le repo est public** (github.com/Brixxou/gros-bebe-tycoon) : jamais de clé d'API (Open Cloud…), de cookie Roblox, de mot de passe ni d'e-mail perso dans un fichier ou un commit. Les commits de ce repo utilisent l'adresse anonyme GitHub (`git config user.email` local). Les IDs de passes et de produits ne sont pas secrets.
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
- `FormatByKey` écrit un nombre avec deux décimales (« 25.00 ») : `Text.get` convertit les nombres en texte, ne pas l'appeler en direct.
- MCP de Studio : le serveur est déclaré dans `.mcp.json` (commande `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`). Dans Studio, l'activer une fois : bouton Assistant (icône atome, en haut à droite) > … > Settings > MCP Servers > « Enable Studio as MCP server ». Une session Claude Code ne charge les serveurs MCP qu'à son démarrage. `execute_luau` ne renvoie que la première valeur de retour : renvoyer une seule chaîne.
- Le plugin Rojo vient du Creator Store (Rojo Foundation) ; il propose « Connect » dès que `rojo serve` tourne. Il lui faut la permission « Script Injection » (Plugins > Manage Plugins) : sans elle, la sortie affiche « Plugin "Rojo" was denied script injection permission » et les scripts ne se mettent plus à jour.
- Rojo pousse les fichiers avec un petit délai, et une partie de test déjà lancée garde l'ancien code : avant Play, vérifier en mode Edit que le code attendu est arrivé.
- La place est en édition collaborative (Team Create) : ce qu'on crée en mode Edit (aperçus de constructeurs) reste dans la place, donc toujours le supprimer après.
- `TextChatService.ChatVersion` est protégée (ni Rojo ni le MCP ne peuvent l'écrire) : la place doit être réglée à la main sur `TextChatService` dans Studio (Explorer > TextChatService > Properties). `default.project.json` la déclare pour `rojo build`.
- `StudsOffsetWorldSpace` d'un BillboardGui suit le repère de son Adornee, pas celui du monde : sur une pièce couchée (cylindre tourné), « vers le haut » n'est plus l'axe Y (voir `Builders/Pad.luau`). De même, une Beam courbée suit l'axe X de ses Attachments.

## État actuel
**Phase 2 (progression)** : rebirth (Couche Cosmique + 30B × 1,6^R PoopCoins en poche ; +50 % de PoopCoins pour toujours et 25 × R Tétines), leaderstats, classements mondiaux « Biggest Babies » et « Poop Kings » sur la place (top 50, couronnes du top 3), gains hors ligne avec l'écran « Welcome back », tutoriel des nouveaux joueurs (bulle + flèche, 5 étapes, +25 Tétines), annonces des 10e, 25e et 50e rebirths. 57 tests Lune.

Phase 1 (le cœur) : map, bases, bébé, 22 boutons, cacas, PUSH! et méga caca, 10 couches, sauvegarde, HUD, traductions, commandes Debug.

À vérifier dès que l'accès aux API est activé en Studio : la sauvegarde (quitter puis revenir : tout est là, phases 1 et 2) et les scores des classements mondiaux (tâche 11 du plan de la phase 2).

Prochaine étape : phase 3 (monétisation), avec son propre plan. Nathan crée d'abord les 4 passes et les 6 produits dans le Creator Dashboard.

## Phases (spec, section 13)
0 Outillage · 1 Le cœur (bases, bébé, cacas, clic, couches, sauvegarde, HUD) · 2 Progression (rebirth, classements, hors ligne, tuto) · 3 Monétisation · 4 Pets · 5 Rétention · 6 Finition et lancement.
