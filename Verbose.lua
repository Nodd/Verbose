local addonName, Verbose = ...

LibStub("AceAddon-3.0"):NewAddon(Verbose, addonName, "AceConsole-3.0", "AceEvent-3.0")

function Verbose:PrintLoading(filename)
	self:Print("loaded "..filename) -- used for debugging purposes
end
Verbose:PrintLoading("Verbose.lua")

function Verbose:OnInitialize()
  -- Code that you want to run when the addon is first loaded goes here.

	self:InitRuntimeData()		-- initialize self.RuntimeData.Stuff\
	self:RegisterAllEvents()	-- includes registering for ADDON_LOADED event -> OnVariablesLoaded
end

function Verbose:OnEnable()
    -- Called when the addon is enabled
    self:DebugMsg("toto")
end

function Verbose:OnDisable()
    -- Called when the addon is disabled
end

function Verbose:Talk(msg, random)
    self:Print(msg)
    --SendChatMessage("msg" ,"chatType" ,"language" ,"channel");
    SendChatMessage(msg ,"SAY" ,nil ,"channel");
end

function Verbose:OnSpeechEvent( DetectedEventStub )
	local funcname = "OnSpeechEvent"
    self:DebugMsg(funcname, "--- EVENT ---")
	self:DebugMsgDumpTable(DetectedEventStub, "DetectedEventStub")
    self:DebugMsg(funcname, "--- END ---")

    self:DebugMsg(funcname, "toto")

    if DetectedEventStub.type == "COMBAT" and DetectedEventStub.eventname == "Damage received" then
        if DetectedEventStub.school == "(Feu)" then
            self:Talk("Ca brûle !")
        else
            self:Talk("Aïe !")
        end


        --[[
		local DetectedEventStub = {
			type = "COMBAT",

			name		= L["Damage received"],
			eventname	= L["Damage received"],

			-- replace the default spellname = eventname = name logic, to provide info about the actual spell
			spellid = spellId,
			spellname = spellName,

			-- spell/ability was cast by source on dest
			caster = self:PlayerNameNoRealm(srcName),
			target = self:PlayerNameNoRealm(dstName),

			-- event-specific substitions
			damage		= amount or 0,
			overkill	= overkill or 0,
			school		= self:DamageSchoolCodeNumberToString(school), --spellSchool is the same code number
        }
        --]]
    end
end
