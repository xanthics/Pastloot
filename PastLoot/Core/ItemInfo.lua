local PastLoot = LibStub("AceAddon-3.0"):GetAddon("PastLoot")

--[[
	Remix of Ascension code for the following functions
	-- IsItemBloodforged
	-- IsItemHeroic
	-- IsItemMythic
	-- IsItemAscended
	-- GetItemMythicLevel
]]
local function processItemFlavorText(item)
	local flavor = GetItemFlavorText(item.id)

	item.isBloodforged = flavor:find("Bloodforged", 1, true) ~= nil
	item.isHeroic = flavor:find("Heroic", 1, true) ~= nil
	if not item.isHeroic then
		item.isMythic = flavor:find("Mythic", 1, true) ~= nil
		if not item.isMythic then
			item.isAscended = flavor:find("Ascended", 1, true) ~= nil
		end
	end
	local level
	if item.isMythic then
		level = flavor:match("Mythic (%d*)")
		level = level and tonumber(level)
	end

	item.mythicLevel = level or 0 -- 0 means not a Mythic+ item
end

local function fillItemInfo(item)
	local name, _, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(item.link)
	item.name = name
	item.quality = quality
	item.iLevel = iLevel
	item.reqLevel = reqLevel or 0
	item.class = class
	item.subclass = subclass
	item.maxStack = maxStack
	item.equipSlot = equipSlot
	item.texture = texture
	item.vendorPrice = vendorPrice
	return item
end

function PastLoot:FillContainerItemInfo(item, bag, slot)
	local _, count, locked, _, readable, lootable, link = GetContainerItemInfo(bag, slot)
	if item == nil and link ~= nil then item = self:InitItem(link) else return end

	item.bag = bag
	item.slot = slot
	item.count = count
	item.locked = locked
	item.readable = readable
	item.lootable = lootable
	item.guid = GetContainerItemGUID(bag, slot)
	item.stackValue = count * (item.vendorPrice or 1)
	return item
end

function PastLoot:InitItem(link)
	if not link then return end

	local item = {}
	item.link = link
	item.id = GetItemInfoFromHyperlink(link)
	item = fillItemInfo(item)
	-- set some defaults since these are checked later if item flavor text isn't processed
	item.isBloodforged = false
	item.isHeroic = false
	item.isMythic = false
	item.isAscended = false
	item.mythicLevel = 0 -- 0 means not a Mythic+ item
	if item.equipSlot and item.equipSlot ~= "" then processItemFlavorText(item) end
	return item
end
