local addonName, Verbose = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- Lua functions
local bit = bit
local ipairs = ipairs
local pairs = pairs
local strtrim = strtrim
local tinsert = tinsert
local tonumber = tonumber
local tostring = tostring
local type = type
local unpack = unpack
local wipe = wipe

-- WoW globals
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local GetSchoolString = GetSchoolString
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

    COMBAT_LOG_EVENT_UNFILTERED = { callback="CombatLog", classic=true },
}

local SUBSTITUTIONS_DESCRIPTION = (
    L["Substitutions:"]
    .."\n|cFF00FF00<sourcename>|r "..L["name of the caster"]
    .."\n|cFF00FF00<destname>|r "..L["the name of the target of the spell"]
    .."\n|cFF00FF00<spellname>|r "..L["name of the spell"]
)
local SUBSTITUTIONS_DESCRIPTION_EXTRASPELL = SUBSTITUTIONS_DESCRIPTION.."\n|cFF00FF00<extraspellname>|r "..L["name of the extra spell"]

Verbose.playerCombatLogSubEvents = {

    SWING_DAMAGE = {
        name=L["Melee hit"],
        desc=SUBSTITUTIONS_DESCRIPTION,
        order=1 },
    SWING_MISSED = {
        name=L["Melee missed"],
        desc=SUBSTITUTIONS_DESCRIPTION,
        order=2 },

    SPELL_CAST_START = {
        name=L["Cast start (combat log)"],
        desc=SUBSTITUTIONS_DESCRIPTION,
        order=5.5 },
    SPELL_CAST_SUCCESS = {
        name=L["Cast success (combat log)"],
        desc=SUBSTITUTIONS_DESCRIPTION,
        order=15.5 },
    SPELL_CAST_FAILED = {
        name=L["Cast fail (combat log)"],
        desc=SUBSTITUTIONS_DESCRIPTION,
        order=30.5 },

    SPELL_AURA_APPLIED = {
        name=L["Aura applied"],
        desc=SUBSTITUTIONS_DESCRIPTION,
        order=60 },
    SPELL_AURA_REMOVED = {
        name=L["Aura removed"],
        desc=SUBSTITUTIONS_DESCRIPTION,
        order=61 },

    SPELL_DAMAGE = {
        name=L["Spell damage"],
        desc=SUBSTITUTIONS_DESCRIPTION,
        order=70 },
    RANGE_DAMAGE = {
        name=L["Range damage"],
        desc=SUBSTITUTIONS_DESCRIPTION,
        order=71 },
    -- ENVIRONMENTAL_DAMAGE = { name=L[""], order=1 },

    SPELL_HEAL = {
        name=L["Heal"],
        desc=SUBSTITUTIONS_DESCRIPTION,
        order=80 },

    -- Fires for both the healer and the dead
    -- Fires for the resurrection request; not the actual resurrection
    SPELL_RESURRECT = {
        name=L["Resurrection request (combat log)"],
        desc=SUBSTITUTIONS_DESCRIPTION,
        order=81 },

    -- Needs a section for non spell events
    --PARTY_KILL = { name=COMBATLOG_HIGHLIGHT_KILL, order=50 },
}

