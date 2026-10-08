--!strict
-- Classements mondiaux (spec, section 4).
return {
	size = 50, -- top 50 sur chaque panneau
	refreshSeconds = 120, -- les panneaux relisent les classements toutes les 2 min
	writeSeconds = 300, -- les scores des joueurs présents sont écrits toutes les 5 min
	crownColors = { "#FFD700", "#C0C0C0", "#CD7F32" }, -- couronnes du top 3 : or, argent, bronze
}
