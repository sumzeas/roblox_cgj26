local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')
local StatusController = require(ServerScriptService.StatusController)
local Status = require(ReplicatedStorage.Shared.Status)
local LobbySystem = require(ServerScriptService.LobbySystem)
local RoundSystem = require(ServerScriptService.RoundSystem)

StatusController.init()
LobbySystem.init()

local statusHandler = {
    [Status.Enum.Playing] = function()
        RoundSystem.beginRound()
    end
}

StatusController.onChanged(function(statusNum)
    local handler = statusHandler[statusNum]
    if handler then
        handler()
    end
end)