local PastLoot = LibStub("AceAddon-3.0"):GetAddon("PastLoot")
local L = LibStub("AceLocale-3.0"):GetLocale("PastLoot")
local module = PastLoot:NewModule(L["Quality"])

module.Choices = {
  L["Any"],
  ITEM_QUALITY_COLORS[0].hex..ITEM_QUALITY0_DESC.."|r", --Poor
  ITEM_QUALITY_COLORS[1].hex..ITEM_QUALITY1_DESC.."|r", --Common
  ITEM_QUALITY_COLORS[2].hex..ITEM_QUALITY2_DESC.."|r", --Uncommon
  ITEM_QUALITY_COLORS[3].hex..ITEM_QUALITY3_DESC.."|r", --Rare
  ITEM_QUALITY_COLORS[4].hex..ITEM_QUALITY4_DESC.."|r", --Epic
  ITEM_QUALITY_COLORS[5].hex..ITEM_QUALITY5_DESC.."|r", --Legendary
  ITEM_QUALITY_COLORS[6].hex..ITEM_QUALITY6_DESC.."|r", --Artifact
  ITEM_QUALITY_COLORS[7].hex..ITEM_QUALITY7_DESC.."|r" -- Vanity
}
module.ConfigOptions_RuleDefaults = {
  -- { VariableName, Default },
  {
    "Quality",
    -- {
      -- [1] = { Value, Exception }
    -- },
  },
}
module.NewFilterValue = 1

function module:OnEnable()
  self:RegisterDefaultVariables(self.ConfigOptions_RuleDefaults)
  self:AddWidget(self.Widget)
end

function module:OnDisable()
  self:UnregisterDefaultVariables()
  self:RemoveWidgets()
end

function module:CreateWidget()
  local Widget = CreateFrame("Frame", "PastLoot_Frames_Widgets_Quality", nil, "UIDropDownMenuTemplate")
  Widget:EnableMouse(true)
  Widget:SetHitRectInsets(15, 15, 0 ,0)
  _G[Widget:GetName().."Text"]:SetJustifyH("CENTER")
  if ( select(4, GetBuildInfo()) < 30000 ) then
    UIDropDownMenu_SetWidth(120, Widget)
  else
    UIDropDownMenu_SetWidth(Widget, 120)
  end
  Widget:SetScript("OnEnter", function() self:ShowTooltip(L["Quality"], L["Selected rule will only match this quality of items."]) end)
  Widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
  local Button = _G[Widget:GetName().."Button"]
  Button:SetScript("OnEnter", function() self:ShowTooltip(L["Quality"], L["Selected rule will only match this quality of items."]) end)
  Button:SetScript("OnLeave", function() GameTooltip:Hide() end)
  local Title = Widget:CreateFontString(Widget:GetName().."Title", "BACKGROUND", "GameFontNormalSmall")
  Title:SetParent(Widget)
  Title:SetPoint("BOTTOMLEFT", Widget, "TOPLEFT", 20, 0)
  Title:SetText(L["Quality"])
  Widget:SetParent(nil)
  Widget:Hide()
  if ( select(4, GetBuildInfo()) < 30000 ) then
    Widget.initialize = function(...) self:DropDown_Init(Widget, ...) end
  else
    Widget.initialize = function(...) self:DropDown_Init(...) end
  end
  Widget.YPaddingTop = Title:GetHeight()
  Widget.Height = Widget:GetHeight() + Widget.YPaddingTop
  Widget.XPaddingLeft = -15
  Widget.XPaddingRight = -15
  Widget.Width = Widget:GetWidth() + Widget.XPaddingLeft + Widget.XPaddingRight
  Widget.PreferredPriority = 3
  Widget.Info = {
    L["Quality"],
    L["Selected rule will only match this quality of items."],
  }
  return Widget
end
module.Widget = module:CreateWidget()

-- Local function to get the data and make sure it's valid data
function module.Widget:GetData(RuleNum)
  local Data = module:GetConfigOption("Quality", RuleNum)
  local Changed = false
  if ( Data ) then
    if ( type(Data) == "table" and #Data > 0 ) then
      for Key, Value in ipairs(Data) do
        if ( type(Value) ~= "table" or type(Value[1]) ~= "number" ) then
          Data[Key] = { module.NewFilterValue, false }
          Changed = true
        end
      end
    else
      Data = nil
      Changed = true
    end
  end
  if ( Changed ) then
    module:SetConfigOption("Quality", Data)
  end
  return Data or {}
end

function module.Widget:GetNumFilters(RuleNum)
  local Value = self:GetData(RuleNum)
  return #Value
end

function module.Widget:AddNewFilter()
  local Value = self:GetData()
  table.insert(Value, { module.NewFilterValue, false })
  module:SetConfigOption("Quality", Value)
end

function module.Widget:RemoveFilter(Index)
  local Value = self:GetData()
  table.remove(Value, Index)
  if ( #Value == 0 ) then
    Value = nil
  end
  module:SetConfigOption("Quality", Value)
end

function module.Widget:DisplayWidget(Index)
  if ( Index ) then
    module.FilterIndex = Index
  end
  local Value = self:GetData()
  if ( select(4, GetBuildInfo()) < 30000 ) then
    UIDropDownMenu_SetText(module.Choices[Value[module.FilterIndex][1]], module.Widget)
  else
    UIDropDownMenu_SetText(module.Widget, module.Choices[Value[module.FilterIndex][1]])
  end
end

function module.Widget:GetFilterText(Index)
  local Value = self:GetData()
  return module.Choices[Value[Index][1]]
end

function module.Widget:IsException(RuleNum, Index)
  local Data = self:GetData(RuleNum)
  return Data[Index][2]
end

function module.Widget:SetException(RuleNum, Index, Value)
  local Data = self:GetData(RuleNum)
  Data[Index][2] = Value
  module:SetConfigOption("Quality", Data)
end

function module.Widget:SetMatch(ItemLink, Tooltip)
  local _, _, Quality, _, _, _, _, _, _, _ = GetItemInfo(ItemLink)
  module.CurrentMatch = Quality
  module:Debug("Quality Type: "..(Quality or "nil"))
end

function module.Widget:GetMatch(RuleNum, Index)
  local RuleValue = self:GetData(RuleNum)
  if ( RuleValue[Index][1] > 1 ) then
    if ( RuleValue[Index][1] - 2 ~= tonumber(module.CurrentMatch) ) then
      return false
    end
  end
  return true
end

function module:DropDown_Init(Frame, Level)
  Level = Level or 1
  local info = {}
  info.checked = false
  info.notCheckable = true
  if ( select(4, GetBuildInfo()) < 30000 ) then
    info.func = function(...) self:DropDown_OnClick(this, ...) end
  else
    info.func = function(...) self:DropDown_OnClick(...) end
  end
  info.owner = Frame
  for Key, Value in ipairs(self.Choices) do
    info.text = Value
    info.value = Key
    UIDropDownMenu_AddButton(info, Level)
  end
end

function module:DropDown_OnClick(Frame)
  local Value = self.Widget:GetData()
  Value[self.FilterIndex][1] = Frame.value
  self:SetConfigOption("Quality", Value)
  if ( select(4, GetBuildInfo()) < 30000 ) then
    UIDropDownMenu_SetText(Frame:GetText(), Frame.owner)
  else
    UIDropDownMenu_SetText(Frame.owner, Frame:GetText())
  end
end
