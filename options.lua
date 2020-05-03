local addonName, Verbose = ...

local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local spellsIconID = 134414  -- inv_misc_rune_01 (Hearthstone)
local combatIconID = 132349  -- ability_warrior_offensivestance
local npcIconID = 2056011  -- ability_warrior_offensivestance
local achievementsIconID = 236670  -- ui_chat


Verbose.options = {
    name = addonName,
    handler = Verbose,
    type = "group",
    childGroups = "tab",
    args = {
        general = {
            -- General options
            type = "group",
            name = "General",
            order = 10,
            args = {
                enable = {
                    type = "toggle",
                    name = "Enable speeches",
                    order = 10,
                    get = function(info) return Verbose.db.profile.enabled end,
                    set = function(info, value) if value then Verbose:OnEnable() else Verbose:OnDisable() end end,
                },
                cooldown = {
                    type = "range",
                    name = "Global message cooldown (s)",
                    order = 20,
                    min = 0,
                    max = 3600,
                    softMax = 60,
                    bigStep = 1,
                    get = function(info) return Verbose.db.profile.cooldown end,
                    set = function(info, value) Verbose.db.profile.cooldown = value end,
                },
                speakDebug = {
                    type = "toggle",
                    name = "Print debug info for muted messages",
                    order = 30,
                    width = "double",
                    get = function(info) return Verbose.db.profile.speakDebug end,
                    set = function(info, value) Verbose.db.profile.speakDebug = value end,
                },
                eventDebug = {
                    type = "toggle",
                    name = "Print all event info",
                    order = 40,
                    width = "double",
                    get = function(info) return Verbose.db.profile.eventDebug end,
                    set = function(info, value) Verbose.db.profile.eventDebug = value end,
                },
                reloadui = {
                    type = "execute",
                    name = "Save data (/reloadui)",
                    order = 50,
                    func = ReloadUI,
                },
            },
        },
        events = {
            -- Tree of known events, and associated configuration
            type = "group",
            name = "Events",
            order = 20,
            childGroups = "tree",
            args = {
                spellcasts = {
                    type = "group",
                    name = "Spellcasts",
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
    },
}

function Verbose:populateEvent(parent, event, title, icon)
    self.options.args.events.args[parent].args[event] = {
        type = "group",
        name = title,
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
                min = 0,
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
                multiline = 20,
                width = "full",
                get = function(info)
                    return Verbose:TableToText(self:EventData(info).messages)
                end,
                set = function(info, value) self:TextToTable(value, self:EventData(info).messages) end,
            },
        },
    }
end

Verbose:populateEvent("combat", "PLAYER_DEAD", "Death")
Verbose:populateEvent("combat", "PLAYER_ALIVE", "Return to life")
Verbose:populateEvent("combat", "PLAYER_UNGHOST", "Return to life from ghost")
Verbose:populateEvent("combat", "RESURRECT_REQUEST", "Resurrection request")
Verbose:populateEvent("combat", "PLAYER_REGEN_DISABLED", "Entering combat")
Verbose:populateEvent("combat", "PLAYER_REGEN_ENABLED", "Leaving combat")
Verbose:populateEvent("achievements", "PLAYER_LEVEL_UP", "Level up")
Verbose:populateEvent("achievements", "ACHIEVEMENT_EARNED", "Achievement")
Verbose:populateEvent("npc", "GOSSIP_SHOW", "Begin talking")
Verbose:populateEvent("npc", "GOSSIP_CLOSED", "Stop talking")
Verbose:populateEvent("npc", "BARBER_SHOP_OPEN", "BARBER_SHOP_OPEN")
Verbose:populateEvent("npc", "BARBER_SHOP_CLOSE", "BARBER_SHOP_CLOSE")
Verbose:populateEvent("npc", "MAIL_SHOW", "MAIL_SHOW")
Verbose:populateEvent("npc", "MAIL_CLOSED", "MAIL_CLOSED")
Verbose:populateEvent("npc", "MERCHANT_SHOW", "MERCHANT_SHOW")
Verbose:populateEvent("npc", "MERCHANT_CLOSED", "MERCHANT_CLOSED")
Verbose:populateEvent("npc", "QUEST_GREETING", "QUEST_GREETING")
Verbose:populateEvent("npc", "QUEST_FINISHED", "QUEST_FINISHED")
Verbose:populateEvent("npc", "TAXIMAP_OPENED", "TAXIMAP_OPENED")
Verbose:populateEvent("npc", "TAXIMAP_CLOSED", "TAXIMAP_CLOSED")
Verbose:populateEvent("npc", "TRAINER_SHOW", "TRAINER_SHOW")
Verbose:populateEvent("npc", "TRAINER_CLOSED", "TRAINER_CLOSED")


-- Return spell and event data for callbacks from info arg
function Verbose:EventData(info)
    return self.db.profile.events[info[#info - 1]]
end


Verbose.defaults = {
    profile = {
        enabled = true,
        speakDebug = true,
        cooldown = 10,
        lastTime = 0,

        -- For LibDBIcon
        minimap = { hide = false, },

        events = {
            spells = {},
            PLAYER_DEAD = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            PLAYER_ALIVE = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            PLAYER_UNGHOST = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            RESURRECT_REQUEST = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            PLAYER_REGEN_DISABLED = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            PLAYER_REGEN_ENABLED = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            PLAYER_LEVEL_UP = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            ACHIEVEMENT_EARNED = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            GOSSIP_SHOW = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            GOSSIP_CLOSED = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            BARBER_SHOP_OPEN = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            BARBER_SHOP_CLOSE = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            MAIL_SHOW = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            MAIL_CLOSED = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            MERCHANT_SHOW = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            MERCHANT_CLOSED = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            QUEST_GREETING = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            QUEST_FINISHED = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            TAXIMAP_OPENED = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            TAXIMAP_CLOSED = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            TRAINER_SHOW = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            TRAINER_CLOSED = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
        },
        lists = {
            -- ListIDXXXX = {
            --     name = "Foo",
            --     values = { "Bar", "Baz" }
            -- },
        },
    }
}

function Verbose:UpdateOptionsGUI()
    -- AceConfigRegistry:NotifyChange(addonName) doesn't work here
    -- I guess it's because it's not the option values that change
    -- but that new options are created
    Verbose:HideOptions()
    Verbose:ShowOptions()
end

function Verbose:SelectOption(...)
    AceConfigDialog:SelectGroup(addonName, ...)
end

function Verbose:RegisterOptions()
    -- Load saved config
    self.db = LibStub("AceDB-3.0"):New("VerboseDB", self.defaults)

    -- Add dynamic data to options
    Verbose:EventsDBToOptions()
    Verbose:ListDBToOptions()

    -- Add profile config tab to options
    self.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    self.options.args.profiles.order = 40

    -- Register options
    AceConfig:RegisterOptionsTable(
        addonName,
        self.options
    )
    self:RegisterChatCommand("verbose", "ChatCommand")
    self:RegisterChatCommand("verb", "ChatCommand")
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

function Verbose:ChatCommand(input)
    if not input or input:trim() == "" then
        self:ShowOptions()
    else
        LibStub("AceConfigCmd-3.0"):HandleCommand("verbose", "Verbose", input)
    end
end
