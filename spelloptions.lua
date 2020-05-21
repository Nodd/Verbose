local addonName, Verbose = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- Lua functions
local pairs = pairs

function Verbose:AddSpellToOptions(spellID, event)
    -- Check spell book
    if self:CheckAndAddSpellbookToOptions(spellID, event) then
        return

    -- Check Mounts
    elseif self:CheckAndAddMountToOptions(spellID, event) then
        return

    else
        -- Insert spell options
        local spellOptionsGroup = self:AddSpellOptionsGroup(
            self.options.args.events.args.spells, spellID)
        -- Insert event options for this spell
        self:AddSpellEventOptions(spellOptionsGroup, event)
    end
end

function Verbose:AddSpellOptionsGroup(parentGroup, spellID)
    if not parentGroup.args[spellID] then
        parentGroup.args[spellID] = {
            type = "group",
            name = function(info) return self:SpellName(info[#info]) end,
            icon = function(info) return self:SpellIconID(info[#info]) end,
            iconCoords = Verbose.iconCropBorders,
            desc = Verbose.SpellOptionsDesc,
            childGroups = "select",
            args = {
            },
        }
        self:UpdateOptionsGUI()
    end
    return parentGroup.args[spellID]
end

local eventDescFmt = L["\n%%s\n   %s%%d (%%s ago)|r"]:format(NORMAL_FONT_COLOR_CODE)
function Verbose.SpellOptionsDesc(info)
    local spellID = info[#info]

    -- Main text
    local txt = ("%s\n%s\n\nSpell ID: %s"):format(
        Verbose:SpellIconTexture(spellID),
        Verbose:SpellDescription(spellID),
        spellID)

    -- Events detail
    local dbTable = Verbose.db.profile.spells[spellID]
    local now = GetServerTime()
    local hasEvents = false
    for event, eventData in pairs(dbTable) do
        hasEvents = true
        local elapsed = Verbose:secondsToString(now - eventData.lastRecord)
        txt = txt..eventDescFmt:format(
            Verbose.EventName(event), eventData.count, elapsed)
    end
    if not hasEvents then
        txt = txt..L["\nNo event recorded"]
    end

    return txt
end

-- Add spell event configuration to a spell option's group if it doesn't exist
function Verbose:AddSpellEventOptions(spellOptionsGroup, event)
    if not spellOptionsGroup.args[event] then
        spellOptionsGroup.args[event] = {
            type = "group",
            name = Verbose.EventNameFromInfo,
            order = Verbose.EventOrder,
            args = {
                enable = {
                    type = "toggle",
                    name = ENABLE,
                    order = 10,
                    width = "full",
                    get = "GetSpellEventEnabled",
                    set = "SetSpellEventEnabled",
                },
                proba = {
                    type = "range",
                    name = L["Message probability"],
                    order = 20,
                    isPercent = true,
                    min = 0,
                    max = 1,
                    bigStep = 0.05,
                    get = "GetSpellEventProba",
                    set = "SetSpellEventProba",
                },
                cooldown = {
                    type = "range",
                    name = L["Message cooldown (s)"],
                    order = 30,
                    min = 0,
                    max = 3600,
                    softMax = 600,
                    bigStep = 1,
                    get = "GetSpellEventCooldown",
                    set = "SetSpellEventCooldown",
                },
                list = {
                    type = "input",
                    name = L["Messages, one per line"],
                    order = 40,
                    multiline = Verbose.multilineHeightTab,
                    width = "full",
                    get = "GetSpellEventMessages",
                    set = "SetSpellEventMessages",
                },
            },
        }
        self:UpdateOptionsGUI()
    end
end

-- Return spell and event data for callbacks from info arg
function Verbose:SpellEventData(info)
    return self.db.profile.spells[info[#info - 2]][info[#info - 1]]
end
function Verbose:GetSpellEventEnabled(info)
    return self:SpellEventData(info).enabled
end
function Verbose:SetSpellEventEnabled(info, value)
    self:SpellEventData(info).enabled = value
end
function Verbose:GetSpellEventProba(info)
    return self:SpellEventData(info).proba
end
function Verbose:SetSpellEventProba(info, value)
    self:SpellEventData(info).proba = value
end
function Verbose:GetSpellEventCooldown(info)
    return self:SpellEventData(info).cooldown
end
function Verbose:SetSpellEventCooldown(info, value)
    self:SpellEventData(info).cooldown = value
end
function Verbose:GetSpellEventMessages(info)
    return self:TableToText(self:SpellEventData(info).messages)
end
function Verbose:SetSpellEventMessages(info, value)
    self:TextToTable(value, self:SpellEventData(info).messages)
end

function Verbose.EventNameFromInfo(info)
    return Verbose.EventName(info[#info])
end
function Verbose.EventName(event)
    if Verbose.usedSpellEvents[event] then
        return Verbose.usedSpellEvents[event].name
    elseif Verbose.playerCombatLogSubEvents[event] then
        return Verbose.playerCombatLogSubEvents[event].name
    else
        return event
    end
end
function Verbose.EventOrder(info)
    event = info[#info]
    if Verbose.usedSpellEvents[event] then
        return Verbose.usedSpellEvents[event].order
    elseif Verbose.playerCombatLogSubEvents[event] then
        return Verbose.playerCombatLogSubEvents[event].order
    else
        return nil
    end
end

-- Load saved events to options table
function Verbose:SpellDBToOptions()
    for spellID, spellData in pairs(self.db.profile.spells) do
        for event in pairs(spellData) do
            self:AddSpellToOptions(spellID, event)
        end
    end
end
