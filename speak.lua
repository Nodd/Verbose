local addonName, Verbose = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- GLOBALS: hash_EmoteTokenList,

-- Lua functions
local fastrandom = fastrandom
local ipairs = ipairs
local pairs = pairs
local tinsert = tinsert
local tostring = tostring
local tremove = tremove

-- WoW globals
local CHAT_SAY_GET = CHAT_SAY_GET
local CHAT_YELL_GET = CHAT_YELL_GET
local DoEmote = DoEmote
local GetChatTypeIndex = GetChatTypeIndex
local GetServerTime = GetServerTime
local IsInInstance = IsInInstance
local SendChatMessage = SendChatMessage
local _G = _G

-- Local variables
local globalLastTime = 0
local elapsedTimeForObsoleteMessage = 3

local sayCommands = {}
local i = 1
while _G["SLASH_SAY"..i] do
    sayCommands[_G["SLASH_SAY"..i]] = true
    i = i + 1
end
local yellCommands = {}
i = 1
while _G["SLASH_YELL"..i] do
    yellCommands[_G["SLASH_YELL"..i]] = true
    i = i + 1
end
local emoteCommands = {}
i = 1
while _G["SLASH_EMOTE"..i] do
    emoteCommands[_G["SLASH_EMOTE"..i]] = true
    i = i + 1
end
i = nil
local chatColors = {
    SAY = "FFFFFF",
    YELL = "FF3F40",
    EMOTE = "FF7E40",
}

function Verbose:SpeakDbgPrint(...)
    if self.db.profile.speakDebug then
        self:Print("|cFFFFFF00SPEAK:|r", ...)
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
    self:EventDetailsDbgPrint(substitutions)

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
    local currentTime = GetServerTime()
    local elapsed = currentTime - globalLastTime
    if elapsed < self.db.profile.cooldown then
        self:SpeakDbgPrint("Event on global CD:", elapsed, "<", self.db.profile.cooldown)
        return
    end

    -- Check event cooldown
    elapsed = currentTime - (msgData.lastTime or 0)
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

    -- Manage commands
    local chatType = "SAY"
    local emoteToken = nil
    local sendText = message
    local bubbleText = message
    if message:sub(1, 1) == "/" then
        local command = message:match("^(/[^%s]+)") or "";
        local args = message:match("^/[^%s]+%s+(.*)$") or "";
        if sayCommands[command] then  -- /say (default)
            sendText = args
            bubbleText = args
        elseif yellCommands[command] then  -- /yell
            chatType = "YELL"
            sendText = args
            bubbleText = args
        elseif emoteCommands[command] then  -- /me
            chatType = "EMOTE"
            sendText = args
        else
            emoteToken = hash_EmoteTokenList[command:upper()]
            if emoteToken then
                chatType = "EMOTE"
                sendText = args
            else
                self:SpeakDbgPrint("Unknown command: ", message)
                return
            end
        end
    end

    -- Update times
    msgData.lastTime = currentTime  -- Event CD
    globalLastTime = currentTime  -- Global CD

    self:CloseBubbleFrame()
    if self.db.profile.mute then
        self:SpeakDbgPrint("MUTED, bubbling:", message)
        self:UseBubbleFrame("|cFF"..chatColors[chatType]..bubbleText.."|r")
    elseif emoteToken then
        self:SpeakDbgPrint("EMOTE:", message)
        DoEmote(emoteToken, sendText)
    elseif chatType == "EMOTE" then
        self:SpeakDbgPrint("Emoting:", message)
        SendChatMessage(sendText, "EMOTE");
    elseif IsInInstance() then
        self:SpeakDbgPrint("In instance, speaking:", message)
        SendChatMessage(sendText, chatType);
    elseif Verbose.db.profile.selectWorkaround == "bubble" then
        -- Bubble+Keybind workaround
        tinsert(self.queue, { time=currentTime, message=message, sendText=sendText, chatType=chatType })
        self:SpeakDbgPrint("Not in instance, bubbling")
        self:UseBubbleFrame("|cFF"..chatColors[chatType]..bubbleText.."|r")
    else
        -- Emote workaround
        self:SpeakDbgPrint("Not in instance, emoting")
        local intro = CHAT_SAY_GET
        if chatType == "YELL" then
            intro = CHAT_YELL_GET
        end
        intro = intro:format("")
        SendChatMessage(intro..sendText, "EMOTE")
    end
end


-------------------------------------------------------------------------------
-- Keybind workaround for open world
-------------------------------------------------------------------------------

Verbose.queue = {}

function Verbose:OpenWorldWorkaround()
    self:SpeakDbgPrint("Keybind workaround")
    self:CloseBubbleFrame()
    if #Verbose.queue == 0 then
        self:SpeakDbgPrint("Empty queue")
        return
    end

    local currentTime = GetServerTime()
    while #Verbose.queue >= 1 do
        -- Get older message
        local messageData = tremove(Verbose.queue, 1)

        -- Check obsolete
        local elapsed = currentTime - messageData.time
        if elapsed < elapsedTimeForObsoleteMessage then
            self:SpeakDbgPrint("Talk", elapsed, "seconds later:", messageData.message)
            SendChatMessage(messageData.sendText, messageData.chatType)
            break
        else
            self:SpeakDbgPrint("Obsolete message since", elapsed, "seconds:", messageData.message)
        end
    end
end
