local addonName, Verbose = ...

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

Verbose.options = {
    name = addonName,
    handler = Verbose,
    type = "group",
    childGroups = "tab",
    args = {
        general = {
            -- General options
            type = "group",
            name = "General",
            order = 10,
            args = {
                enable = {
                    name = "Enable speeches",
                    type = "toggle",
                    order = 10,
                    get = function(info) return Verbose.db.profile.enabled end,
                    set = function(info, value) Verbose.db.profile.enabled = value end,
                },
                cooldown = {
                    name = "Global message cooldown (s)",
                    type = "range",
                    order = 20,
                    min = 0,
                    max = 3600,
                    softMax = 60,
                    bigStep = 1,
                    get = function(info) return Verbose.db.profile.cooldown end,
                    set = function(info, value) Verbose.db.profile.cooldown = value end,
                },
            },
        },
        events = {
            -- Tree of known events, and associated configuration
            type = "group",
            name = "Events",
            order = 20,
            childGroups = "tree",
            args = {
                spellcasts = {
                    type = "group",
                    name = "Spellcasts",
                    order = 10,
                    childGroups = "tree",
                    args = {
                        title = {
                            type = "description",
                            name = "Spellcasts",
                            fontSize = "large",
                            order = 0,
                        },
                        info = {
                            type = "description",
                            name = "Documentation here.",
                            fontSize = "medium",
                            order = 1,
                        },
                    },
                },
            },
        },
        lists = {
            -- Replacement lists
            type = "group",
            name = "Lists",
            order = 30,
            childGroups = "tree",
            args = {
                newList = {
                    type = "execute",
                    name = "New list",
                    func = "CreateList",
                },
            },
        },
    },
}

Verbose.defaults = {
    profile = {
        enabled = true,
        cooldown = 10,
        lastTime = 0,

        events = {
            spells = {},
            combat = {}
        },
        lists = {
            -- ListIDXXXX = {
            --     name = "Foo",
            --     values = { "Bar", "Baz" }
            -- },
        },
    }
}

function Verbose:UpdateOptionsGUI()
    -- AceConfigRegistry:NotifyChange(addonName) doesn't work here
    -- I guess it's because it's not the option values that change
    -- but that new options are created
    Verbose:HideOptions()
    Verbose:ShowOptions()
end

function Verbose:SelectOption(...)
    AceConfigDialog:SelectGroup(addonName, ...)
end

function Verbose:RegisterOptions()
    -- Load saved config
    self.db = LibStub("AceDB-3.0"):New("VerboseDB", self.defaults)

    -- Add dynamic data to options
    Verbose:EventsDBToOptions()
    Verbose:ListDBToOptions()

    -- Add profile config tab to options
    self.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    self.options.args.profiles.order = 40

    -- Register options
    LibStub("AceConfig-3.0"):RegisterOptionsTable(
        addonName,
        self.options
        --{"verbose", "verb"},  -- Commandline commands
    )
    self:RegisterChatCommand("verbose", "ChatCommand")
    self:RegisterChatCommand("verb", "ChatCommand")

    -- Initialize GUI
    self.optionsFrame = AceGUI:Create("Frame")
    self.optionsFrame:SetTitle(addonName)
    self.optionsFrame:SetStatusText("Verbose")
    self.optionsFrame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    self.optionsFrame:SetLayout("Fill")
    self.optionsFrame:Hide()
end

function Verbose:ShowOptions()
    AceConfigDialog:Open(addonName, self.optionsFrame)
end

function Verbose:HideOptions()
    AceConfigDialog:Close(addonName)
end

function Verbose:ChatCommand(input)
    if not input or input:trim() == "" then
        self:ShowOptions()
    else
        LibStub("AceConfigCmd-3.0"):HandleCommand("verbose", "Verbose", input)
    end
end
