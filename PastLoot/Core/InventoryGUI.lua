local PastLoot = LibStub("AceAddon-3.0"):GetAddon("PastLoot")
local L = LibStub("AceLocale-3.0"):GetLocale("PastLoot")
local AceGUI = LibStub("AceGUI-3.0")
local ScrollingTable = LibStub("ScrollingTable")

local rowHeight = 32
local cols = {
	{
		["name"] = "Type",
		["width"] = 100,
		["align"] = "CENTER",
		["color"] = {
			["r"] = 1,
			["g"] = 1,
			["b"] = 1.0,
			["a"] = 1.0
		},
	},
	{
		["name"] = "Filter",
		["width"] = 150,
		["align"] = "CENTER",
		["color"] = {
			["r"] = 1,
			["g"] = 1,
			["b"] = 1.0,
			["a"] = 1.0
		},
	},
	{
		["name"] = "Icon",
		["width"] = 32,
		["align"] = "CENTER",
		["color"] = {
			["r"] = 1,
			["g"] = 1,
			["b"] = 1.0,
			["a"] = 1.0
		},
	},
	{
		["name"] = "iLvl",
		["width"] = 32,
		["align"] = "CENTER",
		["color"] = {
			["r"] = 1,
			["g"] = 1,
			["b"] = 1.0,
			["a"] = 1.0
		},
	},
	{
		["name"] = "Item Name",
		["width"] = 200,
		["align"] = "CENTER",
		["color"] = {
			["r"] = 1,
			["g"] = 1,
			["b"] = 1.0,
			["a"] = 1.0
		},
	},
	{
		["name"] = "ID",
		["width"] = 0,
		["align"] = "LEFT",
		["color"] = {
			["r"] = 1,
			["g"] = 1,
			["b"] = 1.0,
			["a"] = 1.0
		},
	}
}

local InventoryList
local function createInventoryGui()
	local containingFrame = AceGUI:Create("Frame")
	containingFrame:SetTitle("Filter Display")
	containingFrame:SetWidth(500)
	containingFrame:SetHeight(700)
	containingFrame:SetLayout("Flow")

	InventoryList = ScrollingTable:CreateST(cols, 15, rowHeight, nil, containingFrame.frame)
	InventoryList.frame:SetPoint("TOPLEFT", containingFrame.frame, "TOPLEFT", 15, -50)

	containingFrame:SetCallback("OnClose", function(widget)
		AceGUI:Release(widget)
		InventoryList:Hide()
		InventoryList.frame = nil
		InventoryList = nil
		PastLoot.InventoryGUI = nil
	end)

	PastLoot.InventoryGUI = containingFrame
end

local function updateInventoryTable()
	local data = PastLoot.InventoryCache
	InventoryList:SetData(data, true)
end

function PastLoot:OpenInventoryGui()
	if PastLoot.InventoryGUI and PastLoot.InventoryGUI:IsVisible() then return end
	if not PastLoot.InventoryGUI then createInventoryGui() end
	if not PastLoot.InventoryCache then PastLoot:UpdateInventoryCache() else updateInventoryTable() end
	PastLoot.InventoryGUI:Show()
end

function PastLoot:UpdateInventoryCache()
	PastLoot.InventoryCache = {}
	for _, bag in ipairs(PastLoot.bags) do
		for slot = 1, GetContainerNumSlots(bag) do
			local item = PastLoot:FillContainerItemInfo(nil, bag, slot)
			if item and item.link then
				local result, ruleKey = PastLoot:EvaluateItem(item)
				local rule = result == 1 and "Keep" or result == 2 and "Vendor" or result == 3 and "Destroy" or " No Rule"
				local keyText = ruleKey and self.db.profile.Rules[ruleKey].Desc or "-"
				local textureString = format("|T%s:%d:%d|t", item.texture, rowHeight, rowHeight)
				local entry = { rule, keyText, textureString, item.iLevel, item.link, item.id }
				table.insert(PastLoot.InventoryCache, entry)
			end
		end
	end

	if PastLoot.InventoryGUI:IsVisible() then updateInventoryTable() end
end
