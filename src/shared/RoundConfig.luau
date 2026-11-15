export type RoundOverReason = number
return table.freeze({
    HeadStartDuration = 30,
    PostRoundDuration = 10,
    Duration = 180,
    BeastTeamName = "Beast",
    SurvivorTeamName = "Survivor",
    RoundOverReason  = {
        AllEliminated = 1 :: RoundOverReason,
        TimesUp = 2 :: RoundOverReason,
        BeastLeft = 3 :: RoundOverReason,
    }
})