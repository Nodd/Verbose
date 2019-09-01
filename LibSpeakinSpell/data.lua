-- Author      : RisM
-- Create Date : 6/28/2009 3:56:24 PM
local addonName, Verbose = ...

--local Verbose = LibStub("AceAddon-3.0"):GetAddon("Verbose")
local L = LibStub("AceLocale-3.0"):GetLocale("Verbose", false)

Verbose:PrintLoading("data.lua")

-------------------------------------------------------------------------------
-- DATA STRUCTURES (? not sure what to call this category)
-------------------------------------------------------------------------------


function Verbose:GetActiveEventTable()
	--NOTE: myrealm result from UnitName("player") is always nil
	local toon, toonrealm = UnitName("player")
	local realm = GetRealmName()

	if VerboseSavedDataForAll.AllToonsShareSpeeches then
		-- all toons share the same event table
		if not VerboseSavedDataForAll.AllToonsEventTable then
			VerboseSavedDataForAll.AllToonsEventTable = {}
		end
		return VerboseSavedDataForAll.AllToonsEventTable
	end

	-- just to be safe, make sure this table exists at each level
	if not VerboseSavedDataForAll.Toons then
		VerboseSavedDataForAll.Toons = {}
	end
	if not VerboseSavedDataForAll.Toons[realm] then
		VerboseSavedDataForAll.Toons[realm] = {}
	end
	if not VerboseSavedDataForAll.Toons[realm][toon] then
		VerboseSavedDataForAll.Toons[realm][toon] = {}
	end
	if not VerboseSavedDataForAll.Toons[realm][toon].EventTable then
		VerboseSavedDataForAll.Toons[realm][toon].EventTable = {}
	end

	-- return the active character's EventTable - this is one of the most important data structures
	return VerboseSavedDataForAll.Toons[realm][toon].EventTable
end


-------------------------------------------------------------------------------
-- INITIALIZATION / IMPORT OF DEFAULT DATA
-------------------------------------------------------------------------------


function Verbose:InitDefaultSavedData()

	-- Create/Reset the saved data per-character
	table.wipe(VerboseSavedData)
	self:ValidateObject( VerboseSavedData, Verbose.DEFAULTS.VerboseSavedData )

	-- DO NOT Create/Reset the saved data per-account
	-- but do reset this toon's settings within the saved data for all
	table.wipe( self:GetActiveEventTable() )
	self:ValidateObject( VerboseSavedDataForAll, Verbose.DEFAULTS.VerboseSavedDataForAll )

	-- set the data version
	-- the data version lives on the available patches defined in oldversions.lua
	-- so it can't be defined in the constructor templates declared in loader.lua
	VerboseSavedData.Version		= Verbose.DATA_VERSION
	VerboseSavedDataForAll.Version = Verbose.DATA_VERSION

	-- Insert defaults speeches and event settings for all suitable templates
	self:ImportDefaultStarterSpeeches()

	-- set the event hook list to the defaults, to get it started
	local DEFAULT_EVENTHOOKS = Verbose:LoadDefaultEventHooks()
	VerboseSavedDataForAll.NewEventsDetected = self:CopyTable( DEFAULT_EVENTHOOKS.NewEventsDetected )

	-- some info may be missing from the defaults out of convenience
	-- this also performs additional data-driven data construction
	-- for default global settings and other data structures
	self:ValidateAllSavedData()

end


function Verbose:InitDefaultSavedData_NewToonOnly()
	-- like above, as a first-time init only
	-- (InitDefaultSaveData is also used for /ss reset)

	-- Create/Reset the saved data for just this character
	table.wipe(VerboseSavedData)
	self:ValidateObject( VerboseSavedData, Verbose.DEFAULTS.VerboseSavedData )

	-- make sure all global shared data is up-to-date
	-- NOTE: this will still run patches on the saved data For All
	-- if the current user's saved data (assigned above) is at the current version, which it is now
	self:ValidateAllSavedData()

	-- Insert defaults speeches and event settings for all suitable templates
	-- NOTE: global "for all players" default speeches have already been reviewed/deleted/modified
	--		on other toons, presumably, if VerboseSavedDataForAll.AllToonsShareSpeeches
	--		that caveat is handled internally to the templates system - see: Template_UseAsStarterDefault
	self:ImportDefaultStarterSpeeches()
end



