local addonName, Verbose = ...

-- GLOBALS: VerboseOptionsTableForDebug

-- Lua functions
local error = error
local pairs = pairs
local wipe = wipe

-- WoW globals
local SetBindingClick = SetBindingClick
local SaveBindings = SaveBindings
local GetCurrentBindingSet = GetCurrentBindingSet
local ReloadUI = ReloadUI

local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceConsole = LibStub("AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigCmd = AceConfigCmdLibStub("AceConfigCmd-3.0")
local LibDBIcon = LibStub("LibDBIcon-1.0")

local spellsIconID = 134414  -- inv_misc_rune_01 (Hearthstone)
local combatIconID = 132349  -- ability_warrior_offensivestance
local npcIconID = 2056011  -- ability_warrior_offensivestance
local achievementsIconID = 236670  -- ui_chat
local spellbookIcon = 133741  -- inv_misc_book_09
local mountsIconID = "Interface\\Icons\\MountJournalPortrait"

local displayedData = ""

Verbose.multilineHeightNoTab = 17
Verbose.multilineHeightTab = 14

Verbose.options = {
    name = addonName,
    handler = Verbose,
    type = "group",
    childGroups = "tab",
    args = {
        general = {
            -- General options
            type = "group",
            name = "Options",
            order = 10,
            args = {
                enable = {
                    type = "toggle",
                    name = "Enable speeches",
                    order = 10,
                    width = "full",
                    get = function(info) return Verbose.db.profile.enabled end,
                    set = function(info, value) if value then Verbose:OnEnable() else Verbose:OnDisable() end end,
                },
                cooldown = {
                    type = "range",
                    name = "Global message cooldown (s)",
                    order = 20,
                    width = "full",
                    min = 0,
                    max = 3600,
                    softMax = 600,
                    bigStep = 1,
                    get = function(info) return Verbose.db.profile.cooldown end,
                    set = function(info, value) Verbose.db.profile.cooldown = value end,
                },
                showMinimapIcon = {
                    type = "toggle",
                    name = "Show minimap icon",
                    order = 22,
                    width = "double",
                    get = function(info) return not Verbose.db.profile.minimap.hide end,
                    set = function(info, value)
                        Verbose.db.profile.minimap.hide = not value
                        if value then LibDBIcon:Show(addonName) else LibDBIcon:Hide(addonName) end
                    end,
                },
                keybindOpenWorld = {
                    type = "keybinding",
                    name = "Keybind for open world workaround",
                    order = 24,
                    width = "double",
                    get = function(info) return Verbose.db.profile.keybindOpenWorld end,
                    set = function(info, value)
                        Verbose.db.profile.keybindOpenWorld = value
                        -- Add Binding
                        SetBindingClick(value, Verbose.BindingButton:GetName())
                        SaveBindings(GetCurrentBindingSet())  -- Retail
                        -- AttemptToSaveBindings(GetCurrentBindingSet())  -- Classic
                    end,
                },
                debugHeader = {
                    type = "header",
                    name = "DEBUG",
                    order = 28,
                },
                eventDebug = {
                    type = "toggle",
                    name = "Print events",
                    desc = "Print to console when events fire",
                    order = 40,
                    width = "double",
                    get = function(info) return Verbose.db.profile.eventDebug end,
                    set = function(info, value) Verbose.db.profile.eventDebug = value end,
                },
                eventDetailDebug = {
                    type = "toggle",
                    name = "Print all event info",
                    desc = "Print all event details to console",
                    order = 41,
                    width = "double",
                    get = function(info) return Verbose.db.profile.eventDetailDebug end,
                    set = function(info, value) Verbose.db.profile.eventDetailDebug = value end,
                },
                speakDebug = {
                    type = "toggle",
                    name = "Print all speaking info",
                    desc = "Print to console why speaks don't trigger",
                    order = 42,
                    width = "double",
                    get = function(info) return Verbose.db.profile.speakDebug end,
                    set = function(info, value) Verbose.db.profile.speakDebug = value end,
                },
                mute = {
                    type = "toggle",
                    name = "Don't speak but print to console only",
                    desc = "Don't spam the world when testing and tuning messages",
                    order = 50,
                    width = "double",
                    get = function(info) return Verbose.db.profile.mute end,
                    set = function(info, value) Verbose.db.profile.mute = value end,
                },
                reloadui = {
                    type = "execute",
                    name = "Save data by reloading UI",
                    desc = "Addon data is only saved to disk on few occasion, one of them being reloading the UI.",
                    order = 60,
                    width = "double",
                    func = ReloadUI,
                },
            },
        },
        events = {
            -- Tree of known events, and associated configuration
            type = "group",
            name = "Events",
            desc = "Per event messages configuration",
            order = 20,
            childGroups = "tree",
            args = {
                spellbook = {
                    type = "group",
                    name = "Spellbook",
                    order = 1,
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
                            name = "All spellbook spells.",
                            fontSize = "medium",
                            order = 1,
                        },
                    },
                },
                mounts = {
                    type = "group",
                    name = "Mounts",
                    order = 3,
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
                            name = "Documentation here.",
                            fontSize = "medium",
                            order = 1,
                        },
                    },
                },
                combatLog = {
                    type = "group",
                    name = "Combat log",
                    order = 5,
                    icon = combatIconID,
                    iconCoords = Verbose.iconCropBorders,
                    childGroups = "tree",
                    args = {
                        title = {
                            type = "description",
                            name = Verbose:IconTextureBorderlessFromID(combatIconID) .. " Combat log",
                            fontSize = "large",
                            order = 0,
                        },
                        info = {
                            type = "description",
                            name = "Documentation here.",
                            fontSize = "medium",
                            order = 1,
                        },
                    },
                },
                spells = {
                    type = "group",
                    name = "Spells, Items...",
                    order = 10,
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
                            name = "Documentation here.",
                            fontSize = "medium",
                            order = 1,
                        },
                    },
                },
                combat = {
                    type = "group",
                    name = "Combat",
                    order = 20,
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
                            name = "Documentation here.",
                            fontSize = "medium",
                            order = 1,
                        },
                    },
                },
                npc = {
                    type = "group",
                    name = "NPC interaction",
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
                            name = "Documentation here.",
                            fontSize = "medium",
                            order = 1,
                        },
                    },
                },
                achievements = {
                    type = "group",
                    name = "Achievements",
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
                            name = "Documentation here.",
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
            name = "Lists",
            desc = "Substitution lists",
            order = 30,
            childGroups = "tree",
            args = {
                newList = {
                    type = "execute",
                    name = "New list",
                    func = "CreateList",
                },
            },
        },
        save = {
            -- Replacement lists
            type = "group",
            name = "Save",
            desc = "Save or Load configuration",
            order = 35,
            childGroups = "tree",
            args = {
                save = {
                    type = "execute",
                    name = "Update current data",
                    func = "PrepareSaveData",
                    desc = "Dump addon configuration to the input box. You can then copy the text to save or share it.",
                    order = 10,
                },
                load = {
                    type = "execute",
                    name = "Load data",
                    func = "LoadData",
                    desc = "Loads the addon configuration in the input box. |cFFFF0000Warning: This will permanentely destroy all your current configuration !|r",
                    order = 20,
                },
                data = {
                    type = "input",
                    name = "Addon data",
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

function Verbose:populateEvent(parent, event, title, icon)
    if not title then
        title = event:lower():gsub("_", " ")
        title = title:sub(1,1):upper() .. title:sub(2)
    end

    self.options.args.events.args[parent].args[event] = {
        type = "group",
        name = title,
        icon = icon,
        iconCoords = Verbose.iconCropBorders,
        args = {
            enable = {
                type = "toggle",
                name = "Enable",
                order = 10,
                width = "full",
                get = function(info) return self:EventData(info).enabled end,
                set = function(info, value) self:EventData(info).enabled = value end,
            },
            proba = {
                type = "range",
                name = "Message probability",
                order = 20,
                isPercent = true,
                min = 0,
                max = 1,
                bigStep = 0.05,
                get = function(info) return self:EventData(info).proba end,
                set = function(info, value) self:EventData(info).proba = value end,
            },
            cooldown = {
                type = "range",
                name = "Message cooldown (s)",
                order = 30,
                min = 1,
                max = 3600,
                softMax = 60,
                bigStep = 1,
                get = function(info) return self:EventData(info).cooldown end,
                set = function(info, value) self:EventData(info).cooldown = value end,
            },
            list = {
                type = "input",
                name = "Messages, one per line",
                order = 40,
                multiline = Verbose.multilineHeightNoTab,
                width = "full",
                get = function(info)
                    return Verbose:TableToText(self:EventData(info).messages)
                end,
                set = function(info, value) self:TextToTable(value, self:EventData(info).messages) end,
            },
        },
    }
end

-- Populate events config
for event, eventData in pairs(Verbose.usedEvents) do
    Verbose:populateEvent(
        eventData.category,
        event,
        eventData.title,
        eventData.icon
    )
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

function Verbose:ManageOptions()
    -- Get data from game and populaite self.options
    self:InitSpellbook()
    self:InitMounts()

    -- Initialize dB
    self:UpdateDefaultDB()
    self:SetupDB()

    -- Load DB to options
    self:SpellDBToOptions()
    self:CombatLogSpellDBToOptions()
    self:ListDBToOptions()

    -- Add profile config tab to options
    self.options.args.profiles = AceDBOptions:GetOptionsTable(self.db)
    self.options.args.profiles.order = 40

    -- Register options
    AceConfig:RegisterOptionsTable(
        addonName,
        self.options
    )
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

function Verbose:ChatCommand(input)
    local arg1 = AceConsole:GetArgs(input, 1, 1)
    if not arg1 then
        self:ShowOptions()
    elseif arg1 == "openworld" then
        Verbose:OpenWorldWorkaround()
    else
        AceConfigCmd:HandleCommand("verbose", "Verbose", input)
    end
end
