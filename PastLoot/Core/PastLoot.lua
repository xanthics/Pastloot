local VERSION = "4.1 r135"
PastLoot = LibStub("AceAddon-3.0"):NewAddon("PastLoot", "AceConsole-3.0", "AceEvent-3.0", "LibSink-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("PastLoot")
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
-- local LDBIcon = LibStub("LibDBIcon-1.0")
local AceTimer = LibStub('AceTimer-3.0')
function AceTimer:delay_rollOnLoot(RollID, RollMethod) RollOnLoot(RollID, RollMethod) end

local defaults = {
  ["profile"] = {
    ["Quiet"] = false,
    ["AllowMultipleConfirmPopups"] = false,
    ["Rules"] = {},
    ["Modules"] = {},
    ["SinkOptions"] = {},
    -- ["WindowPos"] = {  -- Unused after moving Everything to Blizz Options Frame
      -- ["X"] = nil,
      -- ["Y"] = nil,
    -- },
    ["SkipRules"] = false,
    ["SkipWarning"] = true,
    ["DisplayUnknownVars"] = true,
    ["MessageText"] = {
      ["keep"] = L["keeping %item% (%rule%)"],
      ["vendor"] = L["vendoring %item% (%rule%)"],
      ["destroy"] = L["destroying %item% (%rule%)"],
      ["ignore"] = L["Ignoring %item% (%rule%)"],
    },
  },
}

PastLoot.OptionsTable = {
  ["type"] = "group",
  ["handler"] = PastLoot,
  ["get"] = "OptionsGet",
  ["set"] = "OptionsSet",
  ["args"] = {
    ["Menu"] = {
      ["name"] = L["Menu"],
      ["desc"] = L["Opens the PastLoot Menu."],
      ["type"] = "execute",
      ["func"] = function()
        InterfaceOptionsFrame_OpenToCategory(L["PastLoot"])
      end,
    },
    ["Test"] = {
      ["name"] = L["Test"],
      ["desc"] = L["Test an item link to see how we would roll"],
      ["type"] = "input",
      ["get"] = function() end,
      ["set"] = function(info, value)
        _, PastLoot.TestLink = GetItemInfo(value)
        if ( PastLoot.TestLink ) then
          PastLoot.TestCanKeep, PastLoot.TestCanVendor, PastLoot.TestCanDestroy = true, true, true
          PastLoot:EvaluateItem(PastLoot.TestLink)
        else
          PastLoot.TestLink = nil  -- to make sure
        end
      end,
    },
    ["TestAll"] = {
      ["name"] = L["TestAll"],
      ["desc"] = L["Test all items currently in your inventory"],
      ["type"] = "input",
      ["get"] = function() end,
      ["set"] = function(info)
        for bag=0,4 do
          for slot=1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag,slot)
            if itemLink then
              _, PastLoot.TestLink = GetItemInfo(itemLink)
              if ( PastLoot.TestLink ) then
                PastLoot.TestCanKeep, PastLoot.TestCanVendor, PastLoot.TestCanDestroy = true, true, true
                PastLoot:EvaluateItem(PastLoot.TestLink)
              else
                PastLoot.TestLink = nil  -- to make sure
              end
            end
          end
        end
      end,
    },
    ["Options"] = {
      ["name"] = L["Options"],
      ["desc"] = L["General Options"],
      ["type"] = "group",
      ["args"] = {
        ["Enable"] = {
          ["name"] = L["Enable Mod"],
          ["desc"] = L["Enable or disable this mod."],
          ["type"] = "toggle",
          ["order"] = 0,
          ["get"] = "IsEnabled",
          ["set"] = function(info, v)
            if ( v ) then
              PastLoot:Enable()
            else
              PastLoot:Disable()
            end
          end,
        },
        ["Messages"] = {
          ["name"] = L["Messages"],
          ["type"] = "group",
          ["order"] = 10,
          ["inline"] = true,
          ["args"] = {
            ["Quiet"] = {
              ["name"] = L["Quiet"],
              ["desc"] = L["Checking this will prevent extra details from being displayed."],
              ["type"] = "toggle",
              ["order"] = 0,
              ["arg"] = { "Quiet" },
            },
            ["RollKeep"] = {
              ["name"] = L["Keep"],
              ["desc"] = L["Enter the text displayed when rolling."],
              ["type"] = "input",
              ["order"] = 10,
              ["arg"] = { "MessageText", "keep" },
            },
            ["RollVendor"] = {
              ["name"] = L["Vendor"],
              ["desc"] = L["Enter the text displayed when rolling."],
              ["type"] = "input",
              ["order"] = 20,
              ["arg"] = { "MessageText", "vendor" },
            },
            ["RollDestroy"] = {
              ["name"] = L["Destroy"],
              ["desc"] = L["Enter the text displayed when rolling."],
              ["type"] = "input",
              ["order"] = 30,
              ["arg"] = { "MessageText", "destroy" },
            },
            ["Ignore"] = {
              ["name"] = IGNORE,
              ["desc"] = L["Enter the text displayed when rolling."],
              ["type"] = "input",
              ["order"] = 50,
              ["arg"] = { "MessageText", "ignore" },
            },
          },
        },
        ["AllowMultipleConfirmPopups"] = {
          ["name"] = L["Allow Multiple Confirm Popups"],
          ["desc"] = L["Checking this will disable the exclusive bit to allow multiple confirmation of loot roll popups"],
          ["type"] = "toggle",
          ["order"] = 20,
          ["arg"] = { "AllowMultipleConfirmPopups" },
          ["set"] = function(info, value)
            PastLoot:OptionsSet(info, value)
            PastLoot:SetExclusiveConfirmPopupBit()
          end,
          ["width"] = "full",
          ["disabled"] = function(info, value) return not StaticPopupDialogs.CONFIRM_LOOT_ROLL end,  -- Some versions of WoW (or addons that remove) don't have CONFIRM_LOOT_ROLL
        },
        ["SkipRules"] = {
          ["name"] = L["Skip Rules"],
          ["desc"] = L["Skip rules that have disabled or unknown filters."],
          ["type"] = "toggle",
          ["order"] = 30,
          ["arg"] = { "SkipRules" },
        },
        ["SkipWarning"] = {
          ["name"] = L["Skip Warning"],
          ["desc"] = L["Display a warning when a rule is skipped."],
          ["type"] = "toggle",
          ["order"] = 40,
          ["arg"] = { "SkipWarning" },
        },
        ["DisplayUnknownVars"] = {
          ["name"] = L["Unknown Filters"],
          ["desc"] = L["Displays disabled or unknown filter variables."],
          ["type"] = "toggle",
          ["order"] = 50,
          ["arg"] = { "DisplayUnknownVars" },
          ["set"] = function(info, value)
            PastLoot:OptionsSet(info, value)
            PastLoot:Rules_ActiveFilters_OnScroll()
          end,
        },
        ["CleanRules"] = {
          ["name"] = L["Clean Rules"],
          ["desc"] = L["Removes disabled or unknown filters from current rules."],
          ["type"] = "execute",
          ["order"] = 60,
          ["func"] = "CleanRules",
          ["confirm"] = true,
          ["confirmText"] = L["CLEAN RULES DESC"],
        },
      },
    },
    ["Modules"] = {
      ["name"] = L["Modules"],
      ["type"] = "group",
      ["args"] = {},
    },
    ["Profiles"] = nil,  -- Reserved for profile options
    ["Output"] = nil,  -- Reserved for sink output options
  },
}

  -- A list of variables that are used in the DefaultTemplate (this is a quick lookup table of what variables are used)
