local addonName, Verbose = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- Lua functions
local bit = bit
local ipairs = ipairs
local pairs = pairs
local tinsert = tinsert
local tonumber = tonumber
local tostring = tostring
local type = type
local unpack = unpack
local wipe = wipe

-- WoW globals
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local GetServerTime = GetServerTime
local COMBATLOG_OBJECT_REACTION_MASK = COMBATLOG_OBJECT_REACTION_MASK

local autoAttackSpellID = "6603"

Verbose.usedCombatLogEvents = {
    -- EVENT = {
    --     callback,  -- Function to call
    --     category,  -- Used for grouping events
    --     title,  -- Display name
    --     icon,  -- Icon ID
    --     inClassic,  -- Exists in WoW Classic
    -- },

    COMBAT_LOG_EVENT_UNFILTERED = { callback="CombatLog", category="combat", title="Combat log", icon=icon, classic=true },
}

Verbose.playerCombatLogSubEvents = {

    SWING_DAMAGE = { name=L["Melee hit"], order=1 },
    SWING_MISSED = { name=L["Melee missed"], order=2 },

    SPELL_CAST_START = { name=L["Cast start (combat log)"], order=5.5 },
    SPELL_CAST_SUCCESS = { name=L["Cast success (combat log)"], order=15.5 },
    SPELL_CAST_FAILED = { name=L["Cast fail (combat log)"], order=30.5 },

    SPELL_AURA_APPLIED = { name=L["Aura applied"], order=60 },
    SPELL_AURA_REMOVED = { name=L["Aura removed"], order=61 },

    SPELL_DAMAGE = { name=L["Spell damage"], order=70 },
    RANGE_DAMAGE = { name=L["Range damage"], order=71 },
    -- ENVIRONMENTAL_DAMAGE = { name=L[""], order=1 },

    SPELL_HEAL = { name=L["Heal"], order=80 },

    PARTY_KILL = { name=L["Kill"], order=50 },
}

local playerCombatLogSubEventsAlias = {
    SPELL_AURA_APPLIED_DOSE = SPELL_AURA_APPLIED,
    SPELL_AURA_REFRESH = SPELL_AURA_APPLIED,
}

local blacklist = {
    SPELL_ENERGIZE = true,
    SPELL_ABSORBED = true,
    SPELL_PERIODIC_DAMAGE = true,
    SPELL_PERIODIC_ENERGIZE = true,
    SPELL_PERIODIC_MISSED = true,
    SPELL_PERIODIC_HEAL = true,
    SPELL_AURA_REMOVED_DOSE = true,
    SPELL_AURA_BROKEN = true,

    -- TODO
    DAMAGE_SHIELD = true,
    SPELL_MISSED = true,
    SPELL_DISPEL = true,
    SPELL_SUMMON = true,
    SPELL_INTERRUPT = true,
    PARTY_KILL = true,
}

function Verbose:CombatLog(event)
    local rawEventInfo = { CombatLogGetCurrentEventInfo() }

    local eventInfo = {}

    -- The 11 first parameters are common to all events
    eventInfo.event = rawEventInfo[2]
    if blacklist[eventInfo.event] then
        return
    end

    eventInfo.sourceName = rawEventInfo[5]
    eventInfo.sourceFlags = rawEventInfo[6]
    eventInfo.destName = rawEventInfo[9]
    eventInfo.destFlags = rawEventInfo[10]
    -- eventInfo.timestamp = rawEventInfo[1]  -- useless
    -- eventInfo.hideCaster = rawEventInfo[3]  -- useless
    -- eventInfo.sourceGUID = rawEventInfo[4]  -- useless
    -- eventInfo.sourceRaidFlags = rawEventInfo[7]  -- ?
    -- eventInfo.destGUID = rawEventInfo[8]  -- useless
    -- eventInfo.destRaidFlags = rawEventInfo[11]  -- ?

    -- Computed values
    eventInfo.destReaction = self:FlagToReaction(eventInfo.destFlags)
    eventInfo.sourceReaction = self:FlagToReaction(eventInfo.sourceFlags)

    -- Return early if the player is not involved in the event
    -- TODO: What about the pet(s) ?
    eventInfo.castMode = self:CombatLogCastMode(eventInfo)
    if not eventInfo.castMode then return end

    -- The rest of the parameters depends on the event and will be managed in subfunctions
    self:SetCombatLogArgs(eventInfo, rawEventInfo)
    if playerCombatLogSubEventsAlias[eventInfo.event] then
        eventInfo.event = playerCombatLogSubEventsAlias[eventInfo.event]
    end

    -- Debug
    self:EventDbgPrintFormat("|cFF0070FFCLEU|r "..eventInfo.event, eventInfo.spellName, eventInfo.spellID, eventInfo.sourceName, eventInfo.destName)

    -- Respond to event
    self:spellsRecordCombatLogEvent(eventInfo)
    self:OnCombatLogEvent(eventInfo)
end

