local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Seisen Hub",
    Footer = "HyperShot",
    ToggleKeybind = Enum.KeyCode.LeftAlt,
    Center = true,
    AutoShow = true,
    MobileButtonsSide = "Left"
})

local MainTab = Window:AddTab("Main", "home")
local SettingsTab = Window:AddTab("Settings", "settings", "Customize the UI")
local LeftGroupbox = MainTab:AddLeftGroupbox("Main Features", "star")
local AddRightGroupbox = MainTab:AddRightGroupbox("Essential Features")
local InfoGroup = SettingsTab:AddLeftGroupbox("Script Information", "info")

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SaveFolder = "SeisenHub"
local SaveFile = SaveFolder .. "/seisen_hub_HS.txt"
if not isfolder(SaveFolder) then makefolder(SaveFolder) end
_G.AimbotFOV = 10 -- adjust this (in pixels) to change FOV radius

getgenv().HypershotConfig = getgenv().HypershotConfig or {}
local config = getgenv().HypershotConfig
local autoSpawnLoop = false
local autoPlaytimeLoop = false
local autoPickUpHealLoop = false
local autoPickUpCoinsLoop = false
local espLoop = false
local espOnlyLoop = false
local aimbotLoop = false
local headLockLoop = false
local rapidFireLoop = false
local autoPickUpWeaponsLoop = false
local autoPickUpAmmoLoop = false
local selectedWeaponName = false
local autoOpenChestLoop = false
local autoSpinLoop = false -- Added for auto spin

local function saveConfig() writefile(SaveFile, HttpService:JSONEncode(config)) end
local function loadConfig()
    if isfile(SaveFile) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(SaveFile)) end)
        if success and type(data) == "table" then for k, v in pairs(data) do config[k] = v end end
    end
end
loadConfig()

-- Drawing API FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.NumSides = 64
FOVCircle.Radius = _G.AimbotFOV
FOVCircle.Color = Color3.fromRGB(0, 255, 0)
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Visible = config.Aimbot or false

config.SelectedWeaponName = config.SelectedWeaponName or "All"
config.AutoSpawn = config.AutoSpawn or false
config.AutoPlaytime = config.AutoPlaytime or false
config.AutoPickUpHeal = config.AutoPickUpHeal or false
config.ESPChams = config.ESPChams or false
config.ESPOnly = config.ESPOnly or false
config.Aimbot = config.Aimbot or false
config.HeadLock = config.HeadLock or false
config.AimbotFOV = config.AimbotFOV or 10
config.RapidFire = config.RapidFire or false
config.AutoPickUpWeapons = config.AutoPickUpWeapons or false
config.AutoPickUpCoins = config.AutoPickUpCoins or false
config.SelectedWeaponName = config.SelectedWeaponName or "All"
config.SelectedChest = config.SelectedChest or "Wooden"
config.AutoOpenChest = config.AutoOpenChest or false
config.AutoSpin = config.AutoSpin or false -- Added for auto spin

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local MobsFolder = Workspace:FindFirstChild("Mobs")
if not MobsFolder then
    warn("Mobs folder not found!")
end

local headLockConnection
local function enableHeadLock()
    headLockConnection = RunService.RenderStepped:Connect(function()
        if headLockLoop then
            -- Check Mobs folder
            if MobsFolder then
                for _, v in MobsFolder:GetChildren() do
                    local localTeam = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Team")
                    local mobTeam = v:GetAttribute("Team")
                    if LocalPlayer.Character and localTeam ~= -1 and mobTeam == localTeam then
                        continue
                    end
                    local head = v:FindFirstChild("Head")
                    if head then
                        head.CFrame = Camera.CFrame + Camera.CFrame.LookVector * 5
                    end
                end
            end

            -- Check Players service (for bots with characters)
            for _, v in Players:GetPlayers() do
                if v == LocalPlayer then
                    continue
                end
                local localTeam = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Team")
                local playerTeam = v.Character and v.Character:GetAttribute("Team")
                if LocalPlayer.Character and localTeam ~= -1 and playerTeam == localTeam then
                    continue
                end
                local head = v.Character and v.Character:FindFirstChild("Head")
                if head then
                    head.CFrame = Camera.CFrame + Camera.CFrame.LookVector * 7
                end
            end

            -- Check workspace for real player models
            for _, playerModel in pairs(Workspace:GetChildren()) do
                if playerModel:IsA("Model") and playerModel:FindFirstChild("Head") then
                    -- Skip if this is a mob
                    if MobsFolder and playerModel.Parent == MobsFolder then
                        continue
                    end
                    
                    local localTeam = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Team")
                    local modelTeam = playerModel:GetAttribute("Team")
                    
                    -- Lock real players (assume they're enemies)
                    local shouldLock = true
                    if localTeam and modelTeam and localTeam == modelTeam and localTeam ~= -1 then
                        shouldLock = false -- Same team, don't lock
                    end
                    
                    if shouldLock then
                        local head = playerModel:FindFirstChild("Head")
                        if head then
                            head.CFrame = Camera.CFrame + Camera.CFrame.LookVector * 6
                        end
                    end
                end
            end
        end
    end)
end

local function disableHeadLock()
    if headLockConnection then
        headLockConnection:Disconnect()
        headLockConnection = nil
    end
end

-- ESP + CHAMS Logic
_G.HeadSize = 10
_G.Disabled = config.ESPChams

local function applyPropertiesToPart(part, isEnemy)
    if part then
        part.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize)
        part.Transparency = 0.7
        part.BrickColor = isEnemy and BrickColor.new("Really red") or BrickColor.new("Bright blue")
        part.Material = Enum.Material.Neon
        part.CanCollide = false
    end