-------------------------------------------------------------------------------
-- DATA STRUCTURES (? not sure what to call this category)
-------------------------------------------------------------------------------

function Verbose:InitRuntimeData()
	--NOTE: VerboseSavedData either does not exist yet or is about to be reset to defaults
	--		do not reference it here

	-- declaration moved to loader.lua - just copy the default RuntimeData template/constructor here to reset the runtime state
	self.RuntimeData = self:CopyTable( self.DEFAULTS.RuntimeData )
	self:LoadActiveCompanions();
end


function Verbose:LoadActiveCompanions()
	-- the ActiveCompanions table is used by the COMPANION_UPDATE event
	self.RuntimeData.ActiveCompanions.CRITTER = self:GetActiveCompanion("CRITTER")
	self.RuntimeData.ActiveCompanions.MOUNT   = self:GetActiveCompanion("MOUNT")
end


function Verbose:DeleteSpell(key)
	-- delete the current selection from the SavedData and RuntimeData tables
	self:GetActiveEventTable()[key] = nil

	if not self.RuntimeData then
		-- we're still initializing, so the rest of this stuff doesn't matter
		return
	end

	-- remove runtime data for messaging cooldowns and limits
	self.RuntimeData.AnnouncementHistory[key] = nil

	-- restore the spell to the list of new detected
	-- so the user doesn't have to retrigger it
	-- self:RecordNewSpell(EventTableEntry.DetectedEvent)
	-- NO! could be outdated and bugged event
	-- just make the user recreate it

	self:CurrentMessagesGUI_ValidateSelectedEvent() -- make sure we still have a valid spell selection
end


function Verbose:SetFilterShowMoreThanAHundred(value)
	if VerboseSavedData.ShowMoreThanAHundred == value then
		--value is not changing
		return
	end

	VerboseSavedData.ShowMoreThanAHundred = value

	self.RuntimeData.OptionsGUIStates.MessageSettings.FilterChanged = true
	self.RuntimeData.OptionsGUIStates.CreateNew.FilterChanged = true
end


function Verbose:SetFilterShowUsedHooks(value)
	if VerboseSavedData.ShowUsedHooks == value then
		-- value is not changing
		return
	end

	VerboseSavedData.ShowUsedHooks = value
	--self.RuntimeData.OptionsGUIStates.MessageSettings.FilterChanged = true --the message settings GUI ONLY shows used hooks
	self.RuntimeData.OptionsGUIStates.CreateNew.FilterChanged = true
end


function Verbose:SetFilter(type,text)
	local rebuild = false
	if type and self.RuntimeData.OptionsGUIStates.SelectedEventTypeFilter ~= type then
		self.RuntimeData.OptionsGUIStates.SelectedEventTypeFilter = type
		rebuild = true
	end

	if text and self.RuntimeData.OptionsGUIStates.SelectedEventTextFilter ~= text then
		self.RuntimeData.OptionsGUIStates.SelectedEventTextFilter = text
		rebuild = true
	end

	if rebuild then
		self.RuntimeData.OptionsGUIStates.MessageSettings.FilterChanged = true
		self.RuntimeData.OptionsGUIStates.CreateNew.FilterChanged = true
	end
end


function Verbose:MatchesFilter(DetectedEvent)
	local funcname = "MatchesFilter"

	if not DetectedEvent then -- deleting data may have made a key invalid
		return false
	end

	-- check type filter
	local type = Verbose.RuntimeData.OptionsGUIStates.SelectedEventTypeFilter
	if type and not (type == "*ALL" or type == DetectedEvent.type) then
		--self:DebugMsg(funcname, "type failed:"..tostring(DetectedEvent.type))
		return false
	end

	-- check text filter - use lowercase for case-insensitive comparison
	local text = string.lower( Verbose.RuntimeData.OptionsGUIStates.SelectedEventTextFilter )
	--self:DebugMsg(funcname, "text:"..tostring(text))
	if text and not (text == "") then
		local name = DetectedEvent.name or DetectedEvent.eventname or DetectedEvent.spellname
		if name then
			name = string.lower(name)
		else
			name = ""
		end
		-- NOTE: hyphens cause string.find to fail to find "auto-afk" in "auto-afk"
		--		so replace all hyphens with spaces for the sake of comparison
		--		it's an issue of the LUA pattern syntax
		text = string.gsub(text,"-"," ")
		name = string.gsub(name,"-"," ")
		-- look for the text as a substring anywhere in the name
		local ndxMatch = string.find( name, text )
		if not (ndxMatch and (ndxMatch >= 0)) then
			-- the substring was not found, so this is not a match
			--self:DebugMsg(funcname, string.format("text \"%s\" failed on name \"%s\"",text,name))
			return false
		end
		-- else, the name is a match
	end

	-- we matched all the filters, if any
	--self:DebugMsg(funcname, "pass key:"..tostring(DetectedEvent.key))
	return true
