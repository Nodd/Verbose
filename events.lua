local addonName, Verbose = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- Lua functions
local pairs = pairs
local select = select

-- WoW globals
local GetAchievementInfo = GetAchievementInfo
local GetGuildInfo = GetGuildInfo
local GetSpellLink = GetSpellLink
local TaxiNodeName = TaxiNodeName
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
local EventDetailDbgPrintFormatString = "|cFFFFFF00EVENT:|r    <%s> |cFFFF3F40=|r %s"
function Verbose:EventDetailsDbgPrint(eventInfo)
    if eventInfo and self.db.profile.eventDetailDebug then
        for k, v in Verbose.orderedpairs(eventInfo) do
            if self:NameIsPlayer(v) then
                v = "|cFF3CE13F"..v.."|r"
            elseif v == true then
                v = "|cFF40BC40true|r"
            elseif v == false then
                v = "|cFFFF4700false|r"
            end
            self:Print(EventDetailDbgPrintFormatString:format(k, v))
        end
    end
end

local NPC_DESCRIPTION = (
    L["Substitutions:"]
    .."\n|cFF00FF00<npcname>|r "..L["Name of the NPC"]
    .."\n|cFF00FF00<npcguild>|r "..L["Guild of the NPC"]
    .."\n|cFF00FF00<npcclass>|r "..L["Class of the NPC"]
    .."\n|cFF00FF00<npcrace>|r "..L["Race of the NPC"]
    .."\n|cFF00FF00<npctype>|r "..L["Humanoïd, Beast, Demon..."]
    .."\n|cFF00FF00<npcfamily>|r "..L["Subcategory for beasts and demons"]
    .."\n|cFF00FF00<npcgenreid>|r "..L["1 if NPC is male, 2 if female"]
    .."\n|cFF00FF00<npcgenre>|r "..L["'male' or 'female'"]
)

