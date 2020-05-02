local addonName, Verbose = ...

function Verbose:AddEventToOptions(spellID, event)
    local spellOptions = self.options.args.events.args.spellcasts.args[tostring(spellID)]

    -- Insert spell options
    if not spellOptions then
        spellOptions = {
            type = "group",
            name = function(info) return self:SpellName(info[#info]) end,
            icon = function(info) return self:SpellIconID(info[#info]) end,
            iconCoords = Verbose.iconCropBorders,
            desc = function(info) return self:SpellIconTexture(info[#info]) .. "\n" .. self:SpellDescription(info[#info]) end,
            childGroups = "tree",
            args = {
                header = {
                    type = "description",
                    name = function(info) return self:SpellName(info[#info-1]) .. "\n" .. self:SpellIconTexture(info[#info-1]) end,
                    order = 0,
                    fontSize = "large",
                    width = "full",
                },
                content = {
                    type = "description",
                    name = function(info) return self:SpellDescription(info[#info-1])  .. "\n\nSpell ID: " .. info[#info-1] end,
                    order = 1,
                    fontSize = "medium",
                    width = "full",
                },
            },
        }
        self.options.args.events.args.spellcasts.args[tostring(spellID)] = spellOptions
    end

    -- Insert event options for this spell
    if not spellOptions.args[event] then
        spellOptions.args[event] = {
            type = "group",
            name = event,
            args = {
                enable = {
                    type = "toggle",
                    name = "Enable",
                    order = 10,
                    width = "full",
                    get = function(info) return self:SpellEventData(info).enabled end,
                    set = function(info, value) self:SpellEventData(info).enabled = value end,
                },
                proba = {
                    type = "range",
                    name = "Message probability",
                    order = 20,
                    isPercent = true,
                    min = 0,
                    max = 1,
                    bigStep = 0.05,
                    get = function(info) return self:SpellEventData(info).proba end,
                    set = function(info, value) self:SpellEventData(info).proba = value end,
                },
                cooldown = {
                    type = "range",
                    name = "Message cooldown (s)",
                    order = 30,
                    min = 0,
                    max = 3600,
                    softMax = 60,
                    bigStep = 1,
                    get = function(info) return self:SpellEventData(info).cooldown end,
                    set = function(info, value) self:SpellEventData(info).cooldown = value end,
                },
                list = {
                    type = "input",
                    name = "Messages, one per line",
                    order = 40,
                    multiline = 20,
                    width = "full",
                    get = function(info)
                        return Verbose:TableToText(self:SpellEventData(info).messages)
                    end,
                    set = function(info, value) self:TextToTable(value, self:SpellEventData(info).messages) end,
                },
            },
        }
    end
end

-- Return spell and event data for callbacks from info arg
function Verbose:SpellEventData(info)
    return self.db.profile.events.spells[tonumber(info[#info - 2])][info[#info - 1]]
end

-- Load saved events to options table
function Verbose:EventsDBToOptions()
    for spellID, spellData in pairs(self.db.profile.events.spells) do
        for event in pairs(spellData) do
            self:AddEventToOptions(spellID, event)
        end
    end
end