end

local function applyHighlight(model, isEnemy)
    for _, highlight in ipairs(model:GetChildren()) do
        if highlight:IsA("Highlight") and (highlight.Name == "EnemyHighlight" or highlight.Name == "PlayerOutline") then
            highlight:Destroy()
        end
    end
    local highlightName = isEnemy and "EnemyHighlight" or "PlayerOutline"
    local highlight = Instance.new("Highlight")
    highlight.Name = highlightName
    highlight.FillColor = isEnemy and Color3.fromRGB(234, 0, 0) or Color3.fromRGB(0, 0, 255)
    highlight.OutlineColor = isEnemy and Color3.new(255, 0.4, 0.4) or Color3.new(0, 0, 0.4)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = model
    highlight.Parent = model
end

local espConnection
local function enableESP()
    espConnection = RunService.RenderStepped:Connect(function()
        if espLoop then
            -- Check Players service (for bots/mobs with characters)
            for _, player in Players:GetPlayers() do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    pcall(function()
                        local localTeam = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Team")
                        local playerTeam = player.Character and player.Character:GetAttribute("Team")
                        local isEnemy = (localTeam and playerTeam) and localTeam ~= playerTeam and localTeam ~= -1
                        applyPropertiesToPart(player.Character.HumanoidRootPart, isEnemy)
                        applyHighlight(player.Character, isEnemy)
                    end)
                end
            end

            -- Check workspace for real player models (ugc.workspace.playername.hrp)
            for _, playerModel in pairs(Workspace:GetChildren()) do
                if playerModel:IsA("Model") and playerModel:FindFirstChild("HumanoidRootPart") then
                    -- Skip if this is a mob (mobs are handled separately)
                    if MobsFolder and playerModel.Parent == MobsFolder then
                        continue
                    end
                    
                    pcall(function()
                        local localTeam = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Team")
                        local modelTeam = playerModel:GetAttribute("Team")
                        
                        -- Try multiple ways to determine if this is an enemy
                        local isEnemy = false
                        if localTeam and modelTeam then
                            isEnemy = localTeam ~= modelTeam and localTeam ~= -1
                        else
                            -- Fallback: assume it's an enemy if we can't determine team (real players)
                            isEnemy = true
                        end
                        
                        applyPropertiesToPart(playerModel.HumanoidRootPart, isEnemy)
                        applyHighlight(playerModel, isEnemy)
                    end)
                end
            end

            -- Check Mobs folder
            if MobsFolder then
                for _, mob in MobsFolder:GetChildren() do
                    if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") then
                        pcall(function()
                            local localTeam = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Team")
                            local mobTeam = mob:GetAttribute("Team")
                            local isEnemy = (localTeam and mobTeam) and localTeam ~= mobTeam and localTeam ~= -1
                            applyPropertiesToPart(mob.HumanoidRootPart, isEnemy)
                            applyHighlight(mob, isEnemy)
                        end)
                    end
                end
            end
        end
    end)
end

local espOnlyConnection
local function enableESPOnly()
    espOnlyConnection = RunService.RenderStepped:Connect(function()
        if espOnlyLoop then
            -- Check Players service (for bots/mobs with characters)
            for _, player in Players:GetPlayers() do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    pcall(function()
                        local localTeam = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Team")
                        local playerTeam = player.Character and player.Character:GetAttribute("Team")
                        local isEnemy = (localTeam and playerTeam) and localTeam ~= playerTeam and localTeam ~= -1
                        applyHighlight(player.Character, isEnemy)
                    end)
                end
            end

            -- Check workspace for real player models (ugc.workspace.playername.hrp)
            for _, playerModel in pairs(Workspace:GetChildren()) do
                if playerModel:IsA("Model") and playerModel:FindFirstChild("HumanoidRootPart") then
                    -- Skip if this is a mob (mobs are handled separately)
                    if MobsFolder and playerModel.Parent == MobsFolder then
                        continue
                    end
                    
                    pcall(function()
                        local localTeam = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Team")
                        local modelTeam = playerModel:GetAttribute("Team")
                        
                        -- Try multiple ways to determine if this is an enemy
                        local isEnemy = false
                        if localTeam and modelTeam then
                            isEnemy = localTeam ~= modelTeam and localTeam ~= -1
                        else
                            -- Fallback: assume it's an enemy if we can't determine team (real players)
                            isEnemy = true
                        end
                        
                        applyHighlight(playerModel, isEnemy)
                    end)
                end
            end

            -- Check Mobs folder
            if MobsFolder then
                for _, mob in MobsFolder:GetChildren() do
                    if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") then
                        pcall(function()
                            local localTeam = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Team")
                            local mobTeam = mob:GetAttribute("Team")
                            local isEnemy = (localTeam and mobTeam) and localTeam ~= mobTeam and localTeam ~= -1
                            applyHighlight(mob, isEnemy)
                        end)
                    end
                end
            end
        end
    end)
