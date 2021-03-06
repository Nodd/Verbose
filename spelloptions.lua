local addonName, Verbose = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- Lua functions
local ipairs = ipairs
local min = min
local next = next
local pairs = pairs
local tonumber = tonumber

-- WoW globals
local GetServerTime = GetServerTime
local IsPlayerSpell = IsPlayerSpell

function Verbose:AddSpellToOptions(spellID, event)
    -- Check spell book
    if self:CheckAndAddSpellbookToOptions(spellID, event) then
        return

    -- Check Mounts
    elseif self:CheckAndAddMountToOptions(spellID, event) then
        return

    -- Check Tradeskills
    elseif self:CheckAndAddTradeskillToOptions(spellID, event) then
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
            order = "SpellOrderInOptions",
            hidden = "SpellHideInOptions",
            childGroups = "select",
            args = {
                description = {
                    type = "description",
                    name = L["No event was recorded for this spell. Try to cast it !"],
                    order = 10,
                    fontSize = "medium",
                    hidden = "HideSpellDescription",
                },
                forget = {
                    type = "execute",
                    name = L["Forget this spell"],
                    desc = L["Delete the spell from the recorded list."],
                    order = 15,
                    func = "ForgetSpell",
                    hidden = "ForgetSpellHidden",
                },
            },
        }
        self:UpdateOptionsGUI()
    end
    return parentGroup.args[spellID]
