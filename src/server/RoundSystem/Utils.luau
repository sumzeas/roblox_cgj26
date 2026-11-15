local ServerStorage = game:GetService('ServerStorage')
local Teams = game:GetService('Teams')

local Utils = {}

-- Gets the team given a name.
function Utils.getTeam(teamName: string): Team
    return Teams:FindFirstChild(teamName)
end

-- Gives a players gears
function Utils.giveTeamGear(player: Player, teamName: string)
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
function Utils.giveForcefield(player: Player)
    local character = player.Character
    if character then
        local forceField = Instance.new('ForceField')
        forceField.Visible = false
        forceField.Parent = character
    end
end

-- Spawns a player with the corresponding team gear.
function Utils.spawnPlayer(player: Player, teamName: string)
    local team = Utils.getTeam(teamName)
    player.Team = team
    player:LoadCharacterAsync()
    player.CharacterAppearanceLoaded:Once(function()
        Utils.giveTeamGear(player, teamName)
    end)
end

return Utils