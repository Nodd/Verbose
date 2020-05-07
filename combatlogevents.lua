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
    eventInfo.event = rawEventInfo[2]
    if eventInfo.event == "SPELL_PERIODIC_DAMAGE" then
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
    eventInfo.destReaction = Verbose:FlagToReaction(eventInfo.destFlags)
    eventInfo.sourceReaction = Verbose:FlagToReaction(eventInfo.sourceFlags)

    -- Return early if the player is not involved in the event
    -- TODO: What about the pet(s) ?
    eventInfo.castMode = self:CombatLogCastMode(eventInfo)
    if not eventInfo.castMode then return end

    -- The rest of the parameters depends on the event and will be managed in subfunctions
    self:SetCombatLogArgs(eventInfo, rawEventInfo)


    -- Debug
    self:EventDbgPrint(event, eventInfo.event)
    for k, v in pairs(eventInfo) do
        self:EventDetailsDbgPrint("  ", k, "=", v)
    end

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
        suffixIndex = 15
    elseif Verbose.starts_with(eventInfo.event, "ENVIRONMENTAL_") then
        eventInfo.environmentalType = unpack(rawEventInfo, suffixIndex)
        eventInfo.spellID = "-1"  -- Fake spell ID
        suffixIndex = 13
    elseif Verbose.starts_with(eventInfo.event, "SWING_") then
        eventInfo.spellID = "6603"  -- Autoattack spell
    elseif Verbose.starts_with(eventInfo.event, "UNIT_") then
        eventInfo.recapID, eventInfo.unconsciousOnDeath = unpack(rawEventInfo, suffixIndex)
        suffixIndex = 14
    else
        eventInfo.spellID = "-2"  -- Fake spell ID
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

    elseif eventInfo.event == "SPELL_AURA_APPLIED" or eventInfo.event == "SPELL_AURA_REFRESH" then
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

    else
        self:Print("Unknown combat log event:", eventInfo.event)
    end
    return categories
end

function Verbose.CategoryTypeValue(category)
    local typ, id = string.match(category, "^(.+)#(.+)$") -- use strsplit ?
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
            value = Verbose:SpellName(id)
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
}

function Verbose:CombatLogCastMode(eventInfo)
    if Verbose:NameIsPlayer(eventInfo.destName) then
        if Verbose:NameIsPlayer(eventInfo.sourceName) then
            return "self"
        elseif eventInfo.event == "ENVIRONMENTAL_DAMAGE" then
            return "receivedHarm"
        else
            return "received"..eventInfo.sourceReaction
        end
    elseif Verbose:NameIsPlayer(eventInfo.sourceName) then
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
    swing = { name="Swing", order=10 },
    spells = { name="Spells", order=20 },
    damage = { name="Damage", order=30 },
    heal = { name="Heal", order=40 },
    buffs = { name="Buffs", order=50 },
    debuffs = { name="Debuffs", order=60 },
    other = { name="Other", order=80 },
    environmental = { name="Environmental", order=999 }
}

Verbose.auraEvent = {
    APPLIED = { name="Applied", order=10 },
    REMOVED = { name="Removed", order=20 },
}

