local addonName, Verbose = ...


function Verbose:EventDbgPrint(...)
    if self.db.profile.eventDebug then
        self:Print("(Event)", ...)
    end
end

local spellBlacklist = {
    [836] = true,  -- LOGINEFFECT, fired on login
}

function Verbose:RegisterEvents()
    -- Spell casts
	self:RegisterEvent("UNIT_SPELLCAST_SENT", "OnUnitSpellcastSent")
	self:RegisterEvent("UNIT_SPELLCAST_START", "OnUnitSpellcastCommon")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "OnUnitSpellcastCommon")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnUnitSpellcastEnd")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "OnUnitSpellcastEnd")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "OnUnitSpellcastEnd")
	self:RegisterEvent("UNIT_SPELLCAST_STOP", "OnUnitSpellcastEnd")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "OnUnitSpellcastEnd")

    -- Death events
	self:RegisterEvent("PLAYER_DEAD", "ManageNoArgEvent")
	self:RegisterEvent("PLAYER_ALIVE", "ManageNoArgEvent")
	self:RegisterEvent("PLAYER_UNGHOST", "ManageNoArgEvent")  -- From ghost to alive
    self:RegisterEvent("RESURRECT_REQUEST", "DUMMYEvent")

    -- Combat events
	-- self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "DUMMYEvent")
	-- self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", "DUMMYEvent") --not in Classic
    -- self:RegisterEvent("COMPANION_UPDATE", "DUMMYEvent") --not in Classic
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "ManageNoArgEvent")  -- Entering combat
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "ManageNoArgEvent")  -- Leaving combat

	-- Chat events
	-- self:RegisterEvent("CHAT_MSG_WHISPER", "DUMMYEvent")
	-- self:RegisterEvent("CHAT_MSG_BN_WHISPER", "DUMMYEvent")
	-- self:RegisterEvent("CHAT_MSG_GUILD", "DUMMYEvent")
	-- self:RegisterEvent("CHAT_MSG_PARTY", "DUMMYEvent")

	-- Events from interactions between players
	-- self:RegisterEvent("AUTOFOLLOW_BEGIN", "DUMMYEvent")  -- /follow
	-- self:RegisterEvent("AUTOFOLLOW_END", "DUMMYEvent")  -- /follow
	-- self:RegisterEvent("TRADE_SHOW", "DUMMYEvent")  -- Trade between players
	-- self:RegisterEvent("TRADE_CLOSED", "DUMMYEvent")  -- Trade between players

	-- Achievement events
	self:RegisterEvent("PLAYER_LEVEL_UP", "DUMMYEvent")
	self:RegisterEvent("ACHIEVEMENT_EARNED", "DUMMYEvent") --not in Classic
	-- self:RegisterEvent("CHAT_MSG_ACHIEVEMENT", "DUMMYEvent") --not in Classic
	-- self:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT", "DUMMYEvent") --not in Classic

	-- NPC interaction events
    -- *_CLOSED events are unreliable and can fire anytime,
    -- when speaking to another NPC for example.
    -- It would need some heavy filtering :/
	self:RegisterEvent("GOSSIP_SHOW", "ManageNoArgEvent")
	self:RegisterEvent("BARBER_SHOP_OPEN", "ManageNoArgEvent") --not in Classic
	self:RegisterEvent("BARBER_SHOP_CLOSE", "ManageNoArgEvent") --not in Classic
	self:RegisterEvent("MAIL_SHOW", "ManageNoArgEvent")
	self:RegisterEvent("MERCHANT_SHOW", "ManageNoArgEvent")
	self:RegisterEvent("QUEST_GREETING", "ManageNoArgEvent")
	self:RegisterEvent("QUEST_FINISHED", "ManageNoArgEvent")
	self:RegisterEvent("TAXIMAP_OPENED", "DUMMYEvent")
	self:RegisterEvent("TRAINER_SHOW", "ManageNoArgEvent")
end


-------------------------------------------------------------------------------
-- Spellcast Events
-------------------------------------------------------------------------------
local targetTable = {}

-- For UNIT_SPELLCAST_SENT only, used to retrieve the spell target
function Verbose:OnUnitSpellcastSent(event, caster, target, castID, spellID)
    -- Store target for later use
    -- The other spell events don't provide the target :(
    targetTable[castID] = target
end

function Verbose:OnUnitSpellcastCommon(event, caster, castID, spellID)
    -- Ignore blacklisted spells
    if spellBlacklist[spellID] then return end
    local target = targetTable[castID]
    self:OnSpellcastEvent(event, caster, target, spellID)
end

function Verbose:OnUnitSpellcastEnd(event, caster, castID, spellID)
    self:OnUnitSpellcastCommon(event, caster, castID, spellID)
    -- Clean targetTable
    targetTable[castID] = nil
end

function Verbose:RecordSpellcastEvent(spellID, event)
    local spells = self.db.profile.spells

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
        self:AddSpellToOptions(spellID, event)
        self:UpdateOptionsGUI()
    end
    -- Update timestamp
    spellData[event].lastRecord = GetServerTime()
end

function Verbose:OnSpellcastEvent(event, caster, target, spellID)
    -- Ignore events from others
    if caster ~= "player" and caster ~= "pet" then return end

    spellName, iconTexture = self:SpellNameAndIconTexture(spellID)

    -- Debug
    self:EventDbgPrint(event, caster, target, spellID, spellName)

    -- Record Spell/event
    self:RecordSpellcastEvent(spellID, event)

    -- Talk
    local msgData = self.db.profile.spells[spellID][event]
    self:Speak(event, msgData, {
        caster = caster,
        target = target,
        spellname = spellname,
        icon = nil
     })
end


-------------------------------------------------------------------------------
-- Events with no parameters
-------------------------------------------------------------------------------
function Verbose:ManageNoArgEvent(event, ...)
    -- DEBUG
    self:EventDbgPrint(event, "(NOARG)")
    if ... then
        self:EventDbgPrint("NOARG event received args:", ...)
    end

    local msgData = self.db.profile.events[event]
    self:Speak(event, msgData)
end


-------------------------------------------------------------------------------
-- Events with specific parameters
-------------------------------------------------------------------------------
function Verbose:RESURRECT_REQUEST(event, caster)
    -- DEBUG
    self:EventDbgPrint(event, caster)

    local msgData = self.db.profile.events[event]
    self:Speak(event, msgData, { caster = caster })
end


-------------------------------------------------------------------------------
-- TODOs
-------------------------------------------------------------------------------
function Verbose:DUMMYEvent(event, ...)
    -- DEBUG
    self:EventDbgPrint("DUMMY", event, ...)

    local msgData = self.db.profile.events[event]
    self:Speak(event, msgData, ...)
end
