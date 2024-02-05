﻿local PastLoot = LibStub("AceAddon-3.0"):GetAddon("PastLoot")
local L = LibStub("AceLocale-3.0"):GetLocale("PastLoot")
--[[
Checklist if creating a new module
- first choose an existing module that most closely matches what you want to do
- modify module_key, module_name, module_tooltip to unique values
- make sure to update locales
- Modify SetMatch and GetMatch
- Create/Modify local functions as needed
]]
local module_key = "Vanity"
local module_name = L["Vanity Unlock"]
local module_tooltip = L["Selected rule will only match unlearned vanity items."]

local module = PastLoot:NewModule(module_name)

module.Choices = { {
	["Name"] = L["Any"],
	["Value"] = 1,
}, {
	["Name"] = L["Owned"],
	["Value"] = 2,
}, {
	["Name"] = L["Unowned"],
	["Value"] = 3,
} }

module.ConfigOptions_RuleDefaults = {
	-- { VariableName, Default },
	{
		module_key,
		-- {
		-- [1] = { Value, Exception }
		-- },
	},
}
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
	local frame_name = "PastLoot_Frames_Widgets_Vanity"
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
	if (#Value == 0) then
		Value = nil
	end
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

function module.Widget:SetMatch(itemObj, Tooltip)
	local Owned = 0
	if VANITY_ITEMS[itemObj.id] then
		if C_VanityCollection.IsCollectionItemOwned(itemObj.id) then
			Owned = 2
		else
			Owned = 3
		end
	end

	module.CurrentMatch = Owned
	module:Debug("Vanity: " .. Owned .. " (" .. itemObj.link .. ")")
end

function module.Widget:GetMatch(RuleNum, Index)
	local RuleValue = self:GetData(RuleNum)
	if (RuleValue[Index][1] == 1 and module.CurrentMatch > 0) or -- rule is "any" and item contains a vanity line
		(RuleValue[Index][1] > 1 and RuleValue[Index][1] == module.CurrentMatch) then
		return true
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
