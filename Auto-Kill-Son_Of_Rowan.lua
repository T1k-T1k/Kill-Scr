-- Son of Rowan Boss Killer Script
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

-- Variables
local isEnabled = false
local isBossFound = false
local isProcessing = false
local bossModel = nil
local bossHumanoid = nil
local connection = nil
local notificationCooldowns = {
    bossNotFound = 0,
    bossFound = 0,
    processing = 0,
    success = 0
}

local guiName = "Annouce"  -- Deleting announce Gui

local gui = players:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild(guiName)
if gui then
    gui:Destroy()
end

-- Updated HP threshold to 95 million
local HP_THRESHOLD = 95000000

-- Updated distance threshold to 105 meters
local DISTANCE_THRESHOLD = 105

-- Create a notification function with cooldown
local function sendNotification(title, text, duration, cooldownType)
    local currentTime = tick()
    
    if currentTime - notificationCooldowns[cooldownType] > duration then
        notificationCooldowns[cooldownType] = currentTime
        
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = title;
                Text = text;
                Duration = duration;
            })
        end)
    end
end

-- Create persistent GUI
local function createGUI()
    -- Check if GUI already exists
    local existingGUI = player.PlayerGui:FindFirstChild("BossKillerGUI")
    if existingGUI then return existingGUI end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BossKillerGUI"
    ScreenGui.ResetOnSpawn = false -- Make it persistent
    ScreenGui.Parent = player.PlayerGui
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 200, 0, 100)
    Frame.Position = UDim2.new(0.8, -100, 0.1, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Frame.BorderSizePixel = 2
    Frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
    Frame.Parent = ScreenGui
    
    local Title = Instance.new("TextLabel")
    Title.Text = "Son Of Rowan Killer"
    Title.Size = UDim2.new(1, 0, 0, 25)
    Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Title.TextColor3 = Color3.fromRGB(255, 0, 0)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 16
    Title.Parent = Frame
    
    local Status = Instance.new("TextLabel")
    Status.Name = "StatusLabel"
    Status.Text = "Status: Idle"
    Status.Size = UDim2.new(1, 0, 0, 20)
    Status.Position = UDim2.new(0, 0, 0, 30)
    Status.BackgroundTransparency = 1
    Status.TextColor3 = Color3.fromRGB(255, 255, 255)
    Status.Font = Enum.Font.SourceSans
    Status.TextSize = 14
    Status.Parent = Frame
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Text = "Auto Kill: OFF"
    ToggleButton.Size = UDim2.new(0.8, 0, 0, 30)
    ToggleButton.Position = UDim2.new(0.1, 0, 0, 60)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 14
    ToggleButton.Parent = Frame
    
    -- Make GUI draggable
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    
    local function update(input)
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    Frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    RunService.Heartbeat:Connect(function()
        if dragging and dragInput then
            update(dragInput)
        end
    end)
    
    return ScreenGui
end

-- Function to update status text
local function updateStatus(text)
    pcall(function()
        local gui = player.PlayerGui:FindFirstChild("BossKillerGUI")
        if gui then
            local statusLabel = gui.Frame:FindFirstChild("StatusLabel")
            if statusLabel then
                statusLabel.Text = text
            end
        end
    end)
end

-- Function to check distance between player and boss
local function getDistanceToBoss()
    if not bossModel or not player.Character then return 999 end
    
    local bossHRP = bossModel:FindFirstChild("HumanoidRootPart")
    if not bossHRP then return 999 end
    
    local playerHRP = player.Character:FindFirstChild("HumanoidRootPart")
    if not playerHRP then return 999 end
    
    return (bossHRP.Position - playerHRP.Position).Magnitude
end

-- Function to find the boss model
local function findBoss()
    local workspace = game:GetService("Workspace")
    
    -- Use pcall to avoid errors when checking for paths
    local success, result = pcall(function()
        -- Check if workspace has Main folder
        if not workspace:FindFirstChild("Main") then
            return {found = false, reason = "Main folder not found"}
        end
        
        -- Check if Main has Skull folder
        if not workspace.Main:FindFirstChild("Skull") then
            return {found = false, reason = "Skull folder not found"}
        end
        
        local skullFolder = workspace.Main.Skull
        local boss = skullFolder:FindFirstChild("Son Of Rowan [Lv.???]")
        
        -- Check if boss exists
        if not boss then
            return {found = false, reason = "Boss not spawned"}
        end
        
        local humanoid = boss:FindFirstChildOfClass("Humanoid")
        
        -- Check if boss has humanoid
        if not humanoid then
            return {found = false, reason = "Boss missing humanoid"}
        end
        
        return {found = true, boss = boss, humanoid = humanoid}
    end)
    
    -- Handle errors in pcall
    if not success then
        updateStatus("Status: Script error")
        return nil
    end
    
    -- Handle if boss wasn't found
    if not result.found then
        if isEnabled and isBossFound then
            isBossFound = false
        end
        
        updateStatus("Status: " .. result.reason)
        
        if isEnabled and tick() - notificationCooldowns["bossNotFound"] > 10 then
            sendNotification("ATTENTION!", "Son Of Rowan not found!", 2.5, "bossNotFound")
        end
        
        return nil
    end
    
    -- Boss was found
    local boss = result.boss
    bossHumanoid = result.humanoid
    
    if isEnabled and not isBossFound then
        isBossFound = true
        sendNotification("READY TO WORK :// FINDED SON OF ROWAN", "Waiting for the player to get closer..", 4, "bossFound")
    end
    
    updateStatus("Status: Boss found")
    return boss
end

-- Function to toggle between R6 and R15
local function toggleRigType()
    if not bossModel or not bossHumanoid then return end
    
    -- Use pcall to prevent errors from showing
    local success, healthValue = pcall(function() return bossHumanoid.Health end)
    
    if not success or not healthValue then return end
    
    -- Check if boss health is below threshold (now 95 million)
    if healthValue > HP_THRESHOLD then
        updateStatus("Status: Boss HP too high (" .. math.floor(healthValue/1000000) .. "M/" .. HP_THRESHOLD/1000000 .. "M)")
        isProcessing = false
        return
    end
    
    -- Check player distance - UPDATED to 105 meters
    local distance = getDistanceToBoss()
    if distance > DISTANCE_THRESHOLD then
        updateStatus("Status: Too far (" .. math.floor(distance) .. "m/" .. DISTANCE_THRESHOLD .. "m)")
        isProcessing = false
        return
    end
    
    -- Start the process if all conditions are met
    if not isProcessing then
        isProcessing = true
        sendNotification("IN PROCCESS :// ATTEMPTING TO KILL BOSS", "Stand by...", 4, "processing")
    end
    
    updateStatus("Status: Toggling rig type")
    
    -- Toggle rig type (R6 <-> R15) with error protection
    pcall(function()
        if bossHumanoid.RigType == Enum.HumanoidRigType.R6 then
            bossHumanoid.RigType = Enum.HumanoidRigType.R15
        else
            bossHumanoid.RigType = Enum.HumanoidRigType.R6
        end
    end)
    
    -- Check if boss is defeated
    if healthValue <= 0 then
        sendNotification("PROCCESS FINISHED :// BOSS KILLED SUCCESSFULLY", "You just killed Son of Rowan", 4, "success")
        updateStatus("Status: Boss defeated")
        isProcessing = false
        isBossFound = false
        stopBossTracking()
    end
end

-- Function to start tracking the boss
local function startBossTracking()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    local lastToggleTime = 0
    local lastSearchTime = 0
    
    connection = RunService.Heartbeat:Connect(function()
        -- Use pcall to prevent script errors from showing
        local currentTime = tick()
        
        -- Only search for boss every 0.5 seconds to reduce performance impact
        if currentTime - lastSearchTime < 0.5 then return end
        lastSearchTime = currentTime
        
        pcall(function()
            if not isEnabled then return end
            
            bossModel = findBoss()
            
            if not bossModel then return end
            
            if currentTime - lastToggleTime >= 6.5 then
                toggleRigType()
                lastToggleTime = currentTime
            end
            
            local distance = getDistanceToBoss()
            updateStatus("Status: Tracking boss (" .. math.floor(distance) .. "m/" .. DISTANCE_THRESHOLD .. "m)")
        end)
    end)
end

-- Function to stop tracking the boss
local function stopBossTracking()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    isProcessing = false
    updateStatus("Status: Idle")
end

-- Make sure this function is defined and accessible 
_G.stopBossTracking = stopBossTracking

-- Initialize the script (wrapped in pcall to prevent errors)
pcall(function()
    local gui = createGUI()
    local toggleButton = gui.Frame:FindFirstChild("ToggleButton")
    
    -- Toggle button functionality
    toggleButton.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        
        if isEnabled then
            toggleButton.Text = "Auto Kill: ON"
            toggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            startBossTracking()
            updateStatus("Status: Searching for boss...")
        else
            toggleButton.Text = "Auto Kill: OFF"
            toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            stopBossTracking()
        end
    end)
    
    -- Handle player character respawning
    player.CharacterAdded:Connect(function(char)
        if isEnabled then
            -- Wait a moment for character to fully load
            task.wait(1)
            pcall(startBossTracking)
        end
    end)
end)

-- Create a watchdog to ensure the script runs without errors
spawn(function()
    while true do
        task.wait(5)
        pcall(function()
            if isEnabled and not connection then
                startBossTracking()
            end
        end)
    end
end)

-- Print success message to console
print("Son of Rowan Killer script loaded successfully!")
