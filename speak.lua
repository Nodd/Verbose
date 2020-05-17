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
local DoEmote = DoEmote
local GetChatTypeIndex = GetChatTypeIndex
local GetServerTime = GetServerTime
local IsInInstance = IsInInstance
local SendChatMessage = SendChatMessage
local UIErrorsFrame = UIErrorsFrame

-- Local variables
local globalLastTime = 0
local elapsedTimeForObsoleteMessage = 3

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

    -- Update times
    msgData.lastTime = currentTime  -- Event CD
    globalLastTime = currentTime  -- Global CD

    if self.db.profile.mute then
        self:DisplayTempMessage(message)
        self:Print("MUTED:", message)
    else
        if message:sub(1, 1) == "/" then
            local command = message:match("^(/[^%s]+)") or "";
            local args = message:match("^/[^%s]+%s*(.*)$") or "";
            local emote = hash_EmoteTokenList[command:upper()]
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
            tinsert(self.queue, { time = currentTime, message = message })
            --self:DisplayTempMessage(message)

            -- Emote workaround
            self:UseBubbleFrame(message)
            --self:SpeakDbgPrint("Not in instance, emoting:", message)
            --SendChatMessage("dit : " .. message, "EMOTE")
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
            self:SpeakDbgPrint("Talk", elapsed, "seconds later")
            SendChatMessage(messageData.message, "SAY")
            break
        else
            self:SpeakDbgPrint("Obsolete message since", elapsed, "seconds:")
            self:SpeakDbgPrint(messageData.message)
        end
    end
end


-------------------------------------------------------------------------------
-- Bubble frame
-------------------------------------------------------------------------------

function Verbose:InitBubbleFrame()
    local bubbleFrame = CreateFrame("Frame", "VerboseBubbleFrame", UIParent)
    self.bubbleFrame = bubbleFrame

    -- Bubble frame
    bubbleFrame.borders = 24
    bubbleFrame.infoMargin = 10
    bubbleFrame.defaultWidth = 484
    bubbleFrame:SetWidth(484)
    bubbleFrame:SetHeight(125)
    bubbleFrame:SetPoint("BOTTOMRIGHT", "PlayerFrame", "TOP", -10, 0)
    bubbleFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\ChatBubble-Background.blp",
        edgeFile = "Interface\\Tooltips\\ChatBubble-Backdrop.blp",
        tile = false, edgeSize = bubbleFrame.borders,
        insets = { left = bubbleFrame.borders, right = bubbleFrame.borders, top = bubbleFrame.borders, bottom = bubbleFrame.borders }
    });

    -- Bubble tail
    -- bubbleFrame.tail = bubbleFrame:CreateTexture("VerboseBubbleFrameTailTexture")
    -- bubbleFrame.tail:SetWidth(bubbleFrame.borders)
    -- bubbleFrame.tail:SetHeight(bubbleFrame.borders)
    -- bubbleFrame.tail:SetPoint("TOPRIGHT", bubbleFrame, "BOTTOMRIGHT", -45, 5)
    -- bubbleFrame.tail:SetTexture("Interface\\Tooltips\\ChatBubble-Tail.blp")

    bubbleFrame.tail1 = self:BubbleCircle(30, 20)
    bubbleFrame.tail2 = self:BubbleCircle(18, 12)
    bubbleFrame.tail3 = self:BubbleCircle(12, 9)

    -- Bubble message string
    bubbleFrame.fontstring = bubbleFrame:CreateFontString("VerboseBubbleFrameText")
    bubbleFrame.fontstring:SetWidth(bubbleFrame:GetWidth() - 2 * bubbleFrame.borders)
    bubbleFrame.fontstring:SetPoint("CENTER", bubbleFrame, "CENTER")
    bubbleFrame.fontstring:SetFont("Fonts\\FRIZQT__.TTF", 16)
    bubbleFrame:SetHeight(bubbleFrame.fontstring:GetHeight() + 2 * bubbleFrame.borders)

    -- Bubble info string
    bubbleFrame.fontstringinfo = bubbleFrame:CreateFontString("VerboseBubbleFrameInfo")
    bubbleFrame.fontstringinfo:SetPoint("BOTTOMRIGHT", bubbleFrame, "BOTTOMRIGHT", -bubbleFrame.infoMargin, 5)
    bubbleFrame.fontstringinfo:SetFont("Fonts\\FRIZQT__.TTF", 8)
    bubbleFrame.fontstringinfo:SetTextColor(1, 0.81, 0)
    bubbleFrame.fontstringinfo:SetJustifyH("RIGHT")
    bubbleFrame.fontstringinfo:SetJustifyV("BOTTOM")

    bubbleFrame:Hide()
end

local bubblePositionData = {
    belowleft = {
        parentAnchor = "BOTTOM",
        bubbleAnchor = "TOPRIGHT",
        xOffset = -10,
        yOffset = 10,
        xTailDirection = 1,
        yTailDirection = -1,
    },
    belowright = {
        parentAnchor = "BOTTOM",
        bubbleAnchor = "TOPLEFT",
        xOffset = -72,
        yOffset = 10,
        xTailDirection = -1,
        yTailDirection = -1,
    },
    aboveleft = {
        parentAnchor = "TOP",
        bubbleAnchor = "BOTTOMRIGHT",
        xOffset = -10,
        yOffset = 0,
        xTailDirection = 1,
        yTailDirection = 1,
    },
    aboveright = {
        parentAnchor = "TOP",
        bubbleAnchor = "BOTTOMLEFT",
        xOffset = -72,
        yOffset = 0,
        xTailDirection = -1,
        yTailDirection = 1,
    },
}

