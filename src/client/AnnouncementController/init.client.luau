local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Shared = ReplicatedStorage:WaitForChild('Shared')
local Status = require(Shared:WaitForChild('Status'))
local RoundConfig = require(Shared:WaitForChild('RoundConfig'))
local LobbyConfig = require(Shared:WaitForChild('LobbyConfig'))
local RoundOverReason = require(Shared:WaitForChild('RoundOverReason'))
local Timer = require(Shared:WaitForChild('Timer'))
type Timer = Timer.Timer

local player = Players.LocalPlayer
local playerGui = player:WaitForChild('PlayerGui')

local announcementGui: ScreenGui = playerGui:WaitForChild('AnnouncementGui')
local textLabel: TextLabel = announcementGui:WaitForChild('TextLabel')

local activeTimer: Timer? = nil
local statusVersion = 0

local function stopActiveTimer()
    local timer = activeTimer
    activeTimer = nil
    if timer then
        timer:Stop()
    end
end

local function startCountdown(duration: number, textPrefix: string, onComplete: (() -> ())?)
    stopActiveTimer()

    local timer = Timer.new(duration, 1)
    activeTimer = timer
    timer.Tick:Connect(function(elapsed, remaining)
        textLabel.Text = string.format("%s: %ds", textPrefix, remaining)
    end)

    if onComplete then
        timer.Completed:Once(onComplete)
    end

    timer:Start()
end

local roundOverHandlers = {
    [RoundOverReason.AllEliminated] = function()
        textLabel.Text = 'All survivors eliminated. Beast wins!'
    end,

    [RoundOverReason.TimesUp] = function()
        textLabel.Text = 'Times up. Survivors win!'
    end,

    [RoundOverReason.BeastLeft] = function()
        textLabel.Text = 'Beast left. Survivors win!'
    end
}

local handlers = {
    [Status.Enum.Waiting] = function()
        stopActiveTimer()
        textLabel.Text = 'Waiting for players...'
    end,

    [Status.Enum.Intermission] = function()
        local duration = LobbyConfig.Duration or 10
        startCountdown(duration, 'Intermission')
    end,

    [Status.Enum.RoundOver] = function(payload: Status.RoundOverPayload?)
        stopActiveTimer()
        local reason = payload and payload.reason
        if reason and roundOverHandlers[reason] then
            roundOverHandlers[reason]()
        else
            textLabel.Text = 'Round over!'
        end

        local myVersion = statusVersion
        task.delay(2, function()
            if statusVersion ~= myVersion then return end
            local remainingPostRound = math.max(0, RoundConfig.PostRoundDuration - 2)
            startCountdown(remainingPostRound, 'Next round starting')
        end)
    end,

    [Status.Enum.Playing] = function()
        startCountdown(RoundConfig.HeadStartDuration, 'Head Start', function()
            startCountdown(RoundConfig.Duration, 'Time remaining')
        end)
    end
}

local function onStatus(statusNum, payload)
    statusVersion += 1
    local handler = handlers[statusNum]
    if handler then
        handler(payload)
    end
end

Status.onChanged(onStatus)

task.spawn(function()
    onStatus(Status.getStatus(), nil)
end)