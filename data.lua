local addonName, Verbose = ...


Verbose.data = {
    Cooldown = 5,

    -- DetectedEventStub.type
    COMBAT = {
        -- DetectedEventStub.eventname
        ["Damage received"] = {
            -- DetectedEventStub.school
            ["(Feu)"] = {
                Messages = {
                    "Ça brûle !",
                    "C'est chaud !",
                    "Chaud chaud chaud !",
                    "Je brûle !",
                    "Je crâme !",
                    "Trop chaud !",
                },
                Frequency = 1/10,
                Cooldown = 10,
            },
            ["other"] = {
                Messages = {
                    "Aïe !",
                    "Aïe aïe !",
                    "Aïe aïe aïe !",
                    "Ouille !",
                    "Ouille ouille !",
                    "Ouille ouille ouille !",
                    "Aïe ! Ça fait mal !",
                    "Ouille ! Ça fait mal !",
                    "Hé ! Ça fait mal !",
                    "Aïe ! Mais ça fait mal !",
                    "Ouille ! Mais ça fait mal !",
                    "Hé ! Mais ça fait mal !",
                    "Aïe ! Tu vas me le payer !",
                    "Ouille ! Tu vas me le payer !",
                },
                Frequency = 1/10,
                Cooldown = 10,
            }
        }
    }
}
