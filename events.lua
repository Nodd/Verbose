local addonName, Verbose = ...


function Verbose:EventDbgPrint(...)
    if self.db.profile.eventDebug then
        self:Print("EVENT:", ...)
    end
end

Verbose.usedSpellEvents = {
    -- EVENT = {
    --     callback,  -- Function to call
    --     title,  -- Display name
    --     icon,  -- Icon ID
    --     inClassic,  -- Exists in WoW Classic
    -- }

    UNIT_SPELLCAST_SENT = { callback="OnUnitSpellcastSent", title="Sent", icon=icon, order=-100, classic=true },
    UNIT_SPELLCAST_START = { callback="OnUnitSpellcastCommon", title="Start", icon=icon, order=0, classic=true },
    UNIT_SPELLCAST_CHANNEL_START = { callback="OnUnitSpellcastCommon", title="Channel stasrt", icon=icon, order=10, classic=true },
    UNIT_SPELLCAST_SUCCEEDED = { callback="OnUnitSpellcastEnd", title="Succeeded", icon=icon, order=20, classic=true },
    UNIT_SPELLCAST_FAILED = { callback="OnUnitSpellcastEnd", title="Failed", icon=icon, order=30, classic=true },
    UNIT_SPELLCAST_INTERRUPTED = { callback="OnUnitSpellcastEnd", title="Interrupted", icon=icon, order=40, classic=true },
    UNIT_SPELLCAST_STOP = { callback="OnUnitSpellcastEnd", title="Stop", icon=icon, order=50, classic=true },
    UNIT_SPELLCAST_CHANNEL_STOP = { callback="OnUnitSpellcastEnd", title="Channel stop", icon=icon, order=60, classic=true },
}

Verbose.usedEvents = {
    -- EVENT = {
    --     callback,  -- Function to call
    --     category,  -- Used for grouping events
    --     title,  -- Display name
    --     icon,  -- Icon ID
    --     inClassic,  -- Exists in WoW Classic
    -- }

    -- Death events
    PLAYER_DEAD = { callback="ManageNoArgEvent", category="combat", title="Death", icon=icon, classic=true },
    PLAYER_ALIVE = { callback="ManageNoArgEvent", category="combat", title="Return to life", icon=icon, classic=true },
    PLAYER_UNGHOST = { callback="ManageNoArgEvent", category="combat", title="Return to life from ghost", icon=135898, classic=true },  -- From ghost to alive
    RESURRECT_REQUEST = { callback="DUMMYEvent", category="combat", title="Resurrection request", icon=237542, classic=true },

    -- Combat events
    -- COMBAT_LOG_EVENT_UNFILTERED = { callback="DUMMYEvent", category=category, title=title, icon=icon, classic=true },
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

local spellBlacklist = {
    [836] = true,  -- LOGINEFFECT, fired on login
}

function Verbose:RegisterEvents()
    for event, eventData in pairs(Verbose.usedSpellEvents) do
        self:RegisterEvent(event, eventData.callback)
    end
    for event, eventData in pairs(Verbose.usedEvents) do
        self:RegisterEvent(event, eventData.callback)
    end
end


-------------------------------------------------------------------------------
-- Spellcast Events
-------------------------------------------------------------------------------
local targetTable = {}

-- For UNIT_SPELLCAST_SENT only, used to retrieve the spell target
function Verbose:OnUnitSpellcastSent(event, caster, target, castID, spellID)
    -- Store target for later use
    -- The other spell events don't provide the target :(
    targetTable[castID] = target
end

function Verbose:OnUnitSpellcastCommon(event, caster, castID, spellID)
    -- Ignore blacklisted spells
    if spellBlacklist[spellID] then return end
    local target = targetTable[castID]
    self:OnSpellcastEvent(event, caster, target, spellID)
end

function Verbose:OnUnitSpellcastEnd(event, caster, castID, spellID)
    self:OnUnitSpellcastCommon(event, caster, castID, spellID)
    -- Clean targetTable
    targetTable[castID] = nil
end

function Verbose:RecordSpellcastEvent(spellID, event)
    local spells = self.db.profile.spells

    -- If spell not known at all, register it
    if not spells[spellID] then
        spells[spellID] = {}
    end
    local spellData = spells[spellID]

    -- If event not known for this spell, register it
    if not spellData[event] then
        -- Store
        spellData[event] = {
            enabled = false,
            cooldown = 10,
            proba = 1,
            messages = {},
        }

        -- Update options
        self:AddSpellToOptions(spellID, event)
        self:UpdateOptionsGUI()
    end
    -- Update timestamp
    spellData[event].lastRecord = GetServerTime()
end

function Verbose:OnSpellcastEvent(event, caster, target, spellID)
    -- Ignore events from others
    if caster ~= "player" and caster ~= "pet" then return end

    spellName, iconTexture = self:SpellNameAndIconTexture(spellID)

    -- Debug
    self:EventDbgPrint(event, caster, target, spellID, spellName)

    -- Record Spell/event
    self:RecordSpellcastEvent(spellID, event)

    -- Talk
    local msgData = self.db.profile.spells[spellID][event]
    self:Speak(event, msgData, {
        caster = caster,
        target = target,
        spellname = spellname,
        icon = nil
     })
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
    if ... then
        self:EventDbgPrint("NOARG event received args:", ...)
    end

    self:Speak(
        event,
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
    self:Speak(event, msgData, substitutions)
end


-------------------------------------------------------------------------------
-- TODOs
-------------------------------------------------------------------------------
function Verbose:DUMMYEvent(event, ...)
    -- DEBUG
    self:EventDbgPrint("DUMMY", event, ...)

    local msgData = self.db.profile.events[event]
    self:Speak(event, msgData, ...)
end
