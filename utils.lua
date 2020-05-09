local addonName, Verbose = ...


-------------------------------------------------------------------------------
-- Multiline text and table
-------------------------------------------------------------------------------

function Verbose:TableToText(t)
    return table.concat(t, "\n")
end

function Verbose:TextToTable(s, t)
    -- clear table
    table.wipe(t)

    -- Split on \n, skipping empty lines
    for v in s:gmatch("([^\n]+)") do
        table.insert(t, v)
    end
end


-------------------------------------------------------------------------------
-- String operations
-------------------------------------------------------------------------------

function Verbose.starts_with(str, ...)
    for i = 1, select("#",...) do
        start = select(i, ...)
        if str:sub(1, #start) == start then
            return true
        end
    end
    return false
end

function Verbose.ends_with(str, ...)
    for i = 1, select("#",...) do
        ending = select(i, ...)
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
    return "|cFFFFFFFF" .. name .. "|r", Verbose:IconTextureFromID(iconID)
end

function Verbose:SpellIconID(spellID)
    local _, _, iconID = GetSpellInfo(tonumber(spellID))
    return iconID
end

function Verbose:SpellIconTexture(spellID)
    local _, _, iconID = GetSpellInfo(tonumber(spellID))
    return Verbose:IconTextureFromID(iconID)
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
    return name == playerName or name == playerName.."-"..realmName
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
        return format("%u |4day:days;", days)
    elseif hours > 0 then
        return format("%u |4hour:hours;", hours)
    elseif minutes > 0 then
        return format("%u |4minute:minutes;", minutes)
    else
        return format("%u |4second:seconds;", seconds)
    end
end