Verbose.usedEvents = {
    -- EVENT = {
    --     callback,  -- Function to call
    --     category,  -- Used for grouping events
    --     title,  -- Display name
    --     icon,  -- Icon ID
    --     inClassic,  -- Exists in WoW Classic
    -- },

    -- Death events
    PLAYER_DEAD = {
        callback="ManageNoArgEvent",
        category="combat",
        name=DEAD,
        desc=L["No substitutions"],
        order=20,
        classic=true },
    PLAYER_ALIVE = {
        callback="ManageNoArgEvent",
        category="combat",
        name=L["Resurrection"],
        desc=L["No substitutions"],
        order=30,
        lassic=true },
    -- PLAYER_UNGHOST: cf Verbose.usedEventsAlias
    RESURRECT_REQUEST = {
        callback="RESURRECT_REQUEST",
        category="combat",
        name=L["Resurrection request"],
        desc=L["Substitutions:"].."\n|cFF00FF00<caster>|r "..L["name of the nice player who just casted rez on you"],
        order=25,
        classic=true },

    -- Combat events
    -- UNIT_THREAT_LIST_UPDATE = { callback="TODOEvent", category=category, name=title, classic=false }, --not in Classic
    -- COMPANION_UPDATE = { callback="TODOEvent", category=category, name=title, classic=false }, --not in Classic
    PLAYER_REGEN_DISABLED = {
        callback="ManageNoArgEvent",
        category="combat",
        name=L["Entering combat"],
        desc=L["No substitutions"],
        order=10,
        classic=true },  -- Entering combat
    PLAYER_REGEN_ENABLED = {
        callback="ManageNoArgEvent",
        category="combat",
        name=L["Leaving combat"],
        desc=L["No substitutions"],
        order=15,
        classic=true },  -- Leaving combat

    -- Chat events
    -- CHAT_MSG_WHISPER = { callback="TODOEvent", category=category, name=title, classic=true },
    -- CHAT_MSG_BN_WHISPER = { callback="TODOEvent", category=category, name=title, classic=true },
    -- CHAT_MSG_GUILD = { callback="TODOEvent", category=category, name=title, classic=true },
    -- CHAT_MSG_PARTY = { callback="TODOEvent", category=category, name=title, classic=true },

    -- Events from interactions between players
    -- AUTOFOLLOW_BEGIN = { callback="TODOEvent", category=category, name=title, classic=true },  -- /follow
    -- AUTOFOLLOW_END = { callback="TODOEvent", category=category, name=title, classic=true },  -- /follow
    -- TRADE_SHOW = { callback="TODOEvent", category=category, name=title, classic=true },  -- Trade between players
    -- TRADE_CLOSED = { callback="TODOEvent", category=category, name=title, classic=true },  -- Trade between players

    -- Player events
    PLAYER_LEVEL_UP = {
        callback="PLAYER_LEVEL_UP",
        category="player",
        name=L["Level up"],
        desc=L["Substitutions:"].."\n|cFF00FF00<level>|r "..L["the new level"],
        order=10,
        classic=true },
    ACHIEVEMENT_EARNED = {
        callback="ACHIEVEMENT_EARNED",
        category="player",
        name=ACHIEVEMENT_UNLOCKED,
        desc=L["Substitutions:"].."\n|cFF00FF00<achievement>|r "..L["the achievement label"].."\n|cFF00FF00<points>|r "..L["the number of points gained"],
        order=20,
        classic=false }, --not in Classic
    PLAYER_STARTED_MOVING = {
        callback="ManageNoArgEvent",
        category="player",
        name=L["Start moving"],
        desc=L["No substitutions"],
        order=30,
        classic=true },
    PLAYER_STOPPED_MOVING = {
        callback="PLAYER_STOPPED_MOVING",
        category="player",
        name=L["Stop moving"],
        desc=L["No substitutions"],
        order=40,
        classic=true },

    -- NPC interaction events
    -- *_CLOSED events are unreliable and can fire anytime,
    -- when speaking to another NPC for example.
    -- It would need some heavy filtering :/
    -- I guess they are usefull for UI only
    GOSSIP_SHOW = {
        callback="ManageNoArgEvent",
        category="npc",
        name=L["Gossip"],
        desc=NPC_DESCRIPTION,
        classic=true },
    -- GOSSIP_CLOSED = { callback="ManageNoArgEvent", category="npc", name=L["Gossip close"], classic=true },
    BARBER_SHOP_OPEN = {
        callback="ManageNoArgEvent",
        category="npc",
        name=BARBERSHOP,
        desc=NPC_DESCRIPTION,
        classic=false },
    BARBER_SHOP_CLOSE = {
        callback="ManageNoArgEvent",
        category="npc",
        name=L["Barber shop close"],
        desc=NPC_DESCRIPTION,
        classic=false },
    MAIL_SHOW = {
        callback="ManageNoArgEvent",
        category="npc",
        name=MAIL_LABEL,
        desc=NPC_DESCRIPTION,
        classic=true },
    MERCHANT_SHOW = {
        callback="ManageNoArgEvent",
        category="npc",
        name=MERCHANT,
        desc=NPC_DESCRIPTION,
        classic=true },
    -- QUEST_GREETING = { callback="ManageNoArgEvent", category="npc", name=L["Quest greeting"], classic=true },
    -- QUEST_FINISHED = { callback="ManageNoArgEvent", category="npc", name=L["Quest finished"], classic=true },
    TAXIMAP_OPENED = {
        callback="TAXIMAP_OPENED",
        category="npc",
        name=L["Taxi map"],
        desc=NPC_DESCRIPTION.."\n|cFF00FF00<stationname>|r "..L["Name of the taxi station you're at"],
        classic=true },
    TAXIMAP_CLOSED = {
        callback="ManageNoArgEvent",
        category="npc",
        name=L["Taxi map closed"],
        desc=L["No substitutions"],
        classic=true },
    -- TRAINER_SHOW = { callback="ManageNoArgEvent", category="npc", name=L["Trainer"], classic=true },
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
function Verbose:TargetSubstitutions()
    local substitutions = {
        targetname = UnitName("target"),
        targetguild = GetGuildInfo("target"),
        targetclass = UnitClass("target"),  -- Same as targetname for npc, even named ones
        targetrace = UnitRace("target"),  -- Not set for NPCs
        targettype = UnitCreatureType("target"),  -- Humanoid, Beast... can return "Not specified" (localized)
        targetfamily = UnitCreatureFamily("target"),  -- For beasts and demons
        targetgenreid = UnitSex("target"),
        targetgenre = genders[UnitSex("target")],
    }
    return substitutions
end
function Verbose:NpcSubstitutions()
    local substitutions = {
        npcname = UnitName("npc"),
        npcguild = GetGuildInfo("npc"),
        npcclass = UnitClass("npc"),  -- Same as targetname for npc, even named ones
        npcrace = UnitRace("npc"),  -- Not set for NPCs
        npctype = UnitCreatureType("npc"),  -- Humanoid, Beast... can return "Not specified" (localized)
        npcfamily = UnitCreatureFamily("npc"),  -- For beasts and demons
        npcgenreid = UnitSex("npc"),
        npcgenre = genders[UnitSex("npc")],
    }
    if substitutions.npcclass == substitutions.npcname then
        substitutions.npcclass = nil
    end
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

    local eventData = Verbose.usedEvents[event]
    local substitutions
    if eventData.category == "npc" then
        substitutions = self:NpcSubstitutions()
    end

    self:Speak(
        self.db.profile.events[event],
        substitutions
    )
end

function Verbose:ManageIgnoredArgEvent(event, ...)
    -- DEBUG
    self:EventDbgPrint(event, ..., "(Arguments ignored)")

    local msgData = self.db.profile.events[event]
    self:Speak(msgData)
end

function Verbose:PLAYER_STOPPED_MOVING(event, ...)
    -- When this event is fired, the player is still considered moving (try with /dance)
    -- A 0 delay (OnUpdate ?) is enough

    -- DEBUG
    self:EventDbgPrint(event, "(delayed)")

    self:ScheduleTimer("ManageNoArgEvent", 0, event, ...)
end

-------------------------------------------------------------------------------
-- Events with specific parameters
-------------------------------------------------------------------------------
function Verbose:RESURRECT_REQUEST(event, caster)
    -- DEBUG
    self:EventDbgPrint(event, caster)

    local msgData = self.db.profile.events[event]
    local substitutions = { caster=caster }
    self:Speak(msgData, substitutions)
end

function Verbose:TAXIMAP_OPENED(event, nodeID)
    -- DEBUG
    self:EventDbgPrint(event, nodeID)

    local msgData = self.db.profile.events[event]
    local substitutions = self:NpcSubstitutions()
    substitutions.stationname = TaxiNodeName(nodeID)
    self:Speak(msgData, substitutions)
end

function Verbose:PLAYER_LEVEL_UP(event, level)
    -- Lots of additionnal arguments are ignored (stats and talents updates)

    -- DEBUG
    self:EventDbgPrint(event, level)

    local msgData = self.db.profile.events[event]
    local substitutions = { level=level }
    self:Speak(msgData, substitutions)
end

function Verbose:ACHIEVEMENT_EARNED(event, achievementID, alreadyEarned)
    -- DEBUG
    self:EventDbgPrint(event, achievementID, alreadyEarned)

    local id, name, points = GetAchievementInfo(achievementID)

    local msgData = self.db.profile.events[event]
    local substitutions = { achievement=name, points=points }
    self:Speak(msgData, substitutions)
end


-------------------------------------------------------------------------------
-- TODOs
-------------------------------------------------------------------------------
function Verbose:TODOEvent(event, ...)
    -- DEBUG
    self:EventDbgPrint(event, ..., "(TODO)")

    local msgData = self.db.profile.events[event]
    self:Speak(msgData, ...)
end
