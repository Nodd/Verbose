local addonName, Verbose = ...

function Verbose:EventDbgPrint(...)
    if self.db.profile.eventDebug then
        self:Print("EVENT:", ...)
    end
end
function Verbose:EventDetailsDbgPrint(...)
    if self.db.profile.eventDetailDebug then
        self:Print("   EVENT:", ...)
    end
end

Verbose.usedEvents = {
    -- EVENT = {
    --     callback,  -- Function to call
    --     category,  -- Used for grouping events
    --     title,  -- Display name
    --     icon,  -- Icon ID
    --     inClassic,  -- Exists in WoW Classic
    -- },

    -- Death events
    PLAYER_DEAD = { callback="ManageNoArgEvent", category="combat", title="Death", icon=icon, classic=true },
    PLAYER_ALIVE = { callback="ManageNoArgEvent", category="combat", title="Return to life", icon=icon, classic=true },
    PLAYER_UNGHOST = { callback="ManageNoArgEvent", category="combat", title="Return to life from ghost", icon=135898, classic=true },  -- From ghost to alive
    RESURRECT_REQUEST = { callback="DUMMYEvent", category="combat", title="Resurrection request", icon=237542, classic=true },

    -- Combat events
    -- UNIT_THREAT_LIST_UPDATE = { callback="DUMMYEvent", category=category, title=title, icon=icon, classic=false }, --not in Classic
    -- COMPANION_UPDATE = { callback="DUMMYEvent", category=category, title=title, icon=icon, classic=false }, --not in Classic
    PLAYER_REGEN_DISABLED = { callback="ManageNoArgEvent", category="combat", title="Entering combat", icon=icon, classic=true },  -- Entering combat
    PLAYER_REGEN_ENABLED = { callback="ManageNoArgEvent", category="combat", title="Leaving combat", icon=icon, classic=true },  -- Leaving combat

    -- Chat events
    -- CHAT_MSG_WHISPER = { callback="DUMMYEvent", category=category, title=title, icon=icon, classic=true },
    -- CHAT_MSG_BN_WHISPER = { callback="DUMMYEvent", category=category, title=title, icon=icon, classic=true },
    -- CHAT_MSG_GUILD = { callback="DUMMYEvent", category=category, title=title, icon=icon, classic=true },
    -- CHAT_MSG_PARTY = { callback="DUMMYEvent", category=category, title=title, icon=icon, classic=true },

    -- Events from interactions between players
    -- AUTOFOLLOW_BEGIN = { callback="DUMMYEvent", category=category, title=title, icon=icon, classic=true },  -- /follow
    -- AUTOFOLLOW_END = { callback="DUMMYEvent", category=category, title=title, icon=icon, classic=true },  -- /follow
    -- TRADE_SHOW = { callback="DUMMYEvent", category=category, title=title, icon=icon, classic=true },  -- Trade between players
    -- TRADE_CLOSED = { callback="DUMMYEvent", category=category, title=title, icon=icon, classic=true },  -- Trade between players

    -- Achievement events
    PLAYER_LEVEL_UP = { callback="DUMMYEvent", category="achievements", title="Level up", icon=1033586, classic=true },
    ACHIEVEMENT_EARNED = { callback="DUMMYEvent", category="achievements", title="Achievement", icon=icon, classic=false }, --not in Classic
    -- CHAT_MSG_ACHIEVEMENT = { callback="DUMMYEvent", category="achievements", title=title, icon=icon, classic=false }, --not in Classic
    -- CHAT_MSG_GUILD_ACHIEVEMENT = { callback="DUMMYEvent", category="achievements", title=title, icon=icon, classic=false }, --not in Classic

    -- NPC interaction events
    -- *_CLOSED events are unreliable and can fire anytime,
    -- when speaking to another NPC for example.
    -- It would need some heavy filtering :/
    GOSSIP_SHOW = { callback="ManageNoArgEvent", category="npc", title=title, icon=icon, classic=true },
    GOSSIP_CLOSED = { callback="ManageNoArgEvent", category="npc", title=title, icon=icon, classic=true },
    BARBER_SHOP_OPEN = { callback="ManageNoArgEvent", category="npc", title=title, icon=icon, classic=false },
    BARBER_SHOP_CLOSE = { callback="ManageNoArgEvent", category="npc", title=title, icon=icon, classic=false },
    MAIL_SHOW = { callback="ManageNoArgEvent", category="npc", title=title, icon=icon, classic=true },
    MERCHANT_SHOW = { callback="ManageNoArgEvent", category="npc", title=title, icon=icon, classic=true },
    QUEST_GREETING = { callback="ManageNoArgEvent", category="npc", title=title, icon=icon, classic=true },
    QUEST_FINISHED = { callback="ManageNoArgEvent", category="npc", title=title, icon=icon, classic=true },
    TAXIMAP_OPENED = { callback="DUMMYEvent", category="npc", title=title, icon=icon, classic=true },
    TRAINER_SHOW = { callback="ManageNoArgEvent", category="npc", title=title, icon=icon, classic=true },
}

