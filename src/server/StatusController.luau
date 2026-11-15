local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local GoodSignal = require(ReplicatedStorage.Packages.goodsignal)
local StatusShared = require(Shared.Status)

local StatusController = {}
local currentStatus = StatusShared.Enum.Waiting
local initalized = false

local remoteFn = StatusShared.getRemoteFn()
local remoteEvent = StatusShared.getRemoteEvent()
local changedSignal = GoodSignal.new()

-- Initializes the StatusController.
function StatusController.init()
    if initalized then return end
    initalized = true
    remoteFn.OnServerInvoke = function(player)
        return currentStatus
    end
end

-- Gets the current status of the game.
function StatusController.getStatus(): StatusShared.StatusNumber
    return currentStatus
end

-- Sets the current status of the game.
function StatusController.setStatus(newStatus: StatusShared.StatusNumber)
    currentStatus = newStatus
    remoteEvent:FireAllClients(newStatus)
    changedSignal:Fire(newStatus)
end

function StatusController.onChanged(callback: (statusNum: StatusShared.StatusNumber) -> ())
    return changedSignal:Connect(callback)
end

return StatusController