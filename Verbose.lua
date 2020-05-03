local addonName, Verbose = ...

LibStub("AceAddon-3.0"):NewAddon(Verbose, addonName, "AceConsole-3.0", "AceEvent-3.0")

local VerboseIconID = 2056011  -- ui_chat

function Verbose:OnInitialize()
  -- Code that you want to run when the addon is first loaded goes here.

    self:RegisterOptions()

    self.LDB = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
        type = "data source",
        text = addonName,
        icon = VerboseIconID,
        OnClick = function() self:ToggleOptions() end,
    })
    LibStub("LibDBIcon-1.0"):Register(addonName, self.LDB, self.db.profile.minimap)

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
