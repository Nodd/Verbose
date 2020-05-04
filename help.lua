local addonName, Verbose = ...


local helpData = {
    "Help",
    {
        "Welcome",
        "Welcome to " .. addonName .. " !" ..
        "\n\nThis addon is heavily inspired by SpeakinSpell which doesn't seem to be maintained anymore."..
        " This one aims to be simpler to configure and simpler to maintain, but it was primarily done because coding is fun ! :)"..
        "\n\nYou'll find some informations in th entries on the side. Happy speaking !"
    },
    {
        "Substitutions",
        "To make messages more dynamic and feel alive, it is possible to modify the messages on the fly by using substitutions."..
        "\n\nThere are different kinds of substitutions:"..
        "\n  - unit data such as the name or type of the selected target"..
        "\n  - event data such as the caster or the target of a spell tar"..
        "\n  - user-defined list substitutions"..
        "\n\nSubstitution tokens are indicated between angle brackets like this: <token>."..
        "\n\nTo avoid ugly outputs, a message where there are tokens that can not be replaced  will be avoided."..
        " This can happen for example if <targetname> is used ant there is no target selected.",
        {
            "Unit data",
            "Documentation here",
        },
        {
            "Event data",
            "The available tokens varie among events. They are documented on each event page."..
            "\n\nYeah, taht wasn't terribely useful, sorry."
        },
        {
            "User-defined lists",
            "These lists are configured in the 'List' tab. To create a new list, simply click on the 'New list' button."..
            "\n\n"..NORMAL_FONT_COLOR_CODE.."List name"..FONT_COLOR_CODE_CLOSE..""..
            "\nThe substitution token corresponds to the list name."..
            " In your messages, simply put the list name between angle brackets and it will replaced by arandom list value."..
            "\nAs the name is used for the toke, it's restricted to alphanumeric characters exclusively."..
            "\nIn case of name conflict with another substitution, the other substitution will occur and the list is ignored."..
            "\n\n"..NORMAL_FONT_COLOR_CODE.."List values"..FONT_COLOR_CODE_CLOSE..
            "\nThe values are entered in the multiline edit box, one entry per line."..
            " The caracters < and > are not allowed in the values, to avoid conflicts with tokens."..
            "\n|cFFFF0000Don't forget to validate the modifications with the 'Accept' button !|r"
        },
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
        name = "Help",
        order = 50,
        childGroups = "tree",
        desc = "Need help ?",
        args = {},
    }

    InsertHelp(helpData, helpConfig)

    return helpConfig
end
