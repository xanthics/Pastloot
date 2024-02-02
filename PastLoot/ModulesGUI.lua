local PastLoot = LibStub("AceAddon-3.0"):GetAddon("PastLoot")
local L = LibStub("AceLocale-3.0"):GetLocale("PastLoot")

-- Not using AceGUI until I decide to make my own multi-tier drop down menu widget.
-- local AceGUI = LibStub("AceGUI-3.0")

PastLoot.Prototypes = {}
PastLoot.PluginInfo = {}

-- Unused.  We can let the module unregister variables, and remove widgets from the filter list.
-- function PastLoot.Prototypes:OnDisable()
  -- ChatFrame1:AddMessage("OnDisable() Called for "..self:GetName())
  -- self:UnregisterDefaultVariables()
  -- self:RemoveWidgets()
-- end

-- Registers the default variables
-- RuleVariables = {
  -- { VariableName, Default},
  -- { VariableName, Default},
-- }
function PastLoot.Prototypes:RegisterDefaultVariables(RuleVariables)
  local Module = self:GetName()
  PastLoot.PluginInfo[Module] = PastLoot.PluginInfo[Module] or {}
  if ( type(RuleVariables) ~= "table" ) then
    return
  end
  for NewKey, NewValue in pairs(RuleVariables) do
    if ( type(NewValue) ~= "table" ) then
      return
    end
    for VariableKey, VariableValue in pairs(PastLoot.DefaultTemplate) do
      if ( NewValue[1] == VariableValue[1] ) then
        return
      end
    end
  end
  PastLoot.PluginInfo[Module].RuleVariables = PastLoot.PluginInfo[Module].RuleVariables or {}
  for Key, Value in pairs(RuleVariables) do
    -- table.insert(PastLoot.PluginInfo[self:GetName()].RuleVariables, { Value[1], PastLoot:CopyTable(Value[2]) })
    PastLoot.PluginInfo[self:GetName()].RuleVariables[Value[1]] = true
    -- table.sort(PastLoot.PluginInfo[self:GetName()].RuleVariables, function(A, B) if ( A[1] < B[1] ) then return true end end)
    table.insert(PastLoot.DefaultTemplate, { Value[1], PastLoot:CopyTable(Value[2]) })
  end
end

function PastLoot.Prototypes:UnregisterDefaultVariables()
  local Module = self:GetName()
  PastLoot.PluginInfo[Module] = PastLoot.PluginInfo[Module] or {}
  PastLoot.PluginInfo[Module].RuleVariables = PastLoot.PluginInfo[Module].RuleVariables or {}
  for VarKey, VarValue in pairs(PastLoot.PluginInfo[Module].RuleVariables) do
    for Index = #PastLoot.DefaultTemplate, 1, -1 do
      if ( PastLoot.DefaultTemplate[Index][1] == VarKey ) then
        table.remove(PastLoot.DefaultTemplate, Index)
        break
      end
    end
  end
end

