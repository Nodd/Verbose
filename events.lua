local addonName, Verbose = ...

local blacklist = {
    836: "LOGINEFFECT",
}

function Verbose:RegisterEvents()
	self:RegisterEvent("UNIT_SPELLCAST_SENT", "OnUnitSpellcastSent")
	self:RegisterEvent("UNIT_SPELLCAST_START", "OnUnitSpellcastCommon")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "OnUnitSpellcastCommon")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnUnitSpellcastCommon")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "OnUnitSpellcastCommon")
	self:RegisterEvent("UNIT_SPELLCAST_STOP", "OnUnitSpellcastCommon")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "OnUnitSpellcastCommon")
end

local targetTable = {}

function Verbose:OnUnitSpellcastSent(event, caster, target, castID, spellID)
    targetTable[castID] = target
    self:OnSpellcastEvent(event, caster, target, spellID)
end

function Verbose:OnUnitSpellcastCommon(event, caster, castID, spellID)
    -- Ignore blacklisted spells
    if blacklist[spellID] ~= nil then return end
    local target = targetTable[castID]
    self:OnSpellcastEvent(event, caster, target, spellID)
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