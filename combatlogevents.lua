local addonName, Verbose = ...

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

function Verbose:CombatLog(event)
    local rawEventInfo = { CombatLogGetCurrentEventInfo() }

    local eventInfo = {}

    -- The 11 first parameters are common to all events
    eventInfo.sourceName = rawEventInfo[5]
    eventInfo.destName = rawEventInfo[9]
    -- Return early if the player is not involved in the event
    -- TODO: What about the pet(s) ?
    eventInfo.castMode = self:CombatLogCastMode(eventInfo)
    if not eventInfo.castMode then return end

    eventInfo.timestamp = rawEventInfo[1]
    eventInfo.event = rawEventInfo[2]
    -- eventInfo.hideCaster = rawEventInfo[3]  -- useless
    -- eventInfo.sourceGUID = rawEventInfo[4]  -- useless
    eventInfo.sourceFlags = rawEventInfo[6]
    eventInfo.sourceRaidFlags = rawEventInfo[7]
    -- eventInfo.destGUID = rawEventInfo[8]  -- useless
    eventInfo.destFlags = rawEventInfo[10]
    eventInfo.destRaidFlags = rawEventInfo[11]

    -- The rest of the paramters depends on the subevent and will be managed in subfunctions
    self:SetCombatLogArgs(eventInfo, rawEventInfo)
    eventInfo.category = self:CombatLogCategory(eventInfo)

    -- Ignore events from others ?
    -- if eventInfo.spellId and not Verbose:NameIsPlayer(eventInfo.sourceName) then return end

    -- Debug
    self:EventDbgPrint(event)
    for k, v in pairs(eventInfo) do
        self:EventDbgPrint("  ", k, "=", v)
    end

    -- Respond to event
    if eventInfo.spellID then
        self:RecordCombatLogSpellEvent(eventInfo)
        self:OnCombatLogSpellEvent(eventInfo)
    end
end

function Verbose:SetCombatLogArgs(eventInfo, rawEventInfo)
    -- Prefixes
    local suffixIndex = 12
    if Verbose.starts_with(eventInfo.event, "SPELL_", "RANGE_") then
        eventInfo.spellID, eventInfo.spellName, eventInfo.spellSchool = unpack(rawEventInfo, suffixIndex)
        suffixIndex = 15
    elseif Verbose.starts_with(eventInfo.event, "ENVIRONMENTAL_") then
        eventInfo.environmentalType = unpack(rawEventInfo, suffixIndex)
        suffixIndex = 13
    end

    -- Suffixes
    if Verbose.ends_with(eventInfo.event, "_DAMAGE") then
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
        self:Print("Combat log event has unknown extra arguments:", eventInfo.event)
    end
end

function Verbose:CombatLogCastMode(eventInfo)
    if Verbose:NameIsPlayer(eventInfo.destName) then
        if Verbose:NameIsPlayer(eventInfo.sourceName) then
            return "self"
        else
            return "received"
        end
    elseif Verbose:NameIsPlayer(eventInfo.sourceName) then
        if eventInfo.destName then
            return "done"
        else
            return "noTarget"
        end
    else
        return nil
    end
end

function Verbose:CombatLogCategory(eventInfo)
    if Verbose.starts_with(eventInfo.event, "ENVIRONMENTAL_") then
        return "environmental"
    elseif Verbose.ends_with(eventInfo.event, "_HEAL") then
        return "heal"
    elseif Verbose.ends_with(eventInfo.event, "_DAMAGE") then
        return "damage"
    elseif Verbose.starts_with(eventInfo.event, "SWING_") then
        return "swing"
    elseif Verbose.starts_with(eventInfo.event, "SPELL_AURA_") then
        if eventInfo.auraType == "BUFF" then
            return "buffs"
        else
            return "debuffs"
        end
    elseif Verbose.starts_with(eventInfo.event, "SPELL_") then
        return "spells"
    else
        return "other"
    end
end

function Verbose:RecordCombatLogSpellEvent(eventInfo)
    -- Ignore events from others ?
    if not Verbose:NameIsPlayer(eventInfo.sourceName) then return end

    local combatLog = self.db.profile.combatLog

    -- If cast mode not known at all, register it
    if not combatLog[eventInfo.castMode] then
        combatLog[eventInfo.castMode] = {}
    end

    -- If category not known at all, register it
    if not combatLog[eventInfo.castMode][eventInfo.category] then
        combatLog[eventInfo.castMode][eventInfo.category] = {}
    end

    -- If spell not known at all, register it
    if not combatLog[eventInfo.castMode][eventInfo.category][eventInfo.spellID] then
        combatLog[eventInfo.castMode][eventInfo.category][eventInfo.spellID] = {}
    end
    local spellData = combatLog[eventInfo.castMode][eventInfo.category][eventInfo.spellID]

    -- If event not known for this spell, register it
    if not spellData[eventInfo.event] then
        -- Store
        spellData[eventInfo.event] = {
            enabled = false,
            cooldown = 10,
            proba = 1,
            messages = {},
        }

        -- Update options
        self:AddCombatLogSpellToOptions(eventInfo.castMode, eventInfo.category, eventInfo.spellID, eventInfo.event)
        self:UpdateOptionsGUI()
    end
    -- Update timestamp
    spellData[eventInfo.event].lastRecord = eventInfo.timestamp
end

function Verbose:OnCombatLogSpellEvent(eventInfo)
    -- Talk
    local msgData = self.db.profile.combatLog[eventInfo.castMode][eventInfo.category][eventInfo.spellID][eventInfo.event]
    self:Speak(
        event,
        msgData,
        eventInfo)
end
