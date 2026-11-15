local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Packages = ReplicatedStorage:WaitForChild('Packages')
local GoodSignal = require(Packages:WaitForChild('goodsignal'))

local Timer = {}
Timer.__index = Timer

type GoodSignal = typeof(GoodSignal.new())

export type Timer = {
    _duration: number,
    _tickRateSeconds: number,
    _started: boolean,
    _task: thread?,
    Tick: GoodSignal,
    Started: GoodSignal,
    Stopped: GoodSignal,
    Completed: GoodSignal,
    Start: (self: Timer) -> (),
    Stop: (self: Timer) -> (),
    ModifyDuration: (self: Timer, modifyCallback: (duration: number) -> number) -> (),
    SetDuration: (self: Timer, duration: number) -> (),
    GetDuration: (self: Timer) -> number,
}

function Timer.new(duration: number, tickRateSeconds: number?): Timer
    return setmetatable({
        _duration = duration,
        _tickRateSeconds = tickRateSeconds or 1,
        _started = false,
        _task = nil,
        Tick = GoodSignal.new(),
        Started = GoodSignal.new(),
        Stopped = GoodSignal.new(),
        Completed = GoodSignal.new(),
    }, Timer)
end

function Timer.Start(self: Timer)
    if self._started then return end
    self._started = true
    self.Started:Fire()

    self._task = task.spawn(function()
        local elapsed = 0
        while self._started and elapsed < self._duration do
            local remaining = math.max(0, self._duration - elapsed)
            self.Tick:Fire(elapsed, remaining)

            task.wait(self._tickRateSeconds)
            elapsed += self._tickRateSeconds
        end

        if self._started then
            self._started = false
            self._task = nil
            self.Tick:Fire(self._duration, 0)
            self.Stopped:Fire()
            self.Completed:Fire()
        end
    end)
end

function Timer.Stop(self: Timer)
    if not self._started then return end
    self._started = false

    local thread = self._task
    self._task = nil
    if thread and coroutine.status(thread) == 'suspended' then
        task.cancel(thread)
    end

    self.Stopped:Fire()
end

function Timer.ModifyDuration(self: Timer, modifyCallback: (duration: number) -> number)
    self._duration = modifyCallback(self._duration)
end

function Timer.SetDuration(self: Timer, duration: number)
    self._duration = duration
end

function Timer.GetDuration(self: Timer): number
    return self._duration
end

return Timer