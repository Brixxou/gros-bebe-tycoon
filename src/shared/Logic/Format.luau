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