end


function Verbose:ColorFilterText( DisplayName, BaseColor )
	-- do a case insensitive match to color-code
	local filter = string.lower( Verbose.RuntimeData.OptionsGUIStates.SelectedEventTextFilter )
	if filter and filter ~= "" then
		local name = string.lower( DisplayName )
		local ndx = string.find( name, filter )
		if ndx == nil then
			return (BaseColor)..tostring(DisplayName)
		end

		-- split up the string
		local Start = string.sub( DisplayName, 1, ndx - 1 )
		local Match = string.sub( DisplayName,    ndx, ndx + string.len(filter) - 1 )
		local Rest  = string.sub( DisplayName,         ndx + string.len(filter) )

		-- put it back together again
		return tostring(BaseColor)..tostring(Start)..tostring(VerboseSavedData.Colors.SearchMatch)..tostring(Match)..tostring(BaseColor)..tostring(Rest)
	end
	-- else no search in effect
	return DisplayName
end


-- RecordNewEvent creates and maintains a list of new spells that don't have messages associated with them
-- this list is used to present the user with a list of options when she wants to start announcing a new spell
function Verbose:RecordNewEvent(de)
	local funcname = "RecordNewEvent"

	-- got a bug report that this table was nil
	-- that should never occur because of other safety checks, but be safe here anyway
	if not VerboseSavedDataForAll.NewEventsDetected then
		VerboseSavedDataForAll.NewEventsDetected = {}
	end

	-- if we already recorded this spell, don't add a duplicate
	if VerboseSavedDataForAll.NewEventsDetected[de.key] then
		return
	end

	-- record the new event
	self:DebugMsg(funcname, self:FormatSubs("Found New Event <key>: <SpellLink>", de) )
	VerboseSavedDataForAll.NewEventsDetected[de.key] = { -- only copy necessary identifying info
		type = de.type,
		name = de.name,
		key = de.key,
	}

	-- update the options GUI to include the new event in the dropdown list
	if self.IsGUILoaded then -- LoD GUI might not be loaded, in which case this is unnecessary
		self:GUI_CreateNew_OnNewEventDetected(de)
	end
end


-- NOTE: GetSpellLink on a name will throw a LUA error on invalid names
--		which is why we had to switch over to spell ids
function Verbose:SafeGetSpellLink(de)
	-- NOTE: spellid may be either zero or nil if this event is not a spell with an id
	-- NOTE: use spellname for the unclickable links formatted here, which can be subtly different than name/eventname

	if not de.spellid then
		if de.type == "MACRO" then
			return tostring(de.name)
		else
			return "["..tostring(de.spellname).."]"
		end
	end

	local SpellLink = GetSpellLink( de.spellid )
	if SpellLink then
		return SpellLink
	else
		return "["..tostring(de.spellname).."]"
	end
end


function Verbose:CreateDetectedEvent( DetectedEventStub )
	local funcname = "CreateDetectedEvent"

	local de = self:CopyTable(DetectedEventStub)

	if not de.caster then
		--NOTE: myrealm result from UnitName("player") is always nil
		local myname, myrealm = UnitName("player")
		de.caster = myname
	end

	-- validate the target - get a backup target from selection, focus, or assumed self-cast
	if not de.target or de.target == "" or de.target == "Unknown" then
		de.target = self:GetDefaultTarget(true)
	end

	-- fill in any other missing defaults or auto-generated properties
	self:Validate_DetectedEvent( de )

	return de
end


-------------------------------------------------------------------------------
-- CHECK OPTIONS IF SPEAKING IS ALLOWED
-------------------------------------------------------------------------------