function Verbose:SetCombatLogArgs(eventInfo, rawEventInfo)
    -- Prefixes
    local suffixIndex = 12
    if Verbose.starts_with(eventInfo.event, "SPELL_", "RANGE_") then
        eventInfo.spellID, eventInfo.spellName, eventInfo.school = unpack(rawEventInfo, suffixIndex)
        eventInfo.spellID = tostring(eventInfo.spellID)
        suffixIndex = suffixIndex + 3
    elseif Verbose.starts_with(eventInfo.event, "SWING_") then
        eventInfo.spellID = autoAttackSpellID
    elseif Verbose.starts_with(eventInfo.event, "ENVIRONMENTAL_") then
        eventInfo.environmentalType = unpack(rawEventInfo, suffixIndex)
        suffixIndex = suffixIndex + 1
    elseif Verbose.starts_with(eventInfo.event, "UNIT_") then
        eventInfo.recapID, eventInfo.unconsciousOnDeath = unpack(rawEventInfo, suffixIndex)
        suffixIndex = suffixIndex + 2
    end

    -- Specific
    if eventInfo.event == "PARTY_KILL" then
        eventInfo.arg1, eventInfo.arg2 = unpack(rawEventInfo, suffixIndex)
        suffixIndex = suffixIndex + 2
    end

    -- Suffixes
    if Verbose.ends_with(eventInfo.event, "_DAMAGE") then
        -- This overrides eventInfo.school from above
        eventInfo.amount, eventInfo.overkill, eventInfo.school, eventInfo.resisted, eventInfo.blocked, eventInfo.absorbed, eventInfo.critical, eventInfo.glancing, eventInfo.crushing, eventInfo.isOffHand = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo.event, "_MISSED") then
        eventInfo.missType, eventInfo.isOffHand, eventInfo.amountMissed, eventInfo.critical = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo.event, "_HEAL") then
        eventInfo.amount, eventInfo.overhealing, eventInfo.absorbed, eventInfo.critical = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo.event, "_ENERGIZE") then
        eventInfo.amount, eventInfo.overEnergize, eventInfo.powerType, eventInfo.alternatePowerType = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo.event, "_DRAIN", "_LEECH") then
        eventInfo.amount, eventInfo.powerType, eventInfo.extraAmount = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo.event, "_INTERRUPT", "_DISPEL_FAILED") then
        eventInfo.extraSpellId, eventInfo.extraSpellName, eventInfo.extraSchool = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo.event, "_DISPEL", "_STOLEN") then
        eventInfo.extraSpellId, eventInfo.extraSpellName, eventInfo.extraSchool, eventInfo.auraType = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo.event, "_EXTRA_ATTACKS") then
        eventInfo.amount = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo.event, "_AURA_APPLIED", "_AURA_REMOVED", "_AURA_APPLIED_DOSE", "_AURA_REMOVED_DOSE", "_AURA_REFRESH") then
        eventInfo.auraType, eventInfo.amount = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo.event, "_AURA_BROKEN") then
        eventInfo.auraType = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo.event, "_AURA_BROKEN_SPELL") then
        eventInfo.extraSpellId, eventInfo.extraSpellName, eventInfo.extraSchool, eventInfo.auraType = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo.event, "_CAST_FAILED") then
        eventInfo.failedType = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo.event, "_ABSORBED") then
        eventInfo.amount = unpack(rawEventInfo, suffixIndex)
    elseif #rawEventInfo ~= suffixIndex - 1 then
        self:Print(eventInfo.event.." has unknown extra arguments:", unpack(rawEventInfo, suffixIndex))
    end

    if eventInfo.auraType == "BUFF" then
        eventInfo.auraIsBuff = true
    elseif eventInfo.auraType == "DEBUFF" then
        eventInfo.auraIsDebuff = true
    end
end

function Verbose:CombatLogCastMode(eventInfo)
    if self:NameIsPlayer(eventInfo.destName) then
        if self:NameIsPlayer(eventInfo.sourceName) then
            return "self"
        elseif eventInfo.event == "ENVIRONMENTAL_DAMAGE" then
            return "receivedHarm"
        else
            return "received"..eventInfo.sourceReaction
        end
    elseif self:NameIsPlayer(eventInfo.sourceName) then
        if eventInfo.destName then
            return "done"..eventInfo.destReaction
        else
            return "noTarget"
        end
    else
        return nil
    end
end

local reactionID = {
    [COMBATLOG_OBJECT_REACTION_HOSTILE] = "Harm",
    [COMBATLOG_OBJECT_REACTION_NEUTRAL] = "Harm",
    [COMBATLOG_OBJECT_REACTION_FRIENDLY] = "Help",
}
function Verbose:FlagToReaction(UnitFlag)
    local reaction = bit.band(UnitFlag, COMBATLOG_OBJECT_REACTION_MASK)
    return reactionID[reaction]
end

function Verbose:spellsRecordCombatLogEvent(eventInfo)
    if self.ends_with(eventInfo.event, "_DAMAGE") and self:NameIsPlayer(eventInfo.destName) then
        -- Managed in damagereceived.lua
        return
    end
    if not eventInfo.spellID then
        self:EventDbgPrint("No spell ID for", eventInfo.event)
        return
    end

    -- Fill db and options
    self:RecordSpellcastEvent(eventInfo.spellID, eventInfo.event)
end

function Verbose:OnCombatLogEvent(eventInfo)
    if Verbose.ends_with(eventInfo.event, "_DAMAGE") and self:NameIsPlayer(eventInfo.destName) then
        Verbose:OnDamageEvent(eventInfo)
        return
    end

    local dbTable = self.db.profile.spells[eventInfo.spellID][eventInfo.event]
    local messagesTable

    if dbTable.merge then
        messagesTable = dbTable.messages
        -- TODO: Loop on categories to add their messages
        -- messagesTable = {}
        -- for i, category in ipairs(self:CategoryTree(eventInfo)) do
        --     dbTable = dbTable.children[category]

        --     -- Merge or wipe parent's messages
        --     if not dbTable.merge then
        --         wipe(messagesTable)
        --     end
        --     for _, m in ipairs(dbTable.messages) do
        --         tinsert(messagesTable, m)
        --     end
        -- end
    else
        messagesTable = dbTable.messages
    end

    -- Talk
    self:Speak(
        dbTable,
        eventInfo,
        messagesTable)
end
