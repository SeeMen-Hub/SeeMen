local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local camera = workspace.CurrentCamera

local espModule = {}
espModule.settings = {
    enabled = true,
    dropIn = true,
    showBox = true,
    boxThickness = 2,
    fillBox = true,
    fillBoxColor = Color3.new(0, 0, 0),
    fillTransparency = 0.3,
    showName = true,
    useDisplayName = true,
    showTeamName = true,
    showDistance = true,
    maxTextDistance = 150,
    textSize = 15,
    outlineText = true,
    useTeamColor = true,
    fallbackColor = Color3.new(0.3, 0.5, 1),
    playerOverrides = {},    -- ["PlayerName"] = { enabled=false, showBox=false, tracers=false, ... }
    showHealthBar = true,
    healthBarPosition = "Left",
    tracers = true,
    tracerTransparency = 0.5,
    tracerOrigin = "middle",
}

local bboxOffsets = {
    Vector3.new(1,1,1), Vector3.new(1,1,-1), Vector3.new(1,-1,1), Vector3.new(1,-1,-1),
    Vector3.new(-1,1,1), Vector3.new(-1,1,-1), Vector3.new(-1,-1,1), Vector3.new(-1,-1,-1),
}

local espDrawings = {}

function espModule.createEsp(player)
    local data = {
        lines = {},
        tracer = Drawing.new("Line"),
        nameText = Drawing.new("Text"),
        distanceText = Drawing.new("Text"),
        fillBox = Drawing.new("Square"),
        healthBg = Drawing.new("Square"),
        healthOutline = Drawing.new("Square"),
        healthBar = Drawing.new("Square"),
        originalDisplayDistance = nil,
        originalHealthDisplay = nil,
    }
    -- tracer
    data.tracer.ZIndex = 1
    data.tracer.Visible = false
    data.tracer.Thickness = espModule.settings.boxThickness
    -- corners
    for i = 1, 8 do
        local line = Drawing.new("Line")
        line.ZIndex = 2
        line.Visible = false
        line.Thickness = espModule.settings.boxThickness
        data.lines[i] = line
    end
    -- fill
    data.fillBox.Filled = true
    data.fillBox.Thickness = 0
    data.fillBox.ZIndex = 1
    data.fillBox.Visible = false
    -- name
    data.nameText.Center = true
    data.nameText.ZIndex = 4
    data.nameText.Visible = false
    -- distance
    data.distanceText.Center = true
    data.distanceText.ZIndex = 4
    data.distanceText.Visible = false
    -- health
    data.healthBg.Filled = true; data.healthBg.Thickness = 0; data.healthBg.ZIndex = 3; data.healthBg.Visible = false
    data.healthOutline.Filled = false; data.healthOutline.Thickness = 1; data.healthOutline.Color = Color3.new(0,0,0); data.healthOutline.ZIndex = 3; data.healthOutline.Visible = false
    data.healthBar.Filled = true; data.healthBar.Thickness = 0; data.healthBar.ZIndex = 3; data.healthBar.Visible = false

    espDrawings[player] = data
end

function espModule.removeEsp(player)
    local d = espDrawings[player]
    if not d then return end
    d.tracer:Remove()
    for _, line in ipairs(d.lines) do line:Remove() end
    d.fillBox:Remove()
    d.nameText:Remove()
    d.distanceText:Remove()
    d.healthBg:Remove()
    d.healthOutline:Remove()
    d.healthBar:Remove()
    espDrawings[player] = nil
end

Players.PlayerRemoving:Connect(espModule.removeEsp)

local droppedIn = false

