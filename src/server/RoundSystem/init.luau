local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')
local Players = game:GetService('Players')

local RoundConfig = require(ReplicatedStorage.Shared.RoundConfig)
local RoundOverReason = require(ReplicatedStorage.Shared.RoundOverReason)
local LobbyConfig = require(ReplicatedStorage.Shared.LobbyConfig)
local GoodSignal = require(ReplicatedStorage.Packages.goodsignal)
local StatusController = require(ServerScriptService.StatusController)
local Status = require(ReplicatedStorage.Shared.Status)
local Utils = require(script.Utils)

type RoundOverReason = RoundOverReason.RoundOverReason
local RoundOverReason = RoundOverReason

type Round = {
    _survivors: {[Player]: true},
    _beast: Player,
    _duration: number,
    _started: boolean,
    Ended: typeof(GoodSignal),
}

local Round = {}
Round.__index = Round

function Round.new(players: {Player}, beast: Player): Round
    local survivors = {}

    for _, player in players do
        if player == beast then continue end
        survivors[player] = true
    end

    return setmetatable({
        _survivors = survivors,
        _beast = beast,
        _duration = RoundConfig.Duration,
        _started = false,
        Ended = GoodSignal.new()
    }, Round)
end

local function getSurvivorCount(survivors: {[Player]: true}): number
    local count = 0
    for _, _ in survivors do
        count += 1
    end
    return count
end

-- Spawns all survivors and gives them a head start.
local function spawnSurvivors(survivors: {[Player]: true})
    for survivor, _ in survivors do
        Utils.spawnPlayer(survivor, RoundConfig.SurvivorTeamName)
    end
    task.wait(RoundConfig.HeadStartDuration)
end

-- Spawns the beast and gives them a permanent forcefield for the round.
local function spawnBeast(beast: Player)
    Utils.spawnPlayer(beast, RoundConfig.BeastTeamName)
    Utils.giveForcefield(beast)
end

function Round.Start(self: Round)
    if self._started then return end
    self._started = true

    local playerRemovingConn: RBXScriptConnection
    local deathConnections: {[Player]: RBXScriptConnection} = {}
    local timerThread: thread?

    self.Ended:Once(function(reason: RoundOverReason)
        self._started = false

        if timerThread and coroutine.status(timerThread) == 'suspended' then
            task.cancel(timerThread)
        end

        -- Removing player removing connection
        if playerRemovingConn then
            playerRemovingConn:Disconnect()
        end

        -- Removing death connections
        for _, conn in deathConnections do
            if conn.Connected then
                conn:Disconnect()
            end
        end

        print("Round Over!")
        StatusController.setStatus(Status.Enum.RoundEnding, { reason = reason })
        task.wait(RoundConfig.PostRoundDuration)
        if StatusController.getStatus() == Status.Enum.RoundEnding then
            StatusController.setStatus(Status.Enum.RoundOver, { reason = reason })
        end
    end)

    playerRemovingConn = Players.PlayerRemoving:Connect(function(player: Player)
        if not self._started then return end
        if player == self._beast then
            self.Ended:Fire(RoundOverReason.BeastLeft)
        elseif self._survivors[player] then
            self._survivors[player] = nil
            if getSurvivorCount(self._survivors) == 0 then
                self.Ended:Fire(RoundOverReason.AllEliminated)
            end
        end
    end)

    if self._beast.Parent ~= Players then
        self.Ended:Fire(RoundOverReason.BeastLeft)
        return
    end
    for survivor, _ in self._survivors do
        if survivor.Parent ~= Players then
            self._survivors[survivor] = nil
        end
    end
    if getSurvivorCount(self._survivors) == 0 then
        self.Ended:Fire(RoundOverReason.AllEliminated)
        return
    end

    spawnSurvivors(self._survivors)

    if not self._started then return end

    spawnBeast(self._beast)

    -- Creating connections for when survivors are killed.
    for survivor, _ in self._survivors do
        if not self._survivors[survivor] or survivor.Parent ~= Players then continue end

        local character = survivor.Character or survivor.CharacterAdded:Wait()
        local humanoid: Humanoid? = character:WaitForChild('Humanoid', 5)

        if not self._started then return end

        if not humanoid or humanoid.Health <= 0 then
            self._survivors[survivor] = nil
            if getSurvivorCount(self._survivors) == 0 then
                self.Ended:Fire(RoundOverReason.AllEliminated)
                return
            end
            continue
        end

        deathConnections[survivor] = humanoid.Died:Once(function()
            if not self._started then return end
            self._survivors[survivor] = nil
            survivor.Team = Utils.getTeam(LobbyConfig.TeamName)

            if getSurvivorCount(self._survivors) == 0 then
                self.Ended:Fire(RoundOverReason.AllEliminated)
            end
        end)
    end

    -- Beginning game loop in a separate thread.
    timerThread = task.spawn(function()
        local elapsed = 0
        while self._started and elapsed < self._duration do
            task.wait(1)
            elapsed += 1
        end

        if self._started then
            self.Ended:Fire(RoundOverReason.TimesUp)
        end
    end)
end

local RoundSystem = {}
local initialized = false

-- Begins a new round.
local function beginRound()
    if StatusController.getStatus() ~= Status.Enum.Playing then
        return
    end

    local players = Players:GetPlayers()
    if #players < LobbyConfig.MinPlayers then
        return
    end

    -- Selecting the beast and beginning the round.
    local beast = players[math.random(1, #players)]
    local round = Round.new(players, beast)
    round:Start()
end

function RoundSystem.init()
    if initialized then return end
    initialized = true
    StatusController.onChanged(function(statusNum)
        if statusNum ~= Status.Enum.Playing then
            return
        end

        beginRound()
    end)
end

return RoundSystem