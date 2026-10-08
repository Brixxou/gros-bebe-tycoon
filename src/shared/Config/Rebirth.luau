--!strict
-- Rebirth (spec, section 4). Le bonus de PoopCoins (+50 % par rebirth) est dans Config/Economy.
return {
	base = 30e9, -- PoopCoins à avoir en poche pour le 1er rebirth…
	growth = 1.6, -- …multipliés par 1,6 à chaque rebirth déjà fait
	binkiesPerRebirth = 25, -- 25 × (nouveau nombre de rebirths) Tétines
	milestones = { 10, 25, 50 }, -- rebirths annoncés à tout le serveur
}
