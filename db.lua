local addonName, Verbose = ...

-- Lua functions
local pairs = pairs

local AceDB = LibStub("AceDB-3.0")

local defaultDB = {
    profile = {
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
            -- Populated below
            -- EVENT = {
            --     enabled = false,
            --     proba = 1,
            --     cooldown = 1,
            --     messages = { "Foo", "Bar", "Baz" },
            -- },
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
            -- spellID = {
            --     EVENT = {
            --         enabled = false,
            --         proba = 1,
            --         cooldown = 10,
            --         messages = { "Foo", "Bar", "Baz" },
            --     },
            -- },
        },
        lists = {
            -- Populated dynamically
            -- listID = {
            --     name = "Foo",
            --     values = { "Bar", "Baz" }
            -- },
        },
    }
}

-- Populate events
function Verbose:UpdateDefaultDB()
    for event, eventData in pairs(self.usedEvents) do
        defaultDB.profile.events[event] = {
            enabled = false,
            proba = 1,
            cooldown = 1,
            messages = {},
        }
    end
end

function Verbose:SetupDB()
    -- Load saved config
    self.db = AceDB:New("VerboseDB", defaultDB)
end
