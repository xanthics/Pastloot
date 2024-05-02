local PastLoot = LibStub("AceAddon-3.0"):GetAddon("PastLoot")

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

function PastLoot:FillContainerItemInfo(item,bag,slot)
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
	return item
end
