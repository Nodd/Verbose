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
    -- Text in white like in tooltips
    return "|cFFFFFFFF" .. name .. "|r"
end

function Verbose:SpellNameAndIconID(spellID)
    local name, _, iconID = GetSpellInfo(tonumber(spellID))
    -- Text in white like in tooltips
    return "|cFFFFFFFF" .. name .. "|r", iconID
end

function Verbose:SpellNameAndIconTexture(spellID)
    local name, _, iconID = GetSpellInfo(tonumber(spellID))
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
    -- Text in yellowish like in tooltips
    return NORMAL_FONT_COLOR_CODE .. GetSpellDescription(tonumber(spellID)) .. FONT_COLOR_CODE_CLOSE
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
