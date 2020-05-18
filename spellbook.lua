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

    local currSpec = GetSpecialization()

    -- Map talent spec order (fixed) and spellbook spell order (depends on active spec)
    local allTabs = { 1 }
    for specIndex = 1, GetNumSpecializations() do
        local tabIndex
        if specIndex < currSpec then
            tabIndex = specIndex + 2
        elseif specIndex == currSpec then
            tabIndex = 2
        else
            tabIndex = specIndex + 1
        end
        tinsert(allTabs, tabIndex)
    end

    -- Add professions
    local prof1, prof2, archaeology, fishing, cooking = GetProfessions()
    if prof1 then tinsert(allTabs, prof1) end
    if prof2 then tinsert(allTabs, prof2) end
    if archaeology then tinsert(allTabs, archaeology) end
    if fishing then tinsert(allTabs, fishing) end
    if cooking then tinsert(allTabs, cooking) end

    -- Scan spellbook and add spell structures
    for order, tabIndex in ipairs(allTabs) do
        local tabName, tabTexture, tabOffset, tabNumEntries, tabIsGuild, tabOffspecID = GetSpellTabInfo(tabIndex)

        spellbookOptions.args[tostring(order)] = {
            type = "group",
            name = tabName,
            icon = tabTexture,
            iconCoords = Verbose.iconCropBorders,
            order = order,
            args = {},
        }
        order = tostring(order)
        local spellbookTabOptions = spellbookOptions.args[order]

        for index = tabOffset + 1, tabOffset + tabNumEntries do
            local spellName, spellSubName = GetSpellBookItemName(index, BOOKTYPE_SPELL)
            local skillType, spellID = GetSpellBookItemInfo(index, BOOKTYPE_SPELL)
            local isSpell = skillType == "SPELL" or skillType == "FUTURESPELL"
            if isSpell and not IsPassiveSpell(spellID) then
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
    -- Add all talent spells
    for spec = 1, GetNumSpecializations() do
        for tier = 1, MAX_TALENT_TIERS do
            for column = 1, NUM_TALENT_COLUMNS do
                local talentID, _, _, _, _, spellID = GetTalentInfoBySpecialization(spec, tier, column)
                if not IsPassiveSpell(spellID) then
                    spellID = tostring(spellID)
                    self:AddSpellOptionsGroup(spellbookOptions.args[tostring(spec + 1)], spellID)
                end
            end
        end
    end
    self:UpdateOptionsGUI()
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
