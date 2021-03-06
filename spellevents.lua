local addonName, Verbose = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- Lua functions
local tostring = tostring

-- WoW globals
local GetServerTime = GetServerTime
local GetSpellInfo = GetSpellInfo

local SUBSTITUTIONS_DESCRIPTION = (
    L["Substitutions:"]
    .."\n|cFF00FF00<target>|r "..L["target of the spell"]
    .."\n|cFF00FF00<spellname>|r "..L["name of the spell you're casting"]
    .."\n|cFF00FF00<caster>|r "..L["'player' or 'pet'"]
)


Verbose.usedSpellEvents = {
    -- EVENT = {
    --     callback,  -- Function to call
    --     title,  -- Display name
    --     icon,  -- Icon ID
    --     inClassic,  -- Exists in WoW Classic
    -- },
    UNIT_SPELLCAST_START = {
        callback="OnUnitSpellcastCommon",
        name=L["Cast start"],
        desc=SUBSTITUTIONS_DESCRIPTION,
        order=5,
        classic=true },
    UNIT_SPELLCAST_CHANNEL_START = {
        callback="OnUnitSpellcastCommon",
        name=L["Channel start"],
        desc=SUBSTITUTIONS_DESCRIPTION,
        order=10,
        classic=true },
    UNIT_SPELLCAST_SUCCEEDED = {
        callback="OnUnitSpellcastEnd",
        name=L["Cast success"],
        desc=SUBSTITUTIONS_DESCRIPTION,
        order=15,
        classic=true },
    UNIT_SPELLCAST_CHANNEL_STOP = {
        callback="OnUnitSpellcastEnd",
        name=L["Channel stop"],
        desc=SUBSTITUTIONS_DESCRIPTION,
        order=20,
        classic=true },
    UNIT_SPELLCAST_FAILED = {
        callback="OnUnitSpellcastEnd",
        name=L["Cast start failed"],
        desc=SUBSTITUTIONS_DESCRIPTION,
        order=25,
        classic=true },
    UNIT_SPELLCAST_INTERRUPTED = {
        callback="OnUnitSpellcastEnd",
        name=L["Cast stopped"],
        desc=SUBSTITUTIONS_DESCRIPTION,
        order=40,
        classic=true },

    -- Not used for speeches
    UNIT_SPELLCAST_SENT = {
        callback="OnUnitSpellcastSent",
        name=nil,
        order=-100,
        classic=true },
    UNIT_SPELLCAST_STOP = {
        callback="OnUnitSpellcastStop",
        name=QUEST_SESSION_CHECK_STOP_DIALOG_CONFIRM,
        order=-99,
        classic=true },
}

-- Table to store spell targets, which are not provided for all events
local targetTable = {}

-- For UNIT_SPELLCAST_SENT only, used to retrieve the spell target
function Verbose:OnUnitSpellcastSent(event, caster, target, castID, spellID)
    -- Store target for later use
    -- The other spell events don't provide the target :(
    targetTable[castID] = target
end

function Verbose:OnUnitSpellcastCommon(event, caster, castID, spellID)
    local target = targetTable[castID]
    self:OnSpellcastEvent(event, caster, target, spellID)
end

function Verbose:OnUnitSpellcastStop(event, caster, castID, spellID)
    -- Clean targetTable
    if castID then  -- is sometimes nil
        targetTable[castID] = nil
    end
end

function Verbose:OnUnitSpellcastEnd(event, caster, castID, spellID)
    self:OnUnitSpellcastCommon(event, caster, castID, spellID)
    Verbose:OnUnitSpellcastStop(event, caster, castID, spellID)
end

function Verbose:RecordSpellcastEvent(spellID, event)
    -- If spell not known at all, register it
    local dbTable = self.db.profile.spells[spellID][event]
    dbTable.lastRecord = GetServerTime()
    dbTable.count = dbTable.count + 1

    -- Update options
    self:AddSpellToOptions(spellID, event)
end

function Verbose:OnSpellcastEvent(event, caster, target, spellID)
    -- Ignore events from others
    if caster ~= "player" and caster ~= "pet" then return end

    local spellName = self:SpellName(spellID)

    -- Ignore misc spells from the world
    if Verbose.starts_with(GetSpellInfo(spellID), "[DNT]") then
        return
    end

    spellID = tostring(spellID)

    -- Debug
    self:EventDbgPrintFormat(event, spellName, spellID, caster, target)

    -- Record Spell/event
    self:RecordSpellcastEvent(spellID, event)
    local msgData = self.db.profile.spells[spellID][event]

    -- Talk
    self:Speak(msgData, {
        caster = caster,
        target = target,
        spellname = spellName
     })
end
