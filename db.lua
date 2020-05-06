local addonName, Verbose = ...

Verbose.defaults = {
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
for event, eventData in pairs(Verbose.usedEvents) do
    Verbose.defaults.profile.events[event] = {
        enabled = false,
        proba = 1,
        cooldown = 1,
        messages = {},
    }
end