PastLoot.DefaultVars = {
  -- [VariableName] = true,
}

function PastLoot:OptionsSet(Info, Value)
  local Table = self.db.profile
  for Key = 1, (#Info.arg - 1) do
    if ( not Table[Info.arg[Key]] ) then
      Table[Info.arg[Key]] = {}
    end
    Table = Table[Info.arg[Key]]
  end
  Table[Info.arg[#Info.arg]] = Value
end

function PastLoot:OptionsGet(Info)
  local Table = self.db.profile
  for Key = 1, (#Info.arg - 1) do
    if ( not Table[Info.arg[Key]] ) then
      Table[Info.arg[Key]] = {}
    end
    Table = Table[Info.arg[Key]]
  end
  return Table[Info.arg[#Info.arg]]
end

function PastLoot:SetExclusiveConfirmPopupBit()
  if ( StaticPopupDialogs and StaticPopupDialogs.CONFIRM_LOOT_ROLL ) then  -- Some versions of WoW (or addons that remove) don't have CONFIRM_LOOT_ROLL
    if ( self.db.profile.AllowMultipleConfirmPopups ) then
      StaticPopupDialogs.CONFIRM_LOOT_ROLL.exclusive = nil
      StaticPopupDialogs.CONFIRM_LOOT_ROLL.multiple = 1
    else
      if ( not StaticPopupDialogs.CONFIRM_LOOT_ROLL.exclusive ) then  -- Only modify this if we touched it.
        StaticPopupDialogs.CONFIRM_LOOT_ROLL.exclusive = 1
        StaticPopupDialogs.CONFIRM_LOOT_ROLL.multiple = nil
      end
    end
  end
end

function PastLoot:OnInitialize()
  -- Called when the addon is loaded
  -- LibStub("AceConsole-3.0"):RegisterChatCommand(L["PASTLOOT_SLASH_COMMAND"], function() InterfaceOptionsFrame_OpenToCategory(L["PastLoot"]) end)
  self.db = LibStub("AceDB-3.0"):New("PastLootDB", defaults, L["Default"])
  self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
  self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
  self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
  -- self.db.RegisterCallback(self, "OnProfileDeleted", "OnProfileNewOrDelete")
  -- self.db.RegisterCallback(self, "OnNewProfile", "OnProfileNewOrDelete")
  self:SetSinkStorage(self.db.profile.SinkOptions)

  self.OptionsTable.args.Profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
  self.OptionsTable.args.Output = self:GetSinkAce3OptionsDataTable()
  LibStub("AceConfig-3.0"):RegisterOptionsTable(L["PastLoot"], self.OptionsTable, {L["PASTLOOT_SLASH_COMMAND"]})
  -- Ability_Racial_PackHobgoblin
  -- INV_Misc_Bag_10
  -- INV_Misc_Coin_02
  -- Racial_Dwarf_FindTreasure
  self.LDB = LDB:NewDataObject("PastLoot", {
    ["type"] = "launcher",
    ["icon"] = "Interface\\Icons\\INV_Misc_Coin_02.blp",
    ["OnClick"] = function()
      InterfaceOptionsFrame_OpenToCategory(L["PastLoot"])
    end,
    ["OnTooltipShow"] = function(tooltip)
      if ( tooltip and tooltip.AddLine ) then
        tooltip:SetText(L["PastLoot"])
        for Key, Value in ipairs(self.LastRolls) do
          tooltip:AddLine(Value)
        end
        tooltip:Show()
      end
    end,            
  })

  -- self.MainFrame = self:Create_MainFrame()
  self.RulesFrame = self:Create_RulesFrame()
  InterfaceOptions_AddCategory(self.RulesFrame)
  self.Tooltip = self:Create_PastLootTooltip()
  -- self.BlizOptionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("PastLoot", L["PastLoot"])
  self.BlizOptionsFrames = {
    ["Modules"] = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(L["PastLoot"], L["Modules"], L["PastLoot"], "Modules"),
    ["GeneralOptions"] = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(L["PastLoot"], L["Options"], L["PastLoot"], "Options"),
    ["Profiles"] = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(L["PastLoot"], L["Profiles"], L["PastLoot"], "Profiles"),
    ["Output"] = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(L["PastLoot"], L["Output"], L["PastLoot"], "Output"),
  }
  
  -- PanelTemplates_SetNumTabs(PastLoot_TabbedMenuContainer, 2)  -- 2 because there are 2 tabs total.
  -- PanelTemplates_SetTab(PastLoot_TabbedMenuContainer, 1)      -- 1 because we want tab 1 selected.
  -- PanelTemplates_UpdateTabs(PastLoot_TabbedMenuContainer)
  self.DropDownFrame = CreateFrame("Frame", "PastLoot_DropDownMenu", nil, "UIDropDownMenuTemplate")
end

local function update_sets()
  PastLoot.setIDs = {} -- clear any existing set items
  for i=1, GetNumEquipmentSets() do
    local name = GetEquipmentSetInfo(i)
    for _,v in pairs(GetEquipmentSetItemIDs(name)) do
      if v > 1 then
        PastLoot.setIDs[v] = true
      end
    end
  end
end

function PastLoot:OnEnable()
  self:RegisterEvent("BAG_UPDATE")
  self:RegisterEvent("MERCHANT_SHOW")
  self:RegisterEvent("EQUIPMENT_SETS_CHANGED")
  update_sets()
  self:SetupModulesOptionsTables() -- Creates Module header frames and lays them out in the scroll frame
  self:OnProfileChanged()
  self.LastRolls = {}  -- Last 10 rolls.
end

function PastLoot:OnDisable()
  self:UnregisterEvent("BAG_UPDATE")
  self:UnregisterEvent("MERCHANT_SHOW")
  self:UnregisterEvent("EQUIPMENT_SETS_CHANGED")
end

function PastLoot:OnProfileChanged()
  -- this is called every time your profile changes (after the change)
  self:SetExclusiveConfirmPopupBit()
  self.CurrentRule = 0
  self.CurrentRuleUnknownVars = {}
  self.CurrentOptionFilter = { nil, 0 } -- Frame, line #
  self:LoadModules()
  self:SendMessage("PastLoot_OnProfileChanged")
  -- Now we check our rules to see if all variables are set.
  -- We could check profile variables, but some modules need more than just setting defaults, they need to act on them.
  self:CheckRuleTables()
  self:Rules_RuleList_OnScroll()
  self:DisplayCurrentRule()
  -- self:OnProfileNewOrDelete()
end

-- function PastLoot:OnProfileNewOrDelete()
-- end

function PastLoot:LoadModules()
  local Module
  for ModuleKey, ModuleValue in self:IterateModules() do
    Module = ModuleValue:GetName()
    self.db.profile.Modules[Module] = self.db.profile.Modules[Module] or {}
    if ( self.db.profile.Modules[Module].Status == nil ) then
      self.db.profile.Modules[Module].Status = true
    end
    if ( self.db.profile.Modules[Module].Status ~= ModuleValue.enabledState ) then
      if ( self.db.profile.Modules[Module].Status ) then
        ModuleValue:Enable()
      else
        ModuleValue:Disable()
      end
    end
  end
end

local CanRoll = {
  ["keep"] = nil,
  ["vendor"] = nil,
  ["destroy"] = nil,
}

local RollMethodLookup = {
  [1] = L["Keep"],
  [2] = L["Vendor"],
  [3] = L["Destroy"],
}

function PastLoot:EQUIPMENT_SETS_CHANGED(Event, ...)
  if Event ~= "EQUIPMENT_SETS_CHANGED" then return end
  update_sets()
end

function PastLoot:BAG_UPDATE(Event, Bag, ...)
  if Event ~= "BAG_UPDATE" or Bag == nil or Bag < 0 or Bag > 4 then return end
  -- throttle bag updates
--  print("Bag update")
end
function PastLoot:MERCHANT_SHOW(Event, ...)
  if Event ~= "MERCHANT_SHOW" or "Fix-o-Tron 5000" == UnitName("target") then return end
  local _, sold
  local amount = 0
  for bag=0,4 do
    for slot=1, GetContainerNumSlots(bag) do
      local _, count, _, _, _, _, itemLink = GetContainerItemInfo(bag,slot)
      if itemLink then
        local vendor = select(11, GetItemInfo(itemLink))
        if vendor > 0 then
          local result = PastLoot:EvaluateItem(itemLink)
          if result == 2 or result == 3 then
            amount = amount + count * vendor
            if sold and strlen(sold) + strlen(itemLink) > 255 then
              print("Sold: " .. sold)
              sold = nil
            end
          -- only show count if > 1
          local c = ""
          if count > 1 then
            c = count .. "x "
          end
          if sold then
              sold = sold .. ", ".. c .. itemLink
            else
              sold = c .. itemLink
            end
            UseContainerItem(bag, slot)
          end
        end
      end
    end
  end
  if sold then
    print("Sold: " .. sold)
    print("Total: "..GetCoinTextureString(amount))
  end
end

function PastLoot:EvaluateItem(ItemLink)
  local Name = GetItemInfo(ItemLink)
  self.Tooltip:SetOwner(UIParent, "ANCHOR_NONE")
  self.Tooltip:SetHyperlink(ItemLink)
  for WidgetKey, WidgetValue in ipairs(self.RuleWidgets) do
    WidgetValue:SetMatch(ItemLink, self.Tooltip)
  end
  local MatchedRule, NumFilters
  local IsMatch, IsException, NormalMatch, ExceptionMatch, HadNoNormal
  local NormalMatchText, ExceptionMatchText = "", ""
  for RuleKey, RuleValue in ipairs(self.db.profile.Rules) do
    self:Debug("Checking rule "..RuleKey.." "..RuleValue.Desc)
    if ( self.db.profile.SkipRules and self.SkipRules[RuleKey] ) then
      if ( self.db.profile.SkipWarning ) then
        self:Pour("|cff33ff99"..L["PastLoot"].."|r: "..string.gsub(L["Skipping %rule%"], "%%rule%%", RuleValue.Desc))
      end
    else
      MatchedRule = true
      for WidgetKey, WidgetValue in ipairs(self.RuleWidgets) do
        NumFilters = WidgetValue:GetNumFilters(RuleKey) or 0
        if ( NumFilters > 0 ) then
          NormalMatchText, ExceptionMatchText = "", ""
          self:Debug("Checking filter "..WidgetValue.Info[1].." ("..NumFilters.." NumFilters)")
          -- I can not simply OR normal ones and AND NOT the exception ones.. example: for a 1hd mace
          -- Filter1: OR Armor
          -- Filter2: AND NOT 1hd mace
          -- Filter3: OR Weapon
          -- Will evaluate true, when it should have evaluated false.
          -- It should have been (Armor OR Weapon) AND NOT (1hd mace)
          NormalMatch = false
          ExceptionMatch = false
          HadNoNormal = true
          for Index = 1, NumFilters do
            IsMatch = WidgetValue:GetMatch(RuleKey, Index)
            if ( IsMatch ) then
              IsMatch = true
            else
              IsMatch = false
            end
            IsException = WidgetValue:IsException(RuleKey, Index)
            if ( IsException ) then
              ExceptionMatch = ExceptionMatch or IsMatch
              ExceptionMatchText = ExceptionMatchText..Index.."-"..tostring(IsMatch).." OR "
              if ( IsMatch ) then  -- don't have to go any further, one single true in the exception = a false in the entire filter.
                break
              end
            else
              NormalMatch = NormalMatch or IsMatch
              HadNoNormal = false
              NormalMatchText = NormalMatchText..Index.."-"..tostring(IsMatch).." OR "
            end
          end -- Each Filter
          if ( (NormalMatch or HadNoNormal) and not ExceptionMatch ) then
            self:Debug("Filter matched: ("..NormalMatchText..tostring(HadNoNormal)..") AND NOT ("..ExceptionMatchText.." false)")
          else
            self:Debug("Filter did not match: ("..NormalMatchText..tostring(HadNoNormal)..") AND NOT ("..ExceptionMatchText.." false)")
            MatchedRule = false
            break
          end
        end -- NumFilters > 0
      end -- Each Widget

      if ( MatchedRule ) then
        self:Debug("Matched rule")
        local StatusMsg, RollMethod
        StatusMsg = self.db.profile.MessageText.ignore
        -- To make absolutely sure I roll according to RollOrder
        local WantToRoll = {}
        for LootKey, LootValue in pairs(RuleValue.Loot) do
          WantToRoll[LootValue] = true
        end
        for RollOrderKey, RollOrderValue in ipairs(self.RollOrder) do
          if WantToRoll[RollOrderValue] then
            RollMethod = self.RollMethod[RollOrderValue]
            StatusMsg = self.db.profile.MessageText[RollOrderValue]
            break
          end
        end
        -- for LootKey, LootValue in ipairs(RuleValue.Loot) do
          -- if ( CanRoll[LootValue] ) then
            -- RollMethod = self.RollMethod[LootValue]
            -- StatusMsg = self.db.profile.MessageText[LootValue]
            -- break
          -- end
        -- end
        self:SendMessage("PastLoot_OnRoll", ItemLink, RuleKey, RollMethod)  -- Maybe change this to OnRuleMatched
        if ( not self.TestLink ) then
          if ( RollMethod ) then
            -- RollOnLoot(RollID, RollMethod)
            return RollMethod
          end
        end
        -- Add to LastRolls
        local ItemTexture, TextLine, Method
        if ( RollMethod ) then
          Method = RollMethodLookup[RollMethod]
        else
          Method = L["Ignored"]
        end
        _, _, _, _, _, _, _, _, _, ItemTexture, _ = GetItemInfo(ItemLink)
        TextLine = string.format("|T%s:0|t %s - %s", ItemTexture, ItemLink, Method)
        if ( #self.LastRolls == 10 ) then
          table.remove(self.LastRolls, 1)
        end
        table.insert(self.LastRolls, TextLine)
        -- Send StatusMsg
        if ( self.db.profile.Quiet == false ) then
          -- Workaround for LibSink.  It can handle |c and |r color stuff, but not full ItemLinks
          local ItemText
          if ( self.db.profile.SinkOptions.sink20OutputSink == "Channel" ) then
            ItemText = GetItemInfo(ItemLink)
          else
            ItemText = ItemLink
          end
          StatusMsg = string.gsub(StatusMsg, "%%item%%", ItemText)
          StatusMsg = string.gsub(StatusMsg, "%%rule%%", RuleValue.Desc)
          self:Pour("|cff33ff99"..L["PastLoot"].."|r: "..StatusMsg)
        end
        self.TestLink = nil
        return
      end --MatchedRule
    end  -- SkipRules
    self:Debug("Rule not matched, trying another")
  end --RuleKey, RuleValue
  self:Debug("Ran out of rules, ignoring")
  if ( self.TestLink ) then
    self:Pour(ItemLink..": "..L["No rules matched."])
  end
  self.TestLink = nil
end

function PastLoot:CleanRules()
  -- local DefaultVars = {}
  -- for DefaultKey, DefaultValue in pairs(self.DefaultTemplate) do
    -- DefaultVars[DefaultValue[1]] = true
  -- end
  for RuleKey, RuleValue in pairs(self.db.profile.Rules) do
    for VarKey, VarValue in pairs(RuleValue) do
      if ( not self.DefaultVars[VarKey] ) then
        self.db.profile.Rules[RuleKey][VarKey] = nil
      end
    end
  end
  self.SkipRules = {}
end

-- We make sure each rule has a default value
-- Update the DefaultVars lookup table.
-- Based on DefaultVars, create a list of rules to skip  (A rule has a module variable set, but no module is loaded to check it)
function PastLoot:CheckRuleTables()
  for Key, Value in pairs(self.DefaultVars) do
    self.DefaultVars[Key] = nil
  end
  for DefaultKey, DefaultValue in pairs(self.DefaultTemplate) do
    self.DefaultVars[DefaultValue[1]] = true
  end
  self.SkipRules = {}
  local RulesSkipped = false
  self.db.profile.Rules = self.db.profile.Rules or {}
  for RuleKey, RuleValue in pairs(self.db.profile.Rules) do
    for DefaultKey, DefaultValue in ipairs(self.DefaultTemplate) do
      -- Check if the rule does not have a variable but the default template says we should.
      if ( not RuleValue[DefaultValue[1]] and DefaultValue[2] ) then
        self.db.profile.Rules[RuleKey][DefaultValue[1]] = self:CopyTable(DefaultValue[2])
      end
    end
    -- Check each variable to see if it's listed in the DefaultTemplate
    for VarKey, VarValue in pairs(RuleValue) do
      if ( not self.DefaultVars[VarKey] ) then
        self:Debug("Could not find some variables in rule "..RuleValue.Desc)
        self.SkipRules[RuleKey] = true
        RulesSkipped = true
        break
      end
    end
  end
  if ( RulesSkipped and self.db.profile.SkipRules ) then
    self:Pour("|cff33ff99"..L["PastLoot"].."|r: "..L["Found some rules that will be skipped."])
  end
end

function PastLoot:Debug(...)
  local DebugLine, Counter
  if ( self.DebugVar == true ) then
    DebugLine = ""
    for Counter = 1, select("#", ...) do
      DebugLine = DebugLine..select(Counter, ...)
    end
    self:Print(DebugLine)
  end
end

function PastLoot:IterateRules(CallbackFunc, ...)
  if ( PastLootDB and PastLootDB.profiles ) then
    for ProfileKey, ProfileValue in pairs(PastLootDB.profiles) do
      if ( ProfileValue.Rules ) then
        for RuleKey, RuleValue in ipairs(ProfileValue.Rules) do
          if ( type(CallbackFunc) == "string" ) then
            self[CallbackFunc](self, RuleValue, ...)
          elseif ( type(CallbackFunc) == "function" ) then
            CallbackFunc(RuleValue, ...)
          end
        end -- RuleKey, RuleValue
      end -- if ProfileValue.Rules
    end -- ProfileKey, ProfileValue
  elseif ( self.db and self.db.profile and self.db.profile.Rules ) then
    for RuleKey, RuleValue in ipairs(self.db.profile.Rules) do
      if ( type(CallbackFunc) == "string" ) then
        self[CallbackFunc](self, RuleValue, ...)
      elseif ( type(CallbackFunc) == "function" ) then
        CallbackFunc(RuleValue, ...)
      end
    end -- RuleKey, RuleValue
  end
end

-- ####### Structures ########
-- ## Main PastLoot DB structure ##
-- DB Version 12 structure:
-- PastLoot Global = {
  -- ["Modules"] = {
    -- ["ModuleName"] = {
      -- ["Version"] = 1,
    -- },
  -- },
-- }
-- PastLoot Profile = {
  -- ["Quiet"] = false,
  -- ["Rules"] = {
    -- {
      -- ["Desc"] = "Description",
      -- ["ModuleVar"] = ModuleValue,
      -- ["ModuleVar"] = ModuleValue,
    -- },
  -- },
  -- ["Modules"] = {
    -- ["ModuleName"] = {
      -- ["Status"] = true/false,
      -- ["ProfileVars"] = {},
    -- },
  -- },
-- }

-- ## Table format of Default Template when creating a new rule ##
-- # Also the format for registering the variables
-- PastLoot.DefaultTemplate = {
  -- { VariableName, Default },
  -- { VariableName, Default },
-- }

-- ## Plugin Lookup Table ##
-- This is a lookup only table, we do not delete entries from this table generated
-- # RuleVariables are created when a module uses RegisterDefaultVariables()
    -- Used as verification, as the only variables our module can access with GetConfigOption() and SetConfigOption()
    -- Also used in CheckDBVersion, as a list of variables to upgrade with the Callback function.
-- # RuleWidgets are created when a module uses AddWidget()
    -- Used as a list of widgets to remove from the PastLoot.RuleWidgets table.
    -- (PastLoot.RuleWidgets is a sorted table of all widgets to display)
-- PastLoot.PluginInfo = {
  -- [ModuleName] = {
    -- ["RuleVariables"] = {
      -- VariableName = true,
      -- VariableName = true,
    -- },
    -- ["RuleWidgets"] = {
      -- [1] = WidgetA,
      -- [2] = WidgetB,
    -- },
  -- },
-- }

-- ## Main table of SORTED (Alphabetical > preferred priority) rule widgets to display ##
-- PastLoot.RuleWidgets = {
  -- WidgetA,
  -- WidgetB,
-- }

-- ## Module List in a SORTED order.  Actual headers in self.PluginInfo.ProfileHeader ##
-- PastLoot.ModuleHeaders = {
  -- "ModuleA",
  -- "ModuleB",
-- }

-- Widget.Info = {
  -- [1] = "Text to display in filter list",
  -- [2] = "Tooltip description",
  -- [3] = "Module name this belongs to",
-- }
