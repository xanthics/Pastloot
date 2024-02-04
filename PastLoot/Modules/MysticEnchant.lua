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
local module_key = "MysticEnchant"
local module_name = L["Mystic Enchant"]
local module_tooltip = L["Selected rule will only match unlearned mystic enchants."]

local module = PastLoot:NewModule(module_name)

module.Choices = { {
	["Name"] = L["Any RE"],
	["Value"] = 1,
}, {
	["Name"] = L["Any RE Known"],
	["Value"] = 2,
}, {
	["Name"] = L["Any RE Unknown"],
	["Value"] = 3,
}, {
	["Name"] = L["WRE Known"],
	["Value"] = 4,
}, {
	["Name"] = L["WRE Unknown"],
	["Value"] = 5,
}, {
	["Name"] = L["Non-WRE Known"],
	["Value"] = 6,
}, {
	["Name"] = L["Non-WRE Unknown"],
	["Value"] = 7,
} }

module.ConfigOptions_RuleDefaults = { -- { VariableName, Default },
	{ module_key, {
		-- [1] = { Value, Exception }
	} } }
module.NewFilterValue = 1

function module:OnEnable()
	self:RegisterDefaultVariables(self.ConfigOptions_RuleDefaults)
	self:AddWidget(self.Widget)
	-- self:AddProfileWidget(self.Widget)
end

function module:OnDisable()
	self:UnregisterDefaultVariables()
	self:RemoveWidgets()
end

function module:CreateWidget()
	local frame_name = "PastLoot_Frames_Widgets_MysticEnchant"
	return PastLoot:CreateSimpleDropdown(self, module_name, frame_name, module_tooltip)
end

module.Widget = module:CreateWidget()

-- Local function to get the data and make sure it's valid data
function module.Widget:GetData(RuleNum)
	local Data = module:GetConfigOption(module_key, RuleNum)
	local Changed = false
	if (not Data or type(Data) ~= "table") then
		Data = {}
		Changed = true
	end
	for Key, Value in ipairs(Data) do
		if (type(Value) ~= "table" or type(Value[1]) ~= "number") then
			Data[Key] = { module.NewFilterValue, false }
			Changed = true
		end
	end
	if (Changed) then module:SetConfigOption(module_key, Data) end
	return Data
end

function module.Widget:GetNumFilters(RuleNum)
	local Value = self:GetData(RuleNum)
	return #Value
end

function module.Widget:AddNewFilter()
	local Value = self:GetData()
	table.insert(Value, { module.NewFilterValue, false })
	module:SetConfigOption(module_key, Value)
end

function module.Widget:RemoveFilter(Index)
	local Value = self:GetData()
	table.remove(Value, Index)
	module:SetConfigOption(module_key, Value)
end

function module.Widget:DisplayWidget(Index)
	if (Index) then module.FilterIndex = Index end
	local Value = self:GetData()
	if (select(4, GetBuildInfo()) < 30000) then
		UIDropDownMenu_SetText(module:GetUsableText(Value[module.FilterIndex][1]), module.Widget)
	else
		UIDropDownMenu_SetText(module.Widget, module:GetUsableText(Value[module.FilterIndex][1]))
	end
end

function module.Widget:GetFilterText(Index)
	local Value = self:GetData()
	return module:GetUsableText(Value[Index][1])
end

function module.Widget:IsException(RuleNum, Index)
	local Data = self:GetData(RuleNum)
	return Data[Index][2]
end

function module.Widget:SetException(RuleNum, Index, Value)
	local Data = self:GetData(RuleNum)
	Data[Index][2] = Value
	module:SetConfigOption("Unowned", Data)
end

function module.Widget:SetMatch(ItemLink, Tooltip)
	local Owned = 0 -- 0 means not an RE
	local itemID = GetItemInfoFromHyperlink(ItemLink)
	local enchant = C_MysticEnchant.GetEnchantInfoByItem(itemID)

	if enchant then
		if enchant.Known then
			Owned = 1 -- known will be odd
		else
			Owned = 2 -- unknown will be even
		end
		if enchant.IsWorldforged then
			Owned = Owned + 2 -- WRE will be 3 or 4
		end
	end

	module.CurrentMatch = Owned
	module:Debug("MysticEnchant: " .. Owned .. " (" .. itemID .. ")")
end

function module.Widget:GetMatch(RuleNum, Index)
	local RuleValue = self:GetData(RuleNum)
	local RuleID = RuleValue[Index][1]

	if module.CurrentMatch > 0 then
		if (RuleID == 1) or                         -- any RE
			(RuleID == 4 and module.CurrentMatch == 3) or -- wre known
			(RuleID == 5 and module.CurrentMatch == 4) or -- wre unknown
			(RuleID == 6 and module.CurrentMatch == 1) or -- non-wre known
			(RuleID == 7 and module.CurrentMatch == 2) or -- non-wre unknown
			(RuleID == 2 and module.CurrentMatch % 2 == 1) or -- re known
			(RuleID == 3 and module.CurrentMatch % 2 == 0) -- re unknown
		then
			return true
		end
	end

	return false
end

function module:DropDown_Init(Frame, Level)
	Level = Level or 1
	local info = {}
	info.checked = false
	if (select(4, GetBuildInfo()) < 30000) then
		info.func = function(...) self:DropDown_OnClick(this, ...) end
	else
		info.func = function(...) self:DropDown_OnClick(...) end
	end
	info.owner = Frame
	for Key, Value in ipairs(self.Choices) do
		info.text = Value.Name
		info.value = Value.Value
		UIDropDownMenu_AddButton(info, Level)
	end
end

function module:DropDown_OnClick(Frame)
	local Value = self.Widget:GetData()
	Value[self.FilterIndex][1] = Frame.value
	self:SetConfigOption(module_key, Value)
	if (select(4, GetBuildInfo()) < 30000) then
		UIDropDownMenu_SetText(Frame:GetText(), Frame.owner)
	else
		UIDropDownMenu_SetText(Frame.owner, Frame:GetText())
	end
end

function module:GetUsableText(ID)
	for Key, Value in ipairs(self.Choices) do if (Value.Value == ID) then return Value.Name end end
	return ""
end
