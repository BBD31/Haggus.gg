local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/TeamArchie/Linoria-Library/main/Library.lua'))()
local ThemeManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/TeamArchie/Linoria-Library/main/Addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/TeamArchie/Linoria-Library/main/Addons/SaveManager.lua'))()
local Options = getgenv().Linoria and getgenv().Linoria.Options or {}
local Toggles = getgenv().Linoria and getgenv().Linoria.Toggles or {}
local RunService = game:GetService("RunService")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local plr = players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = plr:GetMouse()
local Window = Library:CreateWindow({
    Title = 'Haggus.gg',
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
    TabPadding = 0,
    MenuFadeTime = 0
})
local Tabs = {
    Aim = Window:AddTab('Aim'),
    Vis = Window:AddTab('Visuals'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

Library:SetWatermarkVisibility(true)

local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

-- Оновлення ватермарки
local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter += 1

    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end

    Library:SetWatermark(('Haggus.gg | %s fps | %s ms'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ))
end)

Library.KeybindFrame.Visible = false

-- При вивантаженні
Library:OnUnload(function()
    WatermarkConnection:Disconnect()
    print('Unloaded!')
    Library.Unloaded = true
end)

-- Група для налаштувань меню
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'Delete', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind

-- Ініціалізація менеджерів
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('MyScriptHub')
SaveManager:SetFolder('MyScriptHub/specific-game')

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

SaveManager:LoadAutoloadConfig()

-- Додамо секцію ESP
local ESPGroupBox = Tabs.Vis:AddLeftGroupbox('ESP')
local toggleKey = "E" -- Бінд
local espEnabled = false
local teamCheckEnabled = false -- Перевірка команди
local rainbowESPEnabled = false -- Включення райдужного ESP
local rainbowSpeed = 10-- Швидкість зміни кольору
local boxColor = Color3.fromRGB(255, 128, 128) -- За замовчуванням колір боксів

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

local espBoxes = {}
local rainbowConnection = nil

local function getTeamColor(player)
    if teamCheckEnabled and player.Team then
        return player.TeamColor.Color 
    else
        return boxColor -- Кастомний колір
    end
end

local function createBox(player)
    if espBoxes[player] then return end 

    local box = Drawing.new("Square")
    box.Color = getTeamColor(player)
    box.Thickness = 1 -- Товщина ліній
    box.Filled = false -- Прозорий
    box.Visible = false
    espBoxes[player] = box
end

local function updateBox(player, hue)
    if not espEnabled or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        if espBoxes[player] then
            espBoxes[player].Visible = false
        end
        return
    end

    if player == LocalPlayer then
        if espBoxes[player] then
            espBoxes[player].Visible = false
        end
        return
    end

    local rootPart = player.Character.HumanoidRootPart
    local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

    local box = espBoxes[player]
    if onScreen then
        -- Якщо райдужний ESP увімкнено, застосовуємо плавну зміну кольору
        box.Color = rainbowESPEnabled and Color3.fromHSV(hue / 360, 1, 1) or getTeamColor(player)
        local size = Vector2.new(2000 / rootPos.Z, 3000 / rootPos.Z) 
        box.Size = size
        box.Position = Vector2.new(rootPos.X - size.X / 2, rootPos.Y - size.Y / 2)
        box.Visible = true
    else
        box.Visible = false
    end
end

local function clearBoxes()
    for _, box in pairs(espBoxes) do
        if box then
            box:Remove()
        end
    end
    espBoxes = {}
end

local function toggleESP()
    espEnabled = not espEnabled
    if not espEnabled then
        clearBoxes()
    else
        for _, player in ipairs(Players:GetPlayers()) do
            createBox(player)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if espEnabled then
            createBox(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if espBoxes[player] then
        espBoxes[player]:Remove()
        espBoxes[player] = nil
    end
end)

-- Райдужний ESP (оновлення кольорів)
game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
    if espEnabled then
        local hue = tick() * rainbowSpeed % 360 -- Динамічна зміна кольору
        for _, player in ipairs(Players:GetPlayers()) do
            updateBox(player, hue)
        end
    end
end)

