local WALK_SPEED = 16
local RUN_SPEED = 24

local UserInputService = game:GetService("UserInputService")
local Player = game.Players.LocalPlayer
local Character = Player.Character
local Humanoid: Humanoid = Character:WaitForChild("Humanoid")

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.LeftShift then
        Humanoid.WalkSpeed = RUN_SPEED
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.LeftShift then
        Humanoid.WalkSpeed = WALK_SPEED
    end
end)