-- Kill Aura Script with GUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer
local Run = true

local function IsAlive(Humanoid)
    return Humanoid and Humanoid.Health > 0
end

local function GetTouchInterest(Tool)
    return Tool and Tool:FindFirstChildWhichIsA("TouchTransmitter", true)
end

local function Attack(Tool, TouchPart, ToTouch)
    if Tool:IsDescendantOf(workspace) then
        Tool:Activate()
        firetouchinterest(TouchPart, ToTouch, 1)
        firetouchinterest(TouchPart, ToTouch, 0)
    end
end

-- GUI Setup
local gui = Instance.new("ScreenGui")
gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 100, 0, 50)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.new(0, 0, 0)
frame.BackgroundTransparency = 0.5
frame.Parent = gui

local toggleButton = Instance.new("TextButton")
toggleButton.Text = "Kill Aura: OFF"
toggleButton.TextSize = 14
toggleButton.Size = UDim2.new(0, 100, 0, 50)
toggleButton.Parent = frame

local function ToggleAura()
    Run = not Run
    toggleButton.Text = "Kill Aura: " .. (Run and "ON" or "OFF")
end

toggleButton.MouseButton1Click:Connect(ToggleAura)

while Run do
    local char = lp.Character
    if IsAlive(char:FindFirstChildOfClass("Humanoid")) then
        local tool = char:FindFirstChildOfClass("Tool")
        local touchInterest = tool and GetTouchInterest(tool)

        if touchInterest then
            local touchPart = touchInterest.Parent
            local instancesInBox = workspace:FindPartsInRegion3(touchPart.Position - getgenv().configs.Size / 2, touchPart.Position + getgenv().configs.Size / 2, nil, math.huge)

            for _, v in ipairs(instancesInBox) do
                local character = v.Parent

                if character:IsA("Model") and character ~= char then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")

                    if humanoid and (not getgenv().configs.DeathCheck or IsAlive(humanoid)) then
                        Attack(tool, touchPart, v)
                    end
                end
            end
        end
    end

    RunService.Heartbeat:Wait()
end

