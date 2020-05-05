local addonName, Verbose = ...

function Verbose:AddCombatLogEventToOptions(optionGroupArgs, category)
    if not optionGroupArgs[category] then
        optionGroupArgs[category] = {
            type = "group",
            name = self.CombatLogOptionToName,
            icon = self.CombatLogOptionToIcon,
            desc = self.CombatLogOptionToDesc,
            order = self.CombatLogOptionToOrder,
            args = {
                enable = {
                    type = "toggle",
                    name = "Enable",
                    order = 10,
                    width = "full",
                    get = "GetCombatLogEnabled",
                    set = "SetCombatLogEnabled",
                },
                proba = {
                    type = "range",
                    name = "Message probability",
                    order = 20,
                    isPercent = true,
                    min = 0,
                    max = 1,
                    bigStep = 0.05,
                    get = "GetCombatLogProba",
                    set = "SetCombatLogProba",
                },
                cooldown = {
                    type = "range",
                    name = "Message cooldown (s)",
                    order = 30,
                    min = 1,
                    max = 3600,
                    softMax = 60,
                    bigStep = 1,
                    get = "GetCombatLogCooldown",
                    set = "GetCombatLogCooldown",
                },
                messages = {
                    type = "input",
                    name = "Messages, one per line",
                    order = 40,
                    multiline = 17,
                    width = "full",
                    get = "GetCombatLogmessages",
                    set = "SetCombatLogmessages",
                },
            },
        }
    end
end

-- Callbacks
function Verbose.CombatLogOptionToName(info)
    return Verbose.InfoToCategoryData(info, "name")
end
function Verbose.CombatLogOptionToIcon(info)
    return Verbose.InfoToCategoryData(info, "icon")
end
function Verbose.CombatLogOptionToDesc(info)
    return Verbose.InfoToCategoryData(info, "desc")
end
function Verbose.CombatLogOptionToOrder(info)
    return Verbose.InfoToCategoryData(info, "order")
end

function Verbose.InfoToCategoryData(info, field)
    local typ, id = Verbose.CategoryTypeValue(info[#info])
    local value = Verbose.categoryData[typ](id)[field]
    if type(value) == "function" then
        value = value(info)
    end
    return value
end

function Verbose:GetCombatLogEnabled(info)
    return self:CombatLogSpellEventData(info).enabled
end

function Verbose:GetCombatLogProba(info)
    return self:CombatLogSpellEventData(info).proba
end

function Verbose:GetCombatLogCooldown(info)
    return self:CombatLogSpellEventData(info).cooldown
end

function Verbose:GetCombatLogmessages(info)
    return self:TableToText(self:CombatLogSpellEventData(info).messages)
end

function Verbose:SetCombatLogEnabled(info, value)
    self:CombatLogSpellEventData(info).enabled = value
end

function Verbose:SetCombatLogProba(info, value)
    self:CombatLogSpellEventData(info).proba = value
end

function Verbose:SetCombatLogCooldown(info, value)
    self:CombatLogSpellEventData(info).cooldown = value
end

function Verbose:SetCombatLogmessages(info, value)
    self:TextToTable(value, self:CombatLogSpellEventData(info).messages)
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
function Verbose:CombatLogSpellDBToOptions()
    local dbTable = self.db.profile.combatLog
    local optionGroupArgs = self.options.args.events.args.combatLog.args
    self:CombatLogSpellDBToOptionsRecursive(optionGroupArgs, dbTable)
end

function Verbose:CombatLogSpellDBToOptionsRecursive(optionGroupArgs, dbTable)
    for category, dbTableData in pairs(dbTable) do
        self:AddCombatLogEventToOptions(
            optionGroupArgs, category)
        self:CombatLogSpellDBToOptionsRecursive(
            optionGroupArgs[category].args, dbTableData.children)
    end
end
