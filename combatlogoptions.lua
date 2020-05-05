local addonName, Verbose = ...


function Verbose:PopulatecombatLogCategoriesOptions(parent, id, data)
    parent[id] = {
        type = "group",
        name = data.title,
        order = data.order,
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


function Verbose:AddCombatLogEventToOptions(optionGroupArgs, categoryTable)
    -- Insert subtype options for this spell
    if not optionGroupArgs[categoryTable.id] then
        optionGroupArgs[categoryTable.id] = {
            type = "group",
            name = categoryTable.name,
            icon = categoryTable.icon,
            desc = categoryTable.desc,
            order = categoryTable.order,
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
                messages = {
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
    local dbTable = self.db.profile.combatLog[info[3]]
    for i = 4, (#info - 1) do
        dbTable = dbTable.children[info[i]]
    end
    return dbTable
end

-- Load saved events to options table
function Verbose:CombatLogSpellDBToOptions(optionGroupArgs, id, dbTable)
    option = self:AddCombatLogEventToOptions(optionGroupArgs, id, dbTable)
    for child, childTable in dbTable.children do
        self:CombatLogSpellDBToOptions(option.args, child, childTable)
    end
end
