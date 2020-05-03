local addonName, Verbose = ...

function Verbose:AddSpellToOptions(spellID, event)
    local spellOptions = self.options.args.events.args.spellcasts.args[tostring(spellID)]

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
        self.options.args.events.args.spellcasts.args[tostring(spellID)] = spellOptions
    end

    -- Insert event options for this spell
    if not spellOptions.args[event] then
        spellOptions.args[event] = {
            type = "group",
            name = self.usedSpellEvents[event].title,
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
                    multiline = 17,
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
    return self.db.profile.spells[tonumber(info[#info - 2])][info[#info - 1]]
end

-- Load saved events to options table
function Verbose:SpellDBToOptions()
    for spellID, spellData in pairs(self.db.profile.spells) do
        for event in pairs(spellData) do
            self:AddSpellToOptions(spellID, event)
        end
    end
end