function Verbose:SaveInRecentList( de, msg )
	-- save in recent list
	if msg then
		-- save in Speeches

		-- make sure this speech is not already in the history list
		for i=1,Verbose.MAX.RECENT_HISTORY,1 do
			local item = self.RuntimeData.Recent.Speeches[i]
			if item and item.msg == msg then
				return
			end
		end
		-- make room in slot 1
		for i=Verbose.MAX.RECENT_HISTORY,2,-1 do
			self.RuntimeData.Recent.Speeches[i] = self.RuntimeData.Recent.Speeches[i-1]
		end
		-- save in slot 1
		self.RuntimeData.Recent.Speeches[1] = {
			de = de,
			msg = msg,
		}
	else
		-- save in Events
		-- make sure this speech is not already in the history list
		for i=1,Verbose.MAX.RECENT_HISTORY,1 do
			local item = self.RuntimeData.Recent.Events[i]
			if item and item.key == de.key then
				return
			end
		end
		-- make room in slot 1
		for i=Verbose.MAX.RECENT_HISTORY,2,-1 do
			self.RuntimeData.Recent.Events[i] = self.RuntimeData.Recent.Events[i-1]
		end
		-- save in slot 1
		self.RuntimeData.Recent.Events[1] = de
	end
end


function Verbose:SaveAnnouncementHistory( de, msg )
	-- record info about the last time we announced this event (which should be right now)
	self.RuntimeData.AnnouncementHistory[de.key] = {
		LastMessage = msg,
		LastTime	= GetTime(),
		LastTarget	= de.target,
	}
	self.RuntimeData.AnnouncedThisCombat[de.key] = true
	self:SaveInRecentList(de,msg)
	self.RuntimeData.GlobalCooldownTime = GetTime() --easier than searching or sorting the AnnouncementHistory table
end


function Verbose:GetLastMessage( de )
	local History = self.RuntimeData.AnnouncementHistory[de.key]
	if History then
		return History.LastMessage
	else
		return nil
	end
end


function Verbose:CheckSpellFrequency( de )
	-- check the frequency setting against a random number to determine if we should speak or not
	local Chance = math.random(1,100)
	local Frequency = de.EventTableEntry.Frequency*100

	if Chance > Frequency then
		de.chance = Chance
		de.frequency = Frequency
		--self:DebugMsg( "CheckSpellFrequency", self:FormatSubs("random chance failed for <SpellLink> rolled <Chance> > <Frequency>", de) )
		self:ShowWhyNot( de, L["the random chance failed (<frequency>%)"] )
		return false
	end

	return true
end


function Verbose:CheckSpellCooldown( de )
	local funcname = "CheckSpellCooldown"

	-- check for a cooldown limit on announcing this spell

	local History = self.RuntimeData.AnnouncementHistory[de.key]
	if not History then
		-- we have not yet announced this spell, so it can't be on cooldown
		return true
	end

	-- calculate elapsed time since last announcement
	-- NOTE: History.LastTime is guaranteed to be a valid value, or we would have aborted above
	local elapsed = GetTime() - History.LastTime

	-- Now finally actually check if the cooldown is in effect
	-- NOTE: "no cooldown" is set by Cooldown=0, so elapsed < 0 will not occur
	if elapsed < de.EventTableEntry.Cooldown then
		-- the cooldown is in effect, so be silent
		de.elapsed = string.format("%d",elapsed) --round off
		de.cd = string.format("%d",de.EventTableEntry.Cooldown)--round off
		de.remaining = string.format("%d",de.EventTableEntry.Cooldown - elapsed)--round off
		--self:DebugMsg( funcname, self:FormatSubs("messaging on cooldown <SpellLink> elapsed:<elapsed>, CD:<cd>", de) )
		self:ShowWhyNot( de, L["this event trigger's cooldown is in effect (<remaining>/<cd> seconds remaining)"] )
		return false
	end

	return true
end


function Verbose:CheckGlobalCooldown()
	local funcname = "CheckGlobalCooldown"

	if self.RuntimeData.RecursiveCall then
		-- If one event fires /ss macro as a shared speech list
		-- the /ss macro event should not be silenced by the global cooldown
		-- to the end-user, it's one event
		return true --allow
	end

	if not VerboseSavedData.GlobalCooldown then -- 0 or nil
		return true --cooldown disabled, always allow
	end

	if nil == self.RuntimeData.GlobalCooldownTime then --lets assume 0 is a valid time, even though it probably isn't
		-- nothing has been spoken yet, so we can't be on cooldown
		return true --allowed to speak
	end

	local elapsed = GetTime() - self.RuntimeData.GlobalCooldownTime
	if elapsed < VerboseSavedData.GlobalCooldown then
		self:DebugMsg( funcname, "global cooldown is in effect" )
		return false --we're still on cooldown, not allowed to speak
	end

	-- cooldown has elapsed
	return true
