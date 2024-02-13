local PastLoot = LibStub("AceAddon-3.0"):GetAddon("PastLoot")
local L = LibStub("AceLocale-3.0"):GetLocale("PastLoot")

--[[
Checklist if creating a new module
- first choose an existing module that most closely matches what you want to do
- modify module_key, module_name, module_tooltip to unique values
- make sure to update locales
- Modify SetMatch and GetMatch
- Create/Modify local functions as needed
]]
local module_key = "ItemIDs"
local module_name = L["Item ID"]
local module_tooltip = L["Selected rule will match on item names."]

local module = PastLoot:NewModule(module_name)

module.ConfigOptions_RuleDefaults = {
	-- { VariableName, Default },
	{
		module_key,
		-- {
		-- [1] = { Name, Type, Exception }
		-- },
	},
}
module.NewFilterValue_ID = L["Temp Item ID"]

function module:OnEnable()
	self:RegisterDefaultVariables(self.ConfigOptions_RuleDefaults)
	self:AddWidget(self.Widget)
end

function module:OnDisable()
	self:UnregisterDefaultVariables()
	self:RemoveWidgets()
end

function module:CreateWidget()
	local frame_name = "PastLoot_Frames_Widgets_ItemID"
	return PastLoot:CreateTextBoxOptionalCheckBox(self, module_name, frame_name, module_tooltip)
end

module.Widget = module:CreateWidget()

local function compare(a, b)
	return a[1]:lower() < b[1]:lower()
end

-- return true if the tables are different
local function simplediff(a, b)
	if #a ~= #b then return true end
	for i=1, #a do
		if a[i][1] ~= b[i][1] then return true end
	end
	return false
end

local function simplecopytable(a)
	if ( not a or type(a) ~= "table" ) then
		return a
	end
	local b
	b = {}
	for k, v in pairs(a) do
		if ( type(v) ~= "table" ) then
			b[k] = v
		else
			b[k] = simplecopytable(v)
		end
	end
	return b
end

-- Local function to get the data and make sure it's valid data
function module.Widget:GetData(RuleNum)
	local Data = module:GetConfigOption(module_key, RuleNum)
	local Changed = false
	if (Data) then
		if (type(Data) == "table" and #Data > 0) then
			for Key, Value in ipairs(Data) do
				if (type(Value) ~= "table" or type(Value[1]) ~= "string") then
					Data[Key] = {
						module.NewFilterValue_ID,
						false
					}
					Changed = true
				end
			end
		else
			Data = nil
			Changed = true
		end
		-- remove duplicates
		local temp = simplecopytable(Data)
		local hash = {}
		Data = {}

		for _, v in ipairs(temp) do
			if (not hash[v[1]]) then
				Data[#Data + 1] = v
				hash[v] = true
			end
		end
		table.sort(Data, compare)
		if simplediff(temp, Data) then Changed = true end
	end
	if (Changed) then
		module:SetConfigOption(module_key, Data)
	end
	return Data or {}
end

function module.Widget:GetNumFilters(RuleNum)
	local Value = self:GetData(RuleNum)
	return #Value
end

function module.Widget:AddNewFilter()
	local Value = self:GetData()
	local NewTable = {
		module.NewFilterValue_ID,
		false
	}
	table.insert(Value, NewTable)
	module:SetConfigOption(module_key, Value)
end

function module.Widget:RemoveFilter(Index)
	local Value = self:GetData()
	table.remove(Value, Index)
	if (#Value == 0) then
		Value = nil
	end
	module:SetConfigOption(module_key, Value)
end

function module.Widget:DisplayWidget(Index)
	if (Index) then
		module.FilterIndex = Index
	end
	local Value = self:GetData()
	if (not Value or not Value[module.FilterIndex]) then
		return
	end
	module.Widget.TextBox:SetText(Value[module.FilterIndex][1])
	module.Widget.TextBox:SetScript("OnUpdate", function(...) module:ScrollLeft(...) end)
end

function module.Widget:GetFilterText(Index)
	local Value = self:GetData()
	return Value[Index][1]
end

function module.Widget:IsException(RuleNum, Index)
	local Data = self:GetData(RuleNum)
	return Data[Index][3]
end

function module.Widget:SetException(RuleNum, Index, Value)
	local Data = self:GetData(RuleNum)
	Data[Index][3] = Value
	module:SetConfigOption(module_key, Data)
end

function module.Widget:SetMatch(itemObj, Tooltip)
	module.CurrentMatch = itemObj.id
	module:Debug("Item ID: " .. (module.CurrentMatch or ""))
end

function module.Widget:GetMatch(RuleNum, Index)
	local RuleValue = self:GetData(RuleNum)
	local ID = RuleValue[Index][1], RuleValue[Index][2]
	if module.CurrentMatch == ID then
		module:Debug("Found item ID match")
		return true
	end

	return false
end

-- should be SetItemID, but trying to template the Widget creation
function module:SetItemName(Frame)
	local Value = self.Widget:GetData()
	Value[self.FilterIndex][1] = Frame:GetText()
	self:SetConfigOption(module_key, Value)
end
