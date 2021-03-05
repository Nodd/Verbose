local addonName, Verbose = ...

-- Lua functions
local pairs = pairs

local AceDB = LibStub("AceDB-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

Verbose.lastDBVersion = 1

-- ["**"] are dynamic defaults, see https://www.wowace.com/projects/ace3/pages/ace-db-3-0-tutorial#title-3-1

local defaultDB = {
    profile = {
        dbVersion = Verbose.lastDBVersion,
        enabled = true,
        eventDebug = false,
        eventDetailDebug = false,
        speakDebug = false,
        mute = false,
        cooldown = 10,
        lastTime = 0,

        filterValues = {},
        sortSpellValue = "alphabetic",
        showPlayerSpellsOnly = false,
        showConfiguredSpellsOnly = false,

        selectWorkaround = "bubble",  -- "bubble" or "emote"
        bubblePosition = "bottomright",  -- "bottom" or "top" .. "right" or "left"
        bubbleVerticalOffset = 0,
        bubbleHorizontalOffset = 0,

        -- For LibDBIcon
        minimap = {
            hide = false,
            minimapPos = 190,  -- Set default so that it doesn't spawn above another one
        },

        events = {
            --- Defaults for all events.
            ["**"] = {
                enabled = false,
                proba = 1,
                cooldown = 10,
                count = 0,
                lastRecord = 0,
                merge = true,
                messages = {},
            },
        },
        spells = {
            ["**"] = {  -- SpellID
                ["**"] = {  -- event, either a true event or a subevent from COMBAT_LOG_EVENT_UNFILTERED
                    enabled = false,
                    proba = 1,
                    cooldown = 10,
                    count = 0,
                    lastRecord = 0,
                    merge = true,
                    messages = {},
                },
            },
        },
        damage = {
            ["**"] = {  -- ID
                enabled = false,
                proba = 1,
                cooldown = 10,
                count = 0,
                lastRecord = 0,
                merge = true,
                messages = {},
            },
        },
        lists = {
            ["**"] = {  -- List name
                name = "",
                values = {}
            },
        },
    }
}

function Verbose:SetupDB()
    -- Load saved config
    self.db = AceDB:New("VerboseDB", defaultDB)

    -- Add profile config tab to options
    self.options.args.profiles = AceDBOptions:GetOptionsTable(self.db)
    self.options.args.profiles.order = 40

    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshOptions")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshOptions")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshOptions")
end
