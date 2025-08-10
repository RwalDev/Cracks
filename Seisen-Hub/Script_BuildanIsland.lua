local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local Window = Library:CreateWindow({
    Title = "Seisen Hub",
    Footer = "Build a Island",
    ToggleKeybind = Enum.KeyCode.LeftAlt,
    Center = true,
    AutoShow = true,
    ShowCustomCursor = true -- Enable custom cursor
})

local MainTab = Window:AddTab("Main", "home")
local SettingsTab = Window:AddTab("Settings", "settings", "Customize the UI")
local UICustomGroup = SettingsTab:AddLeftGroupbox("UI Customization", "paintbrush")
local InfoGroup = SettingsTab:AddLeftGroupbox("Script Information", "info")

InfoGroup:AddLabel("Script by: Seisen")
InfoGroup:AddLabel("Version: 2.0.0")
InfoGroup:AddLabel("Game: Build a Island")

InfoGroup:AddButton("Join Discord", function()
    setclipboard("https://discord.gg/F4sAf6z8Ph")
end)

-- Mobile detection and UI adjustments
if Library.IsMobile then
    UICustomGroup:AddLabel("📱 Mobile Device Detected")
    UICustomGroup:AddLabel("UI optimized for mobile")
else
    UICustomGroup:AddLabel("🖥️ Desktop Device Detected")
end

-- Custom Cursor Toggle
UICustomGroup:AddToggle("CustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Tooltip = "Enable/disable the custom cursor design",
    Callback = function(value)
        Library.ShowCustomCursor = value
    end
})

-- UI Scale dropdown for mobile compatibility
UICustomGroup:AddDropdown("UIScale", {
    Text = "UI Scale",
    Values = {"75%", "100%", "125%", "150%"},
    Default = 2, -- 100%
    Tooltip = "Adjust UI size for better mobile experience",
    Callback = function(value)
        local scaleMap = {
            ["75%"] = 75,
            ["100%"] = 100,
            ["125%"] = 125,
            ["150%"] = 150
        }
        
        -- Disable the library's watermark before scaling
        Library:SetWatermarkVisibility(false)
        
        -- Apply DPI scale to UI only
        Library:SetDPIScale(scaleMap[value])
        
        -- Don't re-enable the library watermark - we'll use our custom one
    end
})

-- Custom Watermark setup (independent of UI scaling)
local CoreGui = game:GetService("CoreGui")

-- Create independent watermark ScreenGui
local WatermarkGui = Instance.new("ScreenGui")
WatermarkGui.Name = "SeisenWatermark"
WatermarkGui.DisplayOrder = 999999
WatermarkGui.IgnoreGuiInset = true
WatermarkGui.ResetOnSpawn = false
WatermarkGui.Parent = CoreGui

-- Create watermark frame (main container)
local WatermarkFrame = Instance.new("Frame")
WatermarkFrame.Name = "WatermarkFrame"
WatermarkFrame.Size = UDim2.new(0, 100, 0, 120) -- Taller container for vertical layout
WatermarkFrame.Position = UDim2.new(0, 10, 0, 100) -- Default position (lower)
WatermarkFrame.BackgroundTransparency = 1 -- Transparent container
WatermarkFrame.BorderSizePixel = 0
WatermarkFrame.Parent = WatermarkGui

-- Create perfect circular logo frame
local CircleFrame = Instance.new("Frame")
CircleFrame.Name = "CircleFrame"
CircleFrame.Size = UDim2.new(0, 60, 0, 60) -- Perfect square = perfect circle
CircleFrame.Position = UDim2.new(0.5, -30, 0, 0) -- Centered horizontally at top
CircleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
CircleFrame.BorderSizePixel = 0
CircleFrame.Parent = WatermarkFrame

-- Create circular corner (makes it a perfect circle)
local WatermarkCorner = Instance.new("UICorner")
WatermarkCorner.CornerRadius = UDim.new(0.5, 0) -- 50% radius = perfect circle
WatermarkCorner.Parent = CircleFrame

-- Create custom logo/image
local WatermarkImage = Instance.new("ImageLabel")
WatermarkImage.Name = "WatermarkImage"
WatermarkImage.Size = UDim2.new(1, 0, 1, 0) -- Fill the entire circle frame
WatermarkImage.Position = UDim2.new(0, 0, 0, 0) -- Cover the entire circle
WatermarkImage.BackgroundTransparency = 1
WatermarkImage.ImageColor3 = Color3.fromRGB(255, 255, 255) -- White tint
WatermarkImage.ScaleType = Enum.ScaleType.Crop -- Crop to fill the circle
WatermarkImage.Parent = CircleFrame

-- Make the image circular to match the frame
local ImageCorner = Instance.new("UICorner")
ImageCorner.CornerRadius = UDim.new(0.5, 0) -- Same circular radius as the frame
ImageCorner.Parent = WatermarkImage

-- Try multiple image formats for better compatibility
local imageFormats = {
    "rbxassetid://121631680891470",
    "http://www.roblox.com/asset/?id=121631680891470",
    "rbxasset://textures/ui/GuiImagePlaceholder.png" -- Fallback image
}

-- Function to try loading the image
local function tryLoadImage()
    for i, imageId in ipairs(imageFormats) do
        WatermarkImage.Image = imageId
        
        -- Wait a bit to see if image loads
        task.wait(0.5)
        
        -- Check if image loaded (non-zero size means it loaded)
        if WatermarkImage.AbsoluteSize.X > 0 and WatermarkImage.AbsoluteSize.Y > 0 then
            break
        elseif i == #imageFormats then
            -- If all formats fail, use a text fallback
            WatermarkImage.Image = ""
            
            -- Create text fallback
            local FallbackText = Instance.new("TextLabel")
            FallbackText.Size = UDim2.new(1, 0, 1, 0)
            FallbackText.Position = UDim2.new(0, 0, 0, 0)
            FallbackText.BackgroundTransparency = 1
            FallbackText.Text = "S"
            FallbackText.TextColor3 = Color3.fromRGB(125, 85, 255) -- Accent color
            FallbackText.TextSize = 24
            FallbackText.Font = Enum.Font.GothamBold
            FallbackText.TextXAlignment = Enum.TextXAlignment.Center
            FallbackText.TextYAlignment = Enum.TextYAlignment.Center
            FallbackText.Parent = CircleFrame
        end
    end
end

-- Try loading the image
task.spawn(tryLoadImage)