end

local function disableESP()
    if espConnection then
        espConnection:Disconnect()
        espConnection = nil
    end
    -- Clean up highlights from Players service
    for _, player in Players:GetPlayers() do
        if player.Character then
            for _, highlight in ipairs(player.Character:GetChildren()) do
                if highlight:IsA("Highlight") and (highlight.Name == "EnemyHighlight" or highlight.Name == "PlayerOutline") then
                    highlight:Destroy()
                end
            end
        end
    end
    -- Clean up highlights from workspace player models
    for _, playerModel in pairs(Workspace:GetChildren()) do
        if playerModel:IsA("Model") then
            for _, highlight in ipairs(playerModel:GetChildren()) do
                if highlight:IsA("Highlight") and (highlight.Name == "EnemyHighlight" or highlight.Name == "PlayerOutline") then
                    highlight:Destroy()
                end
            end
        end
    end
    -- Clean up highlights from Mobs folder
    if MobsFolder then
        for _, mob in MobsFolder:GetChildren() do
            for _, highlight in ipairs(mob:GetChildren()) do
                if highlight:IsA("Highlight") and (highlight.Name == "EnemyHighlight" or highlight.Name == "PlayerOutline") then
                    highlight:Destroy()
                end
            end
        end
    end
end

local function disableESPOnly()
    if espOnlyConnection then
        espOnlyConnection:Disconnect()
        espOnlyConnection = nil
    end
    -- Clean up highlights from Players service
    for _, player in Players:GetPlayers() do
        if player.Character then
            for _, highlight in ipairs(player.Character:GetChildren()) do
                if highlight:IsA("Highlight") and (highlight.Name == "EnemyHighlight" or highlight.Name == "PlayerOutline") then
                    highlight:Destroy()
                end
            end
        end
    end
    -- Clean up highlights from workspace player models
    for _, playerModel in pairs(Workspace:GetChildren()) do
        if playerModel:IsA("Model") then
            for _, highlight in ipairs(playerModel:GetChildren()) do
                if highlight:IsA("Highlight") and (highlight.Name == "EnemyHighlight" or highlight.Name == "PlayerOutline") then
                    highlight:Destroy()
                end
            end
        end
    end
    -- Clean up highlights from Mobs folder
    if MobsFolder then
        for _, mob in MobsFolder:GetChildren() do
            for _, highlight in ipairs(mob:GetChildren()) do
                if highlight:IsA("Highlight") and (highlight.Name == "EnemyHighlight" or highlight.Name == "PlayerOutline") then
                    highlight:Destroy()
                end
            end
        end
    end
end

function getClosestTarget()
    local closestTarget = nil
    local shortestDistance = math.huge
    local mouseLocation = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mouseLocation.X, mouseLocation.Y)).Magnitude
                if distance < (config.AimbotFOV or 10) and distance < shortestDistance then
                    closestTarget = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestTarget
end

function getClosestEnemyHead()
    local closestHead = nil
    local shortestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()

    -- Check Players service first (for bots/mobs with characters)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            local localTeam = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Team")
            local targetTeam = player.Character and player.Character:GetAttribute("Team")
            local isEnemy = (localTeam and targetTeam) and localTeam ~= targetTeam and localTeam ~= -1

            if onScreen and isEnemy then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < config.AimbotFOV and dist < shortestDistance then
                    closestHead = head
                    shortestDistance = dist
                end
            end
        end
    end

    -- Check workspace for real player models (ugc.workspace.playername.hrp)
    if not closestHead then
        for _, playerModel in ipairs(Workspace:GetChildren()) do
            if playerModel:IsA("Model") and playerModel:FindFirstChild("Head") then
                -- Skip if this is a mob
                if MobsFolder and playerModel.Parent == MobsFolder then
                    continue
                end
                
                local head = playerModel.Head
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                local localTeam = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Team")
                local modelTeam = playerModel:GetAttribute("Team")
                
                -- Assume real players are enemies if we can't determine team
                local isEnemy = true
                if localTeam and modelTeam then
                    isEnemy = localTeam ~= modelTeam and localTeam ~= -1
                end

                if onScreen and isEnemy then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < config.AimbotFOV and dist < shortestDistance then
                        closestHead = head
                        shortestDistance = dist
                    end
                end
            end
        end
    end

    -- Check Mobs folder last
    if not closestHead and MobsFolder then
        for _, mob in ipairs(MobsFolder:GetChildren()) do
            if mob:IsA("Model") and mob:FindFirstChild("Head") then
                local head = mob.Head
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                local localTeam = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Team")
                local mobTeam = mob:GetAttribute("Team")
                local isEnemy = (localTeam and mobTeam) and localTeam ~= mobTeam and localTeam ~= -1

                if onScreen and isEnemy then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < config.AimbotFOV and dist < shortestDistance then
                        closestHead = head
                        shortestDistance = dist
                    end
                end
            end
        end
    end

    return closestHead
