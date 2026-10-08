# Big Baby Tycoon : design

*Date : 2026-10-08. Statut : validé. Parties 1 et 2 validées une par une ; pour la suite, Nathan a dit « choisis tout, on changera plus tard si besoin ».*

## Pitch

Un tycoon Roblox goofy : tu élèves un gros bébé. Plus tu le nourris, plus il fait de gros cacas cartoon qui roulent jusqu'au pot et rapportent des PoopCoins. Les PoopCoins achètent des machines à bouffe, des décos et des couches de plus en plus légendaires, jusqu'à la Couche Cosmique et au rebirth. Autour : pets bébés, classements mondiaux, quêtes, récompenses quotidiennes, codes et events.

Objectif : un jeu qui accroche et qui rapporte des Robux (game passes + achats répétables), convertis en euros via le DevEx.

## Décisions

| Sujet | Choix |
|---|---|
| Genre | Tycoon + clicker |
| Boucle | bouffe → bébé → cacas → tapis → pot → PoopCoins → machines, décos, couches |
| Monétisation | game passes + produits répétables, pas de pubs |
| Construction | tout en code (Luau), synchronisé dans Studio avec Rojo ; la map est générée par code |
| Multijoueur | 6 joueurs par serveur, une base chacun, sauvegarde automatique |
| Fin de partie | rebirth + classements serveur et mondiaux |
| Lancement | gros lancement : tout ce qui est dans cette spec est là au jour 1 |
| Langue | anglais (langue source) + traduction française ; les autres langues via la traduction automatique de Roblox |
| Titre | *Big Baby Tycoon*, titre provisoire confirmé en phase 6 (« Cadum » est une marque déposée : jamais dans le jeu) |
| Plateformes | téléphone, tablette, ordinateur ; pas de console au lancement |
| Style | cartoon, fait avec des formes Roblox, cacas façon emoji 💩 (jamais réalistes) |

Dans cette spec, les noms du jeu sont donnés en anglais (ce qui est livré), avec le français entre parenthèses (la traduction).

## 1. Le monde

- **Place centrale** (rayon d'environ 60 studs) : point d'apparition, 3 stands d'œufs (+ 1 stand d'event quand un event est actif), coffre quotidien, panneau des codes, 2 classements mondiaux.
- **6 bases** d'environ 120 × 120 studs, en hexagone autour de la place. À l'arrivée, le joueur reçoit une base libre et y est téléporté. Quand il part, sa base est vidée et redevient libre. Un bouton « My Base » du HUD le ramène chez lui.
- Les autres joueurs peuvent visiter ta base, mais seul le propriétaire peut y acheter.
- Ciel et lumière pastel, matériaux SmoothPlastic ; Neon et Glass sont réservés aux objets rares (couches hautes, pets légendaires).

## 2. La base (la nursery)

**Éléments fixes** dès l'attribution : le sol, le bébé assis sur son tapis, le tapis roulant qui part de sa couche, le pot géant (*Potty*) au bout du tapis, et la table à langer (*Changing Table*) avec une ProximityPrompt.

**Les boutons** : 22 dalles au sol, achetées dans un ordre fixé. Seule la prochaine dalle est active ; la suivante est affichée en transparence pour donner envie. Marcher sur la dalle active l'achète si le joueur a assez de PoopCoins. Sinon, un toast affiche « You need X more » avec un raccourci vers les packs.

