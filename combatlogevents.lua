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

Verbose.combatLogCastModes = {
    self = { name="Self", order=10 },
    done = { name="Done", order=20 },
    received = { name="Received", order=30 },
    noTarget = { name="No target", order=40 },
}

Verbose.combatLogOptionsCategories = {
    swing = { name="Swing", order=10 },
    spells = { name="Spells", order=20 },
    damage = { name="Damage", order=30 },
    heal = { name="Heal", order=40 },
    buffs = { name="Buffs", order=50 },
    debuffs = { name="Debuffs", order=60 },
    environmental = { name="Environmental", order=70 },
    other = { name="Other", order=80 },
}

Verbose.auraEvent = {
    APPLIED = { name = "Applied", order = 10 },
    REMOVED = { name = "Removed", order = 20 },
}

Verbose.categoryData = {
    castMode = function(id) return Verbose.combatLogCastModes[id] end,
    combatLogCategory = function(id) return Verbose.combatLogOptionsCategories[id] end,
    spellID = function(id) return Verbose.spellIDTreeFuncs end,
    school = function(id) return { name=Verbose.SpellSchoolString[tonumber(id)] } end,
    auraEvent = function(id) return Verbose.auraEvent[id] end,
    event = function(id) return { name=id } end,
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

    -- Debug
    self:EventDbgPrint(event)
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

function Verbose:CategoryIDTree(eventInfo)
    local categories = { "castMode#"..eventInfo.castMode }
    if eventInfo.event == "SPELL_HEAL" then
        tinsert(categories, "combatLogCategory#heal")
        tinsert(categories, "spellID#"..eventInfo.spellID)
    elseif eventInfo.event == "SPELL_DAMAGE" then
        tinsert(categories, "combatLogCategory#damage")
        tinsert(categories, "school#"..eventInfo.school)
        tinsert(categories, "spellID#"..eventInfo.spellID)
    elseif eventInfo.event == "ENVIRONMENTAL_DAMAGE" then
        tinsert(categories, "combatLogCategory#damage")
        tinsert(categories, Verbose.combatLogOptionsEnvironmental)
        tinsert(categories, eventInfo.environmentalType)
    elseif eventInfo.event == "SWING_DAMAGE" then
        tinsert(categories, "combatLogCategory#damage")
        tinsert(categories, "Swing")
    elseif eventInfo.event == "RANGE_DAMAGE" then
        tinsert(categories, "combatLogCategory#damage")
        tinsert(categories, "Range")
    elseif eventInfo.event == "SPELL_FAIL" then
        tinsert(categories, "combatLogCategory#damage")
        tinsert(categories, "school#"..eventInfo.school)
        tinsert(categories, "spellID#"..eventInfo.spellID)
        tinsert(categories, eventInfo.failedType)
    elseif eventInfo.event == "SPELL_AURA_APPLIED" or eventInfo.event == "SPELL_AURA_REFRESH" then
        if eventInfo.auraType == "BUFF" then
            tinsert(categories, "combatLogCategory#buffs")
        else
            tinsert(categories, "combatLogCategory#debuffs")
        end
        tinsert(categories, "school#"..eventInfo.school)
        tinsert(categories, "spellID#"..eventInfo.spellID)
        tinsert(categories, "auraEvent#APPLIED")
    elseif eventInfo.event == "SPELL_AURA_REMOVED" then
        if eventInfo.auraType == "BUFF" then
            tinsert(categories, "combatLogCategory#buffs")
        else
            tinsert(categories, "combatLogCategory#debuffs")
        end
        tinsert(categories, "school#"..eventInfo.school)
        tinsert(categories, "spellID#"..eventInfo.spellID)
        tinsert(categories, "auraEvent#REMOVED")
    else
        tinsert(categories, "event#"..eventInfo.event)
        tinsert(categories, "spellID#"..eventInfo.spellID)
    end
    return categories
end

function Verbose:spellsRecordCombatLogEvent(eventInfo)
    local dbTable = self.db.profile.combatLog.children
    local optionGroupArgs = self.options.args.events.args.combatLog.args

    -- Fill tree if necessary
    for _, category in ipairs(self:CategoryIDTree(eventInfo)) do
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
        dbTable[category].lastRecord = eventInfo.timestamp
        dbTable[category].count = dbTable[category].count + 1

        -- Prepare next iteration
        dbTable = dbTable[category].children
        optionGroupArgs = optionGroupArgs[category].args
    end
    self:UpdateOptionsGUI()
end

function Verbose.CategoryTypeValue(category)
    local typ, id = string.match(category, "^(.+)#(.+)$") -- use strsplit ?
    return typ, id
end

function Verbose:OnCombatLogEvent(eventInfo)
    local dbTable = self.db.profile.combatLog
    local messagesTable = {}
    for i, categoryTable in ipairs(self:CategoryIDTree(eventInfo)) do
        dbTable = dbTable.children[categoryTable]
        if not dbTable.merge then
            wipe(messagesTable)
        end
        for _, m in ipairs(dbTable.messages) do
            tinsert(messagesTable, m)
        end
    end
    -- Talk
    self:Speak(
        dbTable,
        eventInfo,
        messagesTable)
end
