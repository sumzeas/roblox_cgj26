export type StatusNumber = number
local REMOTE_FN_NAME = "StatusRemoteFunction"
local REMOTE_EVENT_NAME = "StatusRemoteEvent"
local FOLDER_NAME = "StatusFolder"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Status = {}

Status.Enum = {
    Waiting = 0 :: StatusNumber,
    Intermission = 1 :: StatusNumber,
    Playing = 2 :: StatusNumber,
    RoundOver = 3 :: StatusNumber,
    RepairingMap = 4 :: StatusNumber,
}

-- Helper for getting the folder containing the game state.
local function getFolder(): Folder
    local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
    if not folder and RunService:IsServer() then
        folder = Instance.new('Folder')
        folder.Name = FOLDER_NAME
        folder.Parent = ReplicatedStorage
    end
    return folder
end

-- Gets the remote function. If it does not exist, the server will create it automatically.
function Status.getRemoteFn(): RemoteFunction
    local folder = getFolder()
    if RunService:IsServer() then
        local remote = folder:FindFirstChild(REMOTE_FN_NAME)
        if not remote then
            remote = Instance.new('RemoteFunction')
            remote.Name = REMOTE_FN_NAME
            remote.Parent = folder
        end
        return remote
    else
        return folder:WaitForChild(REMOTE_FN_NAME)
    end
end

-- Gets the remote event. If it does not exist, the server will create it automatically.
function Status.getRemoteEvent(): RemoteEvent
    local folder = getFolder()
    if RunService:IsServer() then
        local remote = folder:FindFirstChild(REMOTE_EVENT_NAME)
        if not remote then
            remote = Instance.new('RemoteEvent')
            remote.Name = REMOTE_EVENT_NAME
            remote.Parent = folder
        end
        return remote
    else
        return folder:WaitForChild(REMOTE_EVENT_NAME)
    end
end

-- Gets the status of the game currently stored on the server. Only can be ran on the client.
function Status.getStatus(): StatusNumber
    if RunService:IsServer() then return end
    return Status:getRemoteFn():InvokeServer()
end

-- Fired when the status of the game is changed on the server. Only can be ran on the client.
function Status.onChanged(callback: (statusNum: StatusNumber) -> ())
    if RunService:IsServer() then return end
    Status:getRemoteEvent().OnClientEvent:Connect(callback)
end 

return Status