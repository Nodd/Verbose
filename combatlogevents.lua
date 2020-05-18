local addonName, Verbose = ...

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

    -- Debug
    self:EventDbgPrintFormat("CLEU/"..eventInfo.event, eventInfo.spellName, eventInfo.spellID, eventInfo.sourceName, eventInfo.destName)
    self:EventDetailsDbgPrint(eventInfo)

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
    elseif Verbose.starts_with(eventInfo.event, "ENVIRONMENTAL_") then
        eventInfo.environmentalType = unpack(rawEventInfo, suffixIndex)
        suffixIndex = suffixIndex + 1
    elseif Verbose.starts_with(eventInfo.event, "SWING_") then
        eventInfo.spellID = "6603"  -- Autoattack spell
    elseif Verbose.starts_with(eventInfo.event, "UNIT_") then
        eventInfo.recapID, eventInfo.unconsciousOnDeath = unpack(rawEventInfo, suffixIndex)
        suffixIndex = suffixIndex + 2
    -- else
    --     eventInfo.spellID = "-2"  -- Fake spell ID
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
end

function Verbose:CategoryTree(eventInfo)
    local categories = {}
    if eventInfo.event == "SPELL_HEAL" then
        tinsert(categories, "combatLogCategory#heal")
        tinsert(categories, "castMode#"..eventInfo.castMode)
        tinsert(categories, "school#"..eventInfo.school)
        tinsert(categories, "spellID#"..eventInfo.spellID)

    elseif eventInfo.event == "SPELL_DAMAGE" then
        tinsert(categories, "combatLogCategory#damage")
        tinsert(categories, "castMode#"..eventInfo.castMode)
        tinsert(categories, "school#"..eventInfo.school)
        tinsert(categories, "spellID#"..eventInfo.spellID)

    elseif eventInfo.event == "ENVIRONMENTAL_DAMAGE" then
        tinsert(categories, "combatLogCategory#damage")
        tinsert(categories, "castMode#"..eventInfo.castMode)
        tinsert(categories, "combatLogCategory#environmental")
        tinsert(categories, eventInfo.environmentalType)

    elseif eventInfo.event == "SWING_DAMAGE" then
        tinsert(categories, "combatLogCategory#damage")
        tinsert(categories, "castMode#"..eventInfo.castMode)
        tinsert(categories, "Swing")

    elseif eventInfo.event == "SWING_MISSED" then
        tinsert(categories, "combatLogCategory#damage")
        tinsert(categories, "castMode#"..eventInfo.castMode)
        tinsert(categories, "Swing missed")

    elseif eventInfo.event == "RANGE_DAMAGE" then
        tinsert(categories, "combatLogCategory#damage")
        tinsert(categories, "castMode#"..eventInfo.castMode)
        tinsert(categories, "Range")

    elseif eventInfo.event == "SPELL_CAST_START" then
        tinsert(categories, "castMode#start")
        tinsert(categories, "school#"..eventInfo.school)
        tinsert(categories, "spellID#"..eventInfo.spellID)

    elseif eventInfo.event == "SPELL_CAST_FAILED" then
        tinsert(categories, "castMode#failed")
        tinsert(categories, eventInfo.failedType)
        tinsert(categories, "school#"..eventInfo.school)
        tinsert(categories, "spellID#"..eventInfo.spellID)

    elseif eventInfo.event == "SPELL_CAST_SUCCESS" then
        tinsert(categories, "castMode#success")
        tinsert(categories, "school#"..eventInfo.school)
        tinsert(categories, "spellID#"..eventInfo.spellID)

    elseif eventInfo.event == "SPELL_AURA_APPLIED" or eventInfo.event == "SPELL_AURA_APPLIED_DOSE" or eventInfo.event == "SPELL_AURA_REFRESH" then
        if eventInfo.auraType == "BUFF" then
            tinsert(categories, "combatLogCategory#buffs")
        else
            tinsert(categories, "combatLogCategory#debuffs")
        end
        tinsert(categories, "castMode#"..eventInfo.castMode)
        tinsert(categories, "school#"..eventInfo.school)
        tinsert(categories, "spellID#"..eventInfo.spellID)
        tinsert(categories, "auraEvent#APPLIED")

    elseif eventInfo.event == "SPELL_AURA_REMOVED" then
        if eventInfo.auraType == "BUFF" then
            tinsert(categories, "combatLogCategory#buffs")
        else
            tinsert(categories, "combatLogCategory#debuffs")
        end
        tinsert(categories, "castMode#"..eventInfo.castMode)
        tinsert(categories, "school#"..eventInfo.school)
        tinsert(categories, "spellID#"..eventInfo.spellID)
        tinsert(categories, "auraEvent#REMOVED")

    elseif eventInfo.event == "PARTY_KILL" then -- Has arguments sometimes ?
    else
        self:Print("Unknown combat log event:", eventInfo.event)
    end
    return categories