end


function Verbose:CheckOncePerTarget( de )
	local funcname = "CheckOncePerTarget"

	if not de.EventTableEntry.OncePerTarget then
		-- "limit once per target" is disabled, so we can always speak
		return true
	end

	local History = self.RuntimeData.AnnouncementHistory[de.key]
	if not History then
		-- we haven't announced this event yet at all, so we can't have announced it for this target
		return true
	end

	-- check the last target that was used
	if de.target == History.LastTarget then
		return false
	end

	-- we have a new target this time, so we can speak
	return true
end


function Verbose:CheckOncePerCombat( de )
	local funcname = "CheckOncePerCombat"

	if not de.EventTableEntry.OncePerCombat then
		-- "limit once per combat" is disabled, so we can always speak
		return true
	end

	local History = self.RuntimeData.AnnouncementHistory[de.key]
	if not History then
		-- we haven't announced this event yet at all, so we can't have announced it for this target
		return true
	end

--	if not self.RuntimeData.InCombat then
--		-- we're not in combat, so this option should not apply
--		self:DebugMsg( funcname, "Limit once per combat no has no effect because you are not in combat" )
--		return true
--	end

	-- AnnouncedThisCombat is reset upon both entering and exiting combat
	if self.RuntimeData.AnnouncedThisCombat[de.key] then
		self:DebugMsg( funcname, "Limit once per combat is in effect for this event key="..tostring(de.key) )
		return false
	end

	-- it's a new combat, so go ahead and announce
	return true
end


function Verbose:ResetOncePerCombatFlags()
	-- forget all the once-per-combat memory
	-- NOTE: this is easier if we track it as a separate table
	--		rather than add data to self.RuntimeData.AnnouncementHistory
	self.RuntimeData.AnnouncedThisCombat = {}

	-- NOTE: don't reset last target info when changing combat sessions
	-- because we want "limit once per target" to apply to targets to the same name in multiple pulls
end


function Verbose:ShowWhyNot( de, reason, func )
	local funcname = "ShowWhyNot"

	if not VerboseSavedData.ShowWhyNot then
		return
	end

	-- this is the complete message format we're going for
	local MessageFormat = L["Announcement of \"<displaylink>\" was silenced because <reason>. <clickhere> to change this setting."]
	local subber = self:CopyTable(de) --so we don't modify the DetectedEvent object
	subber.reason = self:FormatSubs( reason, de ) --provided by caller

	-- make the [Click Here] link
	if not func then -- assume this is an event-specific option and offer to open the settings for this event
		func = string.format("Verbose:OnClickEditEvent(\"%s\")", de.key)
	end
	subber.clickhere = self:MakeClickHereLink( L["[Click Here]"], func )

	-- print it
	self:Print( self:FormatSubs( MessageFormat, subber ) )
end


function Verbose:AllowSpeakForSpell( de )
	local funcname = "AllowSpeakForSpell"

	if de.EventTableEntry.DisableAnnouncements then
		self:ShowWhyNot( de, L["this event trigger is disabled"] )
		return false
	end

	-- NOTE: even if EnableAllMessages is false, if this is a user macro "/ss macro something" then allow it anyway
	if not VerboseSavedData.EnableAllMessages and de.type ~= "MACRO" then
		self:ShowWhyNot( de, L["all automated Verbose announcements are disabled (except for /ss macro events)"], "Verbose:ShowOptions()" )
		return false
	end

	if not self:CheckGlobalCooldown() then
		self:ShowWhyNot( de, L["the global cooldown is in effect"], "Verbose:ShowOptions()" )
		return false
	end

	if not self:CheckSpellFrequency( de ) then
		--self:ShowWhyNot( de, L["the random chance failed (<chance>%)"] )
		return false
	end

	if not self:CheckSpellCooldown( de ) then
		--self:ShowWhyNot( de, L["this event trigger's cooldown is in effect (<elapsed><seconds> sec.)"] )
		return false
	end

	if not self:CheckOncePerTarget( de ) then
		if not de.target then
			-- make sure a target name is displayed
			de.target = L["no target selected"]
		end
		self:ShowWhyNot( de, L["this event trigger is limited to once per target (<target>)"] )
		return false
	end

	if not self:CheckOncePerCombat( de ) then
		self:ShowWhyNot( de, L["this event trigger is limited to once per combat / once per out-of-combat"] )
		return false
	end

	-- no limits or restrictions apply, so go ahead and speak
	return true
