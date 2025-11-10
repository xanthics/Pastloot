local VERSION = "1.0"
PastLoot = LibStub("AceAddon-3.0"):NewAddon("PastLoot", "AceConsole-3.0", "AceEvent-3.0", "AceBucket-3.0", "AceHook-3.0",
	"LibSink-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("PastLoot")
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
-- local LDBIcon = LibStub("LibDBIcon-1.0")

local PASTLOOT_POPUP = "PASTLOOT_CONFIRM_DELETE_YES_NO"

PastLoot.PASTLOOT_CONFIRMED_ITEM_CHOICES = {}
function PASTLOOT_CALL_BAG_UPDATE(clink, choice)
	PastLoot.PASTLOOT_CONFIRMED_ITEM_CHOICES[clink] = choice
	PastLoot:UpdateBags()
end

local defaults = {
	["profile"] = {
		["Quiet"] = false,
		["AllowMultipleConfirmPopups"] = false,
		["Rules"] = {},
		["Modules"] = {},
		["SinkOptions"] = {},
		["SkipRules"] = false,
		["SkipWarning"] = true,
		["DisplayUnknownVars"] = true,
		["DeleteImmediate"] = "noval",
		["KeepOpen"] = 5,
		["DeleteVendor"] = false,
		["ShowDelete"] = true,
		["LearnWardrobe"] = false,
		["DeleteCommon"] = false,
		["DeleteUncommon"] = false,
		["DeleteRare"] = false,
		["DeleteEpic"] = false,
		["DeleteLegendary"] = false,
		["DeleteArtifact"] = false,
		["DeleteVanity"] = false,
		["CacheExpires"] = 900,
		["MessageText"] = {
			["keep"] = L["keeping %item% (%rule%)"],
			["vendor"] = L["vendoring %item% (%rule%)"],
			["destroy"] = L["destroying %item% (%rule%)"],
			["ignore"] = L["Ignoring %item% (%rule%)"],
		},
	},
}

local function handleMouseover(cmdname)
	local name, link = GameTooltip:GetItem()
	if GameTooltip:IsShown() and link then
		if cmdname == "IDRule" then
			local item = PastLoot:InitItem(link)
			return tostring(item.id)
		else
			return name:lower()
		end
	end
	PastLoot:Pour("No valid item tooltip found.")
end

local function dupcheck(a, b)
	if #a == 2 then
		for i = 1, #a do
			if (a[i][2] == "Exact") and a[i][1]:lower() == b then return true end
		end
	else
		for i = 1, #a do
			if a[i][1] == b then return true end
		end
	end
	return false
end

local function slash_feedback(flag, idx, command)
	PastLoot:Pour("Completed: " ..
		flag .. " '" .. command .. "' to rule #" .. idx .. " '" .. PastLoot.db.profile.Rules[idx].Desc .. "'")
end

local function compare_name(a, b)
	local atest = a[1]:lower()
	local btext = b[1]:lower()
	return (atest < btext) or (atest == btext and a[2] < b[2])
end

local function compare_id(a, b)
	return a[1]:lower() < b[1]:lower()
end

local function handleAddRemove(value, cmdname, dbkey, example)
	local idx, flag, command = value:match("(%d-) (%S*) (.*)")
	if command and idx and flag then
		flag = flag:lower()
		idx = tonumber(idx)
	end
	if not command or not idx or (flag ~= "add" and flag ~= "remove") or not PastLoot.db.profile.Rules[idx] then
		PastLoot:Pour(
			"This command requires a valid Rule Number, the operation 'add' or 'remove', and either the value to add or 'mouseover' to use the current tooltip.")
		PastLoot:Pour("Example: /pastloot " .. cmdname .. " 1 add " .. example)
		PastLoot:Pour("Example: /pastloot " .. cmdname .. " 1 remove mouseover")
		return
	end
	if command == "mouseover" then
		command = handleMouseover(cmdname)
	end
	if command then
		if flag == "add" then
			PastLoot.db.profile.Rules[idx][dbkey] = PastLoot.db.profile.Rules[idx][dbkey] or {}
			-- check if already in rule
			if not dupcheck(PastLoot.db.profile.Rules[idx][dbkey], command) then
				if cmdname == "IDRule" then
					table.insert(PastLoot.db.profile.Rules[idx][dbkey], { command, false })
					if PastLoot.db.profile.Rules[idx][dbkey]["ItemIDs"] then
						table.sort(PastLoot.db.profile.Rules[idx][dbkey]["ItemIDs"], compare_id)
					end
				else
					table.insert(PastLoot.db.profile.Rules[idx][dbkey], { command, "Exact", false })
					if PastLoot.db.profile.Rules[idx][dbkey]["Items"] then
						table.sort(PastLoot.db.profile.Rules[idx][dbkey]["Items"], compare_name)
					end
				end
				slash_feedback(flag, idx, command)
			else
				PastLoot:Pour("Item already present in Rule, skipping.")
			end
		elseif PastLoot.db.profile.Rules[idx][dbkey] then
			local found = false
			for i, v in pairs(PastLoot.db.profile.Rules[idx][dbkey]) do
				if v[1]:lower() == command then
					found = true
					table.remove(PastLoot.db.profile.Rules[idx][dbkey], i)
					slash_feedback(flag, idx, command)
					break
				end
			end
			if not found then PastLoot:Pour("Item not found in Rule.") end
		end
	end
end

PastLoot.OptionsTable = {
	["type"] = "group",
	["handler"] = PastLoot,
	["get"] = "OptionsGet",
	["set"] = "OptionsSet",
	["args"] = {
		["Menu"] = {
			["name"] = L["Menu"],
			["order"] = 0,
			["desc"] = L["Opens the PastLoot Menu."],
			["type"] = "execute",
			["func"] = function()
				InterfaceOptionsFrame_OpenToCategory(L["PastLoot"])
			end,
		},
		["Test"] = {
			["name"] = L["Test"],
			["order"] = 30,
			["desc"] = L["Test an item link to see how we would roll"],
			["type"] = "input",
			["get"] = function() end,
			["set"] = function(info, value)
				local _, link = GetItemInfo(value)
				if not link then
					_, link = GameTooltip:GetItem()
				end
				PastLoot.TestLink = PastLoot:InitItem(link)
				if (PastLoot.TestLink) then
					PastLoot.TestCanKeep, PastLoot.TestCanVendor, PastLoot.TestCanDestroy = true, true, true
					PastLoot:EvaluateItem(PastLoot.TestLink)
				else
					PastLoot:Pour("|cff33ff99PastLoot|r: no valid item link or mouseover item found.")
					PastLoot.TestLink = nil -- to make sure
				end
			end,
		},
		["TestAll"] = {
			["name"] = L["TestAll"],
			["order"] = 40,
			["desc"] = L["Test all items currently in your inventory"],
			["type"] = "input",
			["get"] = function() end,
			["set"] = function(info)
				for _, bag in ipairs(PastLoot.bags) do
					for slot = 1, GetContainerNumSlots(bag) do
						PastLoot.TestLink = PastLoot:FillContainerItemInfo(nil, bag, slot)
						if (PastLoot.TestLink) then
							PastLoot.TestCanKeep, PastLoot.TestCanVendor, PastLoot.TestCanDestroy = true, true, true
							PastLoot:EvaluateItem(PastLoot.TestLink)
						else
							PastLoot.TestLink = nil -- to make sure
						end
					end
				end
			end,
		},
		["NameRule"] = {
			["name"] = L["NameRule"],
			["order"] = 60,
			["desc"] = L["(Add) or (remove) an item by name to an existing rule."],
			["type"] = "input",
			["get"] = function() end,
			["set"] = function(info, value)
				handleAddRemove(value, "NameRule", "Items", "Turtle Meat")
				PastLoot:ResetCache()
			end,
		},
		["IDRule"] = {
			["name"] = L["IDRule"],
			["order"] = 50,
			["desc"] = L["(Add) or (remove) an item by id to an existing rule"],
			["type"] = "input",
			["get"] = function() end,
			["set"] = function(info, value)
				handleAddRemove(value, "IDRule", "ItemIDs", "3712")
				PastLoot:ResetCache()
			end,
		},
		["Options"] = {
			["name"] = L["Options"],
			["order"] = 20,
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
						if (v) then
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
				["Options"] = {
					["name"] = "Settings for Delete Rules", --L["Options"],
					["order"] = 70,
					["desc"] = L["General Options"],
					["type"] = "group",
					["inline"] = true,
					["args"] = {
						["DeleteImmediate"] = {
							["name"] = L["DeleteImmediate"],
							["desc"] = L["DeleteImmediateDesc"],
							["type"] = "select",
							["order"] = 10,
							["arg"] = { "DeleteImmediate" },
							["width"] = "normal",
							["values"] = {
								["noval"] = L["NoValDesc"],
								["anyval"] = L["AnyValDesc"],
							},
							["style"] = "dropdown",
						},
						["KeepOpenSlots"] = {
							["name"] = L["KeepOpenSlots"],
							["desc"] = L["KeepOpenSlotsDesc"],
							["type"] = "range",
							["order"] = 20,
							["arg"] = { "KeepOpen" },
							["width"] = "double",
							["min"] = 0,
							["max"] = 168,
							["softMin"] = 0,
							["softMax"] = 10,
							["step"] = 1,
						},
						["DeleteVendor"] = {
							["name"] = L["DeleteVendor"], --L["Skip Warning"],
							["desc"] = L["DeleteVendorDesc"],
							["type"] = "toggle",
							["order"] = 30,
							["arg"] = { "DeleteVendor" },
							["width"] = "normal",
						},
						["ShowDelete"] = {
							["name"] = L["ShowDelete"], --L["Skip Warning"],
							["desc"] = L["ShowDeleteDesc"],
							["type"] = "toggle",
							["order"] = 40,
							["arg"] = { "ShowDelete" },
							["width"] = "normal",
						},
						["LearnWardrobe"] = {
							["name"] = L["LearnWardrobe"], --L["Skip Warning"],
							["desc"] = L["LearnWardrobeDesc"],
							["type"] = "toggle",
							["order"] = 45,
							["arg"] = { "LearnWardrobe" },
							["width"] = "normal",
						},
						["ConfirmDelete"] = {
							["name"] = L["Automatically Confirm Delete"], --L["Options"],
							["order"] = 50,
							["desc"] = L["Confirm Delete Desc"],
							["type"] = "group",
							["inline"] = true,
							["args"] = {
								["DeleteCommon"] = {
									["name"] = ITEM_QUALITY_COLORS[1].hex .. ITEM_QUALITY1_DESC .. "|r", --L["Skip Warning"],
									["type"] = "toggle",
									["order"] = 10,
									["desc"] = L["Confirm Delete Desc"],
									["arg"] = { "DeleteCommon" },
								},
								["DeleteUncommon"] = {
									["name"] = ITEM_QUALITY_COLORS[2].hex .. ITEM_QUALITY2_DESC .. "|r", --L["Skip Warning"],
									["type"] = "toggle",
									["order"] = 20,
									["desc"] = L["Confirm Delete Desc"],
									["arg"] = { "DeleteUncommon" },
								},
								["DeleteRare"] = {
									["name"] = ITEM_QUALITY_COLORS[3].hex .. ITEM_QUALITY3_DESC .. "|r", --L["Skip Warning"],
									["type"] = "toggle",
									["order"] = 30,
									["desc"] = L["Confirm Delete Desc"],
									["arg"] = { "DeleteRare" },
								},
								["DeleteEpic"] = {
									["name"] = ITEM_QUALITY_COLORS[4].hex .. ITEM_QUALITY4_DESC .. "|r", --L["Skip Warning"],
									["type"] = "toggle",
									["order"] = 40,
									["desc"] = L["Confirm Delete Desc"],
									["arg"] = { "DeleteEpic" },
								},
								["DeleteLegendary"] = {
									["name"] = ITEM_QUALITY_COLORS[5].hex .. ITEM_QUALITY5_DESC .. "|r", --L["Skip Warning"],
									["type"] = "toggle",
									["order"] = 50,
									["desc"] = L["Confirm Delete Desc"],
									["arg"] = { "DeleteLegendary" },
								},
								["DeleteArtifact"] = {
									["name"] = ITEM_QUALITY_COLORS[6].hex .. ITEM_QUALITY6_DESC .. "|r", --L["Skip Warning"],
									["type"] = "toggle",
									["order"] = 60,
									["desc"] = L["Confirm Delete Desc"],
									["arg"] = { "DeleteArtifact" },
								},
								["DeleteVanity"] = {
									["name"] = ITEM_QUALITY_COLORS[7].hex .. ITEM_QUALITY7_DESC .. "|r", --L["Skip Warning"],
									["type"] = "toggle",
									["order"] = 70,
									["desc"] = L["Confirm Delete Desc"],
									["arg"] = { "DeleteVanity" },
								},
							},
						},
					},
				},
			},
		},
		["Modules"] = {
			["name"] = L["Modules"],
			["order"] = 10,
			["type"] = "group",
			["args"] = {},
		},
		["Profiles"] = nil, -- Reserved for profile options
		["Output"] = nil, -- Reserved for sink output options
	},
}

