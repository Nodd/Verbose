local addonName, Verbose = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- Lua functions
local pairs = pairs
local tonumber = tonumber
local tostring = tostring

-- Find next unused ID
function Verbose:NextUnusedListID()
    -- IDs are stringifyed ints
    local idMax = 0
    for id in pairs(self.db.profile.lists) do
        local num = tonumber(id)
        if num > idMax then
            idMax = num
        end
    end
    return tostring(idMax + 1)
end

-- Create a new list from the interface
function Verbose:CreateList()
    local listID = self:NextUnusedListID()

    -- Insert in options table
    self:AddListToOptions(listID)

    -- Select new list
    self:SelectOption("lists", listID)
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
                name = L["List name"],
                order = 10,
                pattern = "^%w+$",
                usage = "Only alphanumeric characters allowed",
                get = function(info)
                    return self.db.profile.lists[info[#info - 1]].name
                end,
                set = function(info, value)
                    self.db.profile.lists[info[#info - 1]].name = value
                    self.options.args.lists.args[info[#info - 1]].name = value
                    self:UpdateOptionsGUI()
                end,
            },
            delete = {
                type = "execute",
                name = L["Delete this list"],
                order = 20,
                func = function(info)
                    self.db.profile.lists[info[#info - 1]] = nil
                    self.options.args.lists.args[info[#info - 1]] = nil
                    self:UpdateOptionsGUI()
                end,
            },
            list = {
                type = "input",
                name = L["List elements, one per line"],
                order = 30,
                multiline = Verbose.multilineHeightNoTab,  -- Shows the "Accept" button in the bottom with default windows height
                width = "full",
                pattern = "^[^<>]+$",
                usage = "No '<' nor '>' allowed",
                get = function(info)
                    return self:TableToText(self.db.profile.lists[info[#info - 1]].values)
                end,
                set = function(info, value)
                    local dbValues = self.db.profile.lists[info[#info - 1]].values
                    self:TextToTable(value, dbValues)
                end,
            },
        },
    }
    self:UpdateOptionsGUI()
end

-- Load saved lists to options table
function Verbose:ListDBToOptions()
    for listID in pairs(self.db.profile.lists) do
        self:AddListToOptions(listID)
    end
end
