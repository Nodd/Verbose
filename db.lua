local addonName, Verbose = ...

Verbose.defaults = {
    profile = {
        enabled = true,
        speakDebug = true,
        cooldown = 10,
        lastTime = 0,

        -- For LibDBIcon
        minimap = { hide = false, },

        events = {
            -- Populated below
        },
        spells = {
            -- spellID = { enabled = false, proba = 0.5, cooldown = 0, messages = { "Foo", "Bar", "Baz" } },
        },
        lists = {
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
        proba = 0.5,
        cooldown = 30,
        messages = {},
    }
end
