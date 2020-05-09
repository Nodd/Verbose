local addonName, Verbose = ...
-- Spellcasts are managed in Verbose:OnSpellcastEvent (spellevents.lua)

Verbose.mountTypeString = {
    -- http://www.wowinterface.com/forums/showthread.php?p=294988#post294988
    ["230"] = "GROUND",
    ["231"] = "WATER", -- Turtles
    ["232"] = "WATER", -- Abyssal / Vashj'ir Seahorse, 450% swim speed, zone limited
    ["241"] = "GROUND",  -- AQ40
    ["242"] = "GHOST",  -- Spectral gryphon, hidden, used only while dead
    ["247"] = "AIR", -- Red Flying Cloud
    ["248"] = "AIR",
    ["254"] = "WATER", -- Subdued Seahorse, 300% swim speed
    ["269"] = "GROUND", -- Azure/Crimson Water Strider
    ["284"] = "GROUND", -- Chauffeured Chopper (heritage)
    ["398"] = "AIR", -- Kua'fon's Harness
}
Verbose.mountTypeData = {
    AIR = { name="Flying", icon=icon, desc=desc },
    GROUND = { name="Ground", icon=icon, desc=desc },
    WATER = { name="Water", icon=icon, desc=desc },
    GHOST = { name="Ghost", icon=icon, desc=desc },
}
Verbose.mountEvents = {
    UNIT_SPELLCAST_START = { name="Start casting", order=0 },
    UNIT_SPELLCAST_SUCCEEDED = { name="Successful casting", order=1 },
}

-- Match numbers returned by C_MountJournal.GetMountInfoByID
local playerOppositeFaction = UnitFactionGroup("player") == "Horde" and 1 or 0
Verbose.mountSpells = {}
function Verbose:InitMounts()
    local mountsDB = self.db.profile.mounts
    mountIDs = C_MountJournal.GetMountIDs()
    wipe(Verbose.mountSpells)
    for _, mountID in ipairs(mountIDs) do
        local creatureName, spellID, icon, _, _, _, isFavorite, _, faction, hideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID)
        if isCollected and faction ~= playerOppositeFaction and not hideOnChar then
            local _, description, _, _, mountTypeID = C_MountJournal.GetMountInfoExtraByID(mountID)
            mountTypeID = tostring(mountTypeID)
            local category = Verbose.mountTypeString[mountTypeID]
            spellID = tostring(spellID)
            if not mountsDB[spellID] then
                mountsDB[spellID] = {
                    UNIT_SPELLCAST_START = {
                        enabled = false,
                        cooldown = 10,
                        proba = 1,
                        messages = {},
                    },
                    UNIT_SPELLCAST_SUCCEEDED = {
                        enabled = false,
                        cooldown = 10,
                        proba = 1,
                        messages = { "/mountspecial" },
                    },
                }
            end
            Verbose.mountSpells[spellID] = {
                name=creatureName,
                icon=icon,
                desc=description,
                order=(not isFavorite) and 1 or 0,
                categoryID=tostring(mountTypeID),
            }
            Verbose:AddMountToOptions(spellID)
        end
    end
end

function Verbose:AddMountToOptions(spellID)
    local mountsOptions = self.options.args.events.args.mounts
    local mountData = Verbose.mountSpells[spellID]

    -- Insert mount category options
    local categoryTag = Verbose.mountTypeString[mountData.categoryID]
    if not mountsOptions.args[categoryTag] then
        local mountTypeData = Verbose.mountTypeData[categoryTag]
        mountsOptions.args[categoryTag] = {
            type = "group",
            name = mountTypeData.name,
            icon = mountTypeData.name,
            iconCoords = Verbose.iconCropBorders,
            desc = mountTypeData.name,
            args = {},
        }
    end
    local categoryOptions = mountsOptions.args[categoryTag]

    -- Insert mount options
    if not categoryOptions.args[spellID] then
        categoryOptions.args[spellID] = {
            type = "group",
            name = function(info) return self:SpellName(info[#info]) end,
            icon = function(info) return self:SpellIconID(info[#info]) end,
            iconCoords = Verbose.iconCropBorders,
            desc = function(info)
                return (
                    self:SpellIconTexture(info[#info])
                    .. "\n".. self:SpellDescription(info[#info]))
                    .. "\n\nSpell ID: " .. info[#info]
                end,
            childGroups = "tab",
            args = {
            },
        }

        for event, eventData in pairs(Verbose.mountEvents) do
            -- Insert event options for this mount
            categoryOptions.args[spellID].args[event] = {
                type = "group",
                name = eventData.name,
                order = eventData.order,
                args = {
                    enable = {
                        type = "toggle",
                        name = "Enable",
                        order = 10,
                        width = "full",
                        get = function(info) return self:MountEventData(info).enabled end,
                        set = function(info, value) self:MountEventData(info).enabled = value end,
                    },
                    proba = {
                        type = "range",
                        name = "Message probability",
                        order = 20,
                        isPercent = true,
                        min = 0,
                        max = 1,
                        bigStep = 0.05,
                        get = function(info) return self:MountEventData(info).proba end,
                        set = function(info, value) self:MountEventData(info).proba = value end,
                    },
                    cooldown = {
                        type = "range",
                        name = "Message cooldown (s)",
                        order = 30,
                        min = 1,
                        max = 3600,
                        softMax = 60,
                        bigStep = 1,
                        get = function(info) return self:MountEventData(info).cooldown end,
                        set = function(info, value) self:MountEventData(info).cooldown = value end,
                    },
                    list = {
                        type = "input",
                        name = "Messages, one per line",
                        order = 40,
                        multiline = Verbose.multilineHeightTab,
                        width = "full",
                        get = function(info)
                            return Verbose:TableToText(self:MountEventData(info).messages)
                        end,
                        set = function(info, value) self:TextToTable(value, self:MountEventData(info).messages) end,
                    },
                },
            }
        end
    end
end

-- Return spell and event data for callbacks from info arg
function Verbose:MountEventData(info)
    -- spellID, event
    return self.db.profile.mounts[info[#info - 2]][info[#info - 1]]
end

-- Load saved events to options table
function Verbose:MountDBToOptions()
    for spellID, spellData in pairs(self.db.profile.mounts) do
        for event in pairs(spellData) do
            self:AddMountToOptions(spellID, event)
        end
    end
end
