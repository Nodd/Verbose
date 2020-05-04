local addonName, Verbose = ...

Verbose.combatLogOptionsSourceTarget = {
    self = { title="Self", order=10 },
    done = { title="Done", order=10 },
    received = { title="Received", order=10 },
    noTarget = { title="No target", order=10 },
}

Verbose.combatLogOptionsCategories = {
    swing = { title="Swing", order=10 },
    spells = { title="Spells", order=10 },
    damage = { title="Damage", order=10 },
    heal = { title="Heal", order=10 },
    buffs = { title="Buffs", order=10 },
    debuffs = { title="Debuffs", order=10 },
    environmental = { title="Environmental", order=10 },
    other = { title="Other", order=10 },
}

function Verbose:PopulatecombatLogCategoriesOptions(parent, id, data)
    parent[id] = {
        type = "group",
        name = data.title,
        order = 10,
        icon = data.icon,
        iconCoords = Verbose.iconCropBorders,
        hidden = true,
        childGroups = "tree",
        args = {
            title = {
                type = "description",
                name = data.title,
                fontSize = "large",
                order = 0,
            },
            info = {
                type = "description",
                name = "Documentation here.",
                fontSize = "medium",
                order = 1,
            },
        },
    }
    return parent[id]
end

for sourceTargetID, sourceTargetData in pairs(Verbose.combatLogOptionsSourceTarget) do
    local options = Verbose:PopulatecombatLogCategoriesOptions(
        Verbose.options.args.events.args.combatLog.args, sourceTargetID, sourceTargetData)
    for categoryID, categoryData in pairs(Verbose.combatLogOptionsCategories) do
        Verbose:PopulatecombatLogCategoriesOptions(options.args, categoryID, categoryData)
    end
end

function Verbose:AddCombatLogSpellToOptions(castMode, category, spellID, event)
    local spellOptions = self.options.args.events.args.combatLog.args[castMode].args[category].args[tostring(spellID)]
    self.options.args.events.args.combatLog.args[castMode].hidden = false
    self.options.args.events.args.combatLog.args[castMode].args[category].hidden = false

    -- Insert spell options
    if not spellOptions then
        spellOptions = {
            type = "group",
            name = function(info) return self:SpellName(info[#info]) end,
            icon = function(info) return self:SpellIconID(info[#info]) end,
            iconCoords = Verbose.iconCropBorders,
            desc = function(info)
                return (
                    self:SpellIconTexture(info[#info])
                    .. "\n".. self:SpellDescription(info[#info]))
                    .. "\n\nSpell ID: " .. info[#info]
                end,
            childGroups = "tab",
            args = {
            },
        }
        self.options.args.events.args.combatLog.args[castMode].args[category].args[tostring(spellID)] = spellOptions
    end

    -- Insert event options for this spell
    if not spellOptions.args[event] then
        spellOptions.args[event] = {
            type = "group",
            name = event, --self.usedSpellEvents[event].title,
            order = 100,  --self.usedSpellEvents[event].order,
            args = {
                enable = {
                    type = "toggle",
                    name = "Enable",
                    order = 10,
                    width = "full",
                    get = function(info) return self:CombatLogSpellEventData(info).enabled end,
                    set = function(info, value) self:CombatLogSpellEventData(info).enabled = value end,
                },
                proba = {
                    type = "range",
                    name = "Message probability",
                    order = 20,
                    isPercent = true,
                    min = 0,
                    max = 1,
                    bigStep = 0.05,
                    get = function(info) return self:CombatLogSpellEventData(info).proba end,
                    set = function(info, value) self:CombatLogSpellEventData(info).proba = value end,
                },
                cooldown = {
                    type = "range",
                    name = "Message cooldown (s)",
                    order = 30,
                    min = 1,
                    max = 3600,
                    softMax = 60,
                    bigStep = 1,
                    get = function(info) return self:CombatLogSpellEventData(info).cooldown end,
                    set = function(info, value) self:CombatLogSpellEventData(info).cooldown = value end,
                },
                list = {
                    type = "input",
                    name = "Messages, one per line",
                    order = 40,
                    multiline = 17,
                    width = "full",
                    get = function(info)
                        return Verbose:TableToText(self:CombatLogSpellEventData(info).messages)
                    end,
                    set = function(info, value) self:TextToTable(value, self:CombatLogSpellEventData(info).messages) end,
                },
            },
        }
    end
end

-- Return spell and event data for callbacks from info arg
function Verbose:CombatLogSpellEventData(info)
    local castMode = info[#info - 4]
    local category = info[#info - 3]
    local spellID = tonumber(info[#info - 2])
    local event = info[#info - 1]
    return self.db.profile.combatLog[castMode][category][spellID][event]
end

-- Load saved events to options table
function Verbose:CombatLogSpellDBToOptions()
    for castMode, castModeData in pairs(self.db.profile.combatLog) do
        for category, categoryData in pairs(self.db.profile.combatLog[castMode]) do
            for spellID, spellData in pairs(self.db.profile.combatLog[castMode][category]) do
                for event, eventData in pairs(spellData) do
                    self:AddCombatLogSpellToOptions(castMode, category, spellID, event)
                end
            end
        end
    end
end