end



-- will construct or repair a DetectedEvent (de) object
function Verbose:Validate_DetectedEvent(de)
	-- fill in missing name, spellname, and/or eventname, as needed
	local name = de.name or de.eventname or de.spellname
	local names = {
		name		= name,
		eventname	= name,
		spellname	= name,
	}
	self:ValidateObject( de, names )

	-- check additional defaults
	self:ValidateObject( de, Verbose.DEFAULTS.DetectedEvent )

	-- de.type is an enumerated table key that must be a valid one of a limited list
	-- if we don't have locale strings for this type, set to the generic "EVENT" type
--	if not Verbose.EventTypes.IN_SPELL_LIST[de.type] then
--		de.type = "EVENT"
--	end
	-- nope, could be registered by an addon shortly after validate all data on-load
	-- and Verbose.DEFAULTS.DetectedEvent contains a default "EVENT" if it's totally undefined
	-- so we should be OK

	-- make sure we have a key
	-- are event stubs allowed to override their keys? NO!
	-- force known key forms for patch purposes and general sanity
	de.key = self:Keyify( tostring(de.type)..tostring(de.name) )
end


-- will construct or repair an EventTableEntry (ete) object
function Verbose:Validate_EventTableEntry( ete )
	local funcname = "Validate_EventTableEntry"

	self:ValidateObject( ete, Verbose.DEFAULTS.EventTableEntry )
	ete.Messages = self:StringArray_Compress( ete.Messages ) -- remove empty string indexes and redundant speeches
	self:Validate_DetectedEvent( ete.DetectedEvent )
end


-- TODOSOON: move costly parts of this function into a standard check in oldversions.lua
--		I have never seen the data actually become corrupted, or Blizzard change things unexpectedly
--		but I like the convenience of being able to declare new data in loader without having to
--		always create a patch function... though that has also bitten me, so hmmm...
function Verbose:ValidateAllSavedData()
	local funcname = "ValidateAllSavedData"
	-- NOTE: When creating new data or resetting to defaults
	--		the SavedData.Version number will be set to the current DATA_VERSION prior to entering this function
	--		otherwise, side effects of this function may be used to complete the constructors from the DEFAULTS table in loader.lua

	-----------------------------------------------------------------------------------
	-- prior to v3.0.3.08, a version number was not saved in the VerboseSavedData
	-- create an older version number to force running the first available patch

	if not VerboseSavedData.Version then
		VerboseSavedData.Version = "3.0.3.07"
	end
	if not VerboseSavedDataForAll.Version then
		--this actually gained a version number more recently than this,
		--but not sure exactly which version, and an older number should be OK
		VerboseSavedDataForAll.Version = "3.0.3.07"
	end

	self:DebugMsg(funcname, "data version - this toon:"..tostring(VerboseSavedData.Version))
	self:DebugMsg(funcname, "data version - all toons:"..tostring(VerboseSavedDataForAll.Version))
	self:DebugMsg(funcname, "data version - current v:"..tostring(Verbose.DATA_VERSION))

	-----------------------------------------------------------------------------------
	-- Apply patches if necessary

	-- if the saved data was from the current version
	-- we can speed up loading a little by skipping this loop
	-- NOTE: the current user's data version could be newer than the global For All version
	--		in the case of initializing settings for a new toon immediately after a patch
	--		before the global For All data has been patched yet
	if	(VerboseSavedData.Version		< Verbose.DATA_VERSION) or
		(VerboseSavedDataForAll.Version< Verbose.DATA_VERSION) or
		Verbose.DEBUG_PATCH then
		self:ApplyPatches()
	end
end


function Verbose:EraseAllSpeeches()
	--TODOLATER: prompt Are you sure?
	table.wipe( self:GetActiveEventTable() )
	self:Print(L["All event triggers and speeches have been erased. You now have a clean slate."])
end
