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
            PLAYER_DEAD = { enabled = false, proba = 0.5, cooldown = 0, messages = {} },
            PLAYER_ALIVE = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            PLAYER_UNGHOST = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            RESURRECT_REQUEST = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            PLAYER_REGEN_DISABLED = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            PLAYER_REGEN_ENABLED = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            PLAYER_LEVEL_UP = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            ACHIEVEMENT_EARNED = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            GOSSIP_SHOW = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            BARBER_SHOP_OPEN = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            BARBER_SHOP_CLOSE = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            MAIL_SHOW = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            MERCHANT_SHOW = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            QUEST_GREETING = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            TAXIMAP_OPENED = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
            TRAINER_SHOW = { enabled = false, proba = 0.5, cooldown = 30, messages = {} },
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