-- https://github.com/ketho-wow/KethoCombatLog/blob/master/KethoCombatLog.lua for the table
-- https://www.townlong-yak.com/framexml/8.1.5/GlobalStrings.lua#12934 for the strings
-- https://wow.gamepedia.com/COMBAT_LOG_EVENT for the truth
Verbose.SpellSchoolString = {
	[0x1] = STRING_SCHOOL_PHYSICAL:sub(2, -2),
	[0x2] = STRING_SCHOOL_HOLY:sub(2, -2),
	[0x4] = STRING_SCHOOL_FIRE:sub(2, -2),
	[0x8] = STRING_SCHOOL_NATURE:sub(2, -2),
	[0x10] = STRING_SCHOOL_FROST:sub(2, -2),
	[0x20] = STRING_SCHOOL_SHADOW:sub(2, -2),
	[0x40] = STRING_SCHOOL_ARCANE:sub(2, -2),
    -- double
	[0x3] = STRING_SCHOOL_HOLYSTRIKE:sub(2, -2),
	[0x5] = STRING_SCHOOL_FLAMESTRIKE:sub(2, -2),
	[0x6] = STRING_SCHOOL_HOLYFIRE:sub(2, -2),
	[0x9] = STRING_SCHOOL_STORMSTRIKE:sub(2, -2),
	[0xA] = STRING_SCHOOL_HOLYSTORM:sub(2, -2),
	[0xC] = STRING_SCHOOL_FIRESTORM:sub(2, -2),
	[0x11] = STRING_SCHOOL_FROSTSTRIKE:sub(2, -2),
	[0x12] = STRING_SCHOOL_HOLYFROST:sub(2, -2),
	[0x14] = STRING_SCHOOL_FROSTFIRE:sub(2, -2),
	[0x18] = STRING_SCHOOL_FROSTSTORM:sub(2, -2),
	[0x21] = STRING_SCHOOL_SHADOWSTRIKE:sub(2, -2),
	[0x22] = STRING_SCHOOL_SHADOWLIGHT:sub(2, -2), -- Twilight
	[0x24] = STRING_SCHOOL_SHADOWFLAME:sub(2, -2),
	[0x28] = STRING_SCHOOL_SHADOWSTORM:sub(2, -2), -- Plague
	[0x30] = STRING_SCHOOL_SHADOWFROST:sub(2, -2),
	[0x41] = STRING_SCHOOL_SPELLSTRIKE:sub(2, -2),
	[0x42] = STRING_SCHOOL_DIVINE:sub(2, -2),
	[0x44] = STRING_SCHOOL_SPELLFIRE:sub(2, -2),
	[0x48] = STRING_SCHOOL_SPELLSTORM:sub(2, -2),
	[0x50] = STRING_SCHOOL_SPELLFROST:sub(2, -2),
	[0x60] = STRING_SCHOOL_SPELLSHADOW:sub(2, -2),
    -- triple and more
	[0x1C] = STRING_SCHOOL_ELEMENTAL:sub(2, -2),
	[0x7C] = STRING_SCHOOL_CHROMATIC:sub(2, -2),
	[0x7E] = STRING_SCHOOL_MAGIC:sub(2, -2),
	[0x7F] = STRING_SCHOOL_CHAOS:sub(2, -2),
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
    local dbTable = self.db.profile.combatLog.children
    local optionGroupArgs = self.options.args.events.args.combatLog.args

    -- Fill tree
    for _, category in ipairs(self:CategoryTree(eventInfo)) do
        if not dbTable[category] then
            dbTable[category] = {
                enabled = false,
                merge = false,
                cooldown = 10,
                proba = 1,
                messages = {},
                children = {},
                count = 0,
            }

            -- Update options
            self:AddCombatLogEventToOptions(optionGroupArgs, category)
        end
        dbTable[category].lastRecord = GetServerTime()  -- eventInfo.timestamp is unreliable :/
        dbTable[category].count = dbTable[category].count + 1

        -- Prepare next iteration
        dbTable = dbTable[category].children
        optionGroupArgs = optionGroupArgs[category].args
    end
    self:UpdateOptionsGUI()
end

function Verbose:OnCombatLogEvent(eventInfo)
    local dbTable = self.db.profile.combatLog
    local enabled = true
    local categoryPath = "Combat log"
    local messagesTable = {}
    for i, category in ipairs(self:CategoryTree(eventInfo)) do
        dbTable = dbTable.children[category]

        -- Check that the category is enabled
        categoryPath = categoryPath.."/"..self:CategoryName(category)
        enabled = enabled and dbTable.enabled
        if not enabled then
            self:SpeakDbgPrint("Disabled combat log category:", categoryPath)
            return
        end

        -- Merge or wipe parent's messages
        if not dbTable.merge then
            wipe(messagesTable)
        end
        for _, m in ipairs(dbTable.messages) do
            tinsert(messagesTable, m)
        end
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