end

local aimbotConnection
local function enableAimbot()
    aimbotConnection = RunService.RenderStepped:Connect(function()
        if aimbotLoop then
            local targetHead = getClosestEnemyHead()
            if targetHead then
                local camPos = Camera.CFrame.Position
                local lookAt = targetHead.Position
                local direction = (lookAt - camPos).Unit
                local targetCFrame = CFrame.new(camPos, camPos + direction)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 0.9)
            end
        end
    end)
end

local function disableAimbot()
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
end

local function startAutoSpawn()
    autoSpawnLoop = true
    task.spawn(function()
        while autoSpawnLoop do
            local args = {
                [1] = false;
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Network", 9e9):WaitForChild("Remotes", 9e9):WaitForChild("Spawn", 9e9):FireServer(unpack(args))
            task.wait(1.5)
        end
    end)
end

local function stopAutoSpawn()
    autoSpawnLoop = false
end

local function startAutoPlaytime()
    autoPlaytimeLoop = true
    task.spawn(function()
        while autoPlaytimeLoop do
            for i = 1, 12 do
                local args = { [1] = i }
                print("Trying to claim playtime reward:", i)
                local success, err = pcall(function()
                    game:GetService("ReplicatedStorage"):WaitForChild("Network", 9e9)
                        :WaitForChild("Remotes", 9e9)
                        :WaitForChild("ClaimPlaytimeReward", 9e9)
                        :FireServer(unpack(args))
                end)
                if not success then
                    warn("Failed to claim playtime reward " .. i .. ": " .. tostring(err))
                end
                task.wait(1)
            end
            task.wait(15)
        end
    end)
end

local function stopAutoPlaytime()
    autoPlaytimeLoop = false
end

local function startAutoPickUpHeal()
    autoPickUpHealLoop = true
    task.spawn(function()
        local rs = game:GetService("ReplicatedStorage")
        local network = rs:WaitForChild("Network", 9e9):WaitForChild("Remotes", 9e9):WaitForChild("PickUpHeal", 9e9)
        local healsFolder = workspace:WaitForChild("IgnoreThese", 9e9):WaitForChild("Pickups", 9e9):WaitForChild("Heals", 9e9)

        local function pickUpHeals()
            for _, heal in ipairs(healsFolder:GetChildren()) do
                local args = { heal }
                network:FireServer(unpack(args))
            end
        end

        while autoPickUpHealLoop do
            pickUpHeals()
            task.wait(0.3)
        end
    end)
end

local function stopAutoPickUpHeal()
    autoPickUpHealLoop = false
end

-- Auto Pickup Ammo
local function startAutoPickUpAmmo()
    autoPickUpAmmoLoop = true
    task.spawn(function()
        local rs = game:GetService("ReplicatedStorage")
        local pickUpAmmo = rs:WaitForChild("Network", 9e9):WaitForChild("Remotes", 9e9):WaitForChild("PickUpAmmo", 9e9)
        local ammoFolder = workspace:WaitForChild("IgnoreThese", 9e9):WaitForChild("Pickups", 9e9):WaitForChild("Ammo", 9e9)

        local function pickUpAllAmmo()
            for _, ammo in ipairs(ammoFolder:GetChildren()) do
                if ammo:IsA("Model") or ammo:IsA("Part") then
                    pickUpAmmo:FireServer(ammo)
                end
            end
        end

        while autoPickUpAmmoLoop do
            pickUpAllAmmo()
            task.wait(0.3)
        end
    end)
end

local function stopAutoPickUpAmmo()
    autoPickUpAmmoLoop = false
end

local function enableRapidFire()
    task.spawn(function()
        while rapidFireLoop do
            for _, v in next, getgc(true) do
                if typeof(v) == 'table' and rawget(v, 'Spread') then
                    pcall(function()
                        rawset(v, 'Spread', 0)
                        rawset(v, 'BaseSpread', 0)
                        rawset(v, 'MinCamRecoil', Vector3.new())
                        rawset(v, 'MaxCamRecoil', Vector3.new())
                        rawset(v, 'MinRotRecoil', Vector3.new())
                        rawset(v, 'MaxRotRecoil', Vector3.new())
                        rawset(v, 'MinTransRecoil', Vector3.new())
                        rawset(v, 'MaxTransRecoil', Vector3.new())
                        rawset(v, 'ScopeSpeed', 100)
                    end)
                end
            end
            task.wait(2)
        end
    end)
end

local function startAutoPickUpWeapons()
    autoPickUpWeaponsLoop = true
    task.spawn(function()
        while autoPickUpWeaponsLoop do
            local success, err = pcall(function()
                local weaponFolder = workspace:WaitForChild("IgnoreThese", 9e9)
                    :WaitForChild("Pickups", 9e9):WaitForChild("Weapons", 9e9)

                local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local HumanoidRootPart = character:WaitForChild("HumanoidRootPart")

                for _, weapon in pairs(weaponFolder:GetChildren()) do
                    local center = weapon:FindFirstChild("Center")
                    if center and center:IsA("BasePart") then
                        local prompt = center:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            local distance = (HumanoidRootPart.Position - center.Position).Magnitude
                            if distance <= 25 then
                                if selectedWeaponName == "All" or string.find(weapon.Name:lower(), selectedWeaponName:lower()) then
                                    fireproximityprompt(prompt)
                                    print("Picked up:", weapon.Name)
                                end
                            end
                        end
                    end
                end
            end)
            if not success then
                warn("Auto weapon pickup error:", err)
            end
            task.wait(0.5)
        end
    end)
end

local function stopAutoPickUpWeapons()
    autoPickUpWeaponsLoop = false
end

local function startAutoPickUpCoins()
    autoPickUpCoinsLoop = true
    task.spawn(function()
        local player = Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local lootFolder = workspace:WaitForChild("IgnoreThese", 9e9)
            :WaitForChild("Pickups", 9e9)
            :WaitForChild("Loot", 9e9)

        while autoPickUpCoinsLoop do
            for _, coin in ipairs(lootFolder:GetChildren()) do
                if coin:IsA("BasePart") then
                    local distance = (coin.Position - hrp.Position).Magnitude
                    if distance <= 100 then
                        coin.CFrame = coin.CFrame:Lerp(
                            CFrame.new(hrp.Position + Vector3.new(0, 2, 0)),
                            0.5
                        )
                    end
                end
            end
            task.wait(0.05)
        end
    end)
end

local function stopAutoPickUpCoins()
    autoPickUpCoinsLoop = false
end

local function startAutoOpenChest()
    autoOpenChestLoop = true
    task.spawn(function()
        while autoOpenChestLoop do
            local success, err = pcall(function()
                local args = {
                    [1] = config.SelectedChest,
                    [2] = "Random"
                }
                local result = game:GetService("ReplicatedStorage")
                    :WaitForChild("Network")
                    :WaitForChild("Remotes")
                    :WaitForChild("OpenCase")
                    :InvokeServer(unpack(args))
                print("OpenCase result:", result)
            end)
            if not success then
                warn("Failed to open chest:", err)
            end
            task.wait(5)
        end
    end)
end

local function stopAutoOpenChest()
    autoOpenChestLoop = false
end

local function startAutoSpin()
    autoSpinLoop = true
    task.spawn(function()
        while autoSpinLoop do
            local success, err = pcall(function()
                local args = {}
                local result = game:GetService("ReplicatedStorage")
                    :WaitForChild("Network")
                    :WaitForChild("Remotes")
                    :WaitForChild("SpinWheel")
                    :InvokeServer(unpack(args))
                print("SpinWheel result:", result)
            end)
            if not success then
                warn("Failed to spin wheel:", err)
            end
            task.wait(5) -- Adjustable delay to avoid rate limits
        end
    end)
end

local function stopAutoSpin()
    autoSpinLoop = false
end

RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
end)

