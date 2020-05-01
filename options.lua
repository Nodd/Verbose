local addonName, Verbose = ...
--local AceGUI = LibStub("AceGUI-3.0")

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
                spellCastStart = {
                    type = "group",
                    name = "Spell cast start",
                    order = 10,
                    args = {
                        title = {
                            type = "description",
                            name = "Spell cast start",
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
                spellCastSucceed = {
                    type = "group",
                    name = "Spell cast succeed",
                    order = 11,
                    args = {
                        title = {
                            type = "description",
                            name = "Spell cast succeed",
                            fontSize = "large",
                            order = 0,
                        },
                        info = {
                            type = "description",
                            name = "Documentation here too.",
                            fontSize = "medium",
                            order = 1,
                        },
                    },
                },
                spellCastFail = {
                    type = "group",
                    name = "Spell cast fail",
                    order = 12,
                    args = {
                        title = {
                            type = "description",
                            name = "Spell cast fail",
                            fontSize = "large",
                            order = 0,
                        },
                        info = {
                            type = "description",
                            name = "Documentation here again.",
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

        events = {
            spellCastStart
        },
        lists = {
            -- ListIDXXXX = {
            --     name = "Foo",
            --     values = { "Bar", "Baz" }
            -- },
        },
    }
}

function Verbose:AddEvent(event, name)
    local options = {
        type = "group",
        name = name,
        args = {
            header = {
                type = "description",
                name = event .. ": " .. name,
                order = 0,
                fontSize = "large",
            },
            enable = {
                type = "toggle",
                name = "Enable",
                order = 10,
                width = "full",
            },
            proba = {
                type = "range",
                name = "Message probability",
                order = 20,
                isPercent = true,
                min = 0,
                max = 1,
                bigStep = 0.05,
            },
            cooldown = {
                type = "range",
                name = "Message cooldown (s)",
                order = 30,
                min = 0,
                max = 3600,
                softMax = 60,
                bigStep = 1,
            },
            list = {
                type = "input",
                name = "Messages, one per line",
                order = 40,
                multiline = 20,
                width = "full",
            },
        },
    }

    --if type == spellCastStart then
    self.options.args.events.args.spellCastStart.args[name] = options
    AceConfigRegistry:NotifyChange(appName)
end

-- Create a new list from the interface
function Verbose:CreateList()
    -- Find next unused ID
    local idMax = 0
    for id in pairs(Verbose.db.profile.lists) do
        local num = tonumber(id:sub(7))
        if num > idMax then
            idMax = num
        end
    end
    local listID = "ListID" .. tostring(idMax + 1)

    -- Create list in db
    self.db.profile.lists[listID] = { name = "", values = {} }

    -- Insert in options table
    self:AddListToOptions(listID)

    -- Update GUI and select new list
    AceConfigRegistry:NotifyChange(appName)
    AceConfigDialog:SelectGroup(addonName, "lists", listID)
end

-- Insert list from db in options table
function Verbose:AddListToOptions(listID)
    local dbTable = self.db.profile.lists[listID]

    self.options.args.lists.args[listID] = {
        type = "group",
        name = dbTable.name,
        args = {
            name = {
                type = "input",
                name = "List name",
                order = 10,
                pattern = "^[^%s<>]+$",
                usage = "No whitespace nor '<' nor '>' allowed",
                get = function(info)
                    return Verbose.db.profile.lists[info[#info - 1]].name
                end,
                set = function(info, value)
                    Verbose.db.profile.lists[info[#info - 1]].name = value
                    self.options.args.lists.args[info[#info - 1]].name = value
                    AceConfigRegistry:NotifyChange(appName)
                end,
            },
            delete = {
                type = "execute",
                name = "Delete this list",
                order = 20,
                func = function(info)
                    Verbose.db.profile.lists[info[#info - 1]] = nil
                    self.options.args.lists.args[info[#info - 1]] = nil
                    AceConfigRegistry:NotifyChange(appName)
                end,
            },
            list = {
                type = "input",
                name = "List elements, one per line",
                order = 30,
                multiline = 18,  -- Shows the "Accept" button in the bottom with default windows height
                width = "full",
                pattern = "^[^<>]+$",
                usage = "No '<' nor '>' allowed",
                get = function(info)
                    return table.concat(Verbose.db.profile.lists[info[#info - 1]].values, "\n")
                end,
                set = function(info, value)
                    local dbValues = Verbose.db.profile.lists[info[#info - 1]].values
                    for i=0, #dbValues do dbValues[i] = nil end  -- clear table
                    for v in value:gmatch("([^\n]+)") do  -- Split on \n, skip empty lines
                        table.insert(dbValues, v)
                    end
                end,
            },
        },
    }
end

function Verbose:RegisterOptions()
    -- Test data
    self:AddEvent("type", "test1")
    self:AddEvent("type", "test2")
    self:AddEvent("type", "test3")

    -- Load saved config
    self.db = LibStub("AceDB-3.0"):New("VerboseDB", self.defaults)

    -- Add dynamic data to options
    for listID in pairs(self.db.profile.lists) do
        self:AddListToOptions(listID)
    end

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

function Verbose:DisplayOptions()
    AceConfigDialog:Open(addonName, self.optionsFrame)
end

function Verbose:ChatCommand(input)
    if not input or input:trim() == "" then
        self:DisplayOptions()
    else
        LibStub("AceConfigCmd-3.0"):HandleCommand("verbose", "Verbose", input)
    end
end
