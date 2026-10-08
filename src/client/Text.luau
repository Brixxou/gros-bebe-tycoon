--!strict
-- Textes traduits (Localization.csv) : Text.get("Toast.NeedMore", { "1.2K" }).
-- Une clé absente renvoie la clé elle-même, pour repérer l'oubli tout de suite.
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")

local translator: Translator? = nil
local ok, result = pcall(function()
	return LocalizationService:GetTranslatorForPlayerAsync(Players.LocalPlayer)
end)
if ok then
	translator = result
end

local Text = {}

function Text.get(key: string, args: { any }?): string
	local current = translator
	if current then
		local success, text = pcall(function()
			return current:FormatByKey(key, args or {})
		end)
		if success then
			return text
		end
	end
	return key
end

return Text
