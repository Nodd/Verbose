local addonName, Verbose = ...

-- Lua functions
local pairs = pairs

local AceDB = LibStub("AceDB-3.0")

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
                cooldown = 1,
                messages = {},
            },
        },
        combatLog = {
            children = {
                -- category = {
                --     enabled = false,
                --     proba = 1,
                --     cooldown = 1,
                --     lastRecord = 0.0,
                --     messages = { "Foo", "Bar", "Baz" },
                --     children = {
                --         category = {
                --             ...
                --         },
                --     },
                -- },
            },
        },
        spells = {
            -- Populated dynamically
            ["**"] = {  -- SpellID
                ["**"] = {  -- event
                    enabled = false,
                    proba = 1,
                    cooldown = 10,
                    messages = {},
                },
            },
        },
        lists = {
            -- Populated dynamically
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
end