-- Toggles
LeftGroupbox:AddToggle("ESPChams", {
    Text = "ESP Chams",
    Default = config.ESPChams,
    Tooltip = "Enable chams + ESP highlights",
    Callback = function(Value)
        config.ESPChams = Value
        espLoop = Value
        _G.Disabled = Value
        if Value then 
            -- Disable ESP Only if ESP Chams is enabled
            if config.ESPOnly then
                config.ESPOnly = false
                espOnlyLoop = false
                disableESPOnly()
            end
            enableESP() 
        else 
            disableESP() 
        end
        saveConfig()
    end
})

LeftGroupbox:AddToggle("ESPOnly", {
    Text = "ESP Only",
    Default = config.ESPOnly,
    Tooltip = "Enable ESP highlights without chams",
    Callback = function(Value)
        config.ESPOnly = Value
        espOnlyLoop = Value
        if Value then 
            -- Disable ESP Chams if ESP Only is enabled
            if config.ESPChams then
                config.ESPChams = false
                espLoop = false
                _G.Disabled = false
                disableESP()
            end
            enableESPOnly() 
        else 
            disableESPOnly() 
        end
        saveConfig()
    end
})

LeftGroupbox:AddToggle("Aimbot", {
    Text = "Aimbot (Head Lock)",
    Default = config.Aimbot,
    Tooltip = "Enable aimbot to lock on head",
    Callback = function(Value)
        config.Aimbot = Value
        aimbotLoop = Value
        FOVCircle.Visible = Value
        if Value then enableAimbot() else disableAimbot() end
        saveConfig()
    end
})

