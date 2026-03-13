-- Universal Aimbot + ESP (Fixed ESP not hiding on disable) - Rayfield GUI
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer and game.Players.LocalPlayer.Character

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Rayfield
local s, e = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield', true))()
end)
if not s or not Rayfield then
    warn("[ERRO] Rayfield falhou: " .. tostring(e))
    return
end

local Window = Rayfield:CreateWindow({
    Name = "Universal Aimbot + ESP Fixed",
    LoadingTitle = "Carregando...",
    LoadingSubtitle = "ESP agora some ao desativar",
    ConfigurationSaving = {Enabled = false}
})

local AimbotTab = Window:CreateTab("Aimbot")
local ESPTab = Window:CreateTab("ESP")

-- Configs Aimbot (mantido)
local AimbotEnabled = false
local HoldToAim = true
local FOV = 200
local Smoothness = 0.6
local TeamCheck = true
local WallCheck = true
local ShowFOVCircle = true
local UsePrediction = false
local PredictionStrength = 0.135

-- Configs ESP
local ESPEnabled = false
local ShowBox = true
local ShowTracer = true
local ShowName = true
local ShowHealthText = true
local ShowTeamName = false
local ShowHealthBar = true

-- FOV Circle (mantido)
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

-- ESP structures
local ESPHighlights = {}
local ESPDrawings = {}

local function CleanupESP()
    for player, hl in pairs(ESPHighlights) do
        if hl then hl:Destroy() end
        ESPHighlights[player] = nil
    end
    for player, drawings in pairs(ESPDrawings) do
        if drawings then
            for _, d in pairs(drawings) do
                if d then d:Remove() end
            end
        end
        ESPDrawings[player] = nil
    end
end

local function AddESP(player)
    if player == LocalPlayer or ESPHighlights[player] then return end
    local char = player.Character
    if not char then return end

    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(255, 50, 50)
    hl.OutlineColor = Color3.fromRGB(255, 255, 0)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = char
    hl.Enabled = ESPEnabled
    hl.Parent = char
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
        if ESPDrawings[player] then
            for _, d in pairs(ESPDrawings[player]) do d:Remove() end
            ESPDrawings[player] = nil
        end
    end)
end

local function UpdateESP()
    if not ESPEnabled then
        -- Força hide imediato quando off
        for _, player in Players:GetPlayers() do
            if ESPHighlights[player] then ESPHighlights[player].Enabled = false end
            if ESPDrawings[player] then
                for _, d in pairs(ESPDrawings[player]) do d.Visible = false end
            end
        end
        return
    end

    for _, player in Players:GetPlayers() do
        local char = player.Character
        if player == LocalPlayer or not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
            if ESPHighlights[player] then ESPHighlights[player].Enabled = false end
            if ESPDrawings[player] then for _, d in pairs(ESPDrawings[player]) do d.Visible = false end end
            continue
        end

        if TeamCheck and player.Team == LocalPlayer.Team then continue end

        AddESP(player)
        if ESPHighlights[player] then ESPHighlights[player].Enabled = true end

        local humanoid = char.Humanoid
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if onScreen and ESPDrawings[player] then
            local headPos = Camera:WorldToViewportPoint(char.Head.Position + Vector3.new(0,0.5,0))
            local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
            local size = (headPos.Y - legPos.Y) * 1.2

            local d = ESPDrawings[player]

            d.Box.Visible = ShowBox
            if ShowBox then
                d.Box.Size = Vector2.new(size * 0.6, size)
                d.Box.Position = Vector2.new(rootPos.X - d.Box.Size.X/2, rootPos.Y - d.Box.Size.Y/2)
            end

            d.Tracer.Visible = ShowTracer
            if ShowTracer then
                d.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                d.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
            end

            d.Name.Visible = ShowName
            if ShowName then
                local healthStr = ShowHealthText and " [" .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth) .. "]" or ""
                local teamStr = (ShowTeamName and player.Team and player.Team.Name ~= "") and " (" .. player.Team.Name .. ")" or ""
                d.Name.Text = player.Name .. healthStr .. teamStr
                if ShowTeamName and player.Team and player.TeamColor then d.Name.Color = player.TeamColor.Color end
                d.Name.Position = Vector2.new(rootPos.X, rootPos.Y - size/2 - 20)
            end

            d.Health.Visible = ShowHealthBar
            if ShowHealthBar then
                local pct = humanoid.Health / humanoid.MaxHealth
                d.Health.Color = Color3.fromRGB(255 * (1-pct), 255 * pct, 0)
                d.Health.From = Vector2.new(rootPos.X - d.Box.Size.X/2 - 8, rootPos.Y + d.Box.Size.Y/2 * (1-pct))
                d.Health.To = Vector2.new(rootPos.X - d.Box.Size.X/2 - 8, rootPos.Y + d.Box.Size.Y/2)
            end
        else
            for _, dd in pairs(ESPDrawings[player] or {}) do dd.Visible = false end
        end
    end
