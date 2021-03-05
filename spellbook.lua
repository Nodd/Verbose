local addonName, Verbose = ...
-- Spellcasts are managed in Verbose:OnSpellcastEvent (spellevents.lua)

-- Lua functions
local ipairs = ipairs
local tinsert = tinsert
local tonumber = tonumber
local tostring = tostring
local wipe = wipe

-- WoW globals
local FindSpellOverrideByID = FindSpellOverrideByID
local GetFlyoutInfo = GetFlyoutInfo
local GetFlyoutSlotInfo = GetFlyoutSlotInfo
local GetNumSpecializations = GetNumSpecializations
local GetNumSpellTabs = GetNumSpellTabs
local GetProfessions = GetProfessions
local GetSpecialization = GetSpecialization
local GetSpellBookItemInfo = GetSpellBookItemInfo
local GetSpellBookItemName = GetSpellBookItemName
local GetSpellTabInfo = GetSpellTabInfo
local GetTalentInfoBySpecialization = GetTalentInfoBySpecialization
local IsPassiveSpell = IsPassiveSpell
local BOOKTYPE_SPELL = BOOKTYPE_SPELL
local MAX_TALENT_TIERS = MAX_TALENT_TIERS
local NUM_TALENT_COLUMNS = NUM_TALENT_COLUMNS
local TRADE_SKILLS = TRADE_SKILLS

-- Icons
local tradeskillsIcon = 136243  -- Cog wheel

Verbose.spellbookSpells = {}
local function RegisterSpellbookSpell(spellID, order)
    spellID = tostring(spellID)
    order = tostring(order)

    -- Remember spell for future checks
    if not Verbose.spellbookSpells[spellID] then
        Verbose.spellbookSpells[spellID] = {}
    end
    tinsert(Verbose.spellbookSpells[spellID], order)

    -- Add optionsGroup
    local spellOptionsGroup = Verbose:AddSpellOptionsGroup(
        Verbose.options.args.events.args.spellbook.args[order], spellID)
end
function Verbose:InitSpellbook(event)
    local spellbookOptions = self.options.args.events.args.spellbook

    wipe(Verbose.spellbookSpells)

    local currSpec = GetSpecialization()

    -- Map talent spec order (fixed) and spellbook spell order (depends on active spec)
    local allTabs = { 1, 2 }
    for specIndex = 1, GetNumSpecializations() do
        local tabIndex
        if specIndex < currSpec then
            tabIndex = specIndex + 3
        elseif specIndex == currSpec then
            tabIndex = 3
        else
            tabIndex = specIndex + 2
        end
        tinsert(allTabs, tabIndex)
    end

    -- Scan spellbook and add spell structures
    for order, tabIndex in ipairs(allTabs) do
        local tabName, tabTexture, tabOffset, tabNumEntries, tabIsGuild, tabOffspecID = GetSpellTabInfo(tabIndex)

        spellbookOptions.args[tostring(order)] = {
            type = "group",
            name = tabName,
            icon = tabTexture,
            iconCoords = Verbose.iconCropBorders,
            order = order,
            hidden = "SpecHidden",
            args = {},
        }

        for index = tabOffset + 1, tabOffset + tabNumEntries do
            -- local spellName, spellSubName = GetSpellBookItemName(index, BOOKTYPE_SPELL)
            local skillType, spellID = GetSpellBookItemInfo(index, BOOKTYPE_SPELL)
            local isSpell = skillType == "SPELL" or skillType == "FUTURESPELL"
            if isSpell and not IsPassiveSpell(spellID) then
                RegisterSpellbookSpell(spellID, order)
                local overrideSpellID = FindSpellOverrideByID(spellID)
                if overrideSpellID ~= spellID then
                    RegisterSpellbookSpell(overrideSpellID, order)
                end
            elseif skillType == "FLYOUT" then
                local flyoutID = spellID
                local name, description, numSlots, isKnown = GetFlyoutInfo(flyoutID)
                for slot = 1, numSlots do
                    spellID = GetFlyoutSlotInfo(flyoutID, slot)
                    if not IsPassiveSpell(spellID) then
                        RegisterSpellbookSpell(spellID, order)
                    end
                end
            end
        end
    end

    -- Add all talent spells
    for spec = 1, GetNumSpecializations() do
        for tier = 1, MAX_TALENT_TIERS do
            for column = 1, NUM_TALENT_COLUMNS do
                local talentID, _, _, _, _, spellID = GetTalentInfoBySpecialization(spec, tier, column)
                if not IsPassiveSpell(spellID) then
                    local order = tostring(spec + 1)
                    RegisterSpellbookSpell(spellID, order)
                end
            end
        end
    end

    -- Add professions
    -- They are considered as tabs by the game, but Verbose processes them differently
    local order = #allTabs + 1
    wipe(allTabs)
    local prof1, prof2, archaeology, fishing, cooking = GetProfessions()
    if prof1 then tinsert(allTabs, prof1) end
    if prof2 then tinsert(allTabs, prof2) end
    if archaeology then tinsert(allTabs, archaeology) end
    if fishing then tinsert(allTabs, fishing) end
    if cooking then tinsert(allTabs, cooking) end

    spellbookOptions.args[tostring(order)] = {
        type = "group",
        name = TRADE_SKILLS,
        icon = tradeskillsIcon,
        iconCoords = Verbose.iconCropBorders,
        order = order,
        hidden = false,
        args = {},
    }

    -- Scan spellbook professions and add spell structures
    for _, tabIndex in ipairs(allTabs) do
        local tabName, tabTexture, tabOffset, tabNumEntries, tabIsGuild, tabOffspecID = GetSpellTabInfo(tabIndex)

        for index = tabOffset + 1, tabOffset + tabNumEntries do
            -- local spellName, spellSubName = GetSpellBookItemName(index, BOOKTYPE_SPELL)
            local skillType, spellID = GetSpellBookItemInfo(index, BOOKTYPE_SPELL)
            local isSpell = skillType == "SPELL" or skillType == "FUTURESPELL"
            if isSpell and not IsPassiveSpell(spellID) then
                RegisterSpellbookSpell(spellID, order)
            end
        end
    end

    self:UpdateOptionsGUI()
end

function Verbose:SpecHidden(info)
    -- Early return if not filtered
    if self.db.profile.showUnusableSpells then
        return false
    end

    -- Check that it's a class specialisation
    -- First order is the General tab, then the common spells tab
    local order = tonumber(info[#info])
    if order == 1 or order == 2 or order > GetNumSpecializations() + 2 then
        return false
    end

    -- Hide if it's not the current spec
    return order ~= GetSpecialization() + 2
end

function Verbose:AddSpellbookSpellEventToOptions(spellID, event)
    for _, groupID in ipairs(self.spellbookSpells[spellID]) do
        local spellOptionsGroup = self.options.args.events.args.spellbook.args[groupID].args[spellID]
        self:AddSpellEventOptions(spellOptionsGroup, event)
    end
end

-- Load saved events to options table
function Verbose:CheckAndAddSpellbookToOptions(spellID, event)
    if self.spellbookSpells[spellID] then
        self:AddSpellbookSpellEventToOptions(spellID, event)
        return true
    else
        return false
    end
end