RunService.RenderStepped:Connect(function()
    if espModule.settings.dropIn and droppedIn == false then
        droppedIn = true
        for _, p in ipairs(Players:GetPlayers()) do if p ~= localPlayer then espModule.createEsp(p) end end
        Players.PlayerAdded:Connect(function(p) if p ~= localPlayer then espModule.createEsp(p) end end)
    end
    local localChar = localPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end

    for player, d in pairs(espDrawings) do
        -- per-player overrides
        local settings = espModule.settings
        local override = settings.playerOverrides[player.Name] or {}
        local function get(key)
            if override[key] ~= nil then
                return override[key]
            else
                return settings[key]
            end
        end

        -- skip if override disabled
        if not get("enabled") then
            d.tracer.Visible = false
            for _, ln in ipairs(d.lines) do ln.Visible = false end
            d.fillBox.Visible = false; d.nameText.Visible = false; d.distanceText.Visible = false
            d.healthBg.Visible = false; d.healthOutline.Visible = false; d.healthBar.Visible = false
            local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
            if humanoid then
                if d.originalDisplayDistance then humanoid.DisplayDistanceType = d.originalDisplayDistance end
                if d.originalHealthDisplay then humanoid.HealthDisplayType = d.originalHealthDisplay end
            end
        end

        -- team filter
        if get("showTeam") and player.Team and localPlayer.Team and player.Team == localPlayer.Team then
            d.tracer.Visible = false
            for _, ln in ipairs(d.lines) do ln.Visible = false end
            d.fillBox.Visible = false; d.nameText.Visible = false; d.distanceText.Visible = false
            d.healthBg.Visible = false; d.healthOutline.Visible = false; d.healthBar.Visible = false
            local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
            if humanoid then
                if d.originalDisplayDistance then humanoid.DisplayDistanceType = d.originalDisplayDistance end
                if d.originalHealthDisplay then humanoid.HealthDisplayType = d.originalHealthDisplay end
            end
            continue
        end

        -- core
        local char = player.Character
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChild("Humanoid")
        if rootPart and humanoid then
            -- store originals
            if not d.originalDisplayDistance then d.originalDisplayDistance = humanoid.DisplayDistanceType end
            if not d.originalHealthDisplay then d.originalHealthDisplay = humanoid.HealthDisplayType end

            -- distance check
            local distSq = (rootPart.Position - localRoot.Position).Magnitude^2
            local withinDist = distSq <= get("maxTextDistance")^2

            -- humanoid display
            if get("showName") and withinDist then
                humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            else
                humanoid.DisplayDistanceType = d.originalDisplayDistance
            end
            if get("showHealthBar") and withinDist then
                humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
            else
                humanoid.HealthDisplayType = d.originalHealthDisplay
            end

            local screenPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
            if onScreen and humanoid.Health > 0 then
                -- bounding box
                local cframe, size = char:GetBoundingBox()
                local half = size * 0.5
                local minX, minY = math.huge, math.huge
                local maxX, maxY = -math.huge, -math.huge
                for i = 1, 8 do
                    local wp = cframe:PointToWorldSpace(bboxOffsets[i] * half)
                    local sp, vis = camera:WorldToViewportPoint(wp)
                    if vis then
                        minX = math.min(minX, sp.X); minY = math.min(minY, sp.Y)
                        maxX = math.max(maxX, sp.X); maxY = math.max(maxY, sp.Y)
                    end
                end
                if minX > maxX then
                    minX = screenPos.X - 20; minY = screenPos.Y - 50
                    maxX = screenPos.X + 20; maxY = screenPos.Y + 50
                end
                local width, height = maxX - minX, maxY - minY

                -- color
                local colorBase = override.fallbackColor or ((get("useTeamColor") and player.Team) and player.TeamColor.Color) or get("fallbackColor")

                -- fillBox
                if get("fillBox") then
                    d.fillBox.Color = get("fillBoxColor")
                    d.fillBox.Transparency = get("fillTransparency")
                    d.fillBox.Position = Vector2.new(minX, minY)
                    d.fillBox.Size = Vector2.new(width, height)
                    d.fillBox.Visible = true
                else
                    d.fillBox.Visible = false
                end

                -- corners
                local cLen = math.clamp(width * 0.2, 4, 15)
                local corners = {
                    {Vector2.new(minX, minY), Vector2.new(minX + cLen, minY)},
                    {Vector2.new(minX, minY), Vector2.new(minX, minY + cLen)},
                    {Vector2.new(maxX - cLen, minY), Vector2.new(maxX, minY)},
                    {Vector2.new(maxX, minY), Vector2.new(maxX, minY + cLen)},
                    {Vector2.new(minX, maxY), Vector2.new(minX + cLen, maxY)},
                    {Vector2.new(minX, maxY - cLen), Vector2.new(minX, maxY)},
                    {Vector2.new(maxX - cLen, maxY), Vector2.new(maxX, maxY)},
                    {Vector2.new(maxX, maxY - cLen), Vector2.new(maxX, maxY)},
                }
                for i, pts in ipairs(corners) do
                    local ln = d.lines[i]
                    if ln.ZIndex == 2 then
                        ln.From, ln.To = pts[1], pts[2]
                        ln.Color = colorBase
                        ln.Thickness = get("boxThickness")
                        ln.Visible = get("showBox")
                    end
                end

                -- tracers
                if get("tracers") and withinDist then
                    local screenSize = camera.ViewportSize
                    local originSetting = get("tracerOrigin"):lower()
                    local origin = Vector2.new()
                    if originSetting == "cursor" then
                        origin = Vector2.new(mouse.X, mouse.Y + 50)
                    elseif originSetting == "top" then
                        origin = Vector2.new(screenSize.X/2, 0)
                    elseif originSetting == "bottom" then
                        origin = Vector2.new(screenSize.X/2, screenSize.Y)
                    elseif originSetting == "left" then
                        origin = Vector2.new(0, screenSize.Y/2)
                    elseif originSetting == "right" then
                        origin = Vector2.new(screenSize.X, screenSize.Y/2)
                    elseif originSetting == "middle" then
                        origin = Vector2.new(screenSize.X/2, screenSize.Y/2)
                    end
                    local center = Vector2.new(minX + width/2, minY + height/2)
                    d.tracer.Transparency = get("tracerTransparency")
                    d.tracer.From, d.tracer.To = origin, center
                    d.tracer.Color = colorBase
                    d.tracer.Thickness = get("boxThickness")
                    d.tracer.Visible = true
                else
                    d.tracer.Visible = false
                end

                -- health bar
                if get("showHealthBar") and withinDist then
                    local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    local barTh, pad = 4, 4
                    d.healthBg.Color = Color3.new(0, 0, 0)
                    d.healthBg.Transparency = 0.5
                    d.healthOutline.Color = Color3.new(0, 0, 0)
                    d.healthOutline.Thickness = 1
                    d.healthBar.Color = Color3.new(1 - ratio, ratio, 0)
                    local pos = get("healthBarPosition"):lower()
                    if pos == "left" then
                        local x = minX - pad - barTh
                        d.healthBg.Position, d.healthBg.Size = Vector2.new(x, minY), Vector2.new(barTh, height)
                        d.healthOutline.Position, d.healthOutline.Size = Vector2.new(x-1, minY-1), Vector2.new(barTh+2, height+2)
                        local h = height * ratio
                        d.healthBar.Position, d.healthBar.Size = Vector2.new(x, maxY - h), Vector2.new(barTh, h)
                    elseif pos == "right" then
                        local x = maxX + pad
                        d.healthBg.Position, d.healthBg.Size = Vector2.new(x, minY), Vector2.new(barTh, height)
                        d.healthOutline.Position, d.healthOutline.Size = Vector2.new(x-1, minY-1), Vector2.new(barTh+2, height+2)
                        local h = height * ratio
                        d.healthBar.Position, d.healthBar.Size = Vector2.new(x, maxY - h), Vector2.new(barTh, h)
                    elseif pos == "top" then
                        local y = minY - pad - barTh
                        d.healthBg.Position, d.healthBg.Size = Vector2.new(minX, y), Vector2.new(width, barTh)
                        d.healthOutline.Position, d.healthOutline.Size = Vector2.new(minX-1, y-1), Vector2.new(width+2, barTh+2)
                        local w = width * ratio
                        d.healthBar.Position, d.healthBar.Size = Vector2.new(minX, y), Vector2.new(w, barTh)
                    else
                        local y = maxY + pad
                        d.healthBg.Position, d.healthBg.Size = Vector2.new(minX, y), Vector2.new(width, barTh)
                        d.healthOutline.Position, d.healthOutline.Size = Vector2.new(minX-1, y-1), Vector2.new(width+2, barTh+2)
                        local w = width * ratio
                        d.healthBar.Position, d.healthBar.Size = Vector2.new(minX, y), Vector2.new(w, barTh)
                    end
                    d.healthBg.Visible = true; d.healthOutline.Visible = true; d.healthBar.Visible = true
                else
                    d.healthBg.Visible = false; d.healthOutline.Visible = false; d.healthBar.Visible = false
                end

                -- distance text
                if get("showDistance") and withinDist then
                    d.distanceText.Size = get("textSize")
                    d.distanceText.Outline = get("outlineText")
                    d.distanceText.Text = math.floor((rootPart.Position - localRoot.Position).Magnitude)
                    d.distanceText.Position = Vector2.new(minX + width/2, maxY + 4)
                    d.distanceText.Color = colorBase
                    d.distanceText.Visible = true
                else
                    d.distanceText.Visible = false
                end

                -- name text
                if get("showName") and withinDist then
                    d.nameText.Size = get("textSize")
                    d.nameText.Outline = get("outlineText")
                    local txt = (get("useDisplayName") and player.DisplayName) or player.Name
                    if get("showTeamName") and player.Team then txt = txt .. " [" .. player.Team.Name .. "]" end
                    d.nameText.Text = txt
                    d.nameText.Position = Vector2.new(minX + width/2, minY - 18)
                    d.nameText.Color = colorBase
                    d.nameText.Visible = true
                else
                    d.nameText.Visible = false
                end
            else
                -- off-screen or invalid
                d.tracer.Visible = false
                for _, ln in ipairs(d.lines) do ln.Visible = false end
                d.fillBox.Visible = false; d.nameText.Visible = false; d.distanceText.Visible = false
                d.healthBg.Visible = false; d.healthOutline.Visible = false; d.healthBar.Visible = false
            end
        else
            -- no root or no humanoid
            d.tracer.Visible = false
            for _, ln in ipairs(d.lines) do ln.Visible = false end
            d.fillBox.Visible = false; d.nameText.Visible = false; d.distanceText.Visible = false
            d.healthBg.Visible = false; d.healthOutline.Visible = false; d.healthBar.Visible = false
        end
    end
end)

return espModule
