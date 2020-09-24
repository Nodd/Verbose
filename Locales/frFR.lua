local addonName, Verbose = ...

local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "frFR", false, true)

if not L then
    return
end

--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="english")@

local H = LibStub("AceLocale-3.0"):NewLocale(addonName.."Help", "frFR", false, true)

--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="english", namespace="help", table-name="H")@
