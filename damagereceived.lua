local addonName, Verbose = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- Lua functions
local tonumber = tonumber
local tostring = tostring
local bit_band = bit.band
local bit_rshift = bit.rshift
local bit_lshift = bit.lshift
local pairs = pairs

-- WoW globals
local GetServerTime = GetServerTime
local ENABLE = ENABLE


local environmentalDamage = {
    Drowning = STRING_ENVIRONMENTAL_DAMAGE_DROWNING,
    Falling = STRING_ENVIRONMENTAL_DAMAGE_FALLING,
    Fatigue = STRING_ENVIRONMENTAL_DAMAGE_FATIGUE,
    Fire = STRING_ENVIRONMENTAL_DAMAGE_FIRE,
    Lava = STRING_ENVIRONMENTAL_DAMAGE_LAVA,
    Slime = STRING_ENVIRONMENTAL_DAMAGE_SLIME,
}

-- https://github.com/ketho-wow/KethoDamage/blob/master/KethoDamage.lua for the table (thanks !)
-- https://www.townlong-yak.com/framexml/8.3.0/GlobalStrings.lua#12934 for the strings
-- https://wow.gamepedia.com/COMBAT_LOG_EVENT for the truth
Verbose.SpellSchoolString = {
    [0x1] = STRING_SCHOOL_PHYSICAL:gsub("%(", "", 1):gsub("%)", "", 1),
    [0x2] = STRING_SCHOOL_HOLY:gsub("%(", "", 1):gsub("%)", "", 1),
    [0x4] = STRING_SCHOOL_FIRE:gsub("%(", "", 1):gsub("%)", "", 1),
    [0x8] = STRING_SCHOOL_NATURE:gsub("%(", "", 1):gsub("%)", "", 1),
    [0x10] = STRING_SCHOOL_FROST:gsub("%(", "", 1):gsub("%)", "", 1),
    [0x20] = STRING_SCHOOL_SHADOW:gsub("%(", "", 1):gsub("%)", "", 1),
    [0x40] = STRING_SCHOOL_ARCANE:gsub("%(", "", 1):gsub("%)", "", 1),
    -- double
    [0x3] = STRING_SCHOOL_HOLYSTRIKE,
    [0x5] = STRING_SCHOOL_FLAMESTRIKE,
    [0x6] = STRING_SCHOOL_HOLYFIRE,
    [0x9] = STRING_SCHOOL_STORMSTRIKE,
    [0xA] = STRING_SCHOOL_HOLYSTORM,
    [0xC] = STRING_SCHOOL_FIRESTORM,
    [0x11] = STRING_SCHOOL_FROSTSTRIKE,
    [0x12] = STRING_SCHOOL_HOLYFROST,
    [0x14] = STRING_SCHOOL_FROSTFIRE,
    [0x18] = STRING_SCHOOL_FROSTSTORM,
    [0x21] = STRING_SCHOOL_SHADOWSTRIKE,
    [0x22] = STRING_SCHOOL_SHADOWLIGHT, -- Twilight
    [0x24] = STRING_SCHOOL_SHADOWFLAME,
    [0x28] = STRING_SCHOOL_SHADOWSTORM, -- Plague
    [0x30] = STRING_SCHOOL_SHADOWFROST,
    [0x41] = STRING_SCHOOL_SPELLSTRIKE,
    [0x42] = STRING_SCHOOL_DIVINE,
    [0x44] = STRING_SCHOOL_SPELLFIRE,
    [0x48] = STRING_SCHOOL_SPELLSTORM,
    [0x50] = STRING_SCHOOL_SPELLFROST,
    [0x60] = STRING_SCHOOL_SPELLSHADOW,
    -- triple and more
    [0x1C] = STRING_SCHOOL_ELEMENTAL,
    [0x7C] = STRING_SCHOOL_CHROMATIC,
    [0x7E] = STRING_SCHOOL_MAGIC,
    [0x7F] = STRING_SCHOOL_CHAOS,
}
local schoolDesc = {}

