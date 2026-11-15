local Players = game:GetService('Players')
local Teams = game:GetService('Teams')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')
local StatusController = require(ServerScriptService.StatusController)
local StatusShared = require(ReplicatedStorage.Shared.Status)
local GoodSignal = require(ReplicatedStorage.Packages.goodsignal)

local LobbySystem = {}
local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)

local initialized = false
local timerThread: thread? = nil
local gameStarted = GoodSignal.new()

-- Begins a timer in a separate thread.
local function startTimer()
    if not timerThread then
        timerThread = task.spawn(function()
            task.wait(LobbyConfig.Duration)
            timerThread = nil
            StatusController.setStatus(StatusShared.Enum.Playing)
            gameStarted:Fire()
            print('Now playing!')
        end)
    end
end

-- Stops the timer in the middle of execution. This is for transitioning the game
-- status back to Waiting if the player count drops below the threshold during intermission.
local function stopTimer()
    if timerThread then
        task.cancel(timerThread)
        timerThread = nil
    end
end

-- Checks the current number of players and updates the game status accordingly.
local function checkLobby()
    local currentStatus = StatusController.getStatus()
    local playerCount = #Players:GetPlayers()

    -- Entering intermission if there is enough players.
    if currentStatus == StatusShared.Enum.Waiting and playerCount >= LobbyConfig.MinPlayers then
        -- print('Entering intermission.')
        StatusController.setStatus(StatusShared.Enum.Intermission)
        startTimer()
    -- Exiting intermission if player count falls below threshold.
    elseif currentStatus == StatusShared.Enum.Intermission and playerCount < LobbyConfig.MinPlayers then
        -- print('Return to waiting because a player left during intermission')
        stopTimer()
        StatusController.setStatus(StatusShared.Enum.Waiting)
    end
end

-- Initializes the lobby system.
function LobbySystem.init()
    if initialized then return end
    initialized = true

    Players.PlayerAdded:Connect(function(player)
        checkLobby()
    end)

    Players.PlayerRemoving:Connect(function(player)
        task.defer(checkLobby)
    end)

    task.spawn(checkLobby)
end

-- Fired when the game starts. Or in other words, when the status is playing.
function LobbySystem.onGameStarted(callback: () -> ())
    return gameStarted:Connect(callback)
end

function LobbySystem.resetLobby()
    StatusController.setStatus(StatusShared.Enum.Waiting)
    checkLobby()
    local lobbyTeam = Teams:FindFirstChild(LobbyConfig.TeamName)
    for _, player in Players:GetPlayers() do
        player.Team = lobbyTeam
        player:LoadCharacter()
    end
end

return LobbySystem