-- Each Widget is a filter for PastLoot.
-- Each Filter must have: (Index refers to the index of multiple filters for the same rule)
-- GetNumFilters(RuleNum) -- Returns the number of filters for the rule
-- AddNewFilter() -- Creates a new filter for the currently selected rule
-- RemoveFilter(Index) -- Removes a filter from the currently selected rule at Index
-- DisplayWidget(Index) -- Called when the Filter is selected from the active filters list.  (Keeps to prepare/update the widget's display, does not need to do Widget:Show())
-- GetFilterText(Index) -- Gets text to be displayed for the active filter scroll frame for the Filter's Index
-- SetMatch(ItemLink, Tooltip) -- Called when a loot window is popped up with the itemlink and tooltip frame of the item.
-- GetMatch(RuleNum, Index) -- Keeps to return true/false if the loot matches this filter's index.  DO NOT RETURN INVERSE RESULTS IF EXCEPTION IS SET
-- IsException(RuleNum, Index)  -- If the filter is an exception.
-- SetException(RuleNum, Index, true/false) -- Set the exception.
function PastLoot.Prototypes:AddWidget(Widget)
  if ( type(Widget) ~= "table"
  or not Widget.GetNumFilters
  or not Widget.AddNewFilter
  or not Widget.RemoveFilter
  or not Widget.DisplayWidget
  or not Widget.GetFilterText
  or not Widget.SetMatch
  or not Widget.GetMatch
  or type(Widget.Info) ~= "table" ) then
    -- 1 = Module Text to display in filter list
    -- 2 = Tooltip info
    -- 3 = Module this belongs to.  (Set here)
    return
  end
  if ( not Widget.IsException or not Widget.SetException ) then
    Widget.IsException = PastLoot.TempIsException
    Widget.SetException = PastLoot.TempSetException
  end
  PastLoot.RuleWidgets = PastLoot.RuleWidgets or {}
  for Key, Value in pairs(PastLoot.RuleWidgets) do
    if ( Value == Widget ) then
      return
    end
  end
  local Module = self:GetName()
  Widget.Info[3] = Module
  Widget.PreferredPriority = Widget.PreferredPriority or 1000
  -- Widget.ModuleOwner = self:GetName()
  table.insert(PastLoot.RuleWidgets, Widget)
  -- PastLoot:Settings_ScrollFrame_Update()
  -- table.sort(PastLoot.RuleWidgets, function(a, b) if ( a.PreferredPriority < b.PreferredPriority ) then return true end end)
  table.sort(PastLoot.RuleWidgets, function(a, b) if ( (a.Info[3] < b.Info[3]) or ((a.Info[3] == b.Info[3]) and (a.PreferredPriority < b.PreferredPriority)) ) then return true end end)
  Widget:ClearAllPoints()
  Widget:SetPoint("TOP", PastLoot.RulesFrame.Settings, "BOTTOM", ((Widget.XPaddingLeft or 0) - (Widget.XPaddingRight or 0)) / 2, 83 - (Widget.YPaddingTop or 0))
  Widget:SetParent(PastLoot.RulesFrame.Settings)
  Widget:Hide()
  PastLoot.PluginInfo[Module] = PastLoot.PluginInfo[Module] or {}
  PastLoot.PluginInfo[Module].RuleWidgets = PastLoot.PluginInfo[Module].RuleWidgets or {}
  for Key, Value in pairs(PastLoot.PluginInfo[Module].RuleWidgets) do
    if ( Value == Widget ) then
      return
    end
  end
  table.insert(PastLoot.PluginInfo[Module].RuleWidgets, Widget)
end

function PastLoot.Prototypes:RemoveWidgets()
  local Module = self:GetName()
  PastLoot.PluginInfo[Module] = PastLoot.PluginInfo[Module] or {}
  PastLoot.PluginInfo[Module].RuleWidgets = PastLoot.PluginInfo[Module].RuleWidgets or {}
  for PluginKey, PluginValue in pairs(PastLoot.PluginInfo[Module].RuleWidgets) do
    for RuleKey, RuleValue in pairs(PastLoot.RuleWidgets) do
      if ( RuleValue == PluginValue ) then
        PluginValue:Hide()
        PluginValue:SetParent(nil)
        table.remove(PastLoot.RuleWidgets, RuleKey)
        break
      end
    end
  end
end

function PastLoot.Prototypes:AddModuleOptionTable(TableName, Table)
  local Module = self:GetName()
  if ( not PastLoot.OptionsTable.args.Modules.args[Module].args[TableName] ) then
    PastLoot.OptionsTable.args.Modules.args[Module].args[TableName] = Table
  end
end

function PastLoot.Prototypes:RemoveModuleOptionTable(TableName)
  local Module = self:GetName()
  if ( PastLoot.OptionsTable.args.Modules.args[Module].args[TableName] ) then
    PastLoot.OptionsTable.args.Modules.args[Module].args[TableName] = nil
  end
end

-- Sets a variable in the rule.  This function verifies that the variable being set is registered to the module.
function PastLoot.Prototypes:SetConfigOption(Variable, Value, RuleNum)
  local Module = self:GetName()
  RuleNum = RuleNum or PastLoot.CurrentRule
  if ( RuleNum > 0
  and Module
  and PastLoot.PluginInfo[Module]
  and PastLoot.PluginInfo[Module].RuleVariables ) then
    if ( PastLoot.PluginInfo[Module].RuleVariables[Variable] ) then
      PastLoot.db.profile.Rules[RuleNum][Variable] = Value
      PastLoot:Rules_ActiveFilters_OnScroll()
      return
    end
  end
end

-- Gets a variable from a rule.  This function does not verify that the variable belongs to the module.
function PastLoot.Prototypes:GetConfigOption(Variable, RuleNum)
  RuleNum = RuleNum or PastLoot.CurrentRule
  if ( RuleNum > 0 ) then
    return PastLoot.db.profile.Rules[RuleNum][Variable]
  end
end

function PastLoot.Prototypes:SetGlobalVariable(Variable, Value)
  local Module = self:GetName()
  if ( Module
  and PastLoot.db.global.Modules
  and PastLoot.db.global.Modules[Module] ) then
    PastLoot.db.global.Modules[Module].Vars = PastLoot.db.global.Modules[Module].Vars or {}
    PastLoot.db.global.Modules[Module].Vars[Variable] = Value
  end
end

function PastLoot.Prototypes:GetGlobalVariable(Variable)
  local Module = self:GetName()
  if ( Module
  and PastLoot.db.global.Modules
  and PastLoot.db.global.Modules[Module]
  and PastLoot.db.global.Modules[Module].Vars ) then
    return PastLoot.db.global.Modules[Module].Vars[Variable]
  end
end

function PastLoot.Prototypes:SetProfileVariable(Variable, Value)
  local Module = self:GetName()
  if ( Module
  and PastLoot.db.profile.Modules
  and PastLoot.db.profile.Modules[Module] ) then
    PastLoot.db.profile.Modules[Module].ProfileVars = PastLoot.db.profile.Modules[Module].ProfileVars or {}
    PastLoot.db.profile.Modules[Module].ProfileVars[Variable] = Value
  end
end

function PastLoot.Prototypes:GetProfileVariable(Variable)
  local Module = self:GetName()
  if ( Module
  and PastLoot.db.profile.Modules
  and PastLoot.db.profile.Modules[Module]
  and PastLoot.db.profile.Modules[Module].ProfileVars ) then
    return PastLoot.db.profile.Modules[Module].ProfileVars[Variable]
  end
end

PastLoot.Prototypes.ShowTooltip = PastLoot.ShowTooltip

-- I am going to use this function to scroll text boxes to the left instead of SetCursorPosition()
-- SetCursorPosition(0) requires I ClearFocus(), which will create a loop that I don't really like.
PastLoot.Prototypes.ScrollLeft = PastLoot.ScrollLeft

function PastLoot.Prototypes:Debug(...)
  local DebugLine, Counter
  if ( PastLoot.DebugVar == true ) then
    if ( self.GetName ) then
      DebugLine = "("..(self:GetName() or "")..") "
    else
      DebugLine = ""
    end
    for Counter = 1, select("#", ...) do
      DebugLine = DebugLine..select(Counter, ...)
    end
    -- PastLoot:Print(_G[PastLoot.db.profile.OutputFrame], DebugLine)
    PastLoot:Pour("|cff33ff99PastLoot|r: "..DebugLine)
  end
end

-- CheckDBVersion()
-- ModuleVersion - The version of the module calling this function.
-- CallbackFunc - Function to call to get a new value.
-- If the ModuleVersion is newer, then we will iterate over every rule.  We will call the callback function with the entire rule.
-- This will allow the update to get any variable data it wants from the rule to make decisions on.
-- ReturnData = {
  -- { VariableToBeSet, ValueToBeSet },
  -- { VariableToBeSet, ValueToBeSet },
-- }
-- All variables to be set will be verified that they are variables allowed to be set.
function PastLoot.Prototypes:CheckDBVersion(ModuleVersion, CallbackFunc)
  local Module = self:GetName()
  if ( Module
  and PastLoot.PluginInfo[Module]
  and PastLoot.PluginInfo[Module].RuleVariables
  and ModuleVersion
  and ( type(CallbackFunc) == "string" or type(CallbackFunc) == "function" ) ) then
    local Version, ReturnData, VariableList
    PastLoot.db.global.Modules = PastLoot.db.global.Modules or {}
    PastLoot.db.global.Modules[Module] = PastLoot.db.global.Modules[Module] or {}
    PastLoot.db.global.Modules[Module].Version = PastLoot.db.global.Modules[Module].Version or 1
    Version = PastLoot.db.global.Modules[Module].Version
    if ( Version >= ModuleVersion ) then
      return
    end
    PastLoot:Debug("Upgrading: "..Module.." from "..Version.." to "..ModuleVersion)
    VariableList = PastLoot.PluginInfo[Module].RuleVariables  -- Use only the variables that were defined.
    if ( PastLootDB and PastLootDB.profiles ) then
      for ProfileKey, ProfileValue in pairs(PastLootDB.profiles) do
      PastLoot:Debug("Checking "..ProfileKey)
        if ( ProfileValue.Rules ) then
          for RuleKey, RuleValue in ipairs(ProfileValue.Rules) do
            if ( type(CallbackFunc) == "string" ) then
              ReturnData = self[CallbackFunc](self, Version, RuleValue)
            elseif ( type(CallbackFunc) == "function" ) then
              ReturnData = CallbackFunc(Version, RuleValue)
            end
            if ( ReturnData and type(ReturnData) == "table" ) then
              for ReturnKey, ReturnValue in pairs(ReturnData) do
                if ( type(ReturnValue) == "table" and ReturnValue[1] and VariableList[ReturnValue[1]] ) then
                  PastLootDB.profiles[ProfileKey].Rules[RuleKey][ReturnValue[1]] = ReturnValue[2]
                end
              end -- ReturnKey, ReturnValue
            end
          end -- RuleKey, RuleValue
        end -- if ProfileValue.Rules
      end -- ProfileKey, ProfileValue
    elseif ( self.db and self.db.profile and self.db.profile.Rules ) then
      for RuleKey, RuleValue in ipairs(self.db.profile.Rules) do
        if ( type(CallbackFunc) == "string" ) then
          ReturnData = self[CallbackFunc](self, Version, RuleValue)
        elseif ( type(CallbackFunc) == "function" ) then
          ReturnData = CallbackFunc(Version, RuleValue)
        end
        if ( ReturnData and type(ReturnData) == "table" ) then
          for ReturnKey, ReturnValue in pairs(ReturnData) do
            if ( type(ReturnValue) == "table" and ReturnValue[1] and VariableList[ReturnValue[1]] ) then
              self.db.profile.Rules[RuleKey][ReturnValue[1]] = ReturnValue[2]
            end
          end -- ReturnKey, ReturnValue
        end
      end -- RuleKey, RuleValue
    end
    PastLoot.db.global.Modules[Module].Version = ModuleVersion
  end
end

PastLoot:SetDefaultModulePrototype(PastLoot.Prototypes)
PastLoot:SetDefaultModuleState(false)

function PastLoot:IsModuleEnabled(Info)
  return self.modules[Info.arg].enabledState
end

function PastLoot:SetModuleEnabled(Info, Value)
  local Module = Info.arg
  self.db.profile.Modules[Module].Status = Value
  if ( Value ) then
    self:EnableModule(Module)
  else
    self:DisableModule(Module)
  end
  self:CheckRuleTables()
  self:Rules_RuleList_OnScroll()
  self:DisplayCurrentRule()
  -- self:CountEnabledModules()
end

local Modules_ScrollFrame_RowSpacing = 3
local Modules_ScrollFrame_InitialHeight = 10
function PastLoot:SetupModulesOptionsTables()
  local Module
  for Key, Value in self:IterateModules() do
    Module = Value:GetName()
    self.db.profile.Modules[Module] = self.db.profile.Modules[Module] or {}
    if ( not self.OptionsTable.args.Modules.args[Module] ) then
      self.OptionsTable.args.Modules.args[Module] = {
        ["name"] = Module,
        ["type"] = "group",
        ["inline"] = true,
        ["args"] = {
          ["Enabled"] = {
            ["name"] = L["Enabled"],
            ["desc"] = L["Enable / Disable this module."],
            ["type"] = "toggle",
            ["order"] = 0,
            ["get"] = "IsModuleEnabled",
            ["set"] = "SetModuleEnabled",
            ["arg"] = Module,
          },
        },
      }
    end
  end
end

function PastLoot:TempIsException()
  return false
end

function PastLoot:TempSetException()
end
