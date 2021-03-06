local addonName, Verbose = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
-- Spellcasts are managed in Verbose:OnSpellcastEvent (spellevents.lua)

-- Cache scanned tradeskills so it's only checked once per login
local scanned = {}

function Verbose:AddTradeskillSpellEventToOptions(spellID, event, tradeskillID)
    -- Add recipe group for tradeskill
    local recipesOptions = self.options.args.events.args.recipes
    if not recipesOptions.args[tostring(tradeskillID)] then
        recipesOptions.args[tostring(tradeskillID)] = {
            type = "group",
            name = C_TradeSkillUI.GetTradeSkillDisplayName(tradeskillID),
            icon = C_TradeSkillUI.GetTradeSkillTexture(tradeskillID),
            iconCoords = Verbose.iconCropBorders,
            --hidden = "SpecHidden",
            args = {},
        }
    end
    local tradeskillRecipeOptions = recipesOptions.args[tostring(tradeskillID)]

    -- Add optionsGroup
    spellID = tostring(spellID)
    local spellOptionsGroup = Verbose:AddSpellOptionsGroup(tradeskillRecipeOptions, spellID)
    self:AddSpellEventOptions(spellOptionsGroup, event)
end

-- Add event to options table if it matches
function Verbose:CheckAndAddTradeskillToOptions(spellID, event)
    local _, _, tradeskillID = C_TradeSkillUI.GetTradeSkillLineForRecipe(spellID)
    if tradeskillID then
        self:AddTradeskillSpellEventToOptions(spellID, event, tradeskillID)
        return true
    else
        return false
    end
end
