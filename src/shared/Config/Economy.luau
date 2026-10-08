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
