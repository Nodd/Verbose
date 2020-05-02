local addonName, Verbose = ...

local blacklist = {
    836: "LOGINEFFECT",
}

function Verbose:RegisterEvents()
	self:RegisterEvent("UNIT_SPELLCAST_SENT", "OnUnitSpellcastSent")
	self:RegisterEvent("UNIT_SPELLCAST_START", "OnUnitSpellcastCommon")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "OnUnitSpellcastCommon")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnUnitSpellcastEnd")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "OnUnitSpellcastEnd")
	self:RegisterEvent("UNIT_SPELLCAST_STOP", "OnUnitSpellcastEnd")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "OnUnitSpellcastEnd")
end

local targetTable = {}

-- For UNIT_SPELLCAST_SENT only, used to retrieve the spell target
function Verbose:OnUnitSpellcastSent(event, caster, target, castID, spellID)
    -- Store target for later use
    -- The other spell events don't provide the target :(
    targetTable[castID] = target
end

function Verbose:OnUnitSpellcastCommon(event, caster, castID, spellID)
    -- Ignore blacklisted spells
    if blacklist[spellID] ~= nil then return end
    local target = targetTable[castID]
    self:OnSpellcastEvent(event, caster, target, spellID)
end

function Verbose:OnUnitSpellcastEnd(event, caster, castID, spellID)
    self:OnUnitSpellcastCommon(event, caster, castID, spellID)
    -- Clean targetTable
    targetTable[castID] = nil
end

function Verbose:OnSpellcastEvent(event, caster, target, spellID)
    -- Ignore events from others
    if caster ~= "player" and caster ~= "pet" then return end

    -- Debug
    spellName = GetSpellInfo(spellID)
    print(event, caster, target, spellID, spellName)

    -- Record Spell/event
    self:RecordSpellcastEvent(spellID, event)

    -- Talk
    local msgData = self.db.profile.events.spells[spellID][event]
    self:Speak(msgData)
end

function Verbose:RecordSpellcastEvent(spellID, event)
    local spells = self.db.profile.events.spells

    -- If spell not known at all, register it
    if not spells[spellID] then
        spells[spellID] = {}
    end
    local spellData = spells[spellID]

    -- If event not known for this spell, register it
    if not spellData[event] then
        -- Store
        spellData[event] = {
            enabled = false,
            cooldown = 10,
            messages = {},
        }

        -- Update options
        self:AddEventToOptions(spellID, event)
        self:UpdateOptionsGUI()
    end
    -- Update timestamp
    spellData[event].lastRecord = GetServerTime()
end