-- Тогл для райдужного ESP
ESPGroupBox:AddToggle('RainbowESP', {
   Text = 'ESP Rainbow',
   Default = false,
   Tooltip = 'ESP Rainbow',
   Callback = function(Value)
       rainbowESPEnabled = Value
   end
})

-- Слайдер для регулювання швидкості райдужного ESP

-- Тогл для стандартного ESP
ESPGroupBox:AddToggle('ESPTOGGLE', {
    Text = 'Toggle ESP',
    Default = false,
    Tooltip = 'Toggle ESP',
    Callback = function(Value)
        toggleESP()
    end
}):AddColorPicker('CoForPicker1', {
    Default = Color3.fromRGB(255, 128, 128),
    Title = 'Box Color',
    Callback = function(Value)
        boxColor = Value -- Оновлення кольору боксів
        for _, box in pairs(espBoxes) do
            if box then
                box.Color = Value
            end
        end
    end
})



local AimGroupBox = Tabs.Aim:AddRightGroupbox('Aim Bot')
local config = {
    TeamCheck = false,
    FOV = 150,
    Smoothing = 1,
    AimPart = "Torso", -- За замовчуванням цільова частина
}

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- GUI
local FOVring = Drawing.new("Circle")
FOVring.Visible = false
FOVring.Thickness = 1.5
FOVring.Radius = config.FOV
FOVring.Transparency = 1
FOVring.Color = Color3.fromRGB(255, 128, 128)
FOVring.Position = workspace.CurrentCamera.ViewportSize / 2
FOVring.Filled = false
-- Function to get the closest visible player
local function getClosestVisiblePlayer(camera)
    local closestPlayer = nil
    local closestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            local character = player.Character
            local targetPart = character and character:FindFirstChild(config.AimPart) -- Цільова частина
            if targetPart then
                -- Team Check
                if config.TeamCheck and player.Team == Players.LocalPlayer.Team then
                    continue
                end

                local partPosition = targetPart.Position
                local screenPosition, onScreen = camera:WorldToViewportPoint(partPosition)
                local distanceToCenter = (Vector2.new(screenPosition.X, screenPosition.Y) - camera.ViewportSize / 2).Magnitude

                if onScreen and distanceToCenter < config.FOV and distanceToCenter < closestDistance then
                    closestDistance = distanceToCenter
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

-- Aimbot toggle
local aimbotEnabled = false
local aimbotConnection = nil

local function toggleAimbot()
    aimbotEnabled = not aimbotEnabled
    FOVring.Visible = aimbotEnabled

    if aimbotEnabled then
        -- Start aiming
        aimbotConnection = RunService.RenderStepped:Connect(function()
            local camera = workspace.CurrentCamera
            local closestPlayer = getClosestVisiblePlayer(camera)

            if closestPlayer then
                local targetPart = closestPlayer.Character:FindFirstChild(config.AimPart)
                if targetPart then
                    local partPosition = targetPart.Position
                    local smoothing = math.clamp(config.Smoothing, 0.01, 10)
                    local targetCFrame = CFrame.new(camera.CFrame.Position, partPosition)
                    camera.CFrame = camera.CFrame:Lerp(targetCFrame, 1 / smoothing)
                end
            end
        end)
    else
        -- Stop aiming
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
    end
end

-- ESP UI Toggles and Callbacks
AimGroupBox:AddToggle('Aim', {
   Text = 'Aim Bot',
   Default = false,
   Tooltip = 'Aim Bot',
   Callback = function(Value)
      toggleAimbot()
   end
}):AddColorPicker('ColorPicker1', {
   Default = Color3.fromRGB(255, 128, 128),
   Title = 'FOV Circle Color',
   Callback = function(Value)
      FOVring.Color = Value
   end
})

