local addonName, Verbose = ...


function Verbose:SpeakDbgPrint(...)
    if self.db.profile.speakDebug then
        self:Print("(Speak)", ...)
    end
end

function Verbose:GetRandomFromTable(t)
    if not t then return end

    local len = #t
    if len < 1 then return end

    local n = fastrandom(1, len);
    return t[n]
end

function Verbose:ListSubstitution(message)
    -- Replace from list randomly
    for listID, list in pairs(self.db.profile.lists) do
        local listStr = "<" .. list.name .. ">"
        local n
        repeat
            local element = self:GetRandomFromTable(list.values)
            message, n = message:gsub(listStr, element, 1)
        until(n == 0)
    end
    return message
end

function Verbose:TokenSubstitution(message, substitutions)
    if not substitutions then return message end
    -- Replace from list randomly
    for token, value in pairs(substitutions) do
        local tokenStr = "@" .. token .. "@"
        message = message:gsub(tokenStr, value)
    end
    return message
end

function Verbose:Speak(event, msgData, substitutions)
    self:SpeakDbgPrint("Event", event)

    -- Check arg
    if not msgData then
        self:SpeakDbgPrint("No message data")
        return
    end

    -- Check enabled
    if not self.db.profile.enabled then
        self:SpeakDbgPrint("Addon disabled")
        return
    end
    if not msgData.enabled then
        self:SpeakDbgPrint("Event disabled")
        return
    end

    -- Check global cooldown
    local currentTime = GetTime()
    local lastTime = self.db.profile.lastTime or 0
    local elapsed = currentTime - lastTime
    if elapsed < self.db.profile.cooldown then
        self:SpeakDbgPrint("Event on global CD:", elapsed, "<", self.db.profile.cooldown)
        return
    end

    -- Check event cooldown
    lastTime = msgData.lastTime or 0
    elapsed = currentTime - lastTime
    if elapsed < msgData.cooldown then
        self:SpeakDbgPrint("Event on local CD:", elapsed, "<", self.db.profile.cooldown)
        return
    end

    -- Check probability
    local rand = fastrandom(100)
    if rand > msgData.proba * 100 then
        self:SpeakDbgPrint("Probability check fail:", rand, ">", msgData.proba * 100)
        return
    end

    -- Get a random message !
    local message = self:GetRandomFromTable(msgData.messages)
    if not message then
        self:SpeakDbgPrint("No message in table")
        return
    end

    -- Sutbtistute special tokens
    message = Verbose:ListSubstitution(message)
    message = Verbose:TokenSubstitution(message, substitutions)

    -- Update times
    msgData.lastTime = currentTime  -- Event CD
    self.db.profile.lastTime = currentTime  -- Global CD

    local inInstance = IsInInstance()
    if inInstance then
        -- SendChatMessage("msg", "chatType", "language", "channel");
        SendChatMessage(message, "SAY");
    else
        self:SpeakDbgPrint("NOT IN INSTANCE, emoting instead :(")
        SendChatMessage("dit : " .. message, "EMOTE")
    end
end