end

function Verbose.CategoryTypeValue(category)
    local typ, id = category:match("^(.+)#(.+)$") -- use strsplit ?
    return typ, id
end

function Verbose:CategoryName(category)
    local value
    local typ, id = self.CategoryTypeValue(category)
    if not id then
        value = category
    else
        value = self.categoryData[typ](id).name
        if type(value) == "function" then
            value = self:SpellName(id)
        end
    end
    return value
end

Verbose.categoryData = {
    castMode = function(id) return Verbose.combatLogCastModes[id] end,
    combatLogCategory = function(id) return Verbose.combatLogOptionsCategories[id] end,
    spellID = function(id) return Verbose.spellIDTreeFuncs end,
    school = function(id) return { name=Verbose.SpellSchoolString[tonumber(id)] } end,
    auraEvent = function(id) return Verbose.auraEvent[id] end,
    event = function(id) return { name=id } end,
}

Verbose.combatLogCastModes = {
    start = { name="Start cast", order=5, desc="Start a non-instant, non-channelled cast.\n" },
    success = { name="Successfull cast", order=7, desc="Successfully casting any spell.\n" },
    failed = { name="Failed cast", order=8, desc="Failing to cast any spell. Shit happens.\n" },
    self = { name="Me@Me", order=10, desc="Me, myself and I.\n" },
    noTarget = { name="Me@None", order=15, desc="Non-targeted events done by myself.\n" },
    doneHelp = { name="Me@Help", order=20, desc="Targetting events done by myself to a friend.\n" },
    doneHarm = { name="Me@Harm", order=25, desc="Targetting events done by myself to an enemy.\n" },
    receivedHelp = { name="Help@Me", order=30, desc="Targeting events done by a friend to me.\n" },
    receivedHarm = { name="Harm@Me", order=35, desc="Targeting events done by an enemy to me.\n" },
    other = { name="Other", order=40, desc="Not my problem.\n" },
}

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

Verbose.combatLogOptionsCategories = {
    swing = { name=MELEE, order=10 },
    range = { name=RANGED, order=15 },
    spells = { name=SPELLS, order=20 },
    damage = { name=DAMAGE, order=30 },
    heal = { name=HEALS, order=40 },
    buffs = { name="Buffs", order=50 },
    debuffs = { name="Debuffs", order=60 },
    other = { name="Other", order=80 },
    environmental = { name=ENVIRONMENT_SUBHEADER, order=999 }
}

Verbose.auraEvent = {
    APPLIED = { name="Applied", order=10 },
    REMOVED = { name="Removed", order=20 },
}

Verbose.spellIDTreeFuncs = {
    -- Skip "spellID#" to get the ID
    name = function(spellID) return Verbose:SpellName(spellID) end,
    icon = function(spellID) return Verbose:SpellIconID(spellID) end,
    desc = function(spellID)
        return (
            Verbose:SpellIconTexture(spellID)
            .. "\n".. Verbose:SpellDescription(spellID)
            .. "\n\nSpell ID: " .. spellID
        )
    end,
}

function Verbose:spellsRecordCombatLogEvent(eventInfo)
    if Verbose.ends_with(eventInfo.event, "_DAMAGE") then
        return
    end

    -- Fill db
    if not eventInfo.spellID then
        self:EventDbgPrint("No spell ID for", eventInfo.event)
        return
    end
    local dbTable = self.db.profile.spells[eventInfo.spellID][eventInfo.event]
    dbTable.lastRecord = GetServerTime()  -- eventInfo.timestamp is unreliable :/
    dbTable.count = dbTable.count + 1
    dbTable.categories = self:CategoryTree(eventInfo)

    -- Fill options table
    local optionGroupArgs
    if self.mountSpells[eventInfo.spellID] then
        return
        -- optionGroupArgs = self.options.args.events.args.mounts.args
    elseif self.spellbookSpells[eventInfo.spellID] then
        optionGroupArgs = self.options.args.events.args.spellbook.args[self.spellbookSpells[eventInfo.spellID]]
    else
        optionGroupArgs = self.options.args.events.args.spells.args
    end

    self:AddSpellToOptions(eventInfo.spellID, eventInfo.event)
    --self:AddCombatLogEventToOptions(optionGroupArgs, eventInfo.spellID)
end

function Verbose:OnCombatLogEvent(eventInfo)
    if Verbose.ends_with(eventInfo.event, "_DAMAGE") then
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

    if #messagesTable == 0 then
        self:SpeakDbgPrint("Empty message table")
        return
    end

    -- Talk
    self:Speak(
        dbTable,
        eventInfo,
        messagesTable)
end
