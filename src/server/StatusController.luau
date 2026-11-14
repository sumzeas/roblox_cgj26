local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local StatusShared = require(Shared.Status)

local StatusController = {}
local currentStatus = StatusShared.Enum.Waiting
local initalized = false

local remoteFn = StatusShared.getRemoteFn()
local remoteEvent = StatusShared.getRemoteEvent()

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
end

return StatusController