-- A list of variables that are used in the DefaultTemplate (this is a quick lookup table of what variables are used)
PastLoot.DefaultVars = {
	-- [VariableName] = true,
}

function PastLoot:OptionsSet(Info, Value)
	local Table = self.db.profile
	for Key = 1, (#Info.arg - 1) do
		if (not Table[Info.arg[Key]]) then
			Table[Info.arg[Key]] = {}
		end
		Table = Table[Info.arg[Key]]
	end
	Table[Info.arg[#Info.arg]] = Value
	self:ResetCache()
end

function PastLoot:OptionsGet(Info)
	local Table = self.db.profile
	for Key = 1, (#Info.arg - 1) do
		if (not Table[Info.arg[Key]]) then
			Table[Info.arg[Key]] = {}
		end
		Table = Table[Info.arg[Key]]
	end
	return Table[Info.arg[#Info.arg]]
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
	LibStub("AceConfig-3.0"):RegisterOptionsTable(L["PastLoot"], self.OptionsTable, { L["PASTLOOT_SLASH_COMMAND"] })
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
			if (tooltip and tooltip.AddLine) then
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
		["Modules"] = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(L["PastLoot"], L["Modules"], L["PastLoot"],
			"Modules"),
		["GeneralOptions"] = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(L["PastLoot"], L["Options"], L["PastLoot"],
			"Options"),
		["Profiles"] = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(L["PastLoot"], L["Profiles"], L["PastLoot"],
			"Profiles"),
		["Output"] = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(L["PastLoot"], L["Output"], L["PastLoot"], "Output"),
	}

	-- PanelTemplates_SetNumTabs(PastLoot_TabbedMenuContainer, 2)  -- 2 because there are 2 tabs total.
	-- PanelTemplates_SetTab(PastLoot_TabbedMenuContainer, 1)      -- 1 because we want tab 1 selected.
	-- PanelTemplates_UpdateTabs(PastLoot_TabbedMenuContainer)
	self.DropDownFrame = CreateFrame("Frame", "PastLoot_DropDownMenu", nil, "UIDropDownMenuTemplate")
	PastLoot:ResetCache()

	-- used to confirm deleting items
	StaticPopupDialogs[PASTLOOT_POPUP] = {
		text = "%s\nShould PastLoot delete all instances of this item?\nChoice lasts for the remainder of this session.",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function(self, clink, ...)
			PASTLOOT_CALL_BAG_UPDATE(clink, true)
		end,
		OnCancel = function(self, clink, reason)
			if reason == "clicked" then PASTLOOT_CALL_BAG_UPDATE(clink, false) end
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
end

local function update_sets()
	PastLoot.setGUIDs = {} -- clear any existing set items
	for i = 1, GetNumEquipmentSets() do
		local name = GetEquipmentSetInfo(i)
		for _, v in pairs(GetEquipmentSetItemGUIDs(name)) do
			PastLoot.setGUIDs[v] = true --  This will add 0x0 to the table, but no valid item would have that id
		end
	end
end

local BUCKET_BAG_UPDATE, BUCKET_PLAYER_LEVEL_UP
function PastLoot:OnEnable()
	-- events that may fire multiple times in quick succession and require a cache update, but don't require information from the event
	BUCKET_BAG_UPDATE = self:RegisterBucketEvent("BAG_UPDATE", 1, "UpdateBags")
	BUCKET_PLAYER_LEVEL_UP = self:RegisterBucketEvent("PLAYER_LEVEL_UP", 1, "ClearItemCache")
	-- events that only fire occassionally
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("EQUIPMENT_SETS_CHANGED")
	self:RegisterEvent("ASCENSION_STORE_COLLECTION_ITEM_LEARNED")
	self:RegisterEvent("AUCTION_HOUSE_CLOSED", "ClearItemCache")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ClearItemCache")
	-- events that require the event details and also fire with BAG_UPDATE
	C_Hook:Register(self, "BAG_ITEM_REMOVED, BAG_ITEM_COUNT_CHANGED, BAG_ITEM_REPLACED")

	update_sets()
	self:SetupModulesOptionsTables() -- Creates Module header frames and lays them out in the scroll frame
	self:OnProfileChanged()
	self.LastRolls = {}           -- Last 10 rolls.
end

function PastLoot:OnDisable()
	-- events that may fire multiple times in quick succession and require a cache update, but don't require information from the event
	self:UnregisterBucket(BUCKET_BAG_UPDATE)
	self:UnregisterBucket(BUCKET_PLAYER_LEVEL_UP)
	-- events that only fire occassionally
	self:UnregisterEvent("MERCHANT_SHOW")
	self:UnregisterEvent("EQUIPMENT_SETS_CHANGED")
	self:UnregisterEvent("ASCENSION_STORE_COLLECTION_ITEM_LEARNED")
	self:UnregisterEvent("AUCTION_HOUSE_CLOSED")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	-- events that require the event details and also fire a BAG_UPDATE
	C_Hook:Unregister(self, "BAG_ITEM_REMOVED, BAG_ITEM_COUNT_CHANGED, BAG_ITEM_REPLACED")
end

function PastLoot:OnProfileChanged()
	-- this is called every time your profile changes (after the change)
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
	self:ResetCache()
	-- self:OnProfileNewOrDelete()
end

-- function PastLoot:OnProfileNewOrDelete()
-- end

function PastLoot:LoadModules()
	local Module
	for ModuleKey, ModuleValue in self:IterateModules() do
		Module = ModuleValue:GetName()
		self.db.profile.Modules[Module] = self.db.profile.Modules[Module] or {}
		if (self.db.profile.Modules[Module].Status == nil) then
			self.db.profile.Modules[Module].Status = true
		end
		if (self.db.profile.Modules[Module].Status ~= ModuleValue.enabledState) then
			if (self.db.profile.Modules[Module].Status) then
				ModuleValue:Enable()
			else
				ModuleValue:Disable()
			end
		end
	end
end

local RollMethodLookup = {
	[1] = L["Keep"],
	[2] = L["Vendor"],
	[3] = L["Destroy"],
}

local QueueOperations = {
	["reset"] = false,
	["GUIDs"] = {}, -- Each GUID recalculates EvaluateItem
	--	["BagSlots_Count"] = { [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {} }, -- bag, slot pairs to update with the item there.
	--	["BagSlots_Location"] = { [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {} }, -- bag, slot pairs to update with the item there.
	["IDs"] = {}, -- set of IDs to invalidate matching caches
}

local function sort_delete(a, b)
	return a.value < b.value
end

local validationQue = {}
local function deleteValidation()
	while #validationQue > 0 do
		local entry = table.remove(validationQue)
		if entry.guid ~= "" then
			PastLoot:AddLastRoll(entry.guid, true)
			if self.db.profile.ShowDelete then
				PastLoot:Pour(entry.msg)
			end
		end
	end
end

--cache[item.guid] = { ["itemObj"] = item, ["result"] = 1, ["match"] = -1
function PastLoot:AddLastRoll(guid, destroyed)
	-- Add to LastRolls
	local TextLine, Method
	if destroyed then
		Method = L["Destroyed"]
	elseif (PastLoot.EvalCache[guid]["result"]) then
		Method = RollMethodLookup[PastLoot.EvalCache[guid]["result"]]
	else
		Method = L["Ignored"]
	end
	TextLine = string.format("|T%s:0|t %s - %s -> %s", PastLoot.EvalCache[guid]["itemObj"].texture, PastLoot.EvalCache[guid]["itemObj"].link, Method,
		PastLoot.db.profile.Rules[PastLoot.EvalCache[guid]["match"]].Desc)
	if (#self.LastRolls == 10) then
		table.remove(self.LastRolls, 1)
	end
	table.insert(self.LastRolls, TextLine)
end

-- used to convert quality number to a word to determine if an item needs a delete confirmation
local num_to_word = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Artifact", "Vanity" }

-- Bucket Event to handle updating the item cache
function PastLoot:UpdateBags(...)
	local currentTime = GetTime()
	-- if we are resetting the cache, only do that since any updates or single item deletes will be useless
	if QueueOperations["reset"] then
		PastLoot:ResetCache()
	else
		-- re-evaluate any items based on guid
		for k, _ in pairs(QueueOperations["GUIDs"]) do
			if PastLoot.EvalCache[k] then
				local result, match = PastLoot:EvaluateItem(PastLoot.EvalCache[k]["itemObj"])
				PastLoot.EvalCache[k]["result"] = result or 1
				PastLoot.EvalCache[k]["match"] = match or -1
				PastLoot.EvalCache[k]["expiresAt"] = currentTime + self.db.profile.CacheExpires
			end
		end
		-- forget items based on item id
		if type(next(QueueOperations["IDs"])) ~= "nil" then
			for k, v in pairs(PastLoot.EvalCache) do
				if QueueOperations["IDs"][v["itemObj"].id] then
					PastLoot.EvalCache[k] = nil
				end
			end
		end
	end
	-- we processed the update, reset the queue
	QueueOperations = { ["reset"] = false, ["GUIDs"] = {}, ["IDs"] = {} }
	-- calculate free space and cache any expired or uncached items in bag
	local freespace = 0
	for _, bag in ipairs(PastLoot.bags) do
		freespace = freespace + GetContainerNumFreeSlots(bag)
		for slot = 1, GetContainerNumSlots(bag) do
			local guid = GetContainerItemGUID(bag, slot)
			if guid and (not PastLoot.EvalCache[guid] or PastLoot.EvalCache[guid]["expiresAt"] < currentTime) then
				local itemObj = PastLoot:FillContainerItemInfo(nil, bag, slot)
				PastLoot:GetItemEvaluation(itemObj)
			end
		end
	end
	-- iterate cache, build a guid->value pool for potentially deletable items
	local deletecache = {}
	for guid, data in pairs(PastLoot.EvalCache) do
		if data["result"] == 3 or (self.db.profile.DeleteVendor and data["result"] == 2) then
			local value
			if self.db.profile.DeleteImmediate == "anyval" and data["result"] == 3 then
				value = 0
			else
				value = data["itemObj"].stackValue
			end
			-- so we don't immediately delete summoned items that are tagged vendor and instead only to free space
			if value == 0 and data["result"] == 2 then
				value = 1
			end
			deletecache[#deletecache + 1] = {
				["guid"] = guid,
				["value"] = value,
				["bag"] = data["itemObj"].bag,
				["slot"] = data["itemObj"].slot,
				["clink"] = data["itemObj"].link,
				["rule"] = data["match"],
				["rarity"] = data["itemObj"].quality,
				["id"] = data["itemObj"].id
			}
		end
	end
	-- sort the deletion candidates based on value
	table.sort(deletecache, sort_delete)
	-- delete any items as required
	local todelete = self.db.profile.KeepOpen - freespace
	while #deletecache > 0 and (todelete > 0 or deletecache[1].value == 0) do
		local citem = table.remove(deletecache, 1)
		if citem.guid ~= "" and citem.guid == GetContainerItemGUID(citem.bag, citem.slot) then
			if citem.rarity == 0 or PastLoot.PASTLOOT_CONFIRMED_ITEM_CHOICES[citem.clink] == true or self.db.profile["Delete" .. num_to_word[citem.rarity]] then
				-- try to collect appearances before deleting
				if self.db.profile.LearnWardrobe then
					local appearanceID = C_Appearance.GetItemAppearanceID(citem.id)
					if appearanceID and not C_AppearanceCollection.IsAppearanceCollected(appearanceID) then
						C_AppearanceCollection.CollectItemAppearance(citem.guid)
					end
				end
				PickupContainerItem(citem.bag, citem.slot)
				DeleteCursorItem()
				local StatusMsg = self.db.profile.MessageText.destroy
				StatusMsg = string.gsub(StatusMsg, "%%item%%", citem.clink)
				StatusMsg = string.gsub(StatusMsg, "%%rule%%", self.db.profile.Rules[citem.rule].Desc)
				StatusMsg = "|cff33ff99" .. L["PastLoot"] .. "|r: " .. StatusMsg
				local validationEntry = {}
				validationEntry.bag = citem.bag
				validationEntry.slot = citem.slot
				validationEntry.msg = StatusMsg
				validationEntry.guid = citem.guid
				table.insert(validationQue, validationEntry)
				Timer.NewTimer(.5, deleteValidation)
				todelete = todelete - 1
			elseif not StaticPopup_Visible(PASTLOOT_POPUP) and PastLoot.PASTLOOT_CONFIRMED_ITEM_CHOICES[citem.clink] == nil then
				local dialog = StaticPopup_Show(PASTLOOT_POPUP, citem.clink)
				if dialog then
					dialog.data = citem.clink
				end
			end
		end
	end
end

function PastLoot:ClearItemCache(...)
	QueueOperations["reset"] = true
end

function PastLoot:ASCENSION_STORE_COLLECTION_ITEM_LEARNED(Event, ID, ...)
	QueueOperations["IDs"][ID] = true
end

function PastLoot:BAG_ITEM_REMOVED(Bag, Slot, ID, StackCount, ...)
	QueueOperations["IDs"][ID] = true
end

function PastLoot:BAG_ITEM_COUNT_CHANGED(Bag, Slot, ID, NewStackNum, Change, ...)
	QueueOperations["IDs"][ID] = true
	--	QueueOperations["BagSlots_Count"][Bag][Slot] = NewStackNum
end

function PastLoot:BAG_ITEM_REPLACED(Bag, Slot, OldID, OldCount, NewID, NewCount, ...)
	QueueOperations["IDs"][OldID] = true
	QueueOperations["IDs"][NewID] = true
	--	QueueOperations["BagSlots_Location"][Bag][Slot] = true
end

local function shallow_copy(t)
	local t2 = {}
	for k, v in pairs(t) do
		t2[k] = v
	end
	return t2
end

function PastLoot:EQUIPMENT_SETS_CHANGED(Event, ...)
	if Event ~= "EQUIPMENT_SETS_CHANGED" then return end
	local oldsets = shallow_copy(PastLoot.setGUIDs)
	update_sets()
	-- check the old and new lists for differences
	for k, _ in pairs(PastLoot.setGUIDs) do
		if not oldsets[k] then
			QueueOperations["GUIDs"][k] = true
		end
	end
	for k, _ in pairs(oldsets) do
		if not PastLoot.setGUIDs[k] then
			QueueOperations["GUIDs"][k] = true
		end
	end
end

function PastLoot:MERCHANT_SHOW(Event, ...)
	if Event ~= "MERCHANT_SHOW" or "Fix-o-Tron 5000" == UnitName("target") then return end
	self:ResetCache()
	PastLoot:UpdateBags() -- clear out any pending operations
	local _, sold
	local amount = 0
	for _, bag in ipairs(PastLoot.bags) do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemObj
			local guid = GetContainerItemGUID(bag, slot)
			if PastLoot.EvalCache[guid] then
				itemObj = PastLoot.EvalCache[guid]["itemObj"]
			else
				itemObj = PastLoot:FillContainerItemInfo(nil, bag, slot)
			end
			if itemObj and itemObj.vendorPrice and itemObj.vendorPrice > 0 then
				local result = PastLoot:GetItemEvaluation(itemObj)
				if not result then
					PastLoot:Debug("Invalid Result: slot( " .. bag .. "," .. slot .. ") " .. itemObj.link)
				elseif result[1] == 2 or result[1] == 3 then
					amount = amount + itemObj.count * itemObj.vendorPrice
					if sold and strlen(sold) + strlen(itemObj.link) > 255 then
						PastLoot:Pour("Sold: " .. sold)
						sold = nil
					end
					-- only show count if > 1
					local c = ""
					if itemObj.count > 1 then
						c = itemObj.count .. "x "
					end
					if sold then
						sold = sold .. ", " .. c .. itemObj.link
					else
						sold = c .. itemObj.link
					end
					PastLoot:AddLastRoll(guid)
					-- try to collect appearances before vendoring
					if self.db.profile.LearnWardrobe then
						local appearanceID = C_Appearance.GetItemAppearanceID(itemObj.id)
						if appearanceID and not C_AppearanceCollection.IsAppearanceCollected(appearanceID) then
							C_AppearanceCollection.CollectItemAppearance(itemObj.guid)
						end
					end
					UseContainerItem(bag, slot)
				end
			end
		end
	end
	if sold then
		PastLoot:Pour("Sold: " .. sold)
		PastLoot:Pour("Total: " .. GetCoinTextureString(amount))
	end
end

function PastLoot:EvaluateItem(itemObj)
	if not itemObj or not itemObj.link then return end
	local Name = itemObj.name
	PastLootTT:ClearLines()
	PastLootTT:SetHyperlink(itemObj.link)
	for WidgetKey, WidgetValue in ipairs(self.RuleWidgets) do
		WidgetValue:SetMatch(itemObj, PastLootTT)
	end
	local MatchedRule, NumFilters
	local IsMatch, IsException, NormalMatch, ExceptionMatch, HadNoNormal
	local NormalMatchText, ExceptionMatchText = "", ""
	for RuleKey, RuleValue in ipairs(self.db.profile.Rules) do
		self:Debug("Checking rule " .. RuleKey .. " " .. RuleValue.Desc)
		if (self.db.profile.SkipRules and self.SkipRules[RuleKey]) then
			if (self.db.profile.SkipWarning) then
				self:Pour("|cff33ff99" ..
					L["PastLoot"] .. "|r: " .. string.gsub(L["Skipping %rule%"], "%%rule%%", RuleValue.Desc))
			end
		else
			MatchedRule = true
			for WidgetKey, WidgetValue in ipairs(self.RuleWidgets) do
				NumFilters = WidgetValue:GetNumFilters(RuleKey) or 0
				if (NumFilters > 0) then
					NormalMatchText, ExceptionMatchText = "", ""
					self:Debug("Checking filter " .. WidgetValue.Info[1] .. " (" .. NumFilters .. " NumFilters)")
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
						if (IsMatch) then
							IsMatch = true
						else
							IsMatch = false
						end
						IsException = WidgetValue:IsException(RuleKey, Index)
						if (IsException) then
							ExceptionMatch = ExceptionMatch or IsMatch
							ExceptionMatchText = ExceptionMatchText .. Index .. "-" .. tostring(IsMatch) .. " OR "
							if (IsMatch) then -- don't have to go any further, one single true in the exception = a false in the entire filter.
								break
							end
						else
							NormalMatch = NormalMatch or IsMatch
							HadNoNormal = false
							NormalMatchText = NormalMatchText .. Index .. "-" .. tostring(IsMatch) .. " OR "
						end
					end -- Each Filter
					if ((NormalMatch or HadNoNormal) and not ExceptionMatch) then
						self:Debug("Filter matched: (" ..
							NormalMatchText .. tostring(HadNoNormal) .. ") AND NOT (" .. ExceptionMatchText .. " false)")
					else
						self:Debug("Filter did not match: (" ..
							NormalMatchText .. tostring(HadNoNormal) .. ") AND NOT (" .. ExceptionMatchText .. " false)")
						MatchedRule = false
						break
					end
				end -- NumFilters > 0
			end -- Each Widget

			if (MatchedRule) then
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
				self:SendMessage("PastLoot_OnRoll", itemObj.link, RuleKey, RollMethod) -- Maybe change this to OnRuleMatched
				if (not self.TestLink) then
					if (RollMethod) then
						-- RollOnLoot(RollID, RollMethod)
						return RollMethod, RuleKey
					end
				end
				-- Add to LastRolls
				local ItemTexture, TextLine, Method
				if (RollMethod) then
					Method = RollMethodLookup[RollMethod]
				else
					Method = L["Ignored"]
				end
				TextLine = string.format("|T%s:0|t %s - %s", itemObj.texture, itemObj.link, Method)
				if (#self.LastRolls == 10) then
					table.remove(self.LastRolls, 1)
				end
				table.insert(self.LastRolls, TextLine)
				-- Send StatusMsg
				if (self.db.profile.Quiet == false) then
					-- Workaround for LibSink.  It can handle |c and |r color stuff, but not full ItemLinks
					local ItemText
					if (self.db.profile.SinkOptions.sink20OutputSink == "Channel") then
						ItemText = itemObj.name
					else
						ItemText = itemObj.link
					end
					StatusMsg = string.gsub(StatusMsg, "%%item%%", ItemText)
					StatusMsg = string.gsub(StatusMsg, "%%rule%%", RuleValue.Desc)
					self:Pour("|cff33ff99" .. L["PastLoot"] .. "|r: " .. StatusMsg)
				end
				self.TestLink = nil
				return
			end --MatchedRule
		end -- SkipRules
		self:Debug("Rule not matched, trying another")
	end --RuleKey, RuleValue
	self:Debug("Ran out of rules, ignoring")
	if (self.TestLink) then
		self:Pour(itemObj.link .. ": " .. L["No rules matched."])
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
			if (not self.DefaultVars[VarKey]) then
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
			if (not RuleValue[DefaultValue[1]] and DefaultValue[2]) then
				self.db.profile.Rules[RuleKey][DefaultValue[1]] = self:CopyTable(DefaultValue[2])
			end
		end
		-- Check each variable to see if it's listed in the DefaultTemplate
		for VarKey, VarValue in pairs(RuleValue) do
			if (not self.DefaultVars[VarKey]) then
				self:Debug("Could not find some variables in rule " .. RuleValue.Desc)
				self.SkipRules[RuleKey] = true
				RulesSkipped = true
				break
			end
		end
	end
	if (RulesSkipped and self.db.profile.SkipRules) then
		self:Pour("|cff33ff99" .. L["PastLoot"] .. "|r: " .. L["Found some rules that will be skipped."])
	end
end

function PastLoot:Debug(...)
	local DebugLine, Counter
	if (self.DebugVar == true) then
		DebugLine = ""
		for Counter = 1, select("#", ...) do
			DebugLine = DebugLine .. select(Counter, ...)
		end
		self:Print(DebugLine)
	end
end

function PastLoot:IterateRules(CallbackFunc, ...)
	if (PastLootDB and PastLootDB.profiles) then
		for ProfileKey, ProfileValue in pairs(PastLootDB.profiles) do
			if (ProfileValue.Rules) then
				for RuleKey, RuleValue in ipairs(ProfileValue.Rules) do
					if (type(CallbackFunc) == "string") then
						self[CallbackFunc](self, RuleValue, ...)
					elseif (type(CallbackFunc) == "function") then
						CallbackFunc(RuleValue, ...)
					end
				end -- RuleKey, RuleValue
			end -- if ProfileValue.Rules
		end -- ProfileKey, ProfileValue
	elseif (self.db and self.db.profile and self.db.profile.Rules) then
		for RuleKey, RuleValue in ipairs(self.db.profile.Rules) do
			if (type(CallbackFunc) == "string") then
				self[CallbackFunc](self, RuleValue, ...)
			elseif (type(CallbackFunc) == "function") then
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