local playerCombatLogSubEventsAlias = {
    SPELL_AURA_APPLIED_DOSE = "SPELL_AURA_APPLIED",
    SPELL_AURA_REFRESH = "SPELL_AURA_APPLIED",
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
    eventInfo._event = rawEventInfo[2]
    if blacklist[eventInfo._event] then
        return
    end

    eventInfo.sourcename = rawEventInfo[5]
    eventInfo._sourceFlags = rawEventInfo[6]
    eventInfo.destname = rawEventInfo[9]
    eventInfo._destFlags = rawEventInfo[10]
    -- eventInfo._timestamp = rawEventInfo[1]  -- useless
    -- eventInfo._hideCaster = rawEventInfo[3]  -- useless
    -- eventInfo._sourceGUID = rawEventInfo[4]  -- useless
    -- eventInfo._sourceRaidFlags = rawEventInfo[7]  -- ?
    -- eventInfo._destGUID = rawEventInfo[8]  -- useless
    -- eventInfo._destRaidFlags = rawEventInfo[11]  -- ?

    -- Computed values
    eventInfo._destReaction = self:FlagToReaction(eventInfo._destFlags)
    eventInfo._sourceReaction = self:FlagToReaction(eventInfo._sourceFlags)

    -- Return early if the player is not involved in the event
    -- TODO: What about the pet(s) ?
    eventInfo._castMode = self:CombatLogCastMode(eventInfo)
    if not eventInfo._castMode then return end

    -- The rest of the parameters depends on the event and will be managed in subfunctions
    self:SetCombatLogArgs(eventInfo, rawEventInfo)
    if playerCombatLogSubEventsAlias[eventInfo._event] then
        eventInfo._event = playerCombatLogSubEventsAlias[eventInfo._event]
    end

    -- Debug
    self:EventDbgPrintFormat("|cFF0070FFCLEU|r "..eventInfo._event, eventInfo.spellname, eventInfo._spellID, eventInfo.sourcename, eventInfo.destname)

    -- Respond to event
    self:spellsRecordCombatLogEvent(eventInfo)
    self:OnCombatLogEvent(eventInfo)
end

function Verbose:SetCombatLogArgs(eventInfo, rawEventInfo)
    -- Prefixes
    local suffixIndex = 12
    if Verbose.starts_with(eventInfo._event, "SPELL_", "RANGE_") then
        eventInfo._spellID, eventInfo.spellname, eventInfo._school = unpack(rawEventInfo, suffixIndex)
        eventInfo._spellID = tostring(eventInfo._spellID)
        suffixIndex = suffixIndex + 3
    elseif Verbose.starts_with(eventInfo._event, "SWING_") then
        eventInfo._spellID = autoAttackSpellID
    elseif Verbose.starts_with(eventInfo._event, "ENVIRONMENTAL_") then
        eventInfo._environmentalType = unpack(rawEventInfo, suffixIndex)
        suffixIndex = suffixIndex + 1
    elseif Verbose.starts_with(eventInfo._event, "UNIT_") then
        eventInfo._recapID, eventInfo._unconsciousOnDeath = unpack(rawEventInfo, suffixIndex)
        suffixIndex = suffixIndex + 2
    elseif Verbose.starts_with(eventInfo._event, "ENCHANT_") then
        eventInfo.spellname, eventInfo._itemID, eventInfo.itemname = unpack(rawEventInfo, suffixIndex)
        suffixIndex = suffixIndex + 3
    end

    -- Specific
    if eventInfo._event == "PARTY_KILL" then
        eventInfo._arg1, eventInfo._arg2 = unpack(rawEventInfo, suffixIndex)
        suffixIndex = suffixIndex + 2

    -- Suffixes
    elseif Verbose.ends_with(eventInfo._event, "_DAMAGE") then
        -- This overrides eventInfo._school from above
        eventInfo._amount, eventInfo._overkill, eventInfo._school, eventInfo._resisted, eventInfo._blocked, eventInfo._absorbed, eventInfo._critical, eventInfo._glancing, eventInfo._crushing, eventInfo._isOffHand = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo._event, "_MISSED") then
        eventInfo._missType, eventInfo._isOffHand, eventInfo._amountMissed, eventInfo._critical = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo._event, "_HEAL") then
        eventInfo._amount, eventInfo._overhealing, eventInfo._absorbed, eventInfo._critical = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo._event, "_HEAL_ABSORBED") then
        eventInfo._extraGUID, eventInfo._extraName, eventInfo._extraFlags, eventInfo._extraRaidFlags, eventInfo._extraSpellID, eventInfo._extraSpellName, eventInfo._extraSchool, eventInfo._amount = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo._event, "_ABSORBED") then
        eventInfo._amount = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo._event, "_ENERGIZE") then
        eventInfo._amount, eventInfo._overenergize, eventInfo._powerType, eventInfo._alternatePowerType = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo._event, "_DRAIN", "_LEECH") then
        eventInfo._amount, eventInfo._powerType, eventInfo._extraAmount = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo._event, "_INTERRUPT", "_DISPEL_FAILED") then
        eventInfo._extraSpellId, eventInfo.extraspellname, eventInfo._extraSchool = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo._event, "_DISPEL", "_STOLEN") then
        eventInfo._extraSpellId, eventInfo.extraspellname, eventInfo._extraSchool, eventInfo._auraType = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo._event, "_EXTRA_ATTACKS") then
        eventInfo._amount = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo._event, "_AURA_APPLIED", "_AURA_REMOVED", "_AURA_APPLIED_DOSE", "_AURA_REMOVED_DOSE", "_AURA_REFRESH") then
        eventInfo._auraType, eventInfo._amount = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo._event, "_AURA_BROKEN") then
        eventInfo._auraType = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo._event, "_AURA_BROKEN_SPELL") then
        eventInfo._extraSpellId, eventInfo.extraspellname, eventInfo._extraSchool, eventInfo._auraType = unpack(rawEventInfo, suffixIndex)
    elseif Verbose.ends_with(eventInfo._event, "_CAST_FAILED") then
        eventInfo._failedType = unpack(rawEventInfo, suffixIndex)
    elseif #rawEventInfo ~= suffixIndex - 1 then
        self:Print(eventInfo._event.." has unknown extra arguments:", unpack(rawEventInfo, suffixIndex))
    end

    if eventInfo._auraType == "BUFF" then
        eventInfo._auraIsBuff = true
    elseif eventInfo._auraType == "DEBUFF" then
        eventInfo._auraIsBuff = false
    end
    if eventInfo._school then
        eventInfo.schoolname = strtrim(GetSchoolString(eventInfo._school), "()")
    end
    if eventInfo._extraSchool then
        eventInfo.extraschoolname = strtrim(GetSchoolString(eventInfo._extraSchool), "()")
    end
end

function Verbose:CombatLogCastMode(eventInfo)
    if self:NameIsPlayer(eventInfo.destname) then
        if self:NameIsPlayer(eventInfo.sourcename) then
            return "self"
        elseif eventInfo._event == "ENVIRONMENTAL_DAMAGE" then
            return "receivedHarm"
        elseif eventInfo._sourceReaction then
            return "received"..eventInfo._sourceReaction
        else
            return "received"
        end
    elseif self:NameIsPlayer(eventInfo.sourcename) then
        if eventInfo.destname then
            if eventInfo._destReaction then
                return "done"..eventInfo._destReaction
            else
                return "done"
            end
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
    if self.ends_with(eventInfo._event, "_DAMAGE") and self:NameIsPlayer(eventInfo.destname) then
        -- Managed in damagereceived.lua
        return
    end
    if not eventInfo._spellID then
        self:EventDbgPrint("No spell ID for", eventInfo._event)
        return
    end

    -- Fill db and options
    self:RecordSpellcastEvent(eventInfo._spellID, eventInfo._event)
end

function Verbose:OnCombatLogEvent(eventInfo)
    if Verbose.ends_with(eventInfo._event, "_DAMAGE") and self:NameIsPlayer(eventInfo.destname) then
        Verbose:OnDamageEvent(eventInfo)
        return
    end

    if not eventInfo._spellID then
        self:EventDbgPrint("No spell ID for", eventInfo._event)
        return
    end

    local dbTable = self.db.profile.spells[eventInfo._spellID][eventInfo._event]
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
