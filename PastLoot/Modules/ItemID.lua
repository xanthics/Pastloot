local PastLoot = LibStub("AceAddon-3.0"):GetAddon("PastLoot")
local L = LibStub("AceLocale-3.0"):GetLocale("PastLoot_Modules")
local module = PastLoot:NewModule(L["Item ID"])

module.ConfigOptions_RuleDefaults = {
  -- { VariableName, Default },
  {
    "ItemIDs",
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
  local Widget = CreateFrame("Frame", "PastLoot_Frames_Widgets_ItemID")
  local TextBox = CreateFrame("EditBox", "PastLoot_Frames_Widgets_ItemIDTextBox")
  TextBox:SetBackdrop({
    ["bgFile"] = "Interface\\Tooltips\\UI-Tooltip-Background",
    ["edgeFile"] = "Interface\\Tooltips\\UI-Tooltip-Border",
    ["tile"] = true,
    ["insets"] = {
      ["top"] = 5,
      ["bottom"] = 5,
      ["left"] = 5,
      ["right"] = 5,
    },
    ["tileSize"] = 32,
    ["edgeSize"] = 16,
  })
  TextBox:SetBackdropColor(0, 0, 0, 0.95)
  TextBox:SetFontObject(ChatFontNormal)
  TextBox:SetTextInsets(6, 6, 6, 6)
  TextBox:SetHeight(26)
  TextBox:SetWidth(160)
  TextBox:SetMaxLetters(200)
  -- TextBox:SetHistoryLines(0)
  TextBox:SetAutoFocus(false)
  TextBox:SetScript("OnEnter", function() self:ShowTooltip(L["Item ID"], L["Selected rule will match on item names."]) end)
  TextBox:SetScript("OnLeave", function() GameTooltip:Hide() end)
  TextBox:SetScript("OnEscapePressed", function(Frame) Frame:ClearFocus() end)
  TextBox:SetScript("OnEditFocusGained", function(Frame) Frame:HighlightText() end)
  TextBox:SetScript("OnEditfocusLost", function(Frame)
    Frame:HighlightText(0, 0)
    self.Widget:DisplayWidget()
  end)
  TextBox:SetScript("OnEnterPressed", function(Frame)
    self:SetItemID(Frame)
    Frame:ClearFocus()
  end)
  local Title = TextBox:CreateFontString(TextBox:GetName().."Title", "BACKGROUND", "GameFontNormalSmall")
  Title:SetParent(TextBox)
  Title:SetPoint("BOTTOMLEFT", TextBox, "TOPLEFT", 3, 0)
  Title:SetText(L["Item ID"])
  TextBox:SetParent(Widget)
  TextBox:SetPoint("BOTTOMLEFT", Widget, "BOTTOMLEFT", 0, 0)
  Widget.TextBox = TextBox

  Widget:Hide()
  Widget:SetHeight(TextBox:GetHeight())
  Widget.YPaddingTop = Title:GetHeight() + 1
  Widget.YPaddingBottom = 4
  Widget.Height = Widget:GetHeight() + Widget.YPaddingTop + Widget.YPaddingBottom
  Widget:SetWidth(TextBox:GetWidth() + 30)
  Widget.PreferredPriority = 14
  Widget.Info = {
    L["Item ID"],
    L["Selected rule will match on item names."],
  }
  return Widget
end
module.Widget = module:CreateWidget()

-- Local function to get the data and make sure it's valid data
function module.Widget:GetData(RuleNum)
  local Data = module:GetConfigOption("ItemIDs", RuleNum)
  local Changed = false
  if ( Data ) then
    if ( type(Data) == "table" and #Data > 0 ) then
      for Key, Value in ipairs(Data) do
        if ( type(Value) ~= "table" or type(Value[1]) ~= "string" ) then
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
  end
  if ( Changed ) then
    module:SetConfigOption("ItemIDs", Data)
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
  module:SetConfigOption("ItemIDs", Value)
end

function module.Widget:RemoveFilter(Index)
  local Value = self:GetData()
  table.remove(Value, Index)
  if ( #Value == 0 ) then
    Value = nil
  end
  module:SetConfigOption("ItemIDs", Value)
end

function module.Widget:DisplayWidget(Index)
  if ( Index ) then
    module.FilterIndex = Index
  end
  local Value = self:GetData()
  if ( not Value or not Value[module.FilterIndex] ) then
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
  module:SetConfigOption("ItemIDs", Data)
end

function module.Widget:SetMatch(ItemLink, Tooltip)
  module.CurrentMatch = select(3, ItemLink:find("item:(%d-):"))
  module:Debug("Item ID: "..(module.CurrentMatch or ""))
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

function module:SetItemID(Frame)
  local Value = self.Widget:GetData()
  Value[self.FilterIndex][1] = Frame:GetText()
  self:SetConfigOption("ItemIDs", Value)
end
