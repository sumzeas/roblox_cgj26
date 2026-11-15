local REMOTE_EVENT_NAME = 'AnnouncementsRemoteEvent'
local FOLDER_NAME = 'AnnouncementsFolder'

local Announcements = {}
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

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

-- Gets the remote event. If it does not exist, the server will create it automatically.
function Announcements.getRemoteEvent(): RemoteEvent
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

-- Fires when the server makes an announcement.
function Announcements.onAnnouncement(callback: (message: string) -> ())
    if RunService:IsServer() then return end
    Announcements.getRemoteEvent().OnClientEvent:Connect(callback)
end

return Announcements