function Verbose:UpdateBubbleFrame()
    local posID = self.db.profile.bubbleVertical..self.db.profile.bubbleHorizontal
    local posData = bubblePositionData[posID]
    Verbose.bubbleFrame:ClearAllPoints()
    Verbose.bubbleFrame:SetPoint(
        posData.bubbleAnchor,
        "PlayerFrame",
        posData.parentAnchor,
        posData.xOffset + self.db.profile.bubbleHorizontalOffset,
        posData.yOffset + self.db.profile.bubbleVerticalOffset)
    self:SetBubbleTailPosition(posData.bubbleAnchor, posData.xTailDirection, posData.yTailDirection)
end

function Verbose:BubbleCircle(w, h)
    local t = {}

    t.topleft = self.bubbleFrame:CreateTexture()
    t.topleft:SetWidth(w / 2)
    t.topleft:SetHeight(h / 2)
    t.topleft:SetTexture("Interface\\Tooltips\\ChatBubble-Backdrop.blp")
    t.topleft:SetTexCoord(4/8, 5/8-1/16, 0, 0.5)

    t.topright = self.bubbleFrame:CreateTexture()
    t.topright:SetWidth(w / 2)
    t.topright:SetHeight(h / 2)
    t.topright:SetTexture("Interface\\Tooltips\\ChatBubble-Backdrop.blp")
    t.topright:SetTexCoord(5/8+1/16, 6/8, 0, 0.5)

    t.bottomleft = self.bubbleFrame:CreateTexture()
    t.bottomleft:SetWidth(w / 2)
    t.bottomleft:SetHeight(h / 2)
    t.bottomleft:SetTexture("Interface\\Tooltips\\ChatBubble-Backdrop.blp")
    t.bottomleft:SetTexCoord(6/8, 7/8-1/16, 0.5, 1)

    t.bottomright = self.bubbleFrame:CreateTexture()
    t.bottomright:SetWidth(w / 2)
    t.bottomright:SetHeight(h / 2)
    t.bottomright:SetTexture("Interface\\Tooltips\\ChatBubble-Backdrop.blp")
    t.bottomright:SetTexCoord(7/8+1/16, 8/8, 0.5, 1)

    return t
end

function Verbose:SetBubbleTailPosition(ref, xDirection, yDirection)
    local x = -64 * xDirection
    local y = -2 * yDirection
    self.bubbleFrame.tail1.topleft:SetPoint("BOTTOMRIGHT", self.bubbleFrame, ref, x, y)
    self.bubbleFrame.tail1.topright:SetPoint("BOTTOMLEFT", self.bubbleFrame, ref, x, y)
    self.bubbleFrame.tail1.bottomleft:SetPoint("TOPRIGHT", self.bubbleFrame, ref, x, y)
    self.bubbleFrame.tail1.bottomright:SetPoint("TOPLEFT", self.bubbleFrame, ref, x, y)

    x = -57 * xDirection
    y = -10 * yDirection
    self.bubbleFrame.tail2.topleft:SetPoint("BOTTOMRIGHT", self.bubbleFrame, ref, x, y)
    self.bubbleFrame.tail2.topright:SetPoint("BOTTOMLEFT", self.bubbleFrame, ref, x, y)
    self.bubbleFrame.tail2.bottomleft:SetPoint("TOPRIGHT", self.bubbleFrame, ref, x, y)
    self.bubbleFrame.tail2.bottomright:SetPoint("TOPLEFT", self.bubbleFrame, ref, x, y)

    x = -49 * xDirection
    y = -15 * yDirection
    self.bubbleFrame.tail3.topleft:SetPoint("BOTTOMRIGHT", self.bubbleFrame, ref, x, y)
    self.bubbleFrame.tail3.topright:SetPoint("BOTTOMLEFT", self.bubbleFrame, ref, x, y)
    self.bubbleFrame.tail3.bottomleft:SetPoint("TOPRIGHT", self.bubbleFrame, ref, x, y)
    self.bubbleFrame.tail3.bottomright:SetPoint("TOPLEFT", self.bubbleFrame, ref, x, y)
end

function Verbose:UseBubbleFrame(text)
    local bubbleFrame = self.bubbleFrame
    local infoWidth

    -- Fill message text
    bubbleFrame.fontstring:SetWidth(bubbleFrame.defaultWidth - 2 * bubbleFrame.borders)
    bubbleFrame.fontstring:SetText(text)

    -- Update info message (the keybind can change)
    if self.db.profile.keybindOpenWorld then
        bubbleFrame.fontstringinfo:SetText(L["Press %s to speak aloud"]:format(self.db.profile.keybindOpenWorld))
        bubbleFrame.fontstringinfo:Show()
        infoWidth = bubbleFrame.fontstringinfo:GetStringWidth() + 2 * bubbleFrame.infoMargin
    else
        bubbleFrame.fontstringinfo:Hide()
        infoWidth = 0
    end

    -- Resize frame to fit text
    local textWidth = bubbleFrame.fontstring:GetStringWidth() + 2 * bubbleFrame.borders
    if textWidth < bubbleFrame.defaultWidth then
        bubbleFrame:SetWidth(max(textWidth, infoWidth))
    else
        bubbleFrame:SetWidth(bubbleFrame.defaultWidth)
    end
    bubbleFrame:SetHeight(bubbleFrame.fontstring:GetHeight() + 2 * bubbleFrame.borders)

    -- Hide bubble after a delay
    delay = text:len() / 20
    if delay < 3 then delay = 3 end
    self:CancelTimer(self.SpeakTimerID)
    bubbleFrame:Show()
    self.SpeakTimerID = self:ScheduleTimer(
        "CloseBubbleFrame",
        delay)
end

function Verbose:CloseBubbleFrame()
    self.SpeakTimerID = nil
    self.bubbleFrame:Hide()
end
