local addonName, Verbose = ...

-- Lua functions
local pairs = pairs
local select = select

-- WoW globals
local GetGuildInfo = GetGuildInfo
local UnitClass = UnitClass
local UnitCreatureFamily = UnitCreatureFamily
local UnitCreatureType = UnitCreatureType
local UnitName = UnitName
local UnitRace = UnitRace
local UnitSex = UnitSex

function Verbose:EventDbgPrint(...)
    if self.db.profile.eventDebug then
        self:Print("|cFFFFFF00EVENT:|r", ...)
    end
end
local EventDbgPrintFormatString = "|cFFFFFF00EVENT:|r %s |cFF00FAF6%s|r (%s) |cFFFF3F40:|r %s |cFFFF3F40->|r %s"
function Verbose:EventDbgPrintFormat(event, spellName, spellID, caster, target)
    if self.db.profile.eventDebug then
        if spellID then
            spellName = GetSpellLink(spellID)
        end
        if self:NameIsPlayer(caster) then
            caster = "|cFF3CE13F"..caster.."|r"
        end
        if self:NameIsPlayer(target) then
            target = "|cFF3CE13F"..target.."|r"
        end
        self:Print(EventDbgPrintFormatString:format(event or "|cFFAAABFEnil|r", spellName or "|cFFAAABFEnil|r", spellID or "|cFFAAABFEnil|r", caster or "|cFFAAABFEnil|r", target or "|cFFAAABFEnil|r"))
    end
end
function Verbose:EventDetailsDbgPrint(...)
    if self.db.profile.eventDetailDebug then
        self:Print("   |cFFFFFF00EVENT:|r", ...)
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
    PLAYER_DEAD = { callback="ManageNoArgEvent", category="combat", name=DEAD, order=20, classic=true },
    PLAYER_ALIVE = { callback="ManageNoArgEvent", category="combat", name="Resurrection", order=30, classic=true },
    -- PLAYER_UNGHOST: cf Verbose.usedEventsAlias
    RESURRECT_REQUEST = { callback="DUMMYEvent", category="combat", name="Resurrection request", order=25, classic=true },

    -- Combat events
    -- UNIT_THREAT_LIST_UPDATE = { callback="DUMMYEvent", category=category, name=title, classic=false }, --not in Classic
    -- COMPANION_UPDATE = { callback="DUMMYEvent", category=category, name=title, classic=false }, --not in Classic
    PLAYER_REGEN_DISABLED = { callback="ManageNoArgEvent", category="combat", name="Entering combat", order=10, classic=true },  -- Entering combat
    PLAYER_REGEN_ENABLED = { callback="ManageNoArgEvent", category="combat", name="Leaving combat", order=15, classic=true },  -- Leaving combat

    -- Chat events
    -- CHAT_MSG_WHISPER = { callback="DUMMYEvent", category=category, name=title, classic=true },
    -- CHAT_MSG_BN_WHISPER = { callback="DUMMYEvent", category=category, name=title, classic=true },
    -- CHAT_MSG_GUILD = { callback="DUMMYEvent", category=category, name=title, classic=true },
    -- CHAT_MSG_PARTY = { callback="DUMMYEvent", category=category, name=title, classic=true },

    -- Events from interactions between players
    -- AUTOFOLLOW_BEGIN = { callback="DUMMYEvent", category=category, name=title, classic=true },  -- /follow
    -- AUTOFOLLOW_END = { callback="DUMMYEvent", category=category, name=title, classic=true },  -- /follow
    -- TRADE_SHOW = { callback="DUMMYEvent", category=category, name=title, classic=true },  -- Trade between players
    -- TRADE_CLOSED = { callback="DUMMYEvent", category=category, name=title, classic=true },  -- Trade between players

    -- Achievement events
    PLAYER_LEVEL_UP = { callback="DUMMYEvent", category="achievements", name="Level up", classic=true },
    ACHIEVEMENT_EARNED = { callback="DUMMYEvent", category="achievements", name=ACHIEVEMENT_UNLOCKED, classic=false }, --not in Classic
    -- CHAT_MSG_ACHIEVEMENT = { callback="DUMMYEvent", category="achievements", name=title, classic=false }, --not in Classic
    -- CHAT_MSG_GUILD_ACHIEVEMENT = { callback="DUMMYEvent", category="achievements", name=title, classic=false }, --not in Classic

    -- NPC interaction events
    -- *_CLOSED events are unreliable and can fire anytime,
    -- when speaking to another NPC for example.
    -- It would need some heavy filtering :/
    -- I guess they are usefull for UI only
    GOSSIP_SHOW = { callback="ManageNoArgEvent", category="npc", name="Gossip", classic=true },
    -- GOSSIP_CLOSED = { callback="ManageNoArgEvent", category="npc", name="Gossip close", classic=true },
    BARBER_SHOP_OPEN = { callback="ManageNoArgEvent", category="npc", name=BARBERSHOP, classic=false },
    BARBER_SHOP_CLOSE = { callback="ManageNoArgEvent", category="npc", name="Barber shop close", classic=false },
    MAIL_SHOW = { callback="ManageNoArgEvent", category="npc", name=MAIL_LABEL, classic=true },
    MERCHANT_SHOW = { callback="ManageNoArgEvent", category="npc", name=MERCHANT, classic=true },
    QUEST_GREETING = { callback="ManageNoArgEvent", category="npc", name="Quest greeting", classic=true },
    QUEST_FINISHED = { callback="ManageNoArgEvent", category="npc", name="Quest finished", classic=true },
    TAXIMAP_OPENED = { callback="DUMMYEvent", category="npc", name="Taxi map", classic=true },
    TRAINER_SHOW = { callback="ManageNoArgEvent", category="npc", name="Trainer", classic=true },
}
Verbose.usedEventsAlias = {
    -- Those events should be registered but are processed as another event from Verbose.usedEvents
    PLAYER_UNGHOST = "PLAYER_ALIVE",
}

function Verbose:RegisterEvents()
    for event, eventData in pairs(Verbose.usedSpellEvents) do
        self:RegisterEvent(event, eventData.callback)
    end
    for event, eventData in pairs(Verbose.usedEvents) do
        self:RegisterEvent(event, eventData.callback)
    end
    for event, alias in pairs(Verbose.usedEventsAlias) do
        self:RegisterEvent(event, Verbose.usedEvents[alias].callback)
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

    if Verbose.usedEventsAlias[event] then
        event = Verbose.usedEventsAlias[event]
    end

    self:Speak(
        self.db.profile.events[event],
        self:GlobalSubstitutions()
    )
end


-------------------------------------------------------------------------------
-- Events with specific parameters
-------------------------------------------------------------------------------
function Verbose:RESURRECT_REQUEST(event, caster)
    -- DEBUG
    self:EventDbgPrint(event, caster)

    local msgData = self.db.profile.events[event]
    local substitutions = self:GlobalSubstitutions()
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
