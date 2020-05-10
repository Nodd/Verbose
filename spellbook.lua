local addonName, Verbose = ...
-- Spellcasts are managed in Verbose:OnSpellcastEvent (spellevents.lua)

-- Lua functions
local ipairs = ipairs
local tinsert = tinsert
local tostring = tostring
local wipe = wipe

-- WoW globals
local GetNumSpellTabs = GetNumSpellTabs
local GetProfessions = GetProfessions
local GetSpellBookItemInfo = GetSpellBookItemInfo
local GetSpellBookItemName = GetSpellBookItemName
local GetSpellTabInfo = GetSpellTabInfo
local IsPassiveSpell = IsPassiveSpell
local BOOKTYPE_SPELL = BOOKTYPE_SPELL

Verbose.spellbookSpells = {}
function Verbose:InitSpellbook(event)
    local spellbookOptions = self.options.args.events.args.spellbook

    wipe(Verbose.spellbookSpells)

    local allTabs = {}
    for tabIndex = 1, GetNumSpellTabs() do
        tinsert(allTabs, tabIndex)
    end
    local prof1, prof2, archaeology, fishing, cooking = GetProfessions()
    if prof1 then tinsert(allTabs, prof1) end
    if prof2 then tinsert(allTabs, prof2) end
    if archaeology then tinsert(allTabs, archaeology) end
    if fishing then tinsert(allTabs, fishing) end
    if cooking then tinsert(allTabs, cooking) end

    -- Scan spellbook and add spell structures
    for _, tabIndex in ipairs(allTabs) do
        local tabName, tabTexture, tabOffset, tabNumEntries, tabIsGuild, tabOffspecID = GetSpellTabInfo(tabIndex)

        spellbookOptions.args[tostring(tabIndex)] = {
            type = "group",
            name = tabName,
            icon = tabTexture,
            iconCoords = Verbose.iconCropBorders,
            order = tabIndex,
            args = {},
        }
        tabIndex = tostring(tabIndex)
        local spellbookTabOptions = spellbookOptions.args[tostring(tabIndex)]

        for index = tabOffset + 1, tabOffset + tabNumEntries do
            local spellName, spellSubName = GetSpellBookItemName(index, BOOKTYPE_SPELL)
            local skillType, spellID = GetSpellBookItemInfo(index, BOOKTYPE_SPELL)
            local isPassive = IsPassiveSpell(spellID)
            local isSpell = skillType == "SPELL" or skillType == "FUTURESPELL"
            if isSpell and not isPassive then
                spellID = tostring(spellID)
                -- Remember spell for future checks
                if not Verbose.spellbookSpells[spellID] then
                    Verbose.spellbookSpells[spellID] = {}
                end
                tinsert(Verbose.spellbookSpells[spellID], tabIndex)

                -- Add optionsGroup
                local spellOptionsGroup = self:AddSpellOptionsGroup(spellbookTabOptions, spellID)
            end
        end
    end
end

function Verbose:AddSpellbookSpellEventToOptions(spellID, event)
    for _, groupID in ipairs(Verbose.spellbookSpells[spellID]) do
        local spellOptionsGroup = self.options.args.events.args.spellbook.args[groupID].args[spellID]
        self:AddSpellEventOptions(spellOptionsGroup, event)
    end
end

-- Load saved events to options table
function Verbose:CheckAndAddSpellbookToOptions(spellID, event)
    if Verbose.spellbookSpells[spellID] then
        self:AddSpellbookSpellEventToOptions(spellID, event)
        return true
    else
        return false
    end
end
