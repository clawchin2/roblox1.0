-- Simple Tutorial UI
-- Shows minimal instructions and auto-dismisses

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TutorialUI = {}

function TutorialUI.init()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TutorialUI"
    screenGui.Parent = playerGui
    
    -- Main container - BIG and visible
    local container = Instance.new("Frame")
    container.Name = "TutorialContainer"
    container.Size = UDim2.new(0, 500, 0, 200)
    container.Position = UDim2.new(0.5, -250, 0.3, -100)
    container.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    container.BackgroundTransparency = 0.3
    container.BorderSizePixel = 0
    container.Parent = screenGui
    
    -- Corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = container
    
    -- Title - BIGGER
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "HOW TO PLAY"
    title.TextColor3 = Color3.fromRGB(255, 255, 0)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBlack
    title.TextStrokeTransparency = 0.5
    title.Parent = container
    
    -- Instructions - SIMPLE and BIG
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Size = UDim2.new(1, -40, 0, 80)
    instructions.Position = UDim2.new(0, 20, 0, 80)
    instructions.BackgroundTransparency = 1
    instructions.Text = "WASD to move\nSPACE to jump"
    instructions.TextColor3 = Color3.fromRGB(255, 255, 255)
    instructions.TextScaled = true
    instructions.Font = Enum.Font.GothamBold
    instructions.TextStrokeTransparency = 0.3
    instructions.Parent = container
    
    -- Dismiss hint
    local dismissHint = Instance.new("TextLabel")
    dismissHint.Name = "DismissHint"
    dismissHint.Size = UDim2.new(1, 0, 0, 30)
    dismissHint.Position = UDim2.new(0, 0, 1, -35)
    dismissHint.BackgroundTransparency = 1
    dismissHint.Text = "(Jump to start)"
    dismissHint.TextColor3 = Color3.fromRGB(200, 200, 200)
    dismissHint.TextScaled = true
    dismissHint.Font = Enum.Font.Gotham
    dismissHint.Parent = container
    
    -- Store reference
    TutorialUI.container = container
    TutorialUI.screenGui = screenGui
    
    -- Auto-dismiss after 5 seconds
    task.delay(5, function()
        TutorialUI.dismiss()
    end)
    
    -- Dismiss on jump
    local dismissConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Space then
            TutorialUI.dismiss()
        end
    end)
    
    TutorialUI.dismissConnection = dismissConn
    
    -- Also dismiss when character moves significantly (started playing)
    task.spawn(function()
        local character = player.Character
        if not character then
            character = player.CharacterAdded:Wait()
        end
        local hrp = character:WaitForChild("HumanoidRootPart")
        local startZ = hrp.Position.Z
        
        -- Check if player moved forward
        while container and container.Parent do
            task.wait(0.1)
            if hrp and hrp.Parent then
                local dist = math.abs(hrp.Position.Z - startZ)
                if dist > 10 then
                    TutorialUI.dismiss()
                    break
                end
            end
        end
    end)
end

function TutorialUI.dismiss()
    if TutorialUI.dismissed then return end
    TutorialUI.dismissed = true
    
    if TutorialUI.dismissConnection then
        TutorialUI.dismissConnection:Disconnect()
        TutorialUI.dismissConnection = nil
    end
    
    local container = TutorialUI.container
    if container and container.Parent then
        -- Fade out animation
        local tween = TweenService:Create(container, TweenInfo.new(0.5), {
            Position = UDim2.new(0.5, -250, 0, -250),
            BackgroundTransparency = 1
        })
        tween:Play()
        
        -- Hide text
        for _, child in ipairs(container:GetDescendants()) do
            if child:IsA("TextLabel") then
                TweenService:Create(child, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            end
        end
        
        tween.Completed:Connect(function()
            container:Destroy()
        end)
    end
end

return TutorialUI