function Verbose:RegisterEvents()
    -- for event, eventData in pairs(Verbose.usedSpellEvents) do
    --     self:RegisterEvent(event, eventData.callback)
    -- end
    for event, eventData in pairs(Verbose.usedEvents) do
        self:RegisterEvent(event, eventData.callback)
    end
    for event, eventData in pairs(Verbose.usedCombatLogEvents) do
        self:RegisterEvent(event, eventData.callback)
    end
end

local genders = { nil, "male", "female" }
function Verbose:GlobalSubstitutions()
    local substitutions = {
        targetname = UnitName("target"),
        targetguild = GetGuildInfo("target"),
        targetclass = UnitClass("target"),  -- Same as targetname for npc, even named ones
        targetrace = UnitRace("target"),  -- Not set for NPCs
        targettype = UnitCreatureType("target"),  -- Humanoid, Beast... can return "Not specified" (localized)
        targetfamily = UnitCreatureFamily("target"),  -- For beasts and demons
        targetgenre = genders[UnitSex("target")],
        npcname = UnitName("npc"),
        npcguild = GetGuildInfo("npc"),
        npcclass = UnitClass("npc"),  -- Same as targetname for npc, even named ones
        npcrace = UnitRace("npc"),  -- Not set for NPCs
        npctype = UnitCreatureType("npc"),  -- Humanoid, Beast... can return "Not specified" (localized)
        npcfamily = UnitCreatureFamily("npc"),  -- For beasts and demons
        npcgenre = genders[UnitSex("npc")],
    }
    return substitutions
end


-------------------------------------------------------------------------------
-- Events with no parameters
-------------------------------------------------------------------------------
function Verbose:ManageNoArgEvent(event, ...)
    -- DEBUG
    self:EventDbgPrint(event, "(NOARG)")
    local nbArgs = select("#", ...)
    if nbArgs > 0 then
        self:EventDbgPrint("NOARG event received", nbArgs, "args")
    end

    self:Speak(
        self.db.profile.events[event],
        Verbose:GlobalSubstitutions()
    )
end


-------------------------------------------------------------------------------
-- Events with specific parameters
-------------------------------------------------------------------------------
function Verbose:RESURRECT_REQUEST(event, caster)
    -- DEBUG
    self:EventDbgPrint(event, caster)

    local msgData = self.db.profile.events[event]
    local substitutions = Verbose:GlobalSubstitutions()
    substitutions.caster = caster
    self:Speak(msgData, substitutions)
end


-------------------------------------------------------------------------------
-- TODOs
-------------------------------------------------------------------------------
function Verbose:DUMMYEvent(event, ...)
    -- DEBUG
    self:EventDbgPrint("DUMMY", event, ...)

    local msgData = self.db.profile.events[event]
    self:Speak(msgData, ...)
end
