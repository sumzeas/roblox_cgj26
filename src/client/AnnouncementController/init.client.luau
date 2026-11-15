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

local function stopActiveTimer()
    if activeTimer then
        activeTimer:Stop()
        activeTimer = nil
    end
end

local function startCountdown(duration: number, textPrefix: string, onComplete: (() -> ())?)
    stopActiveTimer()
    
    activeTimer = Timer.new(duration, 1)
    activeTimer.Tick:Connect(function(elapsed, remaining)
        textLabel.Text = string.format("%s: %ds", textPrefix, remaining)
    end)
    
    if onComplete then
        activeTimer.Stopped:Once(onComplete)
    end
    
    activeTimer:Start()
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

    [Status.Enum.RoundOver] = function(payload: Status.RoundOverPayload)
        stopActiveTimer()
        if roundOverHandlers[payload.reason] then
            roundOverHandlers[payload.reason]()
        else
            textLabel.Text = 'Round over!'
        end
        
        task.delay(2, function()
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

Status.onChanged(function(statusNum, payload)
    local handler = handlers[statusNum]
    if handler then
        handler(payload)
    end
end)