LeftGroupbox:AddSlider("AimbotFOVSlider", {
    Text = "Aimbot FOV",
    Min = 10,
    Max = 300,
    Default = _G.AimbotFOV,
    Rounding = 0,
    Compact = false,
    Tooltip = "Limit aimbot to enemies within this radius from cursor (pixels)",
    Callback = function(Value)
        _G.AimbotFOV = Value
        config.AimbotFOV = Value
        FOVCircle.Radius = Value
        saveConfig()
    end
})

LeftGroupbox:AddToggle("HeadLock", {
    Text = "Head Lock",
    Default = config.HeadLock,
    Tooltip = "Lock enemy and mob heads to camera",
    Callback = function(Value)
        config.HeadLock = Value
        headLockLoop = Value
        if Value then enableHeadLock() else disableHeadLock() end
        saveConfig()
    end
})

LeftGroupbox:AddToggle("RapidFire", {
    Text = "Rapid Fire",
    Default = config.RapidFire,
    Tooltip = "Enables reduced spread and recoil repeatedly",
    Callback = function(Value)
        config.RapidFire = Value
        rapidFireLoop = Value
        if Value then enableRapidFire() end
        saveConfig()
    end
})

local AutoSpawnToggle = LeftGroupbox:AddToggle("AutoSpawn", {
    Text = "Auto Spawn",
    Default = config.AutoSpawn or false,
    Tooltip = "Automatically respawn when you die",
    Callback = function(Value)
        config.AutoSpawn = Value
        if Value then
            startAutoSpawn()
        else
            stopAutoSpawn()
        end
        saveConfig()
    end
})

local AutoPlaytimeToggle = AddRightGroupbox:AddToggle("AutoPlaytime", {
    Text = "Auto Collect Playtime Award",
    Default = config.AutoPlaytime or false,
    Tooltip = "Automatically collects all playtime rewards",
    Callback = function(Value)
        config.AutoPlaytime = Value
        if Value then
            startAutoPlaytime()
        else
            stopAutoPlaytime()
        end
        saveConfig()
    end
})

AddRightGroupbox:AddToggle("AutoPickUpHeal", {
    Text = "Auto Pick Up Heal",
    Default = config.AutoPickUpHeal,
    Tooltip = "Automatically picks up all heals",
    Callback = function(Value)
        config.AutoPickUpHeal = Value
        if Value then
            startAutoPickUpHeal()
        else
            stopAutoPickUpHeal()
        end
        saveConfig()
    end
})


AddRightGroupbox:AddToggle("AutoPickUpAmmo", {
    Text = "Auto Pick Up Ammo",
    Default = false,
    Tooltip = "Automatically picks up all ammo on the ground",
    Callback = function(Value)
        if Value then
            startAutoPickUpAmmo()
        else
            stopAutoPickUpAmmo()
        end
        saveConfig()
    end
})

AddRightGroupbox:AddToggle("AutoPickUpCoins", {
    Text = "Auto Pick Up Coins",
    Default = config.AutoPickUpCoins or false,
    Tooltip = "Automatically attracts coins within range",
    Callback = function(Value)
        config.AutoPickUpCoins = Value
        if Value then
            startAutoPickUpCoins()
        else
            stopAutoPickUpCoins()
        end
        saveConfig()
    end
})

AddRightGroupbox:AddToggle("AutoOpenChest", {
    Text = "Auto Open Chest",
    Default = config.AutoOpenChest,
    Tooltip = "Automatically opens selected chest repeatedly",
    Callback = function(Value)
        config.AutoOpenChest = Value
        if Value then
            startAutoOpenChest()
        else
            stopAutoOpenChest()
        end
        saveConfig()
    end
})

AddRightGroupbox:AddToggle("AutoSpin", {
    Text = "Auto Spin Wheel",
    Default = config.AutoSpin,
    Tooltip = "Automatically spins the wheel repeatedly",
    Callback = function(Value)
        config.AutoSpin = Value
        if Value then
            startAutoSpin()
        else
            stopAutoSpin()
        end
        saveConfig()
    end
})

AddRightGroupbox:AddDropdown("ChestSelector", {
    Values = { "Wooden", "Bronze", "Silver", "Gold", "Diamond" },
    Default = config.SelectedChest,
    Multi = false,
    Text = "Chest Type",
    Tooltip = "Select which chest to auto open",
    Callback = function(value)
        config.SelectedChest = value
        saveConfig()
    end
})

AddRightGroupbox:AddToggle("AutoPickUpWeapons", {
    Text = "Auto Pick Up Weapons",
    Default = config.AutoPickUpWeapons,
    Tooltip = "Automatically picks up nearby weapons within range",
    Callback = function(Value)
        config.AutoPickUpWeapons = Value
        if Value then
            startAutoPickUpWeapons()
        else
            stopAutoPickUpWeapons()
        end
        saveConfig()
    end
})

