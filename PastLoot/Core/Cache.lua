local PastLoot = LibStub("AceAddon-3.0"):GetAddon("PastLoot")

local function initCache()
	if not PastLoot.EvalCache then
		PastLoot.EvalCache = {}
	end
	if not PastLoot.TooltipCache then
		PastLoot.TooltipCache = {tt="",Left={},Right={}}
	end
end

local function getLine(line)
	if line then
		local text = line:GetText()
		return text and text or ""
	else
		return ""
	end
end

function PastLoot:BuildTooltipCache(item)
	initCache()
	if not item or not item.link then return end
	local cache = PastLoot.TooltipCache
	if item.link == cache.tt then return end
	cache.Left, cache.Right = {}, {}
	cache.tt = item.link

	PastLootTT:ClearLines()
	PastLootTT:SetHyperlink(item.link)
	local ttName = PastLootTT:GetName()
	for Index = 1, PastLootTT:NumLines() do
		cache.Left[Index]  = getLine( _G[ttName .. "TextLeft"  .. Index] )
		cache.Right[Index] = getLine( _G[ttName .. "TextRight" .. Index] )
	end
end

function PastLoot:GetItemEvaluation(item)
	initCache()
	if not item or not item.link then return end
	local cache = PastLoot.EvalCache
	local result = cache[item.link]
	if not result then 
		result = {PastLoot:EvaluateItem(item)}
		cache[item.link] = result
	end
	return result
end