| # | Bouton | Type | Prix | Effet |
|---|---|---|---|---|
| 1 | Milk Bottle (Biberon) | machine | gratuit | +1 /s |
| 2 | Carrot Mash (Purée de carottes) | machine | 50 | +3 /s |
| 3 | Play Mat (Tapis d'éveil) | déco | 100 | +5 % |
| 4 | Applesauce Fountain (Fontaine de compote) | machine | 300 | +8 /s |
| 5 | Pastel Walls (Murs pastel) | déco | 600 | +5 % |
| 6 | Cereal Cannon (Canon à céréales) | machine | 1.5K | +20 /s |
| 7 | Crib (Berceau) | déco | 3K | +5 % |
| 8 | Nugget Printer (Imprimante à nuggets) | machine | 7.5K | +50 /s |
| 9 | Musical Mobile (Mobile musical) | déco | 15K | +5 % |
| 10 | Spaghetti Waterfall (Cascade de spaghetti) | machine | 40K | +125 /s |
| 11 | Toy Box (Coffre à jouets) | déco | 80K | +5 % |
| 12 | Pizza Launcher (Lance-pizzas) | machine | 200K | +300 /s |
| 13 | Rocking Horse (Cheval à bascule) | déco | 400K | +5 % |
| 14 | Taco Tornado (Tornade de tacos) | machine | 1M | +750 /s |
| 15 | Ball Pit (Piscine à balles) | déco | 2M | +5 % |
| 16 | Bean Reactor (Réacteur à haricots) | machine | 5M | +1.8K /s |
| 17 | Slide (Toboggan) | déco | 10M | +5 % |
| 18 | Cheese Volcano (Volcan de fromage) | machine | 25M | +4.5K /s |
| 19 | Giant Teddy (Nounours géant) | déco | 50M | +5 % |
| 20 | Burger Black Hole (Trou noir à burgers) | machine | 125M | +11K /s |
| 21 | Bouncy Castle (Château gonflable) | déco | 250M | +5 % |
| 22 | Galactic Baby Food (Petit pot galactique) | machine | 600M | +27K /s |

« /s » = production de base en PoopCoins par seconde ; « +5 % » = bonus de PoopCoins (additif entre décos).

**La bouffe** : chaque machine achetée lance régulièrement sa bouffe en arc jusque dans la bouche du bébé. C'est un effet visuel côté client, sans valeur.

**Le bébé grossit** : échelle = (1 + 0,04 × boutons achetés + 0,05 × (n° de couche − 1)) × (1 + 0,1 × rebirths), plafonnée à 4. Il se balance, cligne des yeux, ouvre la bouche quand la bouffe arrive et rigole à chaque achat.

## 3. Cacas, clic, couches

**Cacas physiques** : toutes les 1,5 s, le bébé pose un caca sur le tapis. Sa valeur = revenu/s × 1,5 (voir section 6). Le caca roule jusqu'au pot : *plop*, les PoopCoins sont crédités et un texte flottant affiche « +1.2K ». S'il n'arrive pas au pot en 20 s, il est crédité quand même puis détruit, pour qu'aucun caca coincé ne fasse perdre d'argent.
- **Taille** : selon la valeur, sur une échelle logarithmique de 1 à 4. Plus on produit, plus les cacas sont gros, pas plus nombreux.
- **Look** : il dépend de la couche (marron, doré, diamant, lave, arc-en-ciel, néon, licorne, galaxie, cosmique). Un caca = une boule de collision avec des formes décoratives soudées (spirale de 3 sphères + 2 yeux).

**Le clic (*PUSH!*, en français « POUSSE ! »)** : on tape sur la couche du bébé (ClickDetector) ou sur le gros bouton PUSH! du HUD.
- **Chaque clic** : + max(1 ; 0,15 × revenu/s) tout de suite, un petit caca qui saute et disparaît, et un prout (plusieurs variantes).
- **Tous les 50 clics : MEGA POOP**, un caca physique géant qui vaut max(50 ; 10 × revenu/s), avec tremblement d'écran et gros prout.
- **Limite serveur** : 12 clics par seconde ; les clics en trop sont ignorés. Le pass Auto Push ajoute 4 clics/s, comptés à part.

**Les couches** : elles s'achètent dans l'ordre à la table à langer, et le bébé porte automatiquement la meilleure. Chaque couche multiplie les PoopCoins et change le look des cacas.

| # | Couche | Multiplicateur | Prix |
|---|---|---|---|
| 1 | Cloth (Tissu) | x1 | de départ |
| 2 | Camo (Camouflage) | x2 | 400 |
| 3 | Gold (Or) | x3,5 | 6K |
| 4 | Diamond (Diamant) | x6,5 | 80K |
| 5 | Lava (Lave) | x12 | 1M |
| 6 | Rainbow (Arc-en-ciel) | x24 | 12M |
| 7 | Neon (Néon) | x45 | 150M |
| 8 | Unicorn (Licorne) | x85 | 2B |
| 9 | Galaxy (Galaxie) | x160 | 9B |
| 10 | Cosmic (Cosmique) | x300 | 25B |

La Couche Cosmique débloque le rebirth.

## 4. Progression

### Rebirth

- **Condition** : posséder la Couche Cosmique et avoir en poche 30B × 1,6^R PoopCoins (R = nombre de rebirths déjà faits).
- **Repart à zéro** : PoopCoins, boutons (machines et décos), couches.
- **Est gardé** : Tétines, pets, game passes, rebirths, statistiques, codes utilisés, série quotidienne, quêtes du jour.
- **Gains** : +50 % de PoopCoins pour toujours à chaque rebirth (multiplicateur = 1 + 0,5 × R), 25 × (nouveau R) Tétines, et un bébé plus gros de base.
- **Déblocages** : l'Œuf du Parc à 2 rebirths, l'Œuf Cosmique à 5.
- **Panneau Rebirth** : il montre les conditions, le multiplicateur actuel → le suivant (« x2 → x2.5 ») et ce qui est perdu ou gardé, avec une confirmation.

### Classements

- **Serveur** : `leaderstats` dans la liste des joueurs, avec PoopCoins (texte formaté) et Rebirths.
- **Mondiaux** : 2 panneaux géants sur la place, « Biggest Babies » (rebirths) et « Poop Kings » (total de PoopCoins gagnés depuis le début). Chacun affiche le top 50 et se relit toutes les 2 min.
  - Le score d'un joueur est écrit à chaque rebirth, toutes les 5 min et à son départ.
  - Le total gagné est stocké en `floor(log10(total + 1) × 10^6)` parce qu'un OrderedDataStore n'accepte que des entiers et que ces nombres dépassent vite 2^53. L'affichage le reconvertit.
- **Couronnes** : le top 3 mondial des rebirths a une couronne (or, argent, bronze) au-dessus de son bébé, visible si le joueur est dans le serveur.

### Gains hors ligne

Quand le joueur revient, un écran « While you were away, your baby made 1.2M PoopCoins! » s'affiche. Gain = 25 % × revenu de base/s × temps d'absence, plafonné à 8 h. Le même écran propose le produit « Triple it » (voir section 7).

### Tutoriel (nouveaux joueurs uniquement)

Une flèche lumineuse (Beam) et une bulle guident 7 étapes. L'étape en cours est sauvegardée : en revenant, le joueur reprend où il en était.

1. Achète le biberon (dalle gratuite).
2. Clique 10 fois sur la couche (ou sur PUSH!).
3. Regarde ton premier caca arriver dans le pot.
4. Achète la purée de carottes.
5. Achète la couche Camo à la table à langer.
6. Récompense : +25 Tétines. Va ouvrir ton premier œuf sur la place.
7. Équipe ton pet. Fin : « Make your baby the biggest in the world! »

Chaque étape est envoyée dans l'entonnoir d'onboarding des analytics Roblox (section 11).

### Annonces serveur

Un message système dans le chat + une bannière en haut de l'écran pour tout le serveur quand quelqu'un :
- sort un pet légendaire ou Secret ;
- fait son 10e, 25e ou 50e rebirth ;
- achète une Pluie de caca.

## 5. Pets bébés

- **Œufs** : stands sur la place, ProximityPrompt → panneau avec la liste des pets, les probabilités en %, et les boutons « Open 1 » / « Open 3 ». Les œufs se paient uniquement en Tétines.
- **Ouverture** : le serveur tire le pet et l'enregistre tout de suite. Ensuite seulement, le client joue l'animation : l'œuf tremble, craque, et le pet apparaît avec la couleur de sa rareté (Commun gris, Rare bleu, Épique violet, Légendaire or, Secret arc-en-ciel).
- **Inventaire** : 50 pets maximum. Si l'inventaire n'a pas assez de place, l'ouverture est refusée avec un message. On peut supprimer des pets (sélection multiple) ; supprimer un pet équipé le déséquipe.
- **Équipés** : 3 (5 avec le pass +2 Pets), avec un bouton « Equip Best ». Chaque pet équipé ajoute son bonus de PoopCoins (bonus additifs entre pets).
- **Suivi** : les pets équipés suivent leur joueur en rebondissant. Chaque client les dessine pour tous les joueurs du serveur, et les masque au-delà de 200 studs.
- Les pets sont construits avec des formes : corps et tête ronds, oreilles, couleur, tétine ou bavoir. Un même constructeur paramétré sert à tous les pets.

| Œuf | Prix | Débloqué | Pets (rareté, chance, bonus) |
|---|---|---|---|
| Nursery Egg (Œuf de la Crèche) | 25 | dès le début | Kitten / Chaton (C, 40 %, +10 %) · Puppy / Chiot (C, 30 %, +15 %) · Duckling / Caneton (R, 20 %, +25 %) · Bunny / Lapinou (É, 8 %, +40 %) · Panda (L, 2 %, +75 %) |
| Park Egg (Œuf du Parc) | 150 | 2 rebirths | Piglet / Porcelet (C, 40 %, +30 %) · Penguin / Pingouin (C, 30 %, +40 %) · Koala (R, 20 %, +60 %) · Fox / Renardeau (É, 8 %, +100 %) · Dino (L, 2 %, +175 %) |
| Cosmic Egg (Œuf Cosmique) | 1 000 | 5 rebirths | Alien (R, 45 %, +120 %) · Robot (É, 35 %, +200 %) · Unicorn / Licorne (É, 15 %, +250 %) · Dragon (L, 4,9 %, +350 %) · **Royal Poop / Caca Royal** (Secret, 0,1 %, +500 %) |
| Pumpkin Egg (Œuf Citrouille), event Halloween | 200 | pendant l'event | Ghost / Fantôme (C, 40 %, +45 %) · Pumpkin / Citrouille (C, 30 %, +55 %) · Bat / Chauve-souris (R, 20 %, +80 %) · Mummy / Momie (É, 8 %, +130 %) · Vampire (L, 2 %, +220 %) |
| Gift Egg (Œuf Cadeau), event Noël | 200 | pendant l'event | Reindeer / Renne (C, 40 %, +45 %) · Snowman / Bonhomme de neige (C, 30 %, +55 %) · Elf / Lutin (R, 20 %, +80 %) · Polar Bear / Ours polaire (É, 8 %, +130 %) · Santa Baby / Bébé Père Noël (L, 2 %, +220 %) |

Les pets d'event restent à vie mais ne s'obtiennent plus une fois l'event fini.

## 6. Économie

**Revenu de base/s** = P × couche × décos × rebirth × pets × passes × Premium
- P = somme des productions des machines achetées
- décos = 1 + 0,05 × décos achetées
- rebirth = 1 + 0,5 × R
- pets = 1 + somme des bonus des pets équipés
- passes = 2 avec x2 PoopCoins, × 1,2 avec VIP
- Premium = 1,1 pour un abonné Roblox Premium

**Revenu/s** = revenu de base/s × multiplicateurs temporaires :
- Boost x3 = 3
- Pluie de caca = 2
- event x2 PoopCoins = 2
- amis = 1 + 0,1 × amis dans le serveur, plafonné à 1,5

Tout se multiplie. Les packs, les gains hors ligne et les objectifs de quêtes se calculent sur le **revenu de base**, pour qu'acheter pendant un boost ne crée pas d'effet boule de neige.

**Formules** (récap) :
- caca = revenu/s × 1,5, toutes les 1,5 s
- clic = max(1 ; 0,15 × revenu/s)
- méga caca = max(50 ; 10 × revenu/s), tous les 50 clics
- seuil de rebirth = 30B × 1,6^R
- gains hors ligne = 25 % × revenu de base × min(absence ; 8 h)

**Rythme visé**, calculé par simulation avec les valeurs ci-dessus, sans pets ni boosts :

| Profil | Rebirth 0 | R1 | R2 | R5 | R8 |
|---|---|---|---|---|---|
| Inactif (0 clic) | ~165 min | ~120 | ~102 | ~113 | ~238 |
| Actif (2 clics/s en moyenne) | ~97 min | ~70 | ~60 | ~67 | ~140 |
| Auto Push + x2 PoopCoins | ~34 min | ~25 | ~21 | ~24 | ~50 |

Pour le joueur actif, jusqu'à la couche Licorne, il ne s'écoule jamais plus de 6 min environ entre deux achats. Les pets accélèrent ensuite les rebirths suivants.

**Tétines** : elles s'obtiennent uniquement en jouant. Pour un joueur qui joue environ 1 h par jour, ça fait 150 Tétines par jour environ.
- tutoriel : 25
- coffre quotidien : 10 à 100
- quêtes : 15 chacune, +25 si les 3 sont faites
- cadeaux de présence : 60 par jour
- rebirth : 25 × nouveau R
- codes

**Toutes les valeurs vivent dans `shared/Config`** et sont réglées avec le simulateur (section 12).

## 7. Monétisation

Prix en Robux : ce sont des valeurs de départ, réglées dans le Creator Dashboard (le code lit le prix en direct). Roblox garde 30 % (tu touches 70 %).

**Game passes** (achat unique)

| Pass | Effet | Prix conseillé |
|---|---|---|
| x2 PoopCoins | revenu x2 pour toujours | 249 R$ |
| Auto Push | 4 clics/s automatiques tant que tu es en jeu (interrupteur dans le HUD) | 149 R$ |
| VIP | couche VIP exclusive (skin doré arc-en-ciel par-dessus la couche portée, le multiplicateur ne change pas), tag [VIP] dans le chat, +20 % de PoopCoins | 199 R$ |
| +2 Pets | 5 pets équipés au lieu de 3 | 199 R$ |

**Produits répétables**

| Produit | Effet | Prix conseillé |
|---|---|---|
| Small / Medium / Large Pack | 15 min / 1 h / 6 h de revenu de base (au moins 1 000) | 29 / 99 / 349 R$ |
| Boost x3 | revenu x3 pendant 15 min (durées cumulables, plafond 3 h) | 49 R$ |
| Poop Rain (Pluie de caca) | x2 pour tout le serveur pendant 10 min (cumulable, plafond 60 min). Une pluie de cacas tombe du ciel et le serveur est prévenu avec le nom de l'acheteur. Elle s'arrête si le serveur ferme (c'est dit dans la description). | 99 R$ |
| Triple it (Triple tes gains hors ligne) | ajoute 2 × le gain hors ligne en attente. Proposé uniquement sur l'écran de retour. Si plus rien n'est en attente au moment de l'accorder, donne 30 min de revenu de base à la place. | 25 R$ |

**Règles**
- **Pas de hasard payant.** Aucun achat en Robux ne donne de Tétines et aucun ne change les probabilités des œufs (pas de « luck boost » payant). Les œufs ne sont donc pas des *paid random items* au sens de la politique Roblox : pas de blocage par pays via PolicyService à gérer. Les probabilités restent quand même affichées sur chaque œuf.
- **Accordé une seule fois.** Chaque achat de produit est enregistré dans le profil du joueur, et le serveur ne répond « accordé » qu'une fois ce profil sauvegardé. Si le joueur n'est plus là, la réponse est « pas encore traité » et Roblox réessaie plus tard.
- **Passes** : la possession est vérifiée auprès de Roblox à chaque arrivée et à la fin d'un achat en jeu. Elle n'est jamais stockée dans nos données.
- **Abonnés Premium** : +10 % de PoopCoins. Roblox verse aussi des *Premium Payouts* selon le temps qu'ils passent dans le jeu : la rétention rapporte directement.

**Où on propose d'acheter**
- Boutique (bouton du HUD) avec deux onglets : Passes / Boosts & Packs.
- Toast « You need X more » sur une dalle trop chère, avec un raccourci vers les packs.
- Écran de retour (Triple it).
- Panneau Rebirth : il rappelle x2 PoopCoins si le joueur ne l'a pas.

## 8. Rétention

- **Coffre quotidien** (sur la place + bouton du HUD), série de 7 jours.
  - Récompenses : J1 10 Tétines · J2 pack de 10 min · J3 20 Tétines · J4 Boost x3 10 min · J5 30 Tétines · J6 pack de 30 min · J7 100 Tétines.
  - Si le joueur a ouvert le coffre hier, il passe au jour suivant ; sinon il revient au J1. Après le J7, la série reprend au J1. Les jours suivent l'heure UTC.
- **Quêtes du jour** : 3 par jour, tirées pour chaque joueur parmi des quêtes possibles pour lui. 15 Tétines chacune, +25 si les 3 sont faites. Remise à zéro à 00:00 UTC.
  - « Click 300 times »
  - « Make 5 Mega Poops »
  - « Send 200 poops to the potty »
  - « Buy 3 buttons » (seulement s'il reste au moins 3 boutons à acheter)
  - « Buy a diaper » (seulement s'il reste une couche à acheter)
  - « Open 3 eggs »
  - « Play 20 minutes »
  - « Earn X PoopCoins » (X = 10 min de revenu de base au moment du tirage)
- **Cadeaux de présence** : 6 cadeaux par jour selon le temps joué ce jour-là. Le compteur ne repart pas à zéro si on quitte et revient le même jour.
  - 5 min : 5 Tétines
  - 10 min : pack de 5 min
  - 15 min : 10 Tétines
  - 25 min : Boost x3 5 min
  - 40 min : 15 Tétines
  - 60 min : 30 Tétines
- **Codes** : panneau de saisie, sans tenir compte des majuscules et des espaces, chaque code une seule fois par joueur.
  - Codes de lancement : `BIGBABY` (50 Tétines), `POOP` (Boost x3 15 min), `RELEASE` (pack de 30 min, expire le 2026-12-31).
  - Ensuite, des codes à paliers de likes (« 1KLIKES »…), annoncés dans la description du jeu et ajoutés par une mise à jour.
- **Events** (dates en UTC, dans la config) :
  - Week-end x2 PoopCoins chaque samedi et dimanche.
  - Halloween du 2026-10-23 au 2026-11-08 : Œuf Citrouille, place décorée (citrouilles, lumières orange), Tétines x2.
  - Noël du 2026-12-18 au 2027-01-04 : Œuf Cadeau, sapin et neige, Tétines x2.
  - « Tétines x2 » double les Tétines du coffre, des quêtes et des cadeaux (pas celles des rebirths ni des codes).
  - Une bannière dans le HUD indique l'event en cours.
- **Amis** : +10 % de PoopCoins par ami présent dans le serveur (plafond +50 %), et un bouton « Invite friends » qui ouvre l'invitation Roblox.

## 9. Interface

- **Mobile d'abord** : gros boutons, mise à l'échelle selon l'écran (UIScale), rien sous le bouton de saut mobile.
- **Polices** : Luckiest Guy pour les titres, Fredoka One pour le texte. Couleurs pastel et contours épais (UIStroke).
- **HUD** :
  - en haut au centre : PoopCoins + revenu/s, Tétines en dessous ;
  - à gauche : Shop, Pets, Quests, Gifts, Codes, Rebirth, My Base, Invite ;
  - en bas à droite (au-dessus du saut) : le gros bouton PUSH! et l'interrupteur Auto Push ;
  - en haut à droite : boosts actifs avec compte à rebours, bonus amis, event.
- **Panneaux** : Shop, Pets (inventaire, équiper, supprimer, Equip Best), Hatch (œuf), Quests, Gifts, Daily, Codes, Rebirth, Welcome back, plus des toasts.
- **Nombres** : format court en anglais partout (1.2K, 3.4M, 5.6B, 7.8T, 1.2Qa, Qi, Sx, Sp, Oc, No, Dc…).
- **Textes** : l'anglais est la langue source. Le français est dans une table de traduction (fichier CSV synchronisé en `LocalizationTable`), et les autres langues passent par la traduction automatique de Roblox. Tout texte visible passe par le module de traduction.

## 10. Sons et effets

- **Sons** de la bibliothèque gratuite de Roblox (Creator Store) : prouts (plusieurs variantes), *plop* dans le pot, caisse enregistreuse (achat), *pop* (nouvelle dalle), rire de bébé, craquement d'œuf, fanfare (légendaire), *whoosh* (rebirth), pluie, et une musique de fond légère et goofy. Les IDs sont dans `Config/Sounds` ; un son sans ID est simplement muet.
- **Effets** : textes flottants « +X », tremblement d'écran (méga caca), confettis (rebirth, légendaire), pluie de cacas (Poop Rain), arcs de bouffe.

## 11. Architecture technique

### Outils

- Rokit installe des outils aux versions figées dans `rokit.toml` : Rojo (synchro fichiers ↔ Studio), Lune (exécuter du Luau hors de Roblox : tests et simulateur), StyLua (formatage), Selene (lint) et luau-lsp (vérification des types).
- Roblox Studio avec le plugin Rojo.
- Le **serveur MCP intégré à Studio** (panneau Assistant) est branché sur Claude Code. Il permet de lancer une partie de test, d'exécuter du code, de lire la console, de capturer la vue et de simuler des entrées, donc de vérifier dans Studio.
- ProfileStore (loleris) pour les sauvegardes, copié dans `src/server/Vendor` avec sa licence, pris à sa source officielle.
- Aucune autre dépendance : pas de framework UI ni de framework de services.

### Arborescence

```
default.project.json     arbre Rojo
rokit.toml               outils épinglés
selene.toml, stylua.toml, .luaurc
scripts/check.sh         format + lint + types + tests
src/
  shared/                → ReplicatedStorage.Shared
    Config/              contenu et chiffres (données pures) : Machines, Decor, Diapers,
                         Pets, Eggs, Economy, Rebirth, Quests, Daily, Gifts, Codes,
                         Events, Monetization (IDs), Sounds
    Logic/               logique pure, aucune API Roblox, testée avec Lune : Economy,
                         Progression, Rebirth, Pets, Eggs, Quests, Daily, Gifts, Codes,
                         Events, Offline, Format, Data (modèle + migrations), RateLimit
    Builders/            modèles cartoon (bébé, cacas, machines, décos, pets, œufs, couronne)
    Net.luau             noms des remotes
    Util/                Signal
  server/                → ServerScriptService.Server
    init.server.luau     démarre les services dans l'ordre
    Services/            Data, Plots, Production, Clicks, Shop, Rebirth, Pets,
                         Monetization, Boosts, Daily, Quests, Gifts, Codes, Events,
                         Social (amis, invitations, annonces), Leaderboards,
                         Tutorial, Analytics, Debug (Studio seulement)
    World/               MapBuilder (place, bases, stands, panneaux), PlotBuilder
    Vendor/              ProfileStore
  client/                → StarterPlayerScripts.Client
    init.client.luau
    State.luau           dernier état reçu du serveur + signaux
    UI/                  Theme, Components, HUD et panneaux
    Effects/             sons, textes flottants, tremblement, bouffe, pets qui suivent,
                         pluie, confettis
  Localization.csv       → table de traduction (FR)
tests/                   specs Lune (*.spec.luau) + runner
tools/simulate.luau      simulateur d'économie (Lune)
docs/superpowers/        specs et plans
```

### Principes (repris dans le `CLAUDE.md` du repo)

1. **Le serveur décide de tout.** Le client n'envoie que des intentions (clic, ouvrir un œuf, équiper…) et ne fait que de l'affichage. Le serveur valide tout : propriétaire de la base, argent, limites de fréquence, types et tailles des arguments.
2. **La logique pure vit dans `shared/Logic`**, sans API Roblox, typée en `--!strict` et testée avec Lune. **Les effets de bord vivent dans les Services.** Les modules purs se chargent entre eux par chemins relatifs (`require("./Format")`, `require("../Config/Machines")`), sans fichier `init`, pour se charger pareil dans Roblox et dans Lune.
3. **Une seule source pour le contenu et les chiffres** : `shared/Config`.
   **Une seule horloge** : le code serveur lit l'heure via un module `Clock` (décalable en Studio par Debug), et les fonctions pures reçoivent `now` en paramètre.
4. **Compat des sauvegardes** : chaque champ a une valeur par défaut, et ProfileStore complète les profils anciens avec `Reconcile`. Le profil porte un numéro de schéma ; les migrations sont des fonctions pures testées. On ne joue jamais avec un profil qui n'a pas pu se charger : le joueur est renvoyé avec un message, rien n'est écrasé.
5. **Achats** : idempotents, et accordés seulement une fois le profil sauvegardé (section 7).
6. **Pas de hasard payant** (section 7).
7. **Performance** : au plus 1 caca physique toutes les 1,5 s par base (plus les méga cacas). Les cacas sont possédés par le serveur (pas de propriété réseau côté client). Les arcs de bouffe et les pets sont dessinés côté client.

### Données d'un joueur (profil ProfileStore, clé `Player_<UserId>`)

```lua
{
  schema = 1,
  coins = 0, binkies = 0,
  totalEarned = 0, totalPoops = 0, totalClicks = 0,
  rebirths = 0,
  buttons = 0,            -- nombre de boutons achetés dans la séquence
  diaper = 1,             -- meilleure couche possédée (index)
  clicksSinceMega = 0,
  pets = { nextUid = 1, owned = {} --[[ liste de { uid = "p1", id = "kitten" } ]], equipped = {} --[[ liste d'uid ]] },
  boosts = { x3Until = 0 },
  daily = { streak = 0, lastDay = -1 },
  quests = { day = -1, list = {} --[[ { id, target, progress, claimed } ]], bonusClaimed = false },
  gifts = { day = -1, playedSeconds = 0, claimed = {} },
  codes = {},             -- [CODE] = true
  receipts = {},          -- 50 derniers PurchaseId accordés
  tutorial = 0,           -- étape en cours, 99 = terminé
  lastSeen = 0, pendingOffline = 0,
  settings = { autoPush = true },
  stats = { firstJoin = 0, playSeconds = 0, eggsOpened = 0 },
}
```

Les clés de tables sont des chaînes ou des listes (les DataStores refusent les tables à trous indexées par des nombres). Les jours sont des numéros de jour UTC (`os.time() // 86400`).

### Réseau

- **Du client vers le serveur** (RemoteEvents) : `Click`, `BuyDiaper`, `Rebirth`, `OpenEgg(eggId, count)`, `EquipPet(uid)`, `UnequipPet(uid)`, `EquipBest`, `DeletePets(uids)`, `ClaimDaily`, `ClaimQuest(index)`, `ClaimQuestBonus`, `ClaimGift(index)`, `RedeemCode(text)`, `SetAutoPush(on)`.
  - Les dalles se déclenchent côté serveur par contact, sans remote.
  - Les achats Robux passent par MarketplaceService.
- **Du serveur vers le client** :
  - `State` : instantané complet du profil + valeurs dérivées (revenu, multiplicateurs, boosts, event), envoyé au propriétaire à chaque changement, 5 fois par seconde au plus ;
  - `Toast` ; `Announce` (tout le serveur) ; `HatchResult` ; `WelcomeBack` ; `Effect` (méga caca, rebirth…).
- **Visible par tous** : attributs du Player (`Rebirths`, `EquippedPets`, `Vip`), `leaderstats`, attribut `OwnerUserId` de chaque base, couronnes posées par le serveur.
- **Limites de fréquence** par joueur et par action (seau de jetons) : par exemple 12 clics/s, 2 ouvertures d'œuf/s, 1 code/s.
- **Chargement** : le client attend que `Shared` soit répliqué avant de charger ses modules (les `require` par chaîne n'attendent pas la réplication).

### Services : rôle de chacun

- **Data** : profils (chargement, `Reconcile`, migrations, sauvegarde), envoi de `State`.
- **Plots** : attribution et libération des bases, construction (PlotBuilder), dalles.
- **Production** : boucle des cacas, crédit au pot.
- **Clicks** : clics, méga caca, Auto Push.
- **Shop** : dalles et couches.
- **Rebirth** : rebirths.
- **Pets** : œufs, inventaire, équipement.
- **Monetization** : passes, ProcessReceipt.
- **Boosts** : boosts perso, pluie du serveur, multiplicateurs temporaires.
- **Daily / Quests / Gifts / Codes** : coffre quotidien, quêtes, cadeaux de présence, codes.
- **Events** : event en cours, décor de la place, œuf d'event.
- **Social** : amis, invitations, annonces, tag VIP.
- **Leaderboards** : leaderstats, OrderedDataStores, panneaux, couronnes.
- **Tutorial** : étapes du tutoriel, déduites des événements de jeu côté serveur.
- **Analytics** : AnalyticsService (entonnoir du tutoriel, sources et dépenses de PoopCoins et de Tétines, événements personnalisés : rebirth, œuf).
- **Debug** : commandes en Studio uniquement (donner des PoopCoins ou des Tétines, fixer les rebirths, avancer l'horloge de N jours), appelables depuis la barre de commande ou le MCP, jamais exposées par un remote.

### Erreurs

- **DataStore** : ProfileStore réessaie tout seul. Un profil qui ne se charge pas = le joueur est renvoyé avec « Couldn't load your save, please rejoin ».
- **Classements** : un échec garde la dernière liste affichée et réessaie au cycle suivant.
- **ProcessReceipt** : la moindre erreur renvoie « pas encore traité » (Roblox réessaie).
- **Prix de la boutique** : si `GetProductInfo` échoue, le prix affiche « — » et réessaie.
- **Possession d'un pass** : en cas d'échec, 3 essais, sinon « non possédé » jusqu'à la prochaine vérification.
- **Amis** : un échec de vérification = pas ami.
- **Remotes** : des arguments invalides sont ignorés (journalisés en Studio seulement).

### Spécificités Studio

- Le jeu est publié **en privé** dès la phase 0 et l'accès Studio aux services API est activé, pour que les DataStores marchent en Studio.
- En Studio, les DataStores ont un suffixe `_Studio`, pour ne jamais toucher aux données des vrais joueurs.
- En Studio, les achats Robux sont des achats de test gratuits. Un réglage Studio permet aussi de simuler la possession de chaque pass.

## 12. Tests et vérification

- **Tests unitaires Lune** (`lune run tests`) sur tous les modules de `Logic` :
  - formules et multiplicateurs ;
  - séquence des boutons ;
  - couches ;
  - conditions et effets du rebirth ;
  - tirage des œufs (somme des chances = 100 %, aléatoire injecté pour des tests déterministes) ;
  - Equip Best ;
  - série quotidienne avec horloge simulée ;
  - tirage et progression des quêtes ;
  - cadeaux ;
  - codes (casse, espaces, expiration, une seule fois) ;
  - fenêtres d'events ;
  - gains hors ligne (plafond) ;
  - format des nombres ;
  - modèle de données (défauts, migrations) ;
  - limiteur de fréquence.
- **Simulateur d'économie** (`lune run tools/simulate`) : il rejoue la progression des profils inactif, actif et Auto Push + x2 avec les vraies valeurs de `Config`. Un **test d'équilibrage** vérifie que le premier rebirth d'un joueur actif tombe entre 80 et 120 min, et qu'aucune attente entre deux achats ne dépasse 25 min avant la Couche Cosmique.
- **Contrôles statiques** : StyLua (format), Selene (lint) et luau-lsp (types), tous lancés par `scripts/check.sh`.
- **Dans Studio** : une checklist de test par phase. Elle est jouée via le MCP de Studio (partie de test, commandes Debug, captures) et en serveur local à plusieurs joueurs (Test > Clients and Servers), plus des essais sur téléphone avec le jeu publié en privé.

## 13. Phases de construction

On construit dans cet ordre. Chaque phase est jouable dans Studio et a son propre plan d'implémentation. On publie en public à la fin de la phase 6 seulement.

| Phase | Contenu | Terminée quand |
|---|---|---|
| 0. Outillage | Rokit + outils, Studio + plugin Rojo + MCP, squelette du repo, `CLAUDE.md`, runner de tests, `scripts/check.sh`, jeu publié en privé avec l'accès API | une modif de fichier apparaît dans Studio, `lune run tests` et `scripts/check.sh` passent |
| 1. Le cœur | place + 6 bases, attribution, bébé, 22 dalles, cacas + tapis + pot, clic + méga caca, couches, sauvegarde, HUD de base | on joue du biberon à la Couche Cosmique (avec Debug), on quitte, on revient, tout est là |
| 2. Progression | rebirth, leaderstats + classements mondiaux + couronnes, gains hors ligne, tutoriel, annonces | un nouveau joueur suit le tuto ; un rebirth marche ; les panneaux affichent des scores |
| 3. Monétisation | Nathan crée les 4 passes et les 6 produits dans le Creator Dashboard ; boutique, passes, ProcessReceipt, boosts, Poop Rain, Triple it, Premium | chaque achat de test donne le bon effet une seule fois, même après un rejoin |
| 4. Pets | œufs (3 + 2 d'event), tirage, animation, inventaire, équipement, suivi, bonus | ouvrir, équiper, supprimer, Equip Best marchent, et le bonus change le revenu |
| 5. Rétention | coffre quotidien, quêtes, cadeaux, codes, events, bonus amis, invitations | chaque mécanique vérifiée avec l'horloge Debug |
| 6. Finition et lancement | sons, musique, effets, traduction FR, équilibrage au simulateur, analytics, titre, icône, miniatures, description, questionnaire de maturité, publication publique | jeu public, checklist de lancement faite |

## 14. Lancement (phase 6)

- Passes et produits : nom, description, icône, prix (les IDs sont dans `Config/Monetization` depuis la phase 3).
- Icône 512 × 512 et 3 miniatures 1920 × 1080, faites à partir de captures Studio du bébé, des cacas et du pot.
- Titre, description en anglais et en français (avec les codes et les paliers de likes), genre, taille de serveur 6, appareils : téléphone, tablette, ordinateur.
- Questionnaire de maturité. L'humour caca relève de l'« humour grossier » : label attendu « Mild ».
- Traduction automatique activée pour les autres langues.
- En option : serveurs privés payants, par exemple 100 R$/mois (revenu récurrent).
- **Après le lancement** :
  - suivre les analytics Roblox (rétention J1/J7, entonnoir du tutoriel, conversion des achats) ;
  - une mise à jour toutes les 1 à 2 semaines (codes, œufs, events) ;
  - répondre aux demandes de suppression de données que Roblox transmet, en supprimant la clé du joueur ;
  - DevEx possible à partir de 30 000 Robux gagnés.

## 15. Hors périmètre (plus tard)

Console et manette, échange de pets, fusion ou pets dorés, niveaux de pets, notifications push, bonus de groupe Roblox, vrais modèles 3D (Blender), pubs récompensées, panneau d'admin en jeu, codes ajoutés sans republier, deuxième monde.
