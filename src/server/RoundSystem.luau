local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')
local Players = game:GetService('Players')
local ServerStorage = game:GetService('ServerStorage')
local Teams = game:GetService('Teams')

local RoundConfig = require(ReplicatedStorage.Shared.RoundConfig)
local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)
local StatusController = require(ServerScriptService.StatusController)
local Status = require(ReplicatedStorage.Shared.Status)

local RoundSystem = {}

-- Gets the team given a name.
local function getTeam(teamName: string): Team
    return Teams:FindFirstChild(teamName)
end

-- Gives a players gears
local function giveTeamGear(player: Player, teamName: string)
    local teamGearFolder = ServerStorage:FindFirstChild(`{teamName}Gear`)
    if not (teamGearFolder and teamGearFolder:IsA('Folder')) then
        return
    end

    for _, gear in teamGearFolder:GetChildren() do
        if not gear:IsA('Tool') then continue end
        gear:Clone().Parent = player.Backpack
    end
end

-- Helper function for giving the beast god mode.
local function giveForcefield(player: Player)
    local character = player.Character
    if character then
        local forceField = Instance.new('ForceField')
        forceField.Visible = false
        forceField.Parent = character
    end
end

-- Assigns the teams of players in this round.
local function initPlayers(roundPlayers: {Player}, beastPlayer: Player)
    for _, player in roundPlayers do
        local team: Team

        if player == beastPlayer then
            team = getTeam(RoundConfig.BeastTeamName)
            player.Team = team
        else
            team = getTeam(RoundConfig.SurvivorTeamName)
            player.Team = team
        end

        player:LoadCharacterAsync()
        player.CharacterAppearanceLoaded:Once(function()
            giveTeamGear(player, team)
        end)
    end
end

-- Begins a round by assigning teams and gears.
function RoundSystem.beginRound()
    if StatusController.getStatus() ~= Status.Enum.Playing then
        return
    end

    local players = Players:GetPlayers()
    if #players < LobbyConfig.MinPlayers then
        return
    end

    local roundPlayers = players
    local beastPlayer = roundPlayers[math.random(1, #roundPlayers)]
    initPlayers(roundPlayers, beastPlayer)
    giveForcefield(beastPlayer)
end

return RoundSystem