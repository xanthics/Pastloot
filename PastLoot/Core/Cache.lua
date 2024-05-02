local PastLoot = LibStub("AceAddon-3.0"):GetAddon("PastLoot")

function PastLoot:ResetCache()
	PastLoot.EvalCache = {}
	PastLoot.TooltipCache = {tt="",Left={},Right={}}
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

local function getLine(line)
	if line then
		local text = line:GetText()
		local Red, Green, Blue, Alpha = line:GetTextColor()
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
		cache.Left[Index]  = getLine( _G[ttName .. "TextLeft"  .. Index] )
		cache.Right[Index] = getLine( _G[ttName .. "TextRight" .. Index] )
	end
end

function PastLoot:GetItemEvaluation(item)
	initCache()
	if not item or not item.guid then return end
	local cache = PastLoot.EvalCache
	local result
	if cache[item.guid] and cache[item.guid]["lastUpdate"] + 900 >= GetTime() then
		result = {cache[item.guid]["result"], cache[item.guid]["match"]}
	else -- not cache[item.guid]
		local r, m = PastLoot:EvaluateItem(item)
		result = {r, m}
		cache[item.guid] = {["itemObj"] = item, ["result"] = r, ["match"] = m, ["lastUpdate"] = GetTime()}
	end
	return result
end
