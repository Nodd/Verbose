local addonName, Verbose = ...

LibStub("AceAddon-3.0"):NewAddon(Verbose, addonName, "AceConsole-3.0", "AceEvent-3.0")
local LibDataBroker = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")

local VerboseIconID = 2056011  -- ui_chat

function Verbose:OnInitialize()
  -- Code that you want to run when the addon is first loaded goes here.

    self:ManageOptions()

    self:SetupMinimapButton()

    -- Manage enabled state
    self:SetEnabledState(self.db.profile.enabled)
    if not self.db.profile.enabled then
        Verbose:OnDisable()
    end
end

function Verbose:OnEnable()
    -- Called when the addon is enabled
    self.db.profile.enabled = true
    self:RegisterEvents()
    self.LDB.iconR = 0
    self.LDB.iconG = 1
end

function Verbose:OnDisable()
    -- Called when the addon is disabled
    self.db.profile.enabled = false
    --self:UnregisterEvents()
    self:UnregisterAllEvents()
    self.LDB.iconR = 1
    self.LDB.iconG = 0
end

function Verbose:SetupMinimapButton()
    self.LDB = LibDataBroker:NewDataObject(addonName, {
        type = "data source",
        text = addonName,
        icon = VerboseIconID,
        OnClick = function(...) self:OnLDBClick(...) end,
        OnTooltipShow = function(...) self:OnLDBTooltip(...) end,
    })
    LibDBIcon:Register(addonName, self.LDB, self.db.profile.minimap)
end

function Verbose:OnLDBClick(_, button)
    if button == "LeftButton" then
        if self.db.profile.enabled then
            Verbose:OnDisable()
        else
            Verbose:OnEnable()
        end
    elseif button == "MiddleButton" then
        self:ToggleOptions()
        self:SelectOption("events")
    elseif button == "RightButton" then
        self:ToggleOptions()
    end
end

function Verbose:OnLDBTooltip(tooltip)
    tooltip:SetText(self:IconTextureBorderlessFromID(VerboseIconID) .. " " .. addonName)
    tooltip:AddLine("Left clic: Enable/Disable", 1, 1, 1)
    tooltip:AddLine("Right clic: Toggle options window", 1, 1, 1)
    tooltip:AddLine("Middle clic: Go to events configuration", 1, 1, 1)
    tooltip:Show()
end
