local addonName, Verbose = ...

-- Lua functions
local tostring = tostring

-- WoW globals
local GetServerTime = GetServerTime

Verbose.usedSpellEvents = {
    -- EVENT = {
    --     callback,  -- Function to call
    --     title,  -- Display name
    --     icon,  -- Icon ID
    --     inClassic,  -- Exists in WoW Classic
    -- },

    UNIT_SPELLCAST_SENT = { callback="OnUnitSpellcastSent", name="Sent", icon=icon, order=-100, classic=true },
    UNIT_SPELLCAST_START = { callback="OnUnitSpellcastCommon", name="Start", icon=icon, order=0, classic=true },
    UNIT_SPELLCAST_CHANNEL_START = { callback="OnUnitSpellcastCommon", name="Channel start", icon=icon, order=10, classic=true },
    UNIT_SPELLCAST_SUCCEEDED = { callback="OnUnitSpellcastEnd", name="Succeeded", icon=icon, order=20, classic=true },
    UNIT_SPELLCAST_FAILED = { callback="OnUnitSpellcastEnd", name="Failed", icon=icon, order=30, classic=true },
    UNIT_SPELLCAST_INTERRUPTED = { callback="OnUnitSpellcastEnd", name="Interrupted", icon=icon, order=40, classic=true },
    UNIT_SPELLCAST_STOP = { callback="OnUnitSpellcastEnd", name="Stop", icon=icon, order=50, classic=true },
    UNIT_SPELLCAST_CHANNEL_STOP = { callback="OnUnitSpellcastEnd", name="Channel stop", icon=icon, order=60, classic=true },
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

function Verbose:OnUnitSpellcastEnd(event, caster, castID, spellID)
    self:OnUnitSpellcastCommon(event, caster, castID, spellID)
    -- Clean targetTable
    if castID then  -- is sometimes nil
        targetTable[castID] = nil
    end
end

function Verbose:RecordSpellcastEvent(spellID, event)
    local spells = self.db.profile.spells

    -- If spell not known at all, register it
    if not spells[spellID] then
        spells[spellID] = {}
    end
    local spellData = spells[spellID]

    -- Update options
    self:AddSpellToOptions(spellID, event)
    self:UpdateOptionsGUI()  -- TODO: only for brand new spells

    -- Update timestamp
    spellData[event].lastRecord = GetServerTime()
end

function Verbose:OnSpellcastEvent(event, caster, target, spellID)
    -- Ignore events from others
    if caster ~= "player" and caster ~= "pet" then return end

    local spellName = self:SpellName(spellID)
    spellID = tostring(spellID)

    -- Debug
    self:EventDbgPrint(event, caster, target, spellID, spellName)

    -- Record Spell/event
    self:RecordSpellcastEvent(spellID, event)
    local msgData = self.db.profile.spells[spellID][event]

    -- Talk
    self:Speak(msgData, {
        caster = caster,
        target = target,
        spellName = spellName,
        icon = nil
     })
end