end
function Verbose:HideSpellDescription(info)
    return next(self.db.profile.spells[info[#info - 1]]) ~= nil  -- Check that table is not empty
end
function Verbose:ForgetSpell(info)
    local spellID = info[#info - 1]

    -- Clear options
    local optionsArgs = self.options.args
    for i = 1, #info - 2 do
        optionsArgs = optionsArgs[info[i]].args
    end
    optionsArgs[spellID] = nil

    -- Clear DB
    self.db.profile.spells[spellID] = nil
end
function Verbose:ForgetSpellHidden(info)
    -- Hide buton with description
    if self:HideSpellDescription(info) then
        return true
    end

    -- Hide button if spell is in the spell book
    local spellID = info[#info - 1]
    return self.spellbookSpells[spellID] ~= nil
end

local eventDescFmt = "\n%s\n   "..NORMAL_FONT_COLOR_CODE.."%d "..BNET_BROADCAST_SENT_TIME.."|r"
local function sortByOrder(a, b)
    return Verbose.EventOrder(a) < Verbose.EventOrder(b)
end
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
    for event, eventData in Verbose.orderedpairs(dbTable, sortByOrder) do
        hasEvents = true
        local elapsed = Verbose:secondsToString(now - eventData.lastRecord)
        txt = txt..eventDescFmt:format(
            Verbose.EventName(event), eventData.count, elapsed)
    end
    if not hasEvents then
        txt = txt.."\n"..L["No event recorded"]
    end

    return txt
end

function Verbose:SpellOrderInOptions(info)
    local spellID = info[#info]
    if self.db.profile.sortSpellValue == "recent" then
        local lastRecordNegative = -0.1
        for _, eventData in pairs(self.db.profile.spells[spellID]) do
            lastRecordNegative = min(lastRecordNegative, -eventData.lastRecord)
        end
        return lastRecordNegative
    elseif self.db.profile.sortSpellValue == "count" then
        local countNegative = -0.1
        for _, eventData in pairs(self.db.profile.spells[spellID]) do
            countNegative = min(countNegative, -eventData.count)
        end
        return countNegative
    elseif self.db.profile.sortSpellValue == "icon" then
        return Verbose:SpellIconID(spellID)
    end
    -- Else return nil for alphabetical sort
end

-- Return true if spell should be hidden, false if it should be visible
function Verbose:SpellHideInOptions(info)
    local spellID = info[#info]

    -- Filter non player spells if option activated
    if self.db.profile.showPlayerSpellsOnly and not IsPlayerSpell(tonumber(spellID)) then
        return true
    end

    -- Hide spells without messages if option activated
    if self.db.profile.showConfiguredSpellsOnly then
        local empty = true
        for _, eventData in pairs(self.db.profile.spells[spellID]) do
            empty = empty and Verbose.tableIsEmpty(eventData.messages)
            if not empty then break end
        end
        if empty then
            return true
        end
    end

    -- Filter by spell name
    local spellName = self:SpellName(spellID):lower()
    local hide = false
    for _, word in ipairs(self.db.profile.filterValues) do
        if not spellName:find(word) then
            hide = true
            break
        end
    end
    return hide
end

function Verbose:EventHideInOptions(info)
    -- Hide events without messages if option activated
    if self.db.profile.showConfiguredSpellsOnly then
        local spellID = info[#info-1]
        local event = info[#info]
        local eventData = self.db.profile.spells[spellID][event]
        return Verbose.tableIsEmpty(eventData.messages)
    end
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
function Verbose.EventOrderFromInfo(info)
    return Verbose.EventOrder(info[#info])
end
function Verbose.EventOrder(event)
    if Verbose.usedSpellEvents[event] then
        return Verbose.usedSpellEvents[event].order
    elseif Verbose.playerCombatLogSubEvents[event] then
        return Verbose.playerCombatLogSubEvents[event].order
    else
        return 100
    end
end

-- All fields are dynamic so it's possible to reuse the same table
local spellEventOptionsGroup = {
    type = "group",
    name = Verbose.EventNameFromInfo,
    order = Verbose.EventOrderFromInfo,
    hidden = "EventHideInOptions",  -- hidden is inherted, must be set to false for each child
    args = {
        enable = {
            type = "toggle",
            name = ENABLE,
            order = 10,
            width = 1.5,
            hidden = false,
            get = "GetSpellEventEnabled",
            set = "SetSpellEventEnabled",
        },
        forget = {
            type = "execute",
            name = L["Forget this event"],
            desc = L["Delete the event for this spell. To avoid accidental data loss, the message list must be empty."],
            order = 15,
            width = Verbose.C.proba_option_width,
            hidden = false,
            func = "ForgetEvent",
            disabled = "ForgetEventDisable",
        },
        newline19 = { type="description", name="", order=15.5, hidden = false },
        proba = {
            type = "range",
            name = L["Speak once out of:"],
            desc = L["On average, messages will be sent once out of this number of events. Note that the actual value is random."],
            order = 35,
            min = 1,
            softMax = 20,
            bigStep = 1,
            width = Verbose.C.proba_option_width,
            hidden = false,
            get = "GetSpellEventProba",
            set = "SetSpellEventProba",
        },
        cooldown = {
            type = "range",
            name = L["Message cooldown (s)"],
            desc = L["Minimal delay between speeches for this spell. See also the global cooldown in the main Options tab."],
            order = 30,
            min = 0,
            max = 3600,
            softMax = 600,
            bigStep = 5,
            width = 1.5,
            hidden = false,
            get = "GetSpellEventCooldown",
            set = "SetSpellEventCooldown",
        },
        list = {
            type = "input",
            name = L["Messages, one per line"],
            desc = function(info)
                if Verbose.usedSpellEvents[info[#info - 1]] then
                    return Verbose.usedSpellEvents[info[#info - 1]].desc
                elseif Verbose.playerCombatLogSubEvents[info[#info - 1]] then
                    return Verbose.playerCombatLogSubEvents[info[#info - 1]].desc
                end
            end,
            order = 40,
            multiline = Verbose.multilineHeightTab,
            width = "full",
            hidden = false,
            get = "GetSpellEventMessages",
            set = "SetSpellEventMessages",
        },
    },
}

-- Add spell event configuration to a spell option's group if it doesn't exist
function Verbose:AddSpellEventOptions(spellOptionsGroup, event)
    if not spellOptionsGroup.args[event] then
        spellOptionsGroup.args[event] = spellEventOptionsGroup
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
    return 1 / self:SpellEventData(info).proba
end
function Verbose:SetSpellEventProba(info, value)
    self:SpellEventData(info).proba = 1 / value
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

function Verbose:ForgetEvent(info)
    local event = info[#info - 1]
    local spellID = info[#info - 2]

    -- Clear options
    local optionsArgs = self.options.args
    for i = 1, #info - 2 do
        optionsArgs = optionsArgs[info[i]].args
    end
    optionsArgs[event] = nil

    -- Clear DB
    self.db.profile.spells[spellID][event] = nil
end
function Verbose:ForgetEventDisable(info)
    local event = info[#info - 1]
    local spellID = info[#info - 2]
    return #self.db.profile.spells[spellID][event].messages ~= 0
end

-- Load saved events to options table
function Verbose:SpellDBToOptions()
    for spellID, spellData in pairs(self.db.profile.spells) do
        for event in pairs(spellData) do
            self:AddSpellToOptions(spellID, event)
        end
    end
end
