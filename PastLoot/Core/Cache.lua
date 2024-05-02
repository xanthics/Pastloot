local PastLoot = LibStub("AceAddon-3.0"):GetAddon("PastLoot")

function PastLoot:ResetCache()
	PastLoot.EvalCache = {}
	PastLoot.TooltipCache = { tt = "", Left = {}, Right = {} }
end

local function initCache()
	if not PastLoot.EvalCache or not PastLoot.TooltipCache then
		PastLoot:ResetCache()
	end
end

local function ColorCheck(Red, Green, Blue, Alpha)
	Red = math.floor(Red * 255 + 0.5)
	Green = math.floor(Green * 255 + 0.5)
	Blue = math.floor(Blue * 255 + 0.5)
	Alpha = math.floor(Alpha * 255 + 0.5)
	return (Red == 255 and Green == 32 and Blue == 32 and Alpha == 255)
end

local function getLine(Line)
	if Line then
		local text = Line:GetText()
		local Red, Green, Blue, Alpha = Line:GetTextColor()
		if ColorCheck(Red, Green, Blue, Alpha) then
			PastLoot.TooltipCache.usable = false
		end
		return text and text or ""
	else
		return ""
	end
end

function PastLoot:BuildTooltipCache(item)
	initCache()
	if not item or not item.link then return end
	local cache = PastLoot.TooltipCache
	if item.link == cache.link then return end
	cache.Left, cache.Right = {}, {}
	cache.link = item.link
	cache.usable = true

	PastLootTT:ClearLines()
	PastLootTT:SetHyperlink(item.link)
	local ttName = PastLootTT:GetName()
	for Index = 1, PastLootTT:NumLines() do
		cache.Left[Index]  = getLine(_G[ttName .. "TextLeft" .. Index])
		cache.Right[Index] = getLine(_G[ttName .. "TextRight" .. Index])
	end
end

function PastLoot:GetItemEvaluation(item)
	initCache()
	if not item or not item.guid then return end
	local cache = PastLoot.EvalCache
	if not (cache[item.guid] and cache[item.guid]["expiresAt"] >= GetTime()) then
		if PastLoot:ValidateItemObj(item) then
			local r, m = PastLoot:EvaluateItem(item)
			cache[item.guid] = { ["itemObj"] = item, ["result"] = r, ["match"] = m, ["expiresAt"] = GetTime() +
			self.db.profile.CacheExpires }
		else
			cache[item.guid] = { ["itemObj"] = item, ["result"] = 1, ["match"] = -1, ["expiresAt"] = GetTime() + 5 }
		end
	end
	return { cache[item.guid]["result"], cache[item.guid]["match"] }
end

function PastLoot:ValidateItemObj(itemObj)
	return itemObj.name and itemObj.count and itemObj.id and itemObj.guid
end
