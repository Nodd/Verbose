local addonName, Verbose = ...


function Verbose:SpeakDbgPrint(...)
    if self.db.profile.speakDebug then
        self:Print("SPEAK:", ...)
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
        local tokenStr = "<" .. token .. ">"
        message = message:gsub(tokenStr, tostring(value))
    end
    return message
end

function Verbose:GetRandomMessageWithSubstitution(messages, substitutions)
    -- Get a random message among messages where all substitutions are valid
    local message
    local filteredIndex = 1
    -- Iterator for random choice without intermediate list
    -- The final probability is uniform, yes Sir !
    for index, msg in ipairs(messages) do
        -- Replace tokens
        msg = self:TokenSubstitution(msg, substitutions)
        msg = self:ListSubstitution(msg)

        -- Check that all tokens were replaced
        local valid = true
        if msg:find("<(%w+)>") then valid = false end

        if valid then
            -- Message can be in the random pool
            if fastrandom(1, filteredIndex) == 1 then
                message = msg
            end
            filteredIndex = filteredIndex + 1
        end
    end
    return message
end

function Verbose:Speak(msgData, substitutions, messagesTable)
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
        self:SpeakDbgPrint("Speak event disabled")
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
    if not messagesTable then
        messagesTable = msgData.messages
    end
    local message = self:GetRandomMessageWithSubstitution(messagesTable, substitutions)
    if not message then
        self:SpeakDbgPrint("No valid message in table for substitutions")
        return
    end

    -- Update times
    msgData.lastTime = currentTime  -- Event CD
    self.db.profile.lastTime = currentTime  -- Global CD

    if self.db.profile.mute then
        Verbose:DisplayTempMessage(message)
        self:Print("MUTED:", message)
    else
        if message:sub(1, 1) == "/" then
            local command = strmatch(message, "^(/[^%s]+)") or "";
            local args = strmatch(message, "^/[^%s]+%s*(.*)$") or "";
            print(message, command, args)
            local emote = hash_EmoteTokenList[strupper(command)]
            if emote then
                DoEmote(emote, args)
                self:SpeakDbgPrint("EMOTE:", command, args)
                return
            else
                self:SpeakDbgPrint("EMOTE skipped, not an emote:", emote)
            end
        end
        local inInstance = IsInInstance()
        if inInstance then
            self:SpeakDbgPrint("In instance, speaking:", message)
            -- SendChatMessage("msg", "chatType", "language", "channel");
            SendChatMessage(message, "SAY");
        else
            -- Keybind workaround
            table.insert(self.queue, { time = currentTime, message = message })
            Verbose:DisplayTempMessage(message)

            -- Emote workaround
            self:SpeakDbgPrint("Not in instance, emoting:", message)
            SendChatMessage("dit : " .. message, "EMOTE")
        end
    end
end


-------------------------------------------------------------------------------
-- Keybind workaround for open world
-------------------------------------------------------------------------------

function Verbose:DisplayTempMessage(message)
    UIErrorsFrame:AddMessage(
        self:IconTextureBorderlessFromID(self.VerboseIconID).." ".. message,
        1.0, 0.8, 0.0,  -- R, G, B
        GetChatTypeIndex("CHANNEL_NOTICE"),
        5)  -- Display duration (ignored ?)
end

Verbose.queue = {}

function Verbose:OpenWorldWorkaround()
    self:SpeakDbgPrint("Keybind workaround")
    if #Verbose.queue == 0 then
        self:SpeakDbgPrint("Empty queue")
        return
    end

    local currentTime = GetTime()
    while #Verbose.queue >= 1 do
        -- Get older message
        local messageData = table.remove(Verbose.queue, 1)

        -- Check obsolete
        local elapsed = currentTime - messageData.time
        if elapsed < 5 then
            self:SpeakDbgPrint("Talk", elapsed, "seconds later")
            SendChatMessage(messageData.message, "SAY")
            break
        else
            self:SpeakDbgPrint("Obsolete message since", elapsed, "seconds:")
            self:SpeakDbgPrint(messageData.message)
        end
    end
end
