local addonName, Verbose = ...


function Verbose:OnSpeechEvent( DetectedEventStub )
	local funcname = "OnSpeechEvent"
    self:DebugMsg(funcname, "--- EVENT ---")
	self:DebugMsgDumpTable(DetectedEventStub, "DetectedEventStub")
    self:DebugMsg(funcname, "--- END ---")

    self:DebugMsg(funcname, "toto")

    local selected = Verbose:DispatchData( DetectedEventStub )
    self:DebugMsgDumpTable(selected, "selected")
    Verbose:Speak( selected )
end


function Verbose:DispatchData( DetectedEventStub )
    local selected, data
    -- all stubs are expected to have at least a name and type, which MUST exist
    if DetectedEventStub.type == "COMBAT" then
        data = Verbose.data[DetectedEventStub.type]
        --[[
		local DetectedEventStub = {
			type = "COMBAT",
			name		= L["Damage received"],
			eventname	= L["Damage received"],

			spellid = spellId,
			spellname = spellName,

			caster = self:PlayerNameNoRealm(srcName),
			target = self:PlayerNameNoRealm(dstName),

			damage		= amount or 0,
			overkill	= overkill or 0,
			school		=
        }
        --]]
        if data[DetectedEventStub.eventname] then
            data = data[DetectedEventStub.eventname]
            if data[DetectedEventStub.school] then
                selected = data[DetectedEventStub.school]
            else
                selected = data["other"]
            end
        end
    end
    return selected
end

function Verbose:Speak( selected )
    if not selected then return end

    local lasttime = selected.LastTime or 0
    local currenttime = GetTime()
    local elapsed = currenttime - lasttime

    if elapsed < selected.Cooldown then return end

    if selected.Frequency < 1 and math.random(100) > selected.Frequency * 100 then return end

    selected.LastTime = currenttime

    message = Verbose:GetRandomTableEntry( selected.Messages, selected.LastMsg )
    selected.LastMsg = message

    --SendChatMessage("msg" ,"chatType" ,"language" ,"channel");
    SendChatMessage(message ,"SAY" ,nil ,"channel");
end