local selectedWeaponName = config.SelectedWeaponName or "All"

AddRightGroupbox:AddDropdown("WeaponSelector", {
    Values = { "All", "AK", "M4", "Deagle", "Sniper" },
    Default = config.SelectedWeaponName,
    Multi = false,
    Text = "Weapon Filter",
    Tooltip = "Only pick up this weapon (or All)",
    Callback = function(value)
        config.SelectedWeaponName = value
        selectedWeaponName = value
        saveConfig()
    end
})

task.delay(0.5, function()
    if config.AutoSpawn then startAutoSpawn() end
    if config.AutoPlaytime then startAutoPlaytime() end
    if config.AutoPickUpHeal then startAutoPickUpHeal() end
    if config.AutoPickUpWeapons then startAutoPickUpWeapons() end
    if config.ESPChams then
        espLoop = true
        enableESP()
    end
    if config.ESPOnly then
        espOnlyLoop = true
        enableESPOnly()
    end
    if config.Aimbot then
        aimbotLoop = true
        enableAimbot()
    end
    if config.HeadLock then
        headLockLoop = true
        enableHeadLock()
    end
    if config.RapidFire then
        rapidFireLoop = true
        enableRapidFire()
    end
    if config.AutoPickUpCoins then
        autoPickUpCoinsLoop = true
        startAutoPickUpCoins()
    end
    if config.AutoOpenChest then
        autoOpenChestLoop = true
        startAutoOpenChest()
    end
    if config.AutoSpin then
        autoSpinLoop = true
        startAutoSpin()
    end
end)

InfoGroup:AddLabel("Script by: Seisen")
InfoGroup:AddLabel("Version: 1.0.0")
InfoGroup:AddLabel("Game: HyperShot")

InfoGroup:AddButton("Join Discord", function()
    setclipboard("https://discord.gg/F4sAf6z8Ph")
    print("Copied Discord Invite!")
end)

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
WatermarkFrame.Size = UDim2.new(0, 100, 0, 120)
WatermarkFrame.Position = UDim2.new(0, 10, 0, 100)
WatermarkFrame.BackgroundTransparency = 1
WatermarkFrame.BorderSizePixel = 0
WatermarkFrame.Parent = WatermarkGui

-- Create perfect circular logo frame
local CircleFrame = Instance.new("Frame")
CircleFrame.Name = "CircleFrame"
CircleFrame.Size = UDim2.new(0, 60, 0, 60)
CircleFrame.Position = UDim2.new(0.5, -30, 0, 0)
CircleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
CircleFrame.BorderSizePixel = 0
CircleFrame.Parent = WatermarkFrame

-- Create circular corner (makes it a perfect circle)
local WatermarkCorner = Instance.new("UICorner")
WatermarkCorner.CornerRadius = UDim.new(0.5, 0)
WatermarkCorner.Parent = CircleFrame

-- Create custom logo/image
local WatermarkImage = Instance.new("ImageLabel")
WatermarkImage.Name = "WatermarkImage"
WatermarkImage.Size = UDim2.new(1, 0, 1, 0)
WatermarkImage.Position = UDim2.new(0, 0, 0, 0)
WatermarkImage.BackgroundTransparency = 1
WatermarkImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
WatermarkImage.ScaleType = Enum.ScaleType.Crop
WatermarkImage.Parent = CircleFrame

local ImageCorner = Instance.new("UICorner")
ImageCorner.CornerRadius = UDim.new(0.5, 0)
ImageCorner.Parent = WatermarkImage

local imageFormats = {
    "rbxassetid://121631680891470",
    "http://www.roblox.com/asset/?id=121631680891470",
    "rbxasset://textures/ui/GuiImagePlaceholder.png"
}

local function tryLoadImage()
    for i, imageId in ipairs(imageFormats) do
        WatermarkImage.Image = imageId
        task.wait(0.5)
        if WatermarkImage.AbsoluteSize.X > 0 and WatermarkImage.AbsoluteSize.Y > 0 then
            break
        elseif i == #imageFormats then
            WatermarkImage.Image = ""
            local FallbackText = Instance.new("TextLabel")
            FallbackText.Size = UDim2.new(1, 0, 1, 0)
            FallbackText.Position = UDim2.new(0, 0, 0, 0)
            FallbackText.BackgroundTransparency = 1
            FallbackText.Text = "S"
            FallbackText.TextColor3 = Color3.fromRGB(125, 85, 255)
            FallbackText.TextSize = 24
            FallbackText.Font = Enum.Font.GothamBold
            FallbackText.TextXAlignment = Enum.TextXAlignment.Center
            FallbackText.TextYAlignment = Enum.TextYAlignment.Center
            FallbackText.Parent = CircleFrame
        end
    end
