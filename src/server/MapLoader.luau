local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')
local ServerStorage = game:GetService('ServerStorage')

local StatusController = require(ServerScriptService.StatusController)
local Status = require(ReplicatedStorage.Shared.Status)

local MAP_NAME = 'CrossRoads'

local MapLoader = {}
local initialized = false
local firstGame = true
local oldMap: Model = workspace:FindFirstChild(MAP_NAME)

local function replaceOldMap()
    local mapClone = ServerStorage:FindFirstChild(MAP_NAME):Clone()
    if oldMap then
        oldMap:Destroy()
    end
    oldMap = mapClone
    oldMap.Parent = workspace
end

-- Loads the map, replacing the old one if it exists.
local function loadMap()
    if firstGame then
        firstGame = false
    else
        replaceOldMap()
    end

    StatusController.setStatus(Status.Enum.Playing)
    print('Repaired map!')
end

function MapLoader.init()
    if initialized then return end
    initialized = true

    StatusController.onChanged(function(statusNum)
        if statusNum ~= Status.Enum.RepairingMap then
            return
        end
        loadMap()
    end)
end

return MapLoader