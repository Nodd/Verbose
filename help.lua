local addonName, Verbose = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- Lua functions
local assert = assert
local error = error
local ipairs = ipairs
local type = type
local wipe = wipe
local _G = _G

-- WoW globals
local EmoteList = EmoteList
local TextEmoteSpeechList = TextEmoteSpeechList
local FONT_COLOR_CODE_CLOSE = FONT_COLOR_CODE_CLOSE
local NORMAL_FONT_COLOR_CODE = NORMAL_FONT_COLOR_CODE

local function GenerateEmoteCommandsHelp()
    local typ
    local txt = {
        anim = "",
        speech = "",
        nothing = "",
    }
    local cmds = {}
    for i = 1, 600 do -- local MAXEMOTEINDEX=522 (in WoW 8.3) in ChatFrame.lua
        local token = _G["EMOTE"..i.."_TOKEN"]
        if token then
            local found = false
            -- Find emote type
            for _, e in ipairs(EmoteList) do  -- Incomplete list defined in ChatFrame.lua
                if e == token then
                    typ = "anim"
                    found = true
                    break
                end
            end
            if not found then
                for _, e in ipairs(TextEmoteSpeechList) do  -- Incomplete list defined in ChatFrame.lua
                    if e == token then
                        typ = "speech"
                        found = true
                        break
                    end
                end
            end
            if not found then
                typ = "nothing"
            end

            -- Find commands
            local j = 1
            local cmdString = _G["EMOTE"..i.."_CMD"..j]
            while cmdString do
                -- Avoid duplicates
                if not cmds[cmdString] then
                    txt[typ] = txt[typ]..cmdString.." "
                end
                cmds[cmdString] = true
                j = j + 1
                cmdString = _G["EMOTE"..i.."_CMD"..j]
            end
            txt[typ] = txt[typ]:sub(1,-2).."\n"  -- Remove trailing space
            wipe(cmds)
        end
    end
    return txt.anim:sub(1,-2), txt.speech:sub(1,-2), txt.nothing:sub(1,-2)
end
local txt_anim, txt_speech, txt_nothing = GenerateEmoteCommandsHelp()

local helpData = {
    L["Help"],
    {
        L["Welcome"],
        L["Welcome to "] .. addonName .. L[" !"] ..
        L["\n\nThis addon is heavily inspired by SpeakinSpell which doesn't seem to be maintained anymore."]..
        L[" This one aims to be simpler to configure and simpler to maintain, but it was primarily done because coding is fun ! :)"]..
        L["\n\nYou'll find some informations in th entries on the side. Happy speaking !"]
    },
    {
        L["Substitutions"],
        L["To make messages more dynamic and feel alive, it is possible to modify the messages on the fly by using substitutions."]..
        L["\n\nThere are different kinds of substitutions:"]..
        L["\n  - unit data such as the name or type of the selected target"]..
        L["\n  - event data such as the caster or the target of a spell tar"]..
        L["\n  - user-defined list substitutions"]..
        L["\n\nSubstitution tokens are indicated between angle brackets like this: <token>."]..
        L["\n\nTo avoid ugly outputs, a message where there are tokens that can not be replaced  will be avoided."]..
        L[" This can happen for example if <targetname> is used ant there is no target selected."],
        {
            L["Unit data"],
            L["Documentation here"],
        },
        {
            L["Event data"],
            L["The available tokens varie among events. They are documented on each event page."]..
            L["\n\nYeah, taht wasn't terribely useful, sorry."]
        },
        {
            L["User-defined lists"],
            L["These lists are configured in the 'List' tab. To create a new list, simply click on the 'New list' button."]..
            "\n\n"..NORMAL_FONT_COLOR_CODE..L["List name"]..FONT_COLOR_CODE_CLOSE..
            L["\nThe substitution token corresponds to the list name."]..
            L[" In your messages, simply put the list name between angle brackets and it will replaced by arandom list value."]..
            L["\nAs the name is used for the token, it's restricted to alphanumeric characters exclusively."]..
            L["\nIn case of name conflict with another substitution, the other substitution will occur and the list is ignored."]..
            "\n\n"..NORMAL_FONT_COLOR_CODE..L["List values"]..FONT_COLOR_CODE_CLOSE..
            L["\nThe values are entered in the multiline edit box, one entry per line."]..
            L[" The caracters < and > are not allowed in the values, to avoid conflicts with tokens."]..
            "\n|cFFFF0000"..L["Don't forget to validate the modifications with the 'Accept' button !"].."|r"
        },
    },
    {
        L["Messages"],
        {
            L["Emotes"],
            L["Emotes can be used instead of text. Here is a list of existing emotes:"],
            L["Known emotes with animation:"],
            txt_anim,
            L["Known emotes with sound:"],
            txt_speech,
            L["Other emotes (wich may have animation or sound):"],
            txt_nothing,
        }
    },
}


local function InsertHelp(thisHelpData, optionGroupTable)
    for i, data in ipairs(thisHelpData) do
        if i == 1 then
            -- Title
            assert(type(data) == "string", "First element should be a title")
            optionGroupTable.name = data
            optionGroupTable.args.title =  {
                type = "description",
                order = i,
                name = NORMAL_FONT_COLOR_CODE..data..FONT_COLOR_CODE_CLOSE,
                fontSize = "large",
            }
        elseif type(data) == "string" then
            -- Text
            optionGroupTable.args["desc"..i] = {
                type = "description",
                order = i,
                name = "\n"..data,
                fontSize = "medium",
            }
        elseif type(data) == "table" then
            -- Subpage
            optionGroupTable.args["group"..i] = {
                type = "group",
                name = nil,
                order = i,
                args = {},
            }
            -- Recursion
            InsertHelp(data, optionGroupTable.args["group"..i])
        else
            error("invalid type "..type(data))
        end
    end
end

function Verbose:GenerateHelpOptionTable()
    local helpConfig = {
        type = "group",
        name = HELP_LABEL,
        order = 50,
        cmdHidden = true,
        childGroups = "tree",
        desc = L["Need help ?"],
        args = {},
    }

    InsertHelp(helpData, helpConfig)

    return helpConfig
end
