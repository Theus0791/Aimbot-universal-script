-- Universal Aimbot + ESP (Fixed Flick/Bug to Nothing) - Rayfield GUI
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer and game.Players.LocalPlayer.Character

print("[DEBUG] Carregando versão anti-flick...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Rayfield = nil
local success, err = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield', true))()
end)

if not success or not Rayfield then
    print("[ERRO] Rayfield falhou: " .. tostring(err))
    return
end
print("[DEBUG] Rayfield OK!")

local Window = Rayfield:CreateWindow({
    Name = "Aimbot + ESP Anti-Flick",
    LoadingTitle = "Carregando...",
    LoadingSubtitle = "Fix flick para nada",
    ConfigurationSaving = {Enabled = false}
})

local AimbotTab = Window:CreateTab("Aimbot")
local ESPTab = Window:CreateTab("ESP")

-- Configs
local AimbotEnabled = false
local HoldToAim = true
local FOV = 200
local Smoothness = 0.6
local TeamCheck = true
local WallCheck = true
local ShowFOVCircle = true
local UsePrediction = false
local PredictionStrength = 0.135  -- Ajuste (0.1~0.2 comum)

local ESPEnabled = false
local ShowBox = true
local ShowTracer = true
local ShowName = true
local ShowHealthText = true
local ShowTeamName = false
local ShowHealthBar = true

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.NumSides = 100
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Transparency = 1
fovCircle.Visible = false

RunService.RenderStepped:Connect(function()
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Radius = FOV
    fovCircle.Visible = AimbotEnabled and ShowFOVCircle
end)

-- ESP (mantido igual, sem mudanças aqui)
local ESPHighlights = {}
local ESPDrawings = {}

local function AddESP(player)
    if player == LocalPlayer or ESPHighlights[player] then return end
    
    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(255, 50, 50)
    hl.OutlineColor = Color3.fromRGB(255, 255, 0)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = player.Character
    hl.Parent = player.Character
    ESPHighlights[player] = hl
    
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Filled = false
    box.Transparency = 1
    box.Visible = false
    
    local tracer = Drawing.new("Line")
    tracer.Thickness = 1
    tracer.Color = Color3.fromRGB(255, 255, 0)
    tracer.Transparency = 1
    tracer.Visible = false
    
    local nameTxt = Drawing.new("Text")
    nameTxt.Size = 14
    nameTxt.Color = Color3.fromRGB(255, 255, 255)
    nameTxt.Outline = true
    nameTxt.Center = true
    nameTxt.Visible = false
    
    local healthLine = Drawing.new("Line")
    healthLine.Thickness = 3
    healthLine.Transparency = 1
    healthLine.Visible = false
    
    ESPDrawings[player] = {Box = box, Tracer = tracer, Name = nameTxt, Health = healthLine}
    
    player.CharacterRemoving:Connect(function()
        if ESPHighlights[player] then ESPHighlights[player]:Destroy() ESPHighlights[player] = nil end
        for _, d in pairs(ESPDrawings[player] or {}) do d:Remove() end
        ESPDrawings[player] = nil
    end)
end

local function UpdateESP()
    for _, player in Players:GetPlayers() do
        if not ESPEnabled or player == LocalPlayer or not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then
            if ESPHighlights[player] then ESPHighlights[player].Enabled = false end
            if ESPDrawings[player] then for _, d in pairs(ESPDrawings[player]) do d.Visible = false end end
            continue
        end
        
        if TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        AddESP(player)
        ESPHighlights[player].Enabled = true
        
        local humanoid = player.Character.Humanoid
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        
        local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if onScreen and ESPDrawings[player] then
            local headPos = Camera:WorldToViewportPoint(player.Character.Head.Position + Vector3.new(0,0.5,0))
            local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
            local size = (headPos.Y - legPos.Y) * 1.2
            
            local drawings = ESPDrawings[player]
            
            if ShowBox then
                drawings.Box.Size = Vector2.new(size * 0.6, size)
                drawings.Box.Position = Vector2.new(rootPos.X - drawings.Box.Size.X/2, rootPos.Y - drawings.Box.Size.Y/2)
                drawings.Box.Visible = true
            else
                drawings.Box.Visible = false
            end
            
            if ShowTracer then
                drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                drawings.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                drawings.Tracer.Visible = true
            else
                drawings.Tracer.Visible = false
            end
            
            if ShowName then
                local healthStr = ShowHealthText and " [" .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth) .. "]" or ""
                local teamStr = (ShowTeamName and player.Team and player.Team.Name ~= "") and " (" .. player.Team.Name .. ")" or ""
                drawings.Name.Text = player.Name .. healthStr .. teamStr
                if ShowTeamName and player.Team and player.TeamColor then
                    drawings.Name.Color = player.TeamColor.Color
                else
                    drawings.Name.Color = Color3.fromRGB(255, 255, 255)
                end
                drawings.Name.Position = Vector2.new(rootPos.X, rootPos.Y - size/2 - 20)
                drawings.Name.Visible = true
            else
                drawings.Name.Visible = false
            end
            
            if ShowHealthBar then
                local pct = humanoid.Health / humanoid.MaxHealth
                drawings.Health.Color = Color3.fromRGB(255 * (1-pct), 255 * pct, 0)
                drawings.Health.From = Vector2.new(rootPos.X - drawings.Box.Size.X/2 - 8, rootPos.Y + drawings.Box.Size.Y/2 * (1-pct))
                drawings.Health.To = Vector2.new(rootPos.X - drawings.Box.Size.X/2 - 8, rootPos.Y + drawings.Box.Size.Y/2)
                drawings.Health.Visible = true
            else
                drawings.Health.Visible = false
            end
        else
            for _, d in pairs(ESPDrawings[player]) do d.Visible = false end
        end
    end
