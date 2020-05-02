local addonName, Verbose = ...

LibStub("AceAddon-3.0"):NewAddon(Verbose, addonName, "AceConsole-3.0", "AceEvent-3.0")

function Verbose:PrintLoading(filename)
	self:Print("loaded "..filename) -- used for debugging purposes
end
Verbose:PrintLoading("Verbose.lua")

function Verbose:OnInitialize()
  -- Code that you want to run when the addon is first loaded goes here.

    self:RegisterOptions()
    self:RegisterEvents()

    -- For debug
    self:ShowOptions()
end

function Verbose:OnEnable()
    -- Called when the addon is enabled
end

function Verbose:OnDisable()
    -- Called when the addon is disabled
end
