local addonName, Verbose = ...

-- GLOBALS: CreateFrame

LibStub("AceAddon-3.0"):NewAddon(Verbose, addonName, "AceConsole-3.0", "AceEvent-3.0", "AceSerializer-3.0")
local AceConsole = LibStub("AceConsole-3.0")
local AceConfigCmd = LibStub("AceConfigCmd-3.0")
local LibDataBroker = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")

Verbose.VerboseIconID = 2056011  -- ui_chat

function Verbose:OnInitialize()
  -- Code that you want to run when the addon is first loaded goes here.
    self:RegisterEvent("SPELLS_CHANGED", "OnPostInitialize")

    -- Initialize dB
    self:UpdateDefaultDB()
    self:SetupDB()

    self:RegisterChatCommand("verbose", "ChatCommand")
    self:RegisterChatCommand("verb", "ChatCommand")
    self:SetupMinimapButton()

    -- Create invisible button for keybind callback
    self.BindingButton = CreateFrame("BUTTON", "VerboseOpenWorldWorkaroundBindingButton")
    self.BindingButton:SetScript("OnClick", function(btn, button, down)
        self:OpenWorldWorkaround()
    end)

    -- Manage enabled state
    self:SetEnabledState(self.db.profile.enabled)
    if not self.db.profile.enabled then
        self:OnDisable()
    end
end

function Verbose:OnPostInitialize()
    self:UnregisterEvent("SPELLS_CHANGED")

    self:InitSpellbook()
    self:InitMounts()

    -- Load DB to options
    self:SpellDBToOptions()
    self:CombatLogSpellDBToOptions()
    self:ListDBToOptions()

    -- Populate self.options
    self:RegisterOptions()
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
    tooltip:AddLine("Left clic: Enable/Disable", 1, 1, 1)
    tooltip:AddLine("Right clic: Toggle options window", 1, 1, 1)
    tooltip:AddLine("Middle clic: Go to events configuration", 1, 1, 1)
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