end

-- Get Closest (anti-flick: check onScreen + prediction)
local function GetClosest()
    local closest, minDist = nil, FOV
    local mouseLoc = UserInputService:GetMouseLocation()
    
    for _, player in Players:GetPlayers() do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        if TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local part = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        
        local predictedPos = part.Position
        if UsePrediction and player.Character:FindFirstChild("HumanoidRootPart") then
            local vel = player.Character.HumanoidRootPart.Velocity
            predictedPos = part.Position + (vel * PredictionStrength)  -- Ajuste strength pra mais/less prediction
        end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
        if not onScreen then continue end
        
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouseLoc).Magnitude
        if dist < minDist then
            if WallCheck then
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local result = workspace:Raycast(Camera.CFrame.Position, (predictedPos - Camera.CFrame.Position).Unit * 999, rayParams)
                if result and result.Instance:IsDescendantOf(player.Character) then
                    closest = predictedPos  -- Usa predicted pra mirar
                    minDist = dist
                end
            else
                closest = predictedPos
                minDist = dist
            end
        end
    end
    return closest
end

-- Main loop com anti-flick (clamp delta)
RunService.RenderStepped:Connect(function()
    if ESPEnabled then UpdateESP() end
    
    if not AimbotEnabled then return end
    
    if HoldToAim and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    
    local targetPos = GetClosest()
    if targetPos then
        local screenPos = Camera:WorldToViewportPoint(targetPos)
        local mouseLoc = UserInputService:GetMouseLocation()
        local delta = Vector2.new(screenPos.X, screenPos.Y) - mouseLoc
        
        -- Clamp delta pra evitar flicks insanos
        local maxDelta = 150  -- Ajuste se precisar (menor = mais suave, menos flick)
        delta = delta.Unit * math.min(delta.Magnitude, maxDelta)
        
        mousemoverel(delta.X * Smoothness, delta.Y * Smoothness)
    end
end)

-- Aimbot Tab
AimbotTab:CreateToggle({Name = "Aimbot Enabled", CurrentValue = false, Callback = function(v) AimbotEnabled = v end})
AimbotTab:CreateToggle({Name = "Hold RMB to Aim", CurrentValue = true, Callback = function(v) HoldToAim = v end})
AimbotTab:CreateToggle({Name = "Team Check", CurrentValue = true, Callback = function(v) TeamCheck = v end})
AimbotTab:CreateToggle({Name = "Wall Check", CurrentValue = true, Callback = function(v) WallCheck = v end})
AimbotTab:CreateToggle({Name = "Use Prediction (Anti-Lag)", CurrentValue = false, Callback = function(v) UsePrediction = v end})
AimbotTab:CreateToggle({Name = "Show FOV Circle", CurrentValue = true, Callback = function(v) ShowFOVCircle = v end})
AimbotTab:CreateSlider({Name = "FOV Size", Range = {50, 500}, Increment = 10, CurrentValue = FOV, Callback = function(v) FOV = v end})
AimbotTab:CreateSlider({Name = "Smoothness", Range = {0.05, 1}, Increment = 0.05, CurrentValue = Smoothness, Callback = function(v) Smoothness = v end})
AimbotTab:CreateSlider({Name = "Prediction Strength", Range = {0.08, 0.25}, Increment = 0.005, CurrentValue = PredictionStrength, Callback = function(v) PredictionStrength = v end})

-- ESP Tab (igual antes)
ESPTab:CreateToggle({Name = "ESP Enabled", CurrentValue = false, Callback = function(v) ESPEnabled = v end})
ESPTab:CreateToggle({Name = "Team Check", CurrentValue = true, Callback = function(v) TeamCheck = v end})
ESPTab:CreateToggle({Name = "Show Box", CurrentValue = true, Callback = function(v) ShowBox = v end})
ESPTab:CreateToggle({Name = "Show Tracer", CurrentValue = true, Callback = function(v) ShowTracer = v end})
ESPTab:CreateToggle({Name = "Show Name", CurrentValue = true, Callback = function(v) ShowName = v end})
ESPTab:CreateToggle({Name = "Show Health Text", CurrentValue = true, Callback = function(v) ShowHealthText = v end})
ESPTab:CreateToggle({Name = "Show Team Name", CurrentValue = false, Callback = function(v) ShowTeamName = v end})
ESPTab:CreateToggle({Name = "Show Health Bar", CurrentValue = true, Callback = function(v) ShowHealthBar = v end})

Rayfield:Notify({Title="Anti-Flick Ativado!", Content="Prediction + clamp delta pra evitar virar pro nada. Teste com Prediction ON e ajuste strength. Aperte RightShift se GUI sumir.", Duration=10})

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        Rayfield:Toggle()
    end
end)

print("[DEBUG] Anti-flick rodando! Ative Prediction e teste smoothness alto.")
