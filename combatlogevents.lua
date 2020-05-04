local addonName, Verbose = ...

Verbose.usedCombatLogEvents = {
    -- EVENT = {
    --     callback,  -- Function to call
    --     category,  -- Used for grouping events
    --     title,  -- Display name
    --     icon,  -- Icon ID
    --     inClassic,  -- Exists in WoW Classic
    -- },

    COMBAT_LOG_EVENT_UNFILTERED = { callback="CombatLog", category="combat", title="Combat log", icon=icon, classic=true },
}

function Verbose:CombatLog(event)
    local eventInfo = { CombatLogGetCurrentEventInfo() }

    local p = {}

    -- The 11 first parameters are common to all events
    p.timestamp, p.subevent, p.hideCaster, p.sourceGUID, p.sourceName, p.sourceFlags, p.sourceRaidFlags, p.destGUID, p.destName, p.destFlags, p.destRaidFlags = unpack(eventInfo)

    -- Return early if the player is not involved in the event
    -- TODO: What about the pet(s) ?
    if not (Verbose:NameIsPlayer(p.sourceName) or Verbose:NameIsPlayer(p.destName)) then return end

    -- The rest ot the paramters depends on the subevent and will be managed in subfunctions
    p.args = { unpack(eventInfo, 12) }

    self:EventDbgPrint(event, p.timestamp, p.subevent, p.hideCaster, p.sourceGUID, p.sourceName, p.sourceFlags, p.sourceRaidFlags, p.destGUID, p.destName, p.destFlags, p.destRaidFlags)

    self:EventDbgPrint(#eventArgs, p.args)
    self:EventDbgPrint(#eventArgs, "args:", table.concat(p.args, " "))
end