AimGroupBox:AddSlider('AimSmoothness', {
   Text = 'Aim Smoothness',
   Default = 1,
   Min = 1,
   Max = 5,
   Rounding = 1,
   Callback = function(Value)
      config.Smoothing = Value
   end
})
AimGroupBox:AddToggle('Aiаm', {
   Text = 'Team Check',
   Default = false,
   Tooltip = 'Team Check',
   Callback = function(Value)
      config.TeamCheck = Value
   end
})
AimGroupBox:AddSlider('AimCircleSize', {
   Text = 'FOV Circle Size',
   Default = 150,
   Min = 25,
   Max = 500,
   Rounding = 1,
   Callback = function(Value)
      config.FOV = Value
      FOVring.Radius = Value
   end
})

AimGroupBox:AddDropdown('aisp', {
   Values = { 'Torso', 'HumanoidRootPart', 'Head' }, -- Варіанти вибору
   Default = 1, 
   Multi = false, 
   Text = 'Aiming Part Selection',
   Tooltip = 'Aiming Part Selection',
   Callback = function(Value)
      config.AimPart = Value -- Оновлюємо цільову частину
   end
})
local AcGroupBox = Tabs.Aim:AddLeftGroupbox('Configs')

AcGroupBox:AddSlider('fsfssd', {
   Text = 'FOV Transparency',
   Default = 1,
   Min = 0,
   Max = 1,
   Rounding = 1,
   Callback = function(Value)
      FOVring.Transparency = Value
   end
})
local FOVUnlocked = false
local FOVConnection = nil 

AcGroupBox:AddToggle('Aisdfggаm', {
   Text = 'FOV Unlocked',
   Default = false,
   Tooltip = 'FOV Unlocked',
   Callback = function(Value)
       FOVUnlocked = Value

       if FOVUnlocked then
           -- Якщо вже є підключення, видаляємо його
           if FOVConnection then
               FOVConnection:Disconnect()
               FOVConnection = nil
           end

           -- Оновлюємо позицію FOV кільця за курсором
           FOVConnection = RunService.RenderStepped:Connect(function()
               local MouseLocation = UserInputService:GetMouseLocation()
               FOVring.Position = MouseLocation
           end)
       else
           -- Якщо вимкнено, відключаємо оновлення та повертаємо в центр екрана
           if FOVConnection then
               FOVConnection:Disconnect()
               FOVConnection = nil
           end
           FOVring.Position = workspace.CurrentCamera.ViewportSize / 2
       end
   end
})
AcGroupBox:AddToggle('Aisdfggаm', {
   Text = 'Filled',
   Default = false,
   Tooltip = 'Filled',
   Callback = function(Value)
        FOVring.Filled = Value
   end
})
local RainbowEnabled = false
local RainbowSpeed = 1
local RainbowConnection = nil
-- Слайдер для регулювання швидкості зміни кольору
AcGroupBox:AddSlider('RainbowSpeed', {
   Text = 'Rainbow Speed',
   Default = 1,
   Min = 0,
   Max = 5, -- Збільшив максимальне значення для кращого контролю
   Rounding = 1,
   Callback = function(Value)
       RainbowSpeed = Value
   end
})
-- Тогл для включення/вимкнення райдужного кольору
AcGroupBox:AddToggle('Aisdfggаm', {
   Text = 'Rainbow',
   Default = false,
   Tooltip = 'Rainbow',
   Callback = function(Value)
       RainbowEnabled = Value

       if RainbowEnabled then
           -- Якщо вже є підключення, видаляємо його
           if RainbowConnection then
               RainbowConnection:Disconnect()
               RainbowConnection = nil
           end

           -- Оновлюємо колір кільця кожен кадр
           local hue = 0
           RainbowConnection = RunService.RenderStepped:Connect(function(deltaTime)
               hue = (hue + RainbowSpeed * deltaTime * 100) % 360 -- Враховуємо FPS
               FOVring.Color = Color3.fromHSV(hue / 360, 1, 1)
           end)
       else
           -- Якщо вимкнено, відключаємо оновлення та повертаємо стандартний колір
           if RainbowConnection then
               RainbowConnection:Disconnect()
               RainbowConnection = nil
           end
           FOVring.Color = Color3.fromRGB(255, 128, 128) -- Початковий колір
       end
   end
})
