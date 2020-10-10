local addonName, Verbose = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- Lua functions
local max = max

-- WoW globals
local CreateFrame = CreateFrame
local UIParent = UIParent


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
    bottomleft = {
        parentAnchor = "BOTTOM",
        bubbleAnchor = "TOPRIGHT",
        xOffset = -10,
        yOffset = 10,
        xTailDirection = 1,
        yTailDirection = -1,
    },
    bottomright = {
        parentAnchor = "BOTTOM",
        bubbleAnchor = "TOPLEFT",
        xOffset = -72,
        yOffset = 10,
        xTailDirection = -1,
        yTailDirection = -1,
    },
    topleft = {
        parentAnchor = "TOP",
        bubbleAnchor = "BOTTOMRIGHT",
        xOffset = -10,
        yOffset = 0,
        xTailDirection = 1,
        yTailDirection = 1,
    },
    topright = {
        parentAnchor = "TOP",
        bubbleAnchor = "BOTTOMLEFT",
        xOffset = -72,
        yOffset = 0,
        xTailDirection = -1,
        yTailDirection = 1,
    },
}

function Verbose:UpdateBubbleFrame()
    local posID = self.db.profile.bubblePosition
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

    -- Update info message (keybind and mute can change)
    if self.db.profile.keybindOpenWorld and not self.db.profile.mute then
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
    local delay = 6
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
