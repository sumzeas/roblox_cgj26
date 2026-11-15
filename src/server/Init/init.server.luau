local ServerScriptService = game:GetService("ServerScriptService")
local StatusController = require(ServerScriptService.StatusController)
local LobbySystem = require(ServerScriptService.LobbySystem)

StatusController.init()
LobbySystem.init()

LobbySystem.onGameStarted(function()
    print('Game started! Woohoo!')
end)