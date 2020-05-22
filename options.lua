local addonName, Verbose = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- GLOBALS: VerboseOptionsTableForDebug

-- Lua functions
local error = error
local pairs = pairs
local wipe = wipe
local tconcat = table.concat

-- WoW globals
local SetBindingClick = SetBindingClick
local SaveBindings = SaveBindings
local GetCurrentBindingSet = GetCurrentBindingSet
local ReloadUI = ReloadUI

local AceGUI = LibStub("AceGUI-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LibDBIcon = LibStub("LibDBIcon-1.0")

local spellsIconID = 134414  -- inv_misc_rune_01 (Hearthstone)
local combatIconID = 132349  -- ability_warrior_offensivestance
local npcIconID = 2056011  -- ability_warrior_offensivestance
local achievementsIconID = 236670  -- ui_chat
local spellbookIcon = 133741  -- inv_misc_book_09
local mountsIconID = "Interface\\Icons\\MountJournalPortrait"
local damageIcon = 1394889

local displayedData = ""

local loremIpsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."

Verbose.multilineHeightNoTab = 20
Verbose.multilineHeightTab = 16

Verbose.options = {
    name = addonName,
    handler = Verbose,
    type = "group",
    childGroups = "tab",
    args = {
        general = {
            -- General options
            type = "group",
            name = L["Options"],
            order = 10,
            args = {
                enable = {
                    type = "toggle",
                    name = ENABLE,
                    order = 10,
                    get = function(info) return Verbose.db.profile.enabled end,
                    set = function(info, value) if value then Verbose:OnEnable() else Verbose:OnDisable() end end,
                },
                showMinimapIcon = {
                    type = "toggle",
                    name = L["Show minimap icon"],
                    order = 15,
                    width = "double",
                    get = function(info) return not Verbose.db.profile.minimap.hide end,
                    set = function(info, value)
                        Verbose.db.profile.minimap.hide = not value
                        if value then LibDBIcon:Show(addonName) else LibDBIcon:Hide(addonName) end
                    end,
                },
                newline19 = { type="description", name="", order=19.5 },
                cooldown = {
                    type = "range",
                    name = L["Global message cooldown (s)"],
                    order = 20,
                    min = 0,
                    max = 3600,
                    softMax = 600,
                    bigStep = 1,
                    width = "double",
                    get = function(info) return Verbose.db.profile.cooldown end,
                    set = function(info, value) Verbose.db.profile.cooldown = value end,
                },
                bubbleHeader = {
                    type = "header",
                    name = L["Thought bubble"],
                    order = 21,
                },
                bubbleDesc = {
                    type = "description",
                    name = L["The thought bubble serves as a workaround for addon API limitations outside of instances."],
                    order = 22,
                },
                selectWorkaround = {
                    type = "select",
                    name = L["Select workaround"],
                    desc = L["Two workarounds are possible:\n- a |cFF00FF00thought bubble|r is displayed for you only, and the message can be said aloud in the next few seconds by pressing the keybind or using the command |cFF00FF00/vw|r (typically in a macro)\n- an |cFF00FF00emote|r is directly displayed in chat for everyone to see, but no bubble will be displayed so it might go unnoticed"],
                    order = 22.25,
                    values = { bubble = L["Thought bubble"], emote = L["Emote"] },
                    get = function(info) return Verbose.db.profile.selectWorkaround end,
                    set = function(info, value) Verbose.db.profile.selectWorkaround = value end,
                },
                keybindOpenWorld = {
                    type = "keybinding",
                    name = NORMAL_FONT_COLOR_CODE..L["Speak aloud"]..FONT_COLOR_CODE_CLOSE,
                    desc = L["Keybind to speak aloud the bubble message."],
                    order = 24,
                    get = function(info) return Verbose.db.profile.keybindOpenWorld end,
                    set = function(info, value)
                        Verbose.db.profile.keybindOpenWorld = value
                        -- Add Binding
                        SetBindingClick(value, Verbose.BindingButton:GetName())
                        SaveBindings(GetCurrentBindingSet())  -- Retail
                        -- AttemptToSaveBindings(GetCurrentBindingSet())  -- Classic
                    end,
                },
                newline22 = { type="description", name="", order=22.75 },
                bubblePosition = {
                    type = "select",
                    name = L["Position"],
                    desc = L["Position is relative to the player frame"],
                    order = 23,
                    values = {
                        topleft = L["Above on the left"],
                        topright = L["Above on the right"],
                        bottomleft = L["Below on the left"],
                        bottomright = L["Below on the right"] },
                    get = function(info) return Verbose.db.profile.bubblePosition end,
                    set = function(info, value)
                        Verbose.db.profile.bubblePosition = value
                        Verbose:UpdateBubbleFrame(loremIpsum)
                        Verbose:UseBubbleFrame(loremIpsum)
                    end,
                },
                newline24 = { type="description", name="", order=24.5 },
                positionVerticalOffset = {
                    type = "range",
                    name = L["Vertical offset"],
                    order = 25,
                    min = -1000,
                    max = 1000,
                    softMin = -100,
                    softMax = 100,
                    step = 1,
                    get = function(info) return Verbose.db.profile.bubbleVerticalOffset end,
                    set = function(info, value)
                        Verbose.db.profile.bubbleVerticalOffset = value
                        Verbose:UpdateBubbleFrame(loremIpsum)
                        Verbose:UseBubbleFrame(loremIpsum)
                    end,
                },
                positionHorizontalOffset = {
                    type = "range",
                    name = L["Horizontal offset"],
                    order = 26,
                    min = -1000,
                    max = 1000,
                    softMin = -100,
                    softMax = 100,
                    step = 1,
                    get = function(info) return Verbose.db.profile.bubbleHorizontalOffset end,
                    set = function(info, value)
                        Verbose.db.profile.bubbleHorizontalOffset = value
                        Verbose:UpdateBubbleFrame(loremIpsum)
                        Verbose:UseBubbleFrame(loremIpsum)
                    end,
                },
                debugHeader = {
                    type = "header",
                    name = L["DEBUG"],
                    order = 28,
                },
                eventDebug = {
                    type = "toggle",
                    name = L["Print events"],
                    desc = L["Print to console when events fire"],
                    order = 40,
                    get = function(info) return Verbose.db.profile.eventDebug end,
                    set = function(info, value) Verbose.db.profile.eventDebug = value end,
                },
                eventDetailDebug = {
                    type = "toggle",
                    name = L["Print all event info"],
                    desc = L["Print all event details to console"],
                    order = 41,
                    get = function(info) return Verbose.db.profile.eventDetailDebug end,
                    set = function(info, value) Verbose.db.profile.eventDetailDebug = value end,
                },
                speakDebug = {
                    type = "toggle",
                    name = L["Print all speaking info"],
                    desc = L["Print to console why messages don't trigger"],
                    order = 42,
                    width = "double",
                    get = function(info) return Verbose.db.profile.speakDebug end,
                    set = function(info, value) Verbose.db.profile.speakDebug = value end,
                },
                mute = {
                    type = "toggle",
                    name = L["Mute: Only show bubble"],
                    desc = L["Don't spam the world when testing and tuning messages"],
                    order = 50,
                    width = "double",
                    get = function(info) return Verbose.db.profile.mute end,
                    set = function(info, value) Verbose.db.profile.mute = value end,
                },
                newline59 = { type="description", name="", order=59.5 },
                reloadui = {
                    type = "execute",
                    name = L["Save data by reloading UI"],
                    desc = L["Addon data is only saved to disk on few occasion, one of them being reloading the UI."],
                    order = 60,
                    width = 1.5,
                    func = ReloadUI,
                },
            },
        },
        events = {
            -- Tree of known events, and associated configuration
            type = "group",
            name = L["Messages"],
            desc = L["Per event messages configuration"],
            order = 20,
            cmdHidden = true,
            childGroups = "tree",
            args = {
                filter = {
                    type = "input",
                    name = L["Filter spell names"],
                    order = 10,
                    get = function() return tconcat(Verbose.db.profile.filterValues, " ") end,
                    set = function(_, value)
                        wipe(Verbose.db.profile.filterValues)
                        -- Example from https://wowwiki.fandom.com/wiki/API_strsplit
                        for v in string.gmatch(value, "[^ ]+") do
                            tinsert(Verbose.db.profile.filterValues, v:lower())
                        end
                    end,
                },
                clear = {
                    type = "execute",
                    name = "",
                    image = "Interface\\Buttons\\UI-StopButton",
                    imageWidth = 16,
                    imageHeight = 16,
                    order = 11,
                    width = 0.1,
                    desc = L["Clear the filter input (to the left of this button)."],
                    func = function() wipe(Verbose.db.profile.filterValues) end,
                    disabled = function() return #Verbose.db.profile.filterValues == 0 end,
                },
                sort = {
                    type = "select",
                    name = L["Sort spells"],
                    order = 20,
                    values = { alphabetic=L["Sort by name"], recent=L["Sort by date"], count=L["Sort by count"] },
                    get = function() return Verbose.db.profile.sortSpellValue end,
                    set = function(_, value) Verbose.db.profile.sortSpellValue = value end,
                },
                unusable = {
                    type = "toggle",
                    name = L["Show non player spells"],
                    order = 21,
                    get = function() return Verbose.db.profile.showUnusableSpells end,
                    set = function(_, value) Verbose.db.profile.showUnusableSpells = value end,
                },
                spellbook = {
                    type = "group",
                    name = SPELLBOOK,
                    order = 3,
                    icon = spellbookIcon,
                    iconCoords = Verbose.iconCropBorders,
                    childGroups = "tree",
                    args = {
                        title = {
                            type = "description",
                            name = Verbose:IconTextureBorderlessFromID(spellbookIcon) .. " Spell book",
                            fontSize = "large",
                            order = 0,
                        },
                        info = {
                            type = "description",
                            name = L["All spellbook spells."],
                            fontSize = "medium",
                            order = 1,
                        },
                    },
                },
                mounts = {
                    type = "group",
                    name = MOUNTS,
                    order = 20,
                    icon = mountsIconID,
                    iconCoords = Verbose.iconCropBorders,
                    childGroups = "tree",
                    args = {
                        title = {
                            type = "description",
                            name = Verbose:IconTextureBorderlessFromID(spellsIconID) .. " Mounts",
                            fontSize = "large",
                            order = 0,
                        },
                        info = {
                            type = "description",
                            name = L["Documentation here."],
                            fontSize = "medium",
                            order = 1,
                        },
                    },
                },
                spells = {
                    type = "group",
                    name = L["Spells, Items..."],
                    order = 5,
                    icon = spellsIconID,
                    iconCoords = Verbose.iconCropBorders,
                    childGroups = "tree",
                    args = {
                        title = {
                            type = "description",
                            name = Verbose:IconTextureBorderlessFromID(spellsIconID) .. " Spellcasts",
                            fontSize = "large",
                            order = 0,
                        },
                        info = {
                            type = "description",
                            name = L["Documentation here."],
                            fontSize = "medium",
                            order = 1,
                        },
                    },
                },
                combat = {
                    type = "group",
                    name = COMBAT,
                    order = 10,
                    icon = combatIconID,
                    iconCoords = Verbose.iconCropBorders,
                    childGroups = "tree",
                    args = {
                        title = {
                            type = "description",
                            name = Verbose:IconTextureBorderlessFromID(combatIconID) .. " Combat",
                            fontSize = "large",
                            order = 0,
                        },
                        info = {
                            type = "description",
                            name = L["Documentation here."],
                            fontSize = "medium",
                            order = 1,
                        },
                        damage = {
                            type = "group",
                            name = L["Damage received"],
                            order = 12,
                            icon = damageIcon,
                            iconCoords = Verbose.iconCropBorders,
                            childGroups = "tree",
                            args = {
                                title = {
                                    type = "description",
                                    name = Verbose:IconTextureBorderlessFromID(spellsIconID) .. " Spellcasts",
                                    fontSize = "large",
                                    order = 0,
                                },
                                info = {
                                    type = "description",
                                    name = L["Documentation here."],
                                    fontSize = "medium",
                                    order = 1,
                                },
                                environmental = {
                                    type = "group",
                                    name = ENVIRONMENTAL_DAMAGE,
                                    order = 0,
                                    -- icon = spellsIconID,
                                    iconCoords = Verbose.iconCropBorders,
                                    childGroups = "tree",
                                    args = {},
                                },
                                monoSchool = {
                                    type = "group",
                                    name = L["Mono school"],
                                    order = 1,
                                    -- icon = spellsIconID,
                                    iconCoords = Verbose.iconCropBorders,
                                    childGroups = "tree",
                                    args = {},
                                },
                                dualSchools = {
                                    type = "group",
                                    name = L["Dual schools"],
                                    order = 2,
                                    -- icon = spellsIconID,
                                    iconCoords = Verbose.iconCropBorders,
                                    childGroups = "tree",
                                    args = {},
                                },
                                moreSchools = {
                                    type = "group",
                                    name = L["Triple or more schools"],
                                    order = 3,
                                    -- icon = spellsIconID,
                                    iconCoords = Verbose.iconCropBorders,
                                    childGroups = "tree",
                                    args = {},
                                },
                            },
                        },
                    },
                },
                npc = {
                    type = "group",
                    name = L["NPC interaction"],
                    order = 30,
                    icon = npcIconID,
                    iconCoords = Verbose.iconCropBorders,
                    childGroups = "tree",
                    args = {
                        title = {
                            type = "description",
                            name = Verbose:IconTextureBorderlessFromID(npcIconID) .. " NPC interaction",
                            fontSize = "large",
                            order = 0,
                        },
                        info = {
                            type = "description",
                            name = L["Documentation here."],
                            fontSize = "medium",
                            order = 1,
                        },
                    },
                },
                achievements = {
                    type = "group",
                    name = ACHIEVEMENTS,
                    order = 40,
                    icon = achievementsIconID,
                    iconCoords = Verbose.iconCropBorders,
                    childGroups = "tree",
                    args = {
                        title = {
                            type = "description",
                            name = Verbose:IconTextureBorderlessFromID(achievementsIconID) .. " Achievements",
                            fontSize = "large",
                            order = 0,
                        },
                        info = {
                            type = "description",
                            name = L["Documentation here."],
                            fontSize = "medium",
                            order = 1,
                        },
                    },
                },
            },
        },
        lists = {
            -- Replacement lists
            type = "group",
            name = L["Lists"],
            desc = L["Substitution lists"],
            order = 30,
            cmdHidden = true,
            childGroups = "tree",
            args = {
                newList = {
                    type = "execute",
                    name = L["New list"],
                    func = "CreateList",
                },
            },
        },
        save = {
            -- This is broken, it should use LibDeflate to avoid special chars in the textbox which are not rendered correctly
            type = "group",
            name = L["Save"],
            desc = L["Save or Load configuration"],
            order = 35,
            hidden = true,
            childGroups = "tree",
            args = {
                save = {
                    type = "execute",
                    name = L["Update current data"],
                    func = "PrepareSaveData",
                    desc = L["Dump addon configuration to the input box. You can then copy the text to save or share it."],
                    order = 10,
                },
                load = {
                    type = "execute",
                    name = L["Load data"],
                    func = "LoadData",
                    desc = L["Loads the addon configuration in the input box. |cFFFF0000Warning: This will permanentely destroy all your current configuration !|r"],
                    order = 20,
                },
                data = {
                    type = "input",
                    name = L["Addon data"],
                    order = 30,
                    multiline = Verbose.multilineHeightNoTab,
                    width = "full",
                    get = function(info) return displayedData end,
                    set = function(info, value) displayedData = value end,
                },
            },
        },
    },
}

VerboseOptionsTableForDebug = Verbose.options

local categoryEventOptions = {
    type = "group",
    name = function(info) return Verbose.usedEvents[info[#info]].name end,
    order = function(info) return Verbose.usedEvents[info[#info]].order end,
    args = {
        enable = {
            type = "toggle",
            name = ENABLE,
            order = 10,
            width = "full",
            get = function(info) return Verbose:EventData(info).enabled end,
            set = function(info, value) Verbose:EventData(info).enabled = value end,
        },
        proba = {
            type = "range",
            name = L["Message probability"],
            order = 35,
            isPercent = true,
            min = 0,
            max = 1,
            bigStep = 0.05,
            get = function(info) return Verbose:EventData(info).proba end,
            set = function(info, value) Verbose:EventData(info).proba = value end,
        },
        cooldown = {
            type = "range",
            name = L["Message cooldown (s)"],
            order = 30,
            min = 0,
            max = 3600,
            softMax = 600,
            bigStep = 1,
            width = 1.5,
            get = function(info) return Verbose:EventData(info).cooldown end,
            set = function(info, value) Verbose:EventData(info).cooldown = value end,
        },
        list = {
            type = "input",
            name = L["Messages, one per line"],
            order = 40,
            multiline = Verbose.multilineHeightNoTab,
            width = "full",
            get = function(info)
                return Verbose:TableToText(Verbose:EventData(info).messages)
            end,
            set = function(info, value) Verbose:TextToTable(value, Verbose:EventData(info).messages) end,
        },
    },
}
function Verbose:populateEvent(category, event)
    self.options.args.events.args[category].args[event] = categoryEventOptions
end

-- Populate events config
for event, eventData in pairs(Verbose.usedEvents) do
    Verbose:populateEvent(eventData.category, event)
end

-- Insert help
Verbose.options.args.help = Verbose:GenerateHelpOptionTable()

-- Return spell and event data for callbacks from info arg
function Verbose:EventData(info)
    return self.db.profile.events[info[#info - 1]]
end

function Verbose:UpdateOptionsGUI()
    AceConfigRegistry:NotifyChange(addonName)
end

function Verbose:SelectOption(...)
    AceConfigDialog:SelectGroup(addonName, ...)
end

function Verbose:ShowOptions()
    AceConfigDialog:Open(addonName)
end

function Verbose:HideOptions()
    AceConfigDialog:Close(addonName)
end

function Verbose:ToggleOptions()
    if AceConfigDialog.OpenFrames[addonName] then
        self:HideOptions()
    else
        self:ShowOptions()
    end
end

function Verbose:PrepareSaveData(info)
    displayedData = self:Serialize(self.db.profile)
    self:UpdateOptionsGUI()
end
function Verbose:LoadData(info)
    local status, arg = self:Deserialize(displayedData)
    if not status then
        error("Data loading error: "..arg)
    end
    local profile = self.db.profile
    wipe(profile)
    for k, v in pairs(arg) do
        profile[k] = v
    end
    ReloadUI() -- TODO: more subtle behavior...
end


function Verbose:ResetOptionsGroup(optionArgs)
    for k, v in pairs(optionArgs) do
        if v.type == "group" then
            optionArgs[k] = nil
        end
    end
end


function Verbose:RefreshOptions()
    -- Load DB to options
    self:ResetOptionsGroup(self.options.args.lists.args)
    self:ResetOptionsGroup(self.options.args.events.args.spells.args)
    self:ResetOptionsGroup(self.options.args.events.args.combat.args.damage.args.environmental.args)
    self:ResetOptionsGroup(self.options.args.events.args.combat.args.damage.args.monoSchool.args)
    self:ResetOptionsGroup(self.options.args.events.args.combat.args.damage.args.dualSchools.args)
    self:ResetOptionsGroup(self.options.args.events.args.combat.args.damage.args.moreSchools.args)
    for groupID, groupdata in pairs(self.options.args.events.args.spellbook.args) do
        if groupdata.args then
            for spellID, spellData in pairs(groupdata.args) do
                self:ResetOptionsGroup(spellData.args)
            end
        end
    end

    self:DBToOptions()
    self:UpdateOptionsGUI()
end

function Verbose:DBToOptions()
    -- Load DB to options
    self:SpellDBToOptions()
    self:ListDBToOptions()
end