end
task.spawn(tryLoadImage)

local HubNameText = Instance.new("TextLabel")
HubNameText.Name = "HubNameText"
HubNameText.Size = UDim2.new(1, 0, 0, 20)
HubNameText.Position = UDim2.new(0, 0, 0, 65)
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

local FPSText = Instance.new("TextLabel")
FPSText.Name = "FPSText"
FPSText.Size = UDim2.new(1, 0, 0, 16)
FPSText.Position = UDim2.new(0, 0, 0, 85)
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

local PingText = Instance.new("TextLabel")
PingText.Name = "PingText"
PingText.Size = UDim2.new(1, 0, 0, 16)
PingText.Position = UDim2.new(0, 0, 0, 101)
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

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local dragging = false
local dragStart = nil
local startPos = nil
local dragThreshold = 5
local clickStartPos = nil
local inputChangedConnection = nil
local inputEndedConnection = nil

local function onInputBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        dragStart = input.Position
        clickStartPos = input.Position
        startPos = WatermarkFrame.Position
        local fadeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local fadeTween = TweenService:Create(CircleFrame, fadeInfo, {BackgroundTransparency = 0.3})
        fadeTween:Play()
        if inputChangedConnection then inputChangedConnection:Disconnect() end
        if inputEndedConnection then inputEndedConnection:Disconnect() end
        inputChangedConnection = UserInputService.InputChanged:Connect(function(globalInput)
            if globalInput.UserInputType == Enum.UserInputType.MouseMovement or globalInput.UserInputType == Enum.UserInputType.Touch then
                if dragStart then
                    local delta = globalInput.Position - dragStart
                    local distance = math.sqrt(delta.X^2 + delta.Y^2)
                    if distance > dragThreshold then
                        dragging = true
                        WatermarkFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                    end
                end
            end
        end)
        inputEndedConnection = UserInputService.InputEnded:Connect(function(globalInput)
            if globalInput.UserInputType == Enum.UserInputType.MouseButton1 or globalInput.UserInputType == Enum.UserInputType.Touch then
                local restoreInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local restoreTween = TweenService:Create(CircleFrame, restoreInfo, {BackgroundTransparency = 0})
                restoreTween:Play()
                if not dragging and clickStartPos then
                    local delta = globalInput.Position - clickStartPos
                    local distance = math.sqrt(delta.X^2 + delta.Y^2)
                    if distance <= dragThreshold then
                        Window:Toggle()
                    end
                end
                dragging = false
                dragStart = nil
                clickStartPos = nil
                if inputChangedConnection then inputChangedConnection:Disconnect() end
                if inputEndedConnection then inputEndedConnection:Disconnect() end
            end
        end)
    end
end
WatermarkFrame.InputBegan:Connect(onInputBegan)

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
    pcall(function()
        local pingValue = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()
        FPSText.Text = math.floor(FPS) .. " fps"
        PingText.Text = math.floor(pingValue) .. " ms"
    end)
end)

UISettingsGroupbox:AddButton("Unload Script", function()
    if WatermarkConnection then WatermarkConnection:Disconnect() end
    if inputChangedConnection then inputChangedConnection:Disconnect() end
    if inputEndedConnection then inputEndedConnection:Disconnect() end
    if WatermarkGui then WatermarkGui:Destroy() end
    Library:Unload()
    print("✅ Seisen Hub completely unloaded.")
end)

local UISettingsGroupbox = SettingsTab:AddLeftGroupbox("UI Settings")
UISettingsGroupbox:AddButton("Unload Script", function()
    autoSpawnLoop = false
    autoPlaytimeLoop = false
    autoPickUpHealLoop = false
    autoPickUpCoinsLoop = false 
    espLoop = false 
    espOnlyLoop = false
    aimbotLoop = false 
    headLockLoop = false
    rapidFireLoop = false
    autoPickUpWeaponsLoop = false
    autoOpenChestLoop = false
    autoSpinLoop = false -- Added for auto spin

    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end

    disableESP()
    disableESPOnly()
    disableHeadLock()

    for _, player in Players:GetPlayers() do
        if player.Character then
            for _, v in ipairs(player.Character:GetChildren()) do
                if v:IsA("Highlight") then
                    v:Destroy()
                end
            end
        end
    end

    if MobsFolder then
        for _, mob in MobsFolder:GetChildren() do
            for _, v in ipairs(mob:GetChildren()) do
                if v:IsA("Highlight") then
                    v:Destroy()
                end
            end
        end
    end

    if FOVCircle then
        FOVCircle.Visible = false
        FOVCircle:Remove()
    end

    table.clear(config)
    if isfile(SaveFile) then
        delfile(SaveFile)
    end

    getgenv().HypershotConfig = nil
    _G.AimbotFOV = nil
    _G.HeadSize = nil
    _G.Disabled = nil

    -- Use Obsidian UI Library's proper unload method
    Library:Unload()

    print("✅ Seisen Hub completely unloaded.")
end)
