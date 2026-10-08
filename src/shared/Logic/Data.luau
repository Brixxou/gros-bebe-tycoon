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