end

-- GetClosest e loop aimbot (mantido igual, sem mudanças aqui)
local function GetClosest()
    local closest, minDist = nil, FOV
    local mouseLoc = UserInputService:GetMouseLocation()

    for _, player in Players:GetPlayers() do
        if player == LocalPlayer or not player.Character then continue end
        if TeamCheck and player.Team == LocalPlayer.Team then continue end

        local part = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
        if not part then continue end

        local predictedPos = part.Position
        if UsePrediction and player.Character:FindFirstChild("HumanoidRootPart") then
            predictedPos += player.Character.HumanoidRootPart.Velocity * PredictionStrength
        end

        local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouseLoc).Magnitude
        if dist >= minDist then continue end

        local valid = true
        if WallCheck then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            local res = workspace:Raycast(Camera.CFrame.Position, (predictedPos - Camera.CFrame.Position).Unit * 999, rayParams)
            valid = res and res.Instance:IsDescendantOf(player.Character)
        end

        if valid then
            closest = predictedPos
            minDist = dist
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if ESPEnabled then UpdateESP() end

    if not AimbotEnabled then return end
    if HoldToAim and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end

    local targetPos = GetClosest()
    if targetPos then
        local screenPos = Camera:WorldToViewportPoint(targetPos)
        local mouseLoc = UserInputService:GetMouseLocation()
        local delta = Vector2.new(screenPos.X, screenPos.Y) - mouseLoc

        local maxDelta = 150
        if delta.Magnitude > maxDelta then
            delta = delta.Unit * maxDelta
        end

        mousemoverel(delta.X * Smoothness, delta.Y * Smoothness)
    end
end)

-- GUI Aimbot (mantido)
AimbotTab:CreateToggle({Name = "Aimbot Enabled", CurrentValue = false, Callback = function(v) AimbotEnabled = v end})
AimbotTab:CreateToggle({Name = "Hold RMB to Aim", CurrentValue = true, Callback = function(v) HoldToAim = v end})
AimbotTab:CreateToggle({Name = "Team Check", CurrentValue = true, Callback = function(v) TeamCheck = v end})
AimbotTab:CreateToggle({Name = "Wall Check", CurrentValue = true, Callback = function(v) WallCheck = v end})
AimbotTab:CreateToggle({Name = "Use Prediction", CurrentValue = false, Callback = function(v) UsePrediction = v end})
AimbotTab:CreateToggle({Name = "Show FOV Circle", CurrentValue = true, Callback = function(v) ShowFOVCircle = v end})
AimbotTab:CreateSlider({Name = "FOV Size", Range = {50, 500}, Increment = 10, CurrentValue = FOV, Callback = function(v) FOV = v end})
AimbotTab:CreateSlider({Name = "Smoothness", Range = {0.05, 1}, Increment = 0.05, CurrentValue = Smoothness, Callback = function(v) Smoothness = v end})
AimbotTab:CreateSlider({Name = "Prediction Strength", Range = {0.08, 0.25}, Increment = 0.005, CurrentValue = PredictionStrength, Callback = function(v) PredictionStrength = v end})

-- GUI ESP com cleanup no toggle
ESPTab:CreateToggle({
    Name = "ESP Enabled",
    CurrentValue = false,
    Callback = function(v)
        ESPEnabled = v
        if not v then
            CleanupESP()  -- Limpa tudo ao desativar (fix principal)
            Rayfield:Notify({Title="ESP", Content="Desativado e limpo!", Duration=3})
        else
            Rayfield:Notify({Title="ESP", Content="Ativado!", Duration=3})
        end
    end
})
ESPTab:CreateToggle({Name = "Team Check", CurrentValue = true, Callback = function(v) TeamCheck = v end})
ESPTab:CreateToggle({Name = "Show Box", CurrentValue = true, Callback = function(v) ShowBox = v end})
ESPTab:CreateToggle({Name = "Show Tracer", CurrentValue = true, Callback = function(v) ShowTracer = v end})
ESPTab:CreateToggle({Name = "Show Name", CurrentValue = true, Callback = function(v) ShowName = v end})
ESPTab:CreateToggle({Name = "Show Health Text", CurrentValue = true, Callback = function(v) ShowHealthText = v end})
ESPTab:CreateToggle({Name = "Show Team Name", CurrentValue = false, Callback = function(v) ShowTeamName = v end})
ESPTab:CreateToggle({Name = "Show Health Bar", CurrentValue = true, Callback = function(v) ShowHealthBar = v end})

Rayfield:Notify({Title="Fix ESP Bug!", Content="Agora ao desativar ESP, tudo some (Highlight destruído + Drawings hidden). Teste toggle OFF/ON várias vezes.", Duration=10})

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        Rayfield:Toggle()
    end
end)
