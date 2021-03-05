local addonName, Verbose = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
-- Spellcasts are managed in Verbose:OnSpellcastEvent (spellevents.lua)

-- Lua functions
local wipe = wipe
local ipairs = ipairs
local tinsert = tinsert
local tostring = tostring
local pairs = pairs

-- WoW globals
local C_MountJournal = C_MountJournal

Verbose.mountTypeString = {
    -- http://www.wowinterface.com/forums/showthread.php?p=294988#post294988
    ["230"] = "GROUND",
    ["231"] = "WATER", -- Turtles
    ["232"] = "WATER", -- Abyssal / Vashj'ir Seahorse, 450% swim speed, zone limited
    ["241"] = "GROUND",  -- AQ40
    ["242"] = "AIR",  -- Spectral gryphon, hidden, used only while dead
    ["247"] = "AIR", -- Red Flying Cloud
    ["248"] = "AIR",
    ["254"] = "WATER", -- Subdued Seahorse, 300% swim speed
    ["269"] = "GROUND", -- Azure/Crimson Water Strider
    ["284"] = "GROUND", -- Chauffeured Chopper (heritage)
    ["398"] = "AIR", -- Kua'fon's Harness
}
Verbose.mountTypeData = {
    AIR = { name=BATTLE_PET_NAME_3, icon=618976 },  -- icon_petfamily_flying
    GROUND = { name=L["Ground"], icon=618973 },  -- icon_petfamily_critter
    WATER = { name=RELIC_SLOT_TYPE_WATER, icon=618981 },  -- icon_petfamily_water
}
Verbose.mountEvents = {
    UNIT_SPELLCAST_START = { name=L["Start casting"], order=0 },
    UNIT_SPELLCAST_SUCCEEDED = { name=L["Successful casting"], order=1 },
}

-- Match numbers returned by C_MountJournal.GetMountInfoByID
local playerOppositeFaction = UnitFactionGroup("player") == "Horde" and 1 or 0

Verbose.mountSpells = {}
function Verbose:InitMounts()
    local mountIDs = C_MountJournal.GetMountIDs()
    wipe(Verbose.mountSpells)
    for _, mountID in ipairs(mountIDs) do
        local creatureName, spellID, icon, _, _, _, isFavorite, _, faction, hideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID)
        if isCollected and faction ~= playerOppositeFaction and not hideOnChar then
            local _, description, _, _, mountTypeID = C_MountJournal.GetMountInfoExtraByID(mountID)
            mountTypeID = tostring(mountTypeID)
            local category = Verbose.mountTypeString[mountTypeID]
            spellID = tostring(spellID)
            Verbose.mountSpells[spellID] = tostring(mountTypeID)

            -- Fill options table
            self:AddMountToOptions(spellID)
        end
    end
end

function Verbose:AddMountToOptions(spellID)
    local mountsOptions = self.options.args.events.args.mounts
    local categoryID = Verbose.mountSpells[spellID]

    -- Insert mount category options
    local categoryTag = Verbose.mountTypeString[categoryID]
    if not mountsOptions.args[categoryTag] then
        local mountTypeData = Verbose.mountTypeData[categoryTag]
        mountsOptions.args[categoryTag] = {
            type = "group",
            name = mountTypeData.name,
            icon = mountTypeData.icon,
            iconCoords = Verbose.iconCropBorders,
            args = {},
        }
        self:UpdateOptionsGUI()
    end

    -- Insert mount options
    local spellOptionsGroup = self:AddSpellOptionsGroup(
        mountsOptions.args[categoryTag], spellID)
    for event, eventData in pairs(Verbose.mountEvents) do
        self:AddSpellEventOptions(spellOptionsGroup, event)
    end
end

-- Load saved events to options table
function Verbose:CheckAndAddMountToOptions(spellID, event)
    if Verbose.mountSpells[spellID] then
        self:AddMountToOptions(spellID)
        return true
    else
        return false
    end
end
