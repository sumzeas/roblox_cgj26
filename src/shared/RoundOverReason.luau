export type RoundOverReason = number
return table.freeze({
    AllEliminated = 1 :: RoundOverReason,
    TimesUp = 2 :: RoundOverReason,
    BeastLeft = 3 :: RoundOverReason,
})