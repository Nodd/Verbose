local addonName, Verbose = ...

-- Lua functions
local format = format
local mod = mod
local select = select
local tconcat = table.concat
local tinsert = tinsert
local tonumber = tonumber
local wipe = wipe

-- WoW globals
local GetSpellDescription = GetSpellDescription
local GetSpellInfo = GetSpellInfo
local FONT_COLOR_CODE_CLOSE = FONT_COLOR_CODE_CLOSE
local NORMAL_FONT_COLOR_CODE = NORMAL_FONT_COLOR_CODE


-------------------------------------------------------------------------------
-- Multiline text and table
-------------------------------------------------------------------------------

function Verbose:TableToText(t)
    return tconcat(t, "\n")
end

function Verbose:TextToTable(s, t)
    -- clear table
    wipe(t)

    -- Split on \n, skipping empty lines
    for v in s:gmatch("([^\n]+)") do
        tinsert(t, v)
    end
end

-------------------------------------------------------------------------------
-- Table operations
-------------------------------------------------------------------------------

-- from https://wow.gamepedia.com/Orderedpairs
local function _orderednext(t, n)
    local key = t[t.__next]
    if not key then return end
    t.__next = t.__next + 1
    return key, t.__source[key]
end
function Verbose.orderedpairs(t, f)
    local keys, kn = {__source = t, __next = 1}, 1
    for k in pairs(t) do
        keys[kn], kn = k, kn + 1
    end
    table.sort(keys, f)
    return _orderednext, keys
end

-------------------------------------------------------------------------------
-- String operations
-------------------------------------------------------------------------------

function Verbose.starts_with(str, ...)
    for i = 1, select("#",...) do
        local start = select(i, ...)
        if str:sub(1, #start) == start then
            return true
        end
    end
    return false
end

function Verbose.ends_with(str, ...)
    for i = 1, select("#",...) do
        local ending = select(i, ...)
        if ending == "" or str:sub(-#ending) == ending then
            return true
        end
    end
    return false
end


-------------------------------------------------------------------------------
-- Spells : ID, name, icon, description
-------------------------------------------------------------------------------

-- To be used in option table
Verbose.iconCropBorders = { 1/16, 15/16, 1/16, 15/16 }

-- Icon texture, 32 pixels
function Verbose:IconTextureFromID(iconID)
    if iconID then
        return "|T" .. iconID .. ":32|t"
    else
        return ""
    end
end

-- Borderless icon texture, text height
function Verbose:IconTextureBorderlessFromID(iconID)
    return "|T" .. iconID .. ":0:0:0:0:64:64:4:60:4:60|t"
end

function Verbose:SpellName(spellID)
    local name = GetSpellInfo(tonumber(spellID))
    if not name then return "|cFFFFFFFF???|r" end
    -- Text in white like in tooltips
    return "|cFFFFFFFF" .. name .. "|r"
end

function Verbose:SpellNameAndIconID(spellID)
    local name, _, iconID = GetSpellInfo(tonumber(spellID))
    if not name then return "", "" end
    -- Text in white like in tooltips
    return "|cFFFFFFFF" .. name .. "|r", iconID
end

function Verbose:SpellNameAndIconTexture(spellID)
    local name, _, iconID = GetSpellInfo(tonumber(spellID))
    if not name then return "", "" end
    -- Text in white like in tooltips
    return "|cFFFFFFFF" .. name .. "|r", self:IconTextureFromID(iconID)
end

function Verbose:SpellIconID(spellID)
    local _, _, iconID = GetSpellInfo(tonumber(spellID))
    return iconID
end

function Verbose:SpellIconTexture(spellID)
    local _, _, iconID = GetSpellInfo(tonumber(spellID))
    return self:IconTextureFromID(iconID)
end

function Verbose:SpellDescription(spellID)
    local description = GetSpellDescription(tonumber(spellID))
    if not description then return "" end
    -- Text in yellowish like in tooltips
    return NORMAL_FONT_COLOR_CODE .. description .. FONT_COLOR_CODE_CLOSE
end


-------------------------------------------------------------------------------
-- Spells : Extend WoW API
-------------------------------------------------------------------------------

-- Check if a given name corresponds to the player (with or without the realm name)
local playerName = UnitName("player") -- realm result from UnitName("player") is always nil
local realmName = GetRealmName()
function Verbose:NameIsPlayer(name)
    return name == "player" or name == playerName or name == playerName.."-"..realmName
end

-------------------------------------------------------------------------------
-- Time
-------------------------------------------------------------------------------
function Verbose:secondsToString(value)
    local seconds = mod(value, 60)
    value = (value - seconds) / 60
    local minutes = mod(value, 60)
    value = (value - minutes) / 60
    local hours = mod(value, 60)
    value = (value - hours) / 60
    local days = mod(value, 24)
    value = (value - days) / 24

    if days > 0 then
        return INT_SPELL_DURATION_DAYS:format(days)
    elseif hours > 0 then
        return INT_SPELL_DURATION_HOURS:format(hours)
    elseif minutes > 0 then
        return INT_SPELL_DURATION_MIN:format(minutes)
    else
        return INT_SPELL_DURATION_SEC :format(seconds)
    end
end
