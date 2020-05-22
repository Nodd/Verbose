local addonName, Verbose = ...

Verbose.debug = false
--@debug@ Verbose.debug = true --@end-debug@

local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true, true)

--@localization(locale="enUS", format="lua_additive_table", same-key-is-true=true, handle-subnamespaces="subtable")@
