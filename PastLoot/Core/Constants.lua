local L = LibStub("AceLocale-3.0"):GetLocale("PastLoot")
local PastLoot = LibStub("AceAddon-3.0"):GetAddon("PastLoot")

PastLoot.DefaultTemplate = {
	{ "Desc", L["Temp Description"] },
	{ "Loot", {  -- Choices: "Keep", "Vendor", "destroy", disabled is an empty table
		-- [1] = "keep",
		-- [2] = "vendor",
		-- [3] = "destroy",
	} },
}
PastLoot.FontGold = "|cffffcc00"
PastLoot.FontWhite = "|cffffffff"
PastLoot.FontGray = "|cff736f6e"
PastLoot.FontRed = "|cffff0000"
PastLoot.NumRuleListLines = 6
PastLoot.NumItemListLines = 5
PastLoot.RuleListLineHeight = 16
PastLoot.ItemListLineHeight = 16
PastLoot.NumFilterLines = 8
PastLoot.FilterLineHeight = 16
PastLoot.RollOrder = { "keep", "vendor", "destroy" }
PastLoot.RollOrderToIndex = {}
for Key, Value in pairs(PastLoot.RollOrder) do
	PastLoot.RollOrderToIndex[Value] = Key
end
-- PastLoot.RollMsg = {
	-- ["keep"] = L["keeping %item% (%rule%)"],
	-- ["vendor"] = L["vendoring %item% (%rule%)"],
	-- ["destroy"] = L["destroying %item% (%rule%)"],
	-- ["ignore"] = L["Ignoring %item% (%rule%)"],
-- }
PastLoot.RollMethod = {
	["keep"] = 1,
	["vendor"] = 2,
	["destroy"] = 3,
}
--[===[@debug@
PastLoot.DebugVar = true
--@end-debug@]===]