-- Create Hub Name text
local HubNameText = Instance.new("TextLabel")
HubNameText.Name = "HubNameText"
HubNameText.Size = UDim2.new(1, 0, 0, 20)
HubNameText.Position = UDim2.new(0, 0, 0, 65) -- Below the circle
HubNameText.BackgroundTransparency = 1
HubNameText.Text = "Seisenhub"
HubNameText.TextColor3 = Color3.fromRGB(255, 255, 255)
HubNameText.TextSize = 14
HubNameText.Font = Enum.Font.GothamBold
HubNameText.TextXAlignment = Enum.TextXAlignment.Center
HubNameText.TextYAlignment = Enum.TextYAlignment.Center
HubNameText.TextStrokeTransparency = 0.5
HubNameText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
HubNameText.Parent = WatermarkFrame

-- Create FPS text
local FPSText = Instance.new("TextLabel")
FPSText.Name = "FPSText"
FPSText.Size = UDim2.new(1, 0, 0, 16)
FPSText.Position = UDim2.new(0, 0, 0, 85) -- Below hub name
FPSText.BackgroundTransparency = 1
FPSText.Text = "60 fps"
FPSText.TextColor3 = Color3.fromRGB(200, 200, 200)
FPSText.TextSize = 12
FPSText.Font = Enum.Font.Code
FPSText.TextXAlignment = Enum.TextXAlignment.Center
FPSText.TextYAlignment = Enum.TextYAlignment.Center
FPSText.TextStrokeTransparency = 0.5
FPSText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
FPSText.Parent = WatermarkFrame

-- Create Ping text
local PingText = Instance.new("TextLabel")
PingText.Name = "PingText"
PingText.Size = UDim2.new(1, 0, 0, 16)
PingText.Position = UDim2.new(0, 0, 0, 101) -- Below FPS
PingText.BackgroundTransparency = 1
PingText.Text = "60 ms"
PingText.TextColor3 = Color3.fromRGB(200, 200, 200)
PingText.TextSize = 12
PingText.Font = Enum.Font.Code
PingText.TextXAlignment = Enum.TextXAlignment.Center
PingText.TextYAlignment = Enum.TextYAlignment.Center
PingText.TextStrokeTransparency = 0.5
PingText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
PingText.Parent = WatermarkFrame

-- Make watermark draggable
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local dragging = false
local dragStart = nil
local startPos = nil

-- Mouse/touch input for dragging and UI toggle
local dragThreshold = 5 -- Pixels moved before considering it a drag
local clickStartPos = nil

-- Global input connections for better drag handling
local inputBeganConnection = nil
local inputChangedConnection = nil
local inputEndedConnection = nil

local function onInputBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false -- Reset dragging state
        dragStart = input.Position
        clickStartPos = input.Position
        startPos = WatermarkFrame.Position
        
        -- Visual feedback - slightly fade the circle frame
        local fadeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local fadeTween = TweenService:Create(CircleFrame, fadeInfo, {BackgroundTransparency = 0.3})
        fadeTween:Play()
        
        -- Connect global input events for smooth dragging
        if inputChangedConnection then inputChangedConnection:Disconnect() end
        if inputEndedConnection then inputEndedConnection:Disconnect() end
        
        inputChangedConnection = UserInputService.InputChanged:Connect(function(globalInput)
            if globalInput.UserInputType == Enum.UserInputType.MouseMovement or globalInput.UserInputType == Enum.UserInputType.Touch then
                if dragStart then
                    local delta = globalInput.Position - dragStart
                    local distance = math.sqrt(delta.X^2 + delta.Y^2)
                    
                    -- Only start dragging if moved beyond threshold
                    if distance > dragThreshold then
                        dragging = true
                        WatermarkFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                    end
                end
            end
        end)
        
        inputEndedConnection = UserInputService.InputEnded:Connect(function(globalInput)
            if globalInput.UserInputType == Enum.UserInputType.MouseButton1 or globalInput.UserInputType == Enum.UserInputType.Touch then
                -- Restore original transparency
                local restoreInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local restoreTween = TweenService:Create(CircleFrame, restoreInfo, {BackgroundTransparency = 0})
                restoreTween:Play()
                
                -- If it wasn't a drag, treat it as a click to toggle UI
                if not dragging and clickStartPos then
                    local delta = globalInput.Position - clickStartPos
                    local distance = math.sqrt(delta.X^2 + delta.Y^2)
                    
                    if distance <= dragThreshold then
                        -- Toggle UI visibility
                        Library:Toggle()
                    end
                end
                
                -- Reset states and disconnect global events
                dragging = false
                dragStart = nil
                clickStartPos = nil
                
                if inputChangedConnection then inputChangedConnection:Disconnect() end
                if inputEndedConnection then inputEndedConnection:Disconnect() end
            end
        end)
    end
end

-- Connect only the initial input event to the watermark frame
WatermarkFrame.InputBegan:Connect(onInputBegan)

-- Dynamic watermark with FPS and Ping (completely independent)
local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter = FrameCounter + 1

    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end

    -- Update custom watermark text
    pcall(function()
        local pingValue = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()
        
        -- Update individual text elements
        FPSText.Text = math.floor(FPS) .. " fps"
        PingText.Text = math.floor(pingValue) .. " ms"
        
        -- No need to resize frame - it's now fixed size for vertical layout
    end)
end)

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

-- Set up global running state
getgenv().SeisenHubRunning = true

local configFolder = "SeisenHub"
local configFile = configFolder .. "/seisen_hub_bai.txt"
local HttpService = game:GetService("HttpService")

-- Ensure folder exists
if not isfolder(configFolder) then
    makefolder(configFolder)
end

-- Player
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
-- Character respawn handler
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end)

-- Remote
local HitResource = ReplicatedStorage.Communication.HitResource
local RewardChestClaimRequest = ReplicatedStorage.Communication.RewardChestClaimRequest
local Craft = ReplicatedStorage.Communication.Craft
local DoubleCraft = ReplicatedStorage.Communication.DoubleCraft
local ClaimTimedReward = ReplicatedStorage.Communication.ClaimTimedReward
-- Initialize variables with explicit defaults
local config = getgenv().SeisenHubBuildAPlotConfig or {}

-- Individual variables like AnimeEternal structure
local killAuraEnabled = false
local autoRainbowEnabled = false
local autoSawmillEnabled = false
local autoWorkshopEnabled = false
local autoStonecutterEnabled = false
local autoClaimRewardEnabled = false
local worldTreeEventEnabled = false
local autoClaimDailyEnabled = false
local autoBambooPlankEnabled = false
local autoBuyEggEnabled = false
local autoBuyCrateEnabled = false
local autoHaybaleEnabled = false
local autoFurnaceEnabled = false
local autoCactusLoomEnabled = false
local autoCementEnabled = false
local autoToolsmithEnabled = false
local autoCraftingTimeEnabled = false
local autoRegrowthTimeEnabled = false
local autoSpeedBoostEnabled = false
local autoCropGrowthEnabled = false
local autoGoldenChanceEnabled = false
local autoOfflineEarningsEnabled = false
local autoBeeHiveSpeedEnabled = false
local autoCollectorTimeEnabled = false
local autoFishCrateCapacityEnabled = false
local autoHarvestEnabled = false
local customCursorEnabled = true
local killAuraRange = 15



-- Save config function
local function saveConfig()
    config.killAuraEnabled = killAuraEnabled
    config.killAuraRange = killAuraRange
    config.autoRainbowEnabled = autoRainbowEnabled
    config.autoSawmillEnabled = autoSawmillEnabled
    config.autoWorkshopEnabled = autoWorkshopEnabled
    config.autoStonecutterEnabled = autoStonecutterEnabled
    config.autoClaimRewardEnabled = autoClaimRewardEnabled
    config.worldTreeEventEnabled = worldTreeEventEnabled
    config.autoClaimDailyEnabled = autoClaimDailyEnabled
    config.autoBambooPlankEnabled = autoBambooPlankEnabled
    config.autoBuyEggEnabled = autoBuyEggEnabled
    config.autoBuyCrateEnabled = autoBuyCrateEnabled
    config.autoHaybaleEnabled = autoHaybaleEnabled
    config.autoFurnaceEnabled = autoFurnaceEnabled
    config.autoCactusLoomEnabled = autoCactusLoomEnabled
    config.autoCementEnabled = autoCementEnabled
    config.autoToolsmithEnabled = autoToolsmithEnabled
    config.autoCraftingTimeEnabled = autoCraftingTimeEnabled
    config.autoRegrowthTimeEnabled = autoRegrowthTimeEnabled
    config.autoSpeedBoostEnabled = autoSpeedBoostEnabled
    config.autoCropGrowthEnabled = autoCropGrowthEnabled
    config.autoGoldenChanceEnabled = autoGoldenChanceEnabled
    config.autoOfflineEarningsEnabled = autoOfflineEarningsEnabled
    config.autoBeeHiveSpeedEnabled = autoBeeHiveSpeedEnabled
    config.autoCollectorTimeEnabled = autoCollectorTimeEnabled
    config.autoFishCrateCapacityEnabled = autoFishCrateCapacityEnabled
    config.autoHarvestEnabled = autoHarvestEnabled
    config.customCursorEnabled = customCursorEnabled
    
    getgenv().SeisenHubBuildAPlotConfig = config
    writefile(configFile, HttpService:JSONEncode(config))
end

-- Load config function
local function loadConfig()
    if isfile(configFile) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(configFile))
        end)
        if ok and type(data) == "table" then
            for k, v in pairs(data) do
                config[k] = v
            end
        end
    end
    
    -- Load values into individual variables
    killAuraEnabled = config.killAuraEnabled or false
    killAuraRange = config.killAuraRange or 15
    autoRainbowEnabled = config.autoRainbowEnabled or false
    autoSawmillEnabled = config.autoSawmillEnabled or false
    autoWorkshopEnabled = config.autoWorkshopEnabled or false
    autoStonecutterEnabled = config.autoStonecutterEnabled or false
    autoClaimRewardEnabled = config.autoClaimRewardEnabled or false
    worldTreeEventEnabled = config.worldTreeEventEnabled or false
    autoClaimDailyEnabled = config.autoClaimDailyEnabled or false
    autoBambooPlankEnabled = config.autoBambooPlankEnabled or false
    autoBuyEggEnabled = config.autoBuyEggEnabled or false
    autoBuyCrateEnabled = config.autoBuyCrateEnabled or false
    autoHaybaleEnabled = config.autoHaybaleEnabled or false
    autoFurnaceEnabled = config.autoFurnaceEnabled or false
    autoCactusLoomEnabled = config.autoCactusLoomEnabled or false
    autoCementEnabled = config.autoCementEnabled or false
    autoToolsmithEnabled = config.autoToolsmithEnabled or false
    autoCraftingTimeEnabled = config.autoCraftingTimeEnabled or false
    autoRegrowthTimeEnabled = config.autoRegrowthTimeEnabled or false
    autoSpeedBoostEnabled = config.autoSpeedBoostEnabled or false
    autoCropGrowthEnabled = config.autoCropGrowthEnabled or false
    autoGoldenChanceEnabled = config.autoGoldenChanceEnabled or false
    autoOfflineEarningsEnabled = config.autoOfflineEarningsEnabled or false
    autoBeeHiveSpeedEnabled = config.autoBeeHiveSpeedEnabled or false
    autoCollectorTimeEnabled = config.autoCollectorTimeEnabled or false
    autoFishCrateCapacityEnabled = config.autoFishCrateCapacityEnabled or false
    autoHarvestEnabled = config.autoHarvestEnabled or false
    customCursorEnabled = config.customCursorEnabled ~= nil and config.customCursorEnabled or true
end

-- Auto-save config when values change
local function autoSaveConfig()
    saveConfig()
end

-- Cleanup function
local function cleanupEverything()
    -- Set all enabled states to false
    killAuraEnabled = false
    autoRainbowEnabled = false
    autoSawmillEnabled = false
    autoWorkshopEnabled = false
    autoStonecutterEnabled = false
    autoClaimRewardEnabled = false
    worldTreeEventEnabled = false
    autoClaimDailyEnabled = false
    autoBambooPlankEnabled = false
    autoBuyEggEnabled = false
    autoBuyCrateEnabled = false
    autoHaybaleEnabled = false
    autoFurnaceEnabled = false
    autoCactusLoomEnabled = false
    autoCementEnabled = false
    autoToolsmithEnabled = false
    autoCraftingTimeEnabled = false
    autoRegrowthTimeEnabled = false
    autoSpeedBoostEnabled = false
    autoCropGrowthEnabled = false
    autoGoldenChanceEnabled = false
    autoOfflineEarningsEnabled = false
    autoBeeHiveSpeedEnabled = false
    autoCollectorTimeEnabled = false
    autoFishCrateCapacityEnabled = false
    autoHarvestEnabled = false
    customCursorEnabled = true
    
    _G.HoldingTool = nil
    _G.ToolType = nil
end

-- Auto Buy Crate Function
local function startAutoBuyCrate()
    task.spawn(function()
        while getgenv().SeisenHubRunning and autoBuyCrateEnabled do
            -- Check if enough time has passed since last purchase
            task.wait(5) -- 5 second delay
            
            -- Buy Magical Crate
            pcall(function()
                local args = {
                    [1] = "Magical Crate";
                    [2] = "1";
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("PurchaseCrateRequest", 9e9):FireServer(unpack(args))
            end)
        end
    end)
end

-- Kill Aura Function
local function startKillAura()
    task.spawn(function()
        while killAuraEnabled and getgenv().SeisenHubRunning do
            if not character or not humanoidRootPart then
                task.wait(0.1)
                continue
            end
            
            local playerPosition = humanoidRootPart.Position
            local hitTargets = {}
            
            -- Check player's plot resources first (prioritize own plot)
            local playerPlot = workspace.Plots:FindFirstChild(player.Name)
            if playerPlot and playerPlot.Resources then
                for _, resource in pairs(playerPlot.Resources:GetChildren()) do
                    if resource:IsA("Model") and resource:GetAttribute("HP") and resource:GetAttribute("HP") > 0 then
                        local distance = (resource:GetPivot().Position - playerPosition).Magnitude
                        if distance <= killAuraRange then
                            table.insert(hitTargets, resource)
                        end
                    end
                end
            end
            
            -- Check shared resources
            for _, resource in pairs(CollectionService:GetTagged("SharedResource")) do
                if resource:GetAttribute("HP") and resource:GetAttribute("HP") > 0 then
                    local distance = (resource:GetPivot().Position - playerPosition).Magnitude
                    if distance <= killAuraRange then
                        table.insert(hitTargets, resource)
                    end
                end
            end
            
            -- Check global resources
            for _, resource in pairs(workspace.GlobalResources:GetChildren()) do
                if resource:IsA("Model") then
                    local distance = (resource:GetPivot().Position - playerPosition).Magnitude
                    if distance <= killAuraRange then
                        table.insert(hitTargets, resource)
                    end
                end
            end
            
            -- Check other plots for resources
            for _, plot in pairs(workspace.Plots:GetChildren()) do
                if plot:IsA("Model") and plot.Resources and plot ~= playerPlot then
                    for _, resource in pairs(plot.Resources:GetChildren()) do
                        if resource:IsA("Model") and resource:GetAttribute("HP") and resource:GetAttribute("HP") > 0 then
                            local distance = (resource:GetPivot().Position - playerPosition).Magnitude
                            if distance <= killAuraRange then
                                table.insert(hitTargets, resource)
                            end
                        end
                    end
                end
            end
            
            -- Hit all targets found
            if #hitTargets > 0 then
                for _, target in pairs(hitTargets) do
                    HitResource:FireServer(target)
                end
            end
            
            task.wait(0.1) -- Small delay to prevent spam
        end
    end)
end
-- Auto Rainbow Function
local function startAutoRainbow()
    task.spawn(function()
        -- Teleport to Rainbow Island once when starting
        pcall(function()
            local rainbowIsland = workspace.RainbowIsland.FloatingIsland.Base.Land:GetChildren()[12]
            if rainbowIsland then
                humanoidRootPart.CFrame = rainbowIsland.CFrame + Vector3.new(0,10, 0)
            end
        end)
        
        while autoRainbowEnabled and getgenv().SeisenHubRunning do
            -- Only collect the chest (no teleporting in the loop)
            pcall(function()
                RewardChestClaimRequest:FireServer("RainbowIslandShamrockChest")
            end)
            
            task.wait(5) -- 5 second delay
        end
    end)
end
-- Auto Sawmill Function
local function startAutoSawmill()
    task.spawn(function()
        while autoSawmillEnabled and getgenv().SeisenHubRunning do
            -- Find the player's sawmill and craft (exclude workshop S9 and stonecutter S24)
            pcall(function()
                local playerPlot = workspace.Plots:FindFirstChild(player.Name)
                if playerPlot and playerPlot.Land then
                    -- Look for sawmill in the player's plot (exclude S9 and S24 which are workshop and stonecutter)
                    for _, item in pairs(playerPlot.Land:GetDescendants()) do
                        if item.Name == "Crafter" and item:FindFirstChild("Attachment") and 
                           not item.Parent.Name:find("S9") and not item.Parent.Name:find("S24") then
                            Craft:FireServer(item.Attachment)
                            break
                        end
                    end
                end
            end)
            task.wait(3) -- 3 second delay
        end
    end)
end

-- Auto Workshop Function
local function startAutoWorkshop()
    task.spawn(function()
        while autoWorkshopEnabled and getgenv().SeisenHubRunning do
            -- Find the player's workshop and craft
            pcall(function()
                local playerPlot = workspace.Plots:FindFirstChild(player.Name)
                if playerPlot and playerPlot.Land then
                    -- Look for workshop in the player's plot (S9 location for workshop)
                    for _, item in pairs(playerPlot.Land:GetDescendants()) do
                        if item.Name == "Crafter" and item:FindFirstChild("Attachment") and item.Parent.Name:find("S9") then
                            DoubleCraft:FireServer(item.Attachment)
                            break
                        end
                    end
                end
            end)
            task.wait(3) -- 3 second delay
        end
    end)
end

-- Auto Stonecutter Function
local function startAutoStonecutter()
    task.spawn(function()
        while autoStonecutterEnabled and getgenv().SeisenHubRunning do
            -- Find the player's stonecutter and craft
            pcall(function()
                local playerPlot = workspace.Plots:FindFirstChild(player.Name)
                if playerPlot and playerPlot.Land then
                    -- Look for stonecutter in the player's plot (S24 location for stonecutter)
                    for _, item in pairs(playerPlot.Land:GetDescendants()) do
                        if item.Name == "Crafter" and item:FindFirstChild("Attachment") and item.Parent.Name:find("S24") then
                            Craft:FireServer(item.Attachment)
                            break
                        end
                    end
                end
            end)
            task.wait(3) -- 3 second delay
        end
    end)
end
-- Auto Claim Reward Function
local function startAutoClaimReward()
    task.spawn(function()
        while autoClaimRewardEnabled and getgenv().SeisenHubRunning do
            -- Claim all timed rewards from rewardOne to rewardTwelve
            pcall(function()
                local rewards = {
                    "rewardOne", "rewardTwo", "rewardThree", "rewardFour", "rewardFive", "rewardSix",
                    "rewardSeven", "rewardEight", "rewardNine", "rewardTen", "rewardEleven", "rewardTwelve"
                }
                
                for _, reward in pairs(rewards) do
                    ClaimTimedReward:InvokeServer(reward)
                    task.wait(1) -- 1 second delay between individual claims
                end
            end)

            task.wait(60) -- Wait 60 seconds before next full cycle
        end
    end)
end
-- World Tree Event Function
local function startWorldTreeEvent()
    task.spawn(function()
        -- Teleport to World Tree once when starting
        pcall(function()
            local worldTree = workspace.GlobalResources["World Tree"]["0"].Part67
            if worldTree then
                humanoidRootPart.CFrame = worldTree.CFrame + Vector3.new(0, 5, 0)
            end
        end)
        
        while worldTreeEventEnabled and getgenv().SeisenHubRunning do
            -- Generate a unique timestamp similar to your spy capture
            pcall(function()
                local uniqueTimestamp = tick() + math.random() * 0.1 -- Add small random component
                local args = {
                    [1] = uniqueTimestamp;
                }
                
                -- Fire RewardChestClaimRequest
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("RewardChestClaimRequest", 9e9):FireServer(unpack(args))
                
                -- Small delay between calls
                task.wait(0.1)
                
                -- Fire CollectWorldTree with same timestamp
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("CollectWorldTree", 9e9):FireServer(unpack(args))
            end)

            task.wait(2) -- 5 second delay
        end
    end)
end

-- Auto Claim Daily Function
local function startAutoClaimDaily()
    task.spawn(function()
        while autoClaimDailyEnabled and getgenv().SeisenHubRunning do
            -- Claim all daily rewards from 1 to 25
            pcall(function()
                for i = 1, 100 do
                    local args = {
                        [1] = i;
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("ClaimDailyReward", 9e9):FireServer(unpack(args))
                    task.wait(1) -- 2 seconds delay between each daily claim
                end
            end)
            task.wait(30) -- Wait 30 seconds before next attempt
        end
    end)
end

-- Auto Bamboo Plank Function
local function startAutoBambooPlank()
    task.spawn(function()
        while autoBambooPlankEnabled and getgenv().SeisenHubRunning do
            -- Craft bamboo plank at S72 location
            pcall(function()
                local args = {
                    [1] = workspace:WaitForChild("Plots", 9e9):WaitForChild("seisen120", 9e9):WaitForChild("Land", 9e9):WaitForChild("S72", 9e9):WaitForChild("Crafter", 9e9):WaitForChild("Attachment", 9e9);
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("Craft", 9e9):FireServer(unpack(args))
            end)
            task.wait(3) -- 3 second delay
        end
    end)
end

-- Auto Haybale Function
local function startAutoHaybale()
    task.spawn(function()
        while autoHaybaleEnabled and getgenv().SeisenHubRunning do
            -- Craft haybale at S178 location
            pcall(function()
                local args = {
                    [1] = workspace:WaitForChild("Plots", 9e9):WaitForChild("seisen120", 9e9):WaitForChild("Land", 9e9):WaitForChild("S178", 9e9):WaitForChild("Crafter", 9e9):WaitForChild("Attachment", 9e9);
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("Craft", 9e9):FireServer(unpack(args))
            end)
            task.wait(3) -- 3 second delay
        end
    end)
end

-- Auto Furnace Function
local function startAutoFurnace()
    task.spawn(function()
        while autoFurnaceEnabled and getgenv().SeisenHubRunning do
            -- Craft furnace at S23 location
            pcall(function()
                local args = {
                    [1] = workspace:WaitForChild("Plots", 9e9):WaitForChild("seisen120", 9e9):WaitForChild("Land", 9e9):WaitForChild("S23", 9e9):WaitForChild("Crafter", 9e9):WaitForChild("Attachment", 9e9);
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("DoubleCraft", 9e9):FireServer(unpack(args))
            end)
            task.wait(3) -- 3 second delay
        end
    end)
end

-- Auto Cactus Loom Function
local function startAutoCactusLoom()
    task.spawn(function()
        while autoCactusLoomEnabled and getgenv().SeisenHubRunning do
            -- Craft cactus loom at S54 location
            pcall(function()
                local args = {
                    [1] = workspace:WaitForChild("Plots", 9e9):WaitForChild("seisen120", 9e9):WaitForChild("Land", 9e9):WaitForChild("S54", 9e9):WaitForChild("Crafter", 9e9):WaitForChild("Attachment", 9e9);
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("Craft", 9e9):FireServer(unpack(args))
            end)
            task.wait(3) -- 3 second delay
        end
    end)
end

-- Auto Cement Function
local function startAutoCement()
    task.spawn(function()
        while autoCementEnabled and getgenv().SeisenHubRunning do
            -- Craft cement at S281 location
            pcall(function()
                local args = {
                    [1] = workspace:WaitForChild("Plots", 9e9):WaitForChild("seisen120", 9e9):WaitForChild("Land", 9e9):WaitForChild("S281", 9e9):WaitForChild("Crafter", 9e9):WaitForChild("Attachment", 9e9);
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("DoubleCraft", 9e9):FireServer(unpack(args))
            end)
            task.wait(3) -- 3 second delay
        end
    end)
end

-- Auto Toolsmith Function
local function startAutoToolsmith()
    task.spawn(function()
        while autoToolsmithEnabled and getgenv().SeisenHubRunning do
            -- Craft toolsmith at S38 location
            pcall(function()
                local args = {
                    [1] = workspace:WaitForChild("Plots", 9e9):WaitForChild("seisen120", 9e9):WaitForChild("Land", 9e9):WaitForChild("S38", 9e9):WaitForChild("Crafter", 9e9):WaitForChild("Attachment", 9e9);
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("DoubleCraft", 9e9):FireServer(unpack(args))
            end)
            task.wait(3) -- 3 second delay
        end
    end)
end

-- Auto Crafting Time Function
local function startAutoCraftingTime()
    task.spawn(function()
        while autoCraftingTimeEnabled and getgenv().SeisenHubRunning do
            pcall(function()
                local args = {
                    [1] = "CraftingTime";
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("DoGoldUpgrade", 9e9):FireServer(unpack(args))
            end)
            task.wait(5) -- 5 second delay
        end
    end)
end

-- Auto Regrowth Time Function
local function startAutoRegrowthTime()
    task.spawn(function()
        while autoRegrowthTimeEnabled and getgenv().SeisenHubRunning do
            pcall(function()
                local args = {
                    [1] = "RegrowthTime";
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("DoGoldUpgrade", 9e9):FireServer(unpack(args))
            end)
            task.wait(5) -- 5 second delay
        end
    end)
end

-- Auto Speed Boost Function
local function startAutoSpeedBoost()
    task.spawn(function()
        while autoSpeedBoostEnabled and getgenv().SeisenHubRunning do
            pcall(function()
                local args = {
                    [1] = "SpeedBoost";
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("DoGoldUpgrade", 9e9):FireServer(unpack(args))
            end)
            task.wait(5) -- 5 second delay
        end
    end)
end

-- Auto Crop Growth Function
local function startAutoCropGrowth()
    task.spawn(function()
        while autoCropGrowthEnabled and getgenv().SeisenHubRunning do
            pcall(function()
                local args = {
                    [1] = "CropGrowth";
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("DoGoldUpgrade", 9e9):FireServer(unpack(args))
            end)
            task.wait(5) -- 5 second delay
        end
    end)
end

-- Auto Golden Chance Function
local function startAutoGoldenChance()
    task.spawn(function()
        while autoGoldenChanceEnabled and getgenv().SeisenHubRunning do
            pcall(function()
                local args = {
                    [1] = "GoldenChance";
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("DoGoldUpgrade", 9e9):FireServer(unpack(args))
            end)
            task.wait(5) -- 5 second delay
        end
    end)
end

-- Auto Offline Earnings Function
local function startAutoOfflineEarnings()
    task.spawn(function()
        while autoOfflineEarningsEnabled and getgenv().SeisenHubRunning do
            pcall(function()
                local args = {
                    [1] = "OfflineEarnings";
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("DoGoldUpgrade", 9e9):FireServer(unpack(args))
            end)
            task.wait(5) -- 5 second delay
        end
    end)
end

-- Auto Bee Hive Speed Function
local function startAutoBeeHiveSpeed()
    task.spawn(function()
        while autoBeeHiveSpeedEnabled and getgenv().SeisenHubRunning do
            pcall(function()
                local args = {
                    [1] = "BeeHiveSpeed";
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("DoGoldUpgrade", 9e9):FireServer(unpack(args))
            end)
            task.wait(5) -- 5 second delay
        end
    end)
end

-- Auto Collector Time Function
local function startAutoCollectorTime()
    task.spawn(function()
        while autoCollectorTimeEnabled and getgenv().SeisenHubRunning do
            pcall(function()
                local args = {
                    [1] = "CollectorTime";
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("DoGoldUpgrade", 9e9):FireServer(unpack(args))
            end)
            task.wait(5) -- 5 second delay
        end
    end)
end

-- Auto Fish Crate Capacity Function
local function startAutoFishCrateCapacity()
    task.spawn(function()
        while autoFishCrateCapacityEnabled and getgenv().SeisenHubRunning do
            pcall(function()
                local args = {
                    [1] = "FishCrateCapacity";
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("DoGoldUpgrade", 9e9):FireServer(unpack(args))
            end)
            task.wait(5) -- 5 second delay
        end
    end)
end

-- Auto Harvest Function
local function startAutoHarvest()
    task.spawn(function()
        while autoHarvestEnabled and getgenv().SeisenHubRunning do
            -- Harvest all locations from 1 to 25
            pcall(function()
                for i = 1, 25 do
                    local args = {
                        [1] = tostring(i);
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("Communication", 9e9):WaitForChild("Harvest", 9e9):FireServer(unpack(args))
                    task.wait(0.5) -- Small delay between each harvest
                end
            end)
            task.wait(10) -- Wait 10 seconds before next full cycle
        end
    end)
end
-- Load config on startup
loadConfig()

-- Set Library cursor state based on loaded config
Library.ShowCustomCursor = customCursorEnabled

-- Apply saved config to UI flags
task.defer(function()
    repeat task.wait() until Library.Flags
    
    -- Set UI toggles to match saved config
    if Library.Flags.AutoBuyEgg then Library.Flags.AutoBuyEgg:Set(autoBuyEggEnabled) end
    if Library.Flags.AutoBuyCrate then Library.Flags.AutoBuyCrate:Set(autoBuyCrateEnabled) end
    if Library.Flags.KillAura then Library.Flags.KillAura:Set(killAuraEnabled) end
    if Library.Flags.Range then Library.Flags.Range:Set(killAuraRange) end
    if Library.Flags.AutoClaimReward then Library.Flags.AutoClaimReward:Set(autoClaimRewardEnabled) end
    if Library.Flags.AutoClaimDaily then Library.Flags.AutoClaimDaily:Set(autoClaimDailyEnabled) end
    if Library.Flags.AutoSawmill then Library.Flags.AutoSawmill:Set(autoSawmillEnabled) end
    if Library.Flags.AutoWorkshop then Library.Flags.AutoWorkshop:Set(autoWorkshopEnabled) end
    if Library.Flags.AutoStonecutter then Library.Flags.AutoStonecutter:Set(autoStonecutterEnabled) end
    if Library.Flags.AutoBambooPlank then Library.Flags.AutoBambooPlank:Set(autoBambooPlankEnabled) end
    if Library.Flags.AutoHaybale then Library.Flags.AutoHaybale:Set(autoHaybaleEnabled) end
    if Library.Flags.AutoFurnace then Library.Flags.AutoFurnace:Set(autoFurnaceEnabled) end
    if Library.Flags.AutoCactusLoom then Library.Flags.AutoCactusLoom:Set(autoCactusLoomEnabled) end
    if Library.Flags.AutoCement then Library.Flags.AutoCement:Set(autoCementEnabled) end
    if Library.Flags.AutoToolsmith then Library.Flags.AutoToolsmith:Set(autoToolsmithEnabled) end
    if Library.Flags.AutoCraftingTime then Library.Flags.AutoCraftingTime:Set(autoCraftingTimeEnabled) end
    if Library.Flags.AutoRegrowthTime then Library.Flags.AutoRegrowthTime:Set(autoRegrowthTimeEnabled) end
    if Library.Flags.AutoSpeedBoost then Library.Flags.AutoSpeedBoost:Set(autoSpeedBoostEnabled) end
    if Library.Flags.AutoCropGrowth then Library.Flags.AutoCropGrowth:Set(autoCropGrowthEnabled) end
    if Library.Flags.AutoGoldenChance then Library.Flags.AutoGoldenChance:Set(autoGoldenChanceEnabled) end
    if Library.Flags.AutoOfflineEarnings then Library.Flags.AutoOfflineEarnings:Set(autoOfflineEarningsEnabled) end
    if Library.Flags.AutoBeeHiveSpeed then Library.Flags.AutoBeeHiveSpeed:Set(autoBeeHiveSpeedEnabled) end
    if Library.Flags.AutoCollectorTime then Library.Flags.AutoCollectorTime:Set(autoCollectorTimeEnabled) end
    if Library.Flags.AutoFishCrateCapacity then Library.Flags.AutoFishCrateCapacity:Set(autoFishCrateCapacityEnabled) end
    if Library.Flags.AutoHarvest then Library.Flags.AutoHarvest:Set(autoHarvestEnabled) end
    if Library.Flags.AutoRainbow then Library.Flags.AutoRainbow:Set(autoRainbowEnabled) end
    if Library.Flags.WorldTreeEvent then Library.Flags.WorldTreeEvent:Set(worldTreeEventEnabled) end
    if Library.Flags.CustomCursor then Library.Flags.CustomCursor:Set(customCursorEnabled) end
end)

-- Start automation functions if they were enabled
if killAuraEnabled then startKillAura() end
if autoRainbowEnabled then startAutoRainbow() end
if autoSawmillEnabled then startAutoSawmill() end
if autoWorkshopEnabled then startAutoWorkshop() end
if autoStonecutterEnabled then startAutoStonecutter() end
if autoClaimRewardEnabled then startAutoClaimReward() end
if worldTreeEventEnabled then startWorldTreeEvent() end
if autoClaimDailyEnabled then startAutoClaimDaily() end
if autoBambooPlankEnabled then startAutoBambooPlank() end
if autoBuyEggEnabled then startAutoBuyEgg() end
if autoBuyCrateEnabled then startAutoBuyCrate() end
if autoHaybaleEnabled then startAutoHaybale() end
if autoFurnaceEnabled then startAutoFurnace() end
if autoCactusLoomEnabled then startAutoCactusLoom() end
if autoCementEnabled then startAutoCement() end
if autoToolsmithEnabled then startAutoToolsmith() end
if autoCraftingTimeEnabled then startAutoCraftingTime() end
if autoRegrowthTimeEnabled then startAutoRegrowthTime() end
if autoSpeedBoostEnabled then startAutoSpeedBoost() end
if autoCropGrowthEnabled then startAutoCropGrowth() end
if autoGoldenChanceEnabled then startAutoGoldenChance() end
if autoOfflineEarningsEnabled then startAutoOfflineEarnings() end
if autoBeeHiveSpeedEnabled then startAutoBeeHiveSpeed() end
if autoCollectorTimeEnabled then startAutoCollectorTime() end
if autoFishCrateCapacityEnabled then startAutoFishCrateCapacity() end
if autoHarvestEnabled then startAutoHarvest() end

-- Main Group
local MainGroup = MainTab:AddLeftGroupbox("Auto Farm", "target")
-- Essentials Group (below Auto Farm)
local EssentialsGroup = MainTab:AddLeftGroupbox("Essentials", "wrench")
-- Tools Group (below Essentials)
local ToolsGroup = MainTab:AddLeftGroupbox("Tools", "hammer")
-- Auto Events Group (right side)
local AutoEventsGroup = MainTab:AddRightGroupbox("Auto Events", "calendar")
-- Upgrades Group (right side, below Auto Events)
local UpgradesGroup = MainTab:AddRightGroupbox("Upgrades", "trending-up")

MainGroup:AddToggle("AutoBuyEgg", {
    Text = "Auto Buy Egg",
    Default = autoBuyEggEnabled,
    Tooltip = "Automatically buys Egg1 every 5 seconds",
    Callback = function(value)
        autoBuyEggEnabled = value
        if value then startAutoBuyEgg() end
        autoSaveConfig()
    end
})

MainGroup:AddToggle("AutoBuyCrate", {
    Text = "Auto Buy Crate",
    Default = autoBuyCrateEnabled,
    Tooltip = "Automatically buys Magical Crate every 5 seconds",
    Callback = function(value)
        autoBuyCrateEnabled = value
        if value then startAutoBuyCrate() end
        autoSaveConfig()
    end
})

MainGroup:AddToggle("KillAura", {
    Text = "Auto Chop/Mine",
    Default = killAuraEnabled,
    Tooltip = "Automatically hits all resources within range",
    Callback = function(value)
        killAuraEnabled = value
        if value then startKillAura() end
        autoSaveConfig()
    end
})

MainGroup:AddSlider("Range", {
    Text = "Chop/Mine Range",
    Default = killAuraRange,
    Min = 15,
    Max = 30,
    Rounding = 1,
    Compact = false,
    Tooltip = "Set the range for kill aura (in studs)",
    Callback = function(value)
        killAuraRange = value
        autoSaveConfig()
    end
})

MainGroup:AddToggle("AutoClaimReward", {
    Text = "Auto Claim Reward",
    Default = autoClaimRewardEnabled,
    Tooltip = "Automatically claims all timed rewards (rewardOne to rewardTwelve)",
    Callback = function(value)
        autoClaimRewardEnabled = value
        if value then startAutoClaimReward() end
        autoSaveConfig()
    end
})

MainGroup:AddToggle("AutoClaimDaily", {
    Text = "Auto Claim Daily",
    Default = autoClaimDailyEnabled,
    Tooltip = "Automatically claims daily rewards from 1 to 25",
    Callback = function(value)
        autoClaimDailyEnabled = value
        if value then startAutoClaimDaily() end
        autoSaveConfig()
    end
})

MainGroup:AddToggle("AutoHarvest", {
    Text = "Auto Harvest",
    Default = autoHarvestEnabled,
    Tooltip = "Automatically harvests all locations (1-25) every 10 seconds",
    Callback = function(value)
        autoHarvestEnabled = value
        if value then startAutoHarvest() end
        autoSaveConfig()
    end
})

EssentialsGroup:AddToggle("AutoSawmill", {
    Text = "Auto Sawmill",
    Default = autoSawmillEnabled,
    Tooltip = "Automatically crafts with sawmill machines on your plot",
    Callback = function(value)
        autoSawmillEnabled = value
        if value then startAutoSawmill() end
        autoSaveConfig()
    end
})

EssentialsGroup:AddToggle("AutoStonecutter", {
    Text = "Auto Stonecutter",
    Default = autoStonecutterEnabled,
    Tooltip = "Automatically crafts with stonecutter machines on your plot",
    Callback = function(value)
        autoStonecutterEnabled = value
        if value then startAutoStonecutter() end
        autoSaveConfig()
    end
})

EssentialsGroup:AddToggle("AutoBambooPlank", {
    Text = "Auto Bamboo Plank",
    Default = autoBambooPlankEnabled,
    Tooltip = "Automatically crafts bamboo planks at S72 location",
    Callback = function(value)
        autoBambooPlankEnabled = value
        if value then startAutoBambooPlank() end
        autoSaveConfig()
    end
})

EssentialsGroup:AddToggle("AutoHaybale", {
    Text = "Auto Haybale",
    Default = autoHaybaleEnabled,
    Tooltip = "Automatically crafts haybales at S178 location",
    Callback = function(value)
        autoHaybaleEnabled = value
        if value then startAutoHaybale() end
        autoSaveConfig()
    end
})

EssentialsGroup:AddToggle("AutoFurnace", {
    Text = "Auto Furnace",
    Default = autoFurnaceEnabled,
    Tooltip = "Automatically crafts with furnace at S23 location",
    Callback = function(value)
        autoFurnaceEnabled = value
        if value then startAutoFurnace() end
        autoSaveConfig()
    end
})

EssentialsGroup:AddToggle("AutoCactusLoom", {
    Text = "Auto Cactus Loom",
    Default = autoCactusLoomEnabled,
    Tooltip = "Automatically crafts with cactus loom at S54 location",
    Callback = function(value)
        autoCactusLoomEnabled = value
        if value then startAutoCactusLoom() end
        autoSaveConfig()
    end
})

EssentialsGroup:AddToggle("AutoCement", {
    Text = "Auto Cement",
    Default = autoCementEnabled,
    Tooltip = "Automatically crafts cement at S281 location",
    Callback = function(value)
        autoCementEnabled = value
        if value then startAutoCement() end
        autoSaveConfig()
    end
})

ToolsGroup:AddToggle("AutoWorkshop", {
    Text = "Auto Workshop",
    Default = autoWorkshopEnabled,
    Tooltip = "Automatically crafts with workshop machines on your plot",
    Callback = function(value)
        autoWorkshopEnabled = value
        if value then startAutoWorkshop() end
        autoSaveConfig()
    end
})

ToolsGroup:AddToggle("AutoToolsmith", {
    Text = "Auto Toolsmith",
    Default = autoToolsmithEnabled,
    Tooltip = "Automatically crafts with toolsmith at S38 location",
    Callback = function(value)
        autoToolsmithEnabled = value
        if value then startAutoToolsmith() end
        autoSaveConfig()
    end
})

AutoEventsGroup:AddToggle("AutoRainbow", {
    Text = "Rainbow Event",
    Default = autoRainbowEnabled,
    Tooltip = "Automatically teleports to Rainbow Island and collects the chest",
    Callback = function(value)
        autoRainbowEnabled = value
        if value then startAutoRainbow() end
        autoSaveConfig()
    end
})

AutoEventsGroup:AddToggle("WorldTreeEvent", {
    Text = "World Tree Event",
    Default = worldTreeEventEnabled,
    Tooltip = "Automatically teleports to World Tree location",
    Callback = function(value)
        worldTreeEventEnabled = value
        if value then startWorldTreeEvent() end
        autoSaveConfig()
    end
})

UpgradesGroup:AddToggle("AutoCraftingTime", {
    Text = "Auto Crafting Time",
    Default = autoCraftingTimeEnabled,
    Tooltip = "Makes your machines craft items faster",
    Callback = function(value)
        autoCraftingTimeEnabled = value
        if value then startAutoCraftingTime() end
        autoSaveConfig()
    end
})

UpgradesGroup:AddToggle("AutoRegrowthTime", {
    Text = "Auto Regrowth Time",
    Default = autoRegrowthTimeEnabled,
    Tooltip = "Makes trees, rocks, and other resources respawn quicker",
    Callback = function(value)
        autoRegrowthTimeEnabled = value
        if value then startAutoRegrowthTime() end
        autoSaveConfig()
    end
})

UpgradesGroup:AddToggle("AutoSpeedBoost", {
    Text = "Auto Speed Boost",
    Default = autoSpeedBoostEnabled,
    Tooltip = "Makes your character move faster around the map",
    Callback = function(value)
        autoSpeedBoostEnabled = value
        if value then startAutoSpeedBoost() end
        autoSaveConfig()
    end
})

UpgradesGroup:AddToggle("AutoCropGrowth", {
    Text = "Auto Crop Growth",
    Default = autoCropGrowthEnabled,
    Tooltip = "Makes crops like wheat, corn, etc. grow faster",
    Callback = function(value)
        autoCropGrowthEnabled = value
        if value then startAutoCropGrowth() end
        autoSaveConfig()
    end
})

UpgradesGroup:AddToggle("AutoGoldenChance", {
    Text = "Auto Golden Chance",
    Default = autoGoldenChanceEnabled,
    Tooltip = "Increases chance of getting golden resources",
    Callback = function(value)
        autoGoldenChanceEnabled = value
        if value then startAutoGoldenChance() end
        autoSaveConfig()
    end
})

UpgradesGroup:AddToggle("AutoOfflineEarnings", {
    Text = "Auto Offline Earnings",
    Default = autoOfflineEarningsEnabled,
    Tooltip = "Increases earnings while offline",
    Callback = function(value)
        autoOfflineEarningsEnabled = value
        if value then startAutoOfflineEarnings() end
        autoSaveConfig()
    end
})

UpgradesGroup:AddToggle("AutoBeeHiveSpeed", {
    Text = "Auto Honeybee",
    Default = autoBeeHiveSpeedEnabled,
    Tooltip = "Increases bee hive production speed",
    Callback = function(value)
        autoBeeHiveSpeedEnabled = value
        if value then startAutoBeeHiveSpeed() end
        autoSaveConfig()
    end
})

UpgradesGroup:AddToggle("AutoCollectorTime", {
    Text = "Auto Collector Time",
    Default = autoCollectorTimeEnabled,
    Tooltip = "Reduces collector cooldown time",
    Callback = function(value)
        autoCollectorTimeEnabled = value
        if value then startAutoCollectorTime() end
        autoSaveConfig()
    end
})

UpgradesGroup:AddToggle("AutoFishCrateCapacity", {
    Text = "Auto Fish Crate Capacity",
    Default = autoFishCrateCapacityEnabled,
    Tooltip = "Increases fish crate storage capacity",
    Callback = function(value)
        autoFishCrateCapacityEnabled = value
        if value then startAutoFishCrateCapacity() end
        autoSaveConfig()
    end
})




UICustomGroup:AddButton("Unload Script", function()
    -- Stop watermark connection
    if WatermarkConnection then
        WatermarkConnection:Disconnect()
    end
    
    -- Disconnect any remaining global input connections
    if inputChangedConnection then
        inputChangedConnection:Disconnect()
    end
    if inputEndedConnection then
        inputEndedConnection:Disconnect()
    end
    
    -- Remove custom watermark
    if WatermarkGui then
        WatermarkGui:Destroy()
    end
    
    -- Stop all running automation
    getgenv().SeisenHubRunning = false
    
    -- Set all variables to false/nil
    killAuraEnabled = false
    autoRainbowEnabled = false
    autoSawmillEnabled = false
    autoWorkshopEnabled = false
    autoStonecutterEnabled = false
    autoClaimRewardEnabled = false
    worldTreeEventEnabled = false
    autoClaimDailyEnabled = false
    autoBambooPlankEnabled = false
    autoBuyEggEnabled = false
    autoBuyCrateEnabled = false
    autoHaybaleEnabled = false
    autoFurnaceEnabled = false
    autoCactusLoomEnabled = false
    autoCementEnabled = false
    autoToolsmithEnabled = false
    autoCraftingTimeEnabled = false
    autoRegrowthTimeEnabled = false
    autoSpeedBoostEnabled = false
    autoCropGrowthEnabled = false
    autoGoldenChanceEnabled = false
    autoOfflineEarningsEnabled = false
    autoBeeHiveSpeedEnabled = false
    autoCollectorTimeEnabled = false
    autoFishCrateCapacityEnabled = false
    customCursorEnabled = true
    
    -- Clear global variables
    getgenv().SeisenHubBuildAPlotConfig = nil
    _G.HoldingTool = nil
    _G.ToolType = nil
    
    -- Destroy UI
    Library:Unload()
end)