local function getDamageDesc(info)
    local damageID = info[#info]
    local desc
    if schoolDesc[tonumber(damageID)] then
        desc = schoolDesc[tonumber(damageID)].."\n\n"
    else
        desc = ""
    end

    local dbTable = Verbose.db.profile.damage[damageID]
    desc = desc..L["Count:"].." "..dbTable.count
    if dbTable.count > 0 then
        local elapsed = Verbose:secondsToString(GetServerTime() - dbTable.lastRecord)
        desc = desc .. "\n"..L["Last: %s ago"]:format(elapsed)
    end
    return desc
end

function Verbose:AddDamageToOptions(optionGroupArgs, damageID, name, desc)
    damageID = tostring(damageID)
    if not optionGroupArgs[damageID] then
        optionGroupArgs[damageID] = {
            type = "group",
            name = name,
            desc = getDamageDesc,
            order = "DamageOrderInOptions",
            hidden = "DamageHideInOptions",
            args = {
                enable = {
                    type = "toggle",
                    name = ENABLE,
                    order = 10,
                    width = "full",
                    get = "GetDamageEnabled",
                    set = "SetDamageEnabled",
                },
                merge = {
                    type = "toggle",
                    name = L["Merge parent's messages"],
                    order = 15,
                    hidden = true,
                    get = "GetDamageMerge",
                    set = "SetDamageMerge",
                },
                proba = {
                    type = "range",
                    name = L["Speak once out of:"],
                    desc = L["On average, messages will be sent once out of this number of events. Note that the actual value is random."],
                    order = 30,
                    min = 1,
                    softMax = 20,
                    bigStep = 1,
                    width = Verbose.C.proba_option_width,
                    get = "GetDamageProba",
                    set = "SetDamageProba",
                },
                cooldown = {
                    type = "range",
                    name = L["Message cooldown (s)"],
                    desc = L["Minimal delay between speeches for this spell. See also the global cooldown in the main Options tab."],
                    order = 20,
                    min = 0,
                    max = 3600,
                    softMax = 600,
                    bigStep = 1,
                    width = 1.5,
                    get = "GetDamageCooldown",
                    set = "SetDamageCooldown",
                },
                messages = {
                    type = "input",
                    name = L["Messages, one per line"],
                    order = 40,
                    multiline = Verbose.multilineHeightNoTab,
                    width = "full",
                    get = "GetDamageMessages",
                    set = "SetDamageMessages",
                },
            },
        }
        self:UpdateOptionsGUI()
    end
end

function Verbose:GetDamageEnabled(info)
    return self:DamageEventData(info).enabled
end

function Verbose:GetDamageMerge(info)
    return self:DamageEventData(info).merge
end

function Verbose:GetDamageProba(info)
    return 1 / self:DamageEventData(info).proba
end

function Verbose:GetDamageCooldown(info)
    return self:DamageEventData(info).cooldown
end

function Verbose:GetDamageMessages(info)
    return self:TableToText(self:DamageEventData(info).messages)
end

function Verbose:SetDamageEnabled(info, value)
    self:DamageEventData(info).enabled = value
end

function Verbose:SetDamageMerge(info, value)
    self:DamageEventData(info).merge = value
end

function Verbose:SetDamageProba(info, value)
    self:DamageEventData(info).proba = 1 / value
end

function Verbose:SetDamageCooldown(info, value)
    self:DamageEventData(info).cooldown = value
end

function Verbose:SetDamageMessages(info, value)
    self:TextToTable(value, self:DamageEventData(info).messages)
end

-- Return spell and event data for callbacks from info arg
function Verbose:DamageEventData(info)
    return self.db.profile.damage[info[#info - 1]]
end

function Verbose:DamageOrderInOptions(info)
    local damageID = info[#info]
    local dbTable = Verbose.db.profile.damage[damageID]
    if self.db.profile.sortSpellValue == "recent" then
        return min(-0.1, -dbTable.lastRecord)
    elseif self.db.profile.sortSpellValue == "count" then
        return min(-0.1, -dbTable.count)
    end
    -- Else return nil for alphabetical sort (and icon sort)
end

-- Return true if damage type should be hidden, false if it should be visible
function Verbose:DamageHideInOptions(info)
    local damageID = info[#info]
    local dbTable = Verbose.db.profile.damage[damageID]

    -- Hide damage types without messages if option activated
    if self.db.profile.showConfiguredSpellsOnly then
        if Verbose.tableIsEmpty(dbTable.messages) then
            return true
        end
    end

    -- Filter by damage name
    local damageName = info.option.name:lower()
    local hide = false
    for _, word in ipairs(self.db.profile.filterValues) do
        if not damageName:find(word) then
            hide = true
            break
        end
    end
    return hide
end

local function nbBits1(num)
    local count = 0
    for i=0,8 do
        if bit_band(bit_rshift(num, i), 0x01) == 0x01 then
            count = count + 1
        end
    end
    return count
end

local function descBits(id)
    local desc
    for i=0,6 do
        local n = bit_lshift(0x01, i)
        if bit_band(n, id) ~= 0 then
            if desc then
                desc = desc.." + "..Verbose.SpellSchoolString[n]
            else
                desc = Verbose.SpellSchoolString[n]
            end
        end
    end
    return desc
end

function Verbose:InitDamageReceived()
    local optionGroupArgs = self.options.args.events.args.damage.args.environmental.args
    for damageID, str in pairs(environmentalDamage) do
        self:AddDamageToOptions(optionGroupArgs, damageID, str)
    end

    for damageID, str in pairs(Verbose.SpellSchoolString) do
        local n = nbBits1(damageID)
        local detail
        if n == 1 then
            optionGroupArgs = self.options.args.events.args.damage.args.monoSchool.args
        elseif n == 2 then
            optionGroupArgs = self.options.args.events.args.damage.args.dualSchools.args
            schoolDesc[damageID] = descBits(damageID)
        else
            optionGroupArgs = self.options.args.events.args.damage.args.moreSchools.args
            schoolDesc[damageID] = descBits(damageID)
        end
        self:AddDamageToOptions(optionGroupArgs, damageID, str, detail)
    end
end

function Verbose:OnDamageEvent(eventInfo)
    if not self:NameIsPlayer(eventInfo.destname) then
        return
    end
    local dbTable
    if eventInfo._event == "ENVIRONMENTAL_DAMAGE" then
        dbTable = self.db.profile.damage[eventInfo._environmentalType]
    else
        dbTable = self.db.profile.damage[tostring(eventInfo._school)]
    end

    dbTable.count = dbTable.count + 1
    dbTable.lastRecord = GetServerTime()

    -- Talk
    self:Speak(
    dbTable,
    eventInfo)
end
