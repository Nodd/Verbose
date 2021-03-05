local addonName, Verbose = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- GLOBALS: CreateFrame

LibStub("AceAddon-3.0"):NewAddon(Verbose, addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local AceConsole = LibStub("AceConsole-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigCmd = LibStub("AceConfigCmd-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LibDataBroker = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")

Verbose.VerboseIconID = 2056011  -- ui_chat

function Verbose:OnInitialize()
  -- Code that you want to run when the addon is first loaded goes here.

    -- Initialize dB
    self:SetupDB()

    self:RegisterChatCommand("verbose", "ChatCommand")
    self:RegisterChatCommand("verb", "ChatCommand")
    self:RegisterChatCommand("vw", "OpenWorldWorkaround")
    self:SetupMinimapButton()

    -- Create invisible button for keybind callback
    self.BindingButton = CreateFrame("BUTTON", "VerboseOpenWorldWorkaroundBindingButton")
    self.BindingButton:SetScript("OnClick", function(btn, button, down)
        self:OpenWorldWorkaround()
    end)

    self:InitBubbleFrame()
    self:UpdateBubbleFrame()

    -- Delay OnEnable call
    self:SetEnabledState(false)

    -- The next part of the initialization process needs spell infos
    self:RegisterEvent("SPELLS_CHANGED", "OnPostInitialize")
end

function Verbose:OnPostInitialize()
    self:UnregisterEvent("SPELLS_CHANGED")

    self:InitSpellbook()
    self:InitMounts()
    self:InitDamageReceived()

    -- Load DB to options
    self:DBToOptions()

    -- Register self.options
    AceConfig:RegisterOptionsTable(addonName, self.options)
    AceConfigDialog:SetDefaultSize(addonName, 800, 600)

    -- Manage enabled state
    self:SetEnabledState(self.db.profile.enabled)
    if self.db.profile.enabled then
        self:OnEnable()
    else
        self:OnDisable()
    end
end

function Verbose:OnEnable()
    -- Called when the addon is enabled
    self.db.profile.enabled = true
    self:UpdateOptionsGUI()
    self:RegisterEvents()
    self.LDB.iconR = 0
    self.LDB.iconG = 1
end

function Verbose:OnDisable()
    -- Called when the addon is disabled
    self.db.profile.enabled = false
    self:UpdateOptionsGUI()
    --self:UnregisterEvents()
    self:UnregisterAllEvents()
    self.LDB.iconR = 1
    self.LDB.iconG = 0
end

function Verbose:SetupMinimapButton()
    self.LDB = LibDataBroker:NewDataObject(addonName, {
        type = "data source",
        text = addonName,
        icon = Verbose.VerboseIconID,
        OnClick = function(...) self:OnLDBClick(...) end,
        OnTooltipShow = function(...) self:OnLDBTooltip(...) end,
    })
    LibDBIcon:Register(addonName, self.LDB, self.db.profile.minimap)
end

function Verbose:OnLDBClick(_, button)
    if button == "LeftButton" then
        if self.db.profile.enabled then
            self:OnDisable()
        else
            self:OnEnable()
        end
    elseif button == "MiddleButton" then
        self:ToggleOptions()
        self:SelectOption("events")
    elseif button == "RightButton" then
        self:ToggleOptions()
    end
end

function Verbose:OnLDBTooltip(tooltip)
    tooltip:SetText(self:IconTextureBorderlessFromID(Verbose.VerboseIconID) .. " " .. addonName)
    tooltip:AddLine(L["Left click: Enable/Disable"], 1, 1, 1)
    tooltip:AddLine(L["Right click: Toggle options window"], 1, 1, 1)
    tooltip:AddLine(L["Middle click: Go to events configuration"], 1, 1, 1)
    tooltip:Show()
end

function Verbose:ChatCommand(input)
    local arg1 = AceConsole:GetArgs(input, 1, 1)
    if not arg1 then
        self:ShowOptions()
    elseif arg1 == "openworld" then
        self:OpenWorldWorkaround()
    else
        AceConfigCmd:HandleCommand("verbose", "Verbose", input)
    end
end
