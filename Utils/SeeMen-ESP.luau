local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESPModule = {}
ESPModule.settings = {
    toggle = true,
    box = true,
    boxThickness = 2,
    boxFill = true,
    boxFillTransparency = 0.9,
    showName = true,
    showTeamName = true,
    maxNameDistance = 100,
    nameTextSize = 14,
    nameTextOutline = true,
}

local BBOX_OFFSETS = {
    Vector3.new(1,1,1), Vector3.new(1,1,-1), Vector3.new(1,-1,1), Vector3.new(1,-1,-1),
    Vector3.new(-1,1,1), Vector3.new(-1,1,-1), Vector3.new(-1,-1,1), Vector3.new(-1,-1,-1),
}

local drawings = {}

local function createESP(pl)
    local data = {Lines = {}, Name = nil, Fill = nil}
    for i = 1, 8 do
        local line = Drawing.new("Line")
        line.ZIndex = 2
        line.Visible = false
        data.Lines[i] = line
    end
    local text = Drawing.new("Text")
    text.Center = true
    text.Visible = false
    data.Name = text
    local sq = Drawing.new("Square")
    sq.Filled = true
    sq.Thickness = 0
    sq.ZIndex = 1
    sq.Color = Color3.new(0.5,0.5,0.5)
    sq.Transparency = 1
    sq.Visible = true
    data.Fill = sq
    drawings[pl] = data
end

local function removeESP(pl)
    local d = drawings[pl]
    if not d then return end
    for _, line in ipairs(d.Lines) do line:Remove() end
    d.Name:Remove()
    d.Fill:Remove()
    drawings[pl] = nil
end

for _, pl in ipairs(Players:GetPlayers()) do
    if pl ~= LocalPlayer then createESP(pl) end
end
Players.PlayerAdded:Connect(function(pl)
    if pl ~= LocalPlayer then createESP(pl) end
end)
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    local cfg = ESPModule.settings
    -- hide all by default
    for _, d in pairs(drawings) do
        for _, line in ipairs(d.Lines) do line.Visible = false end
        d.Name.Visible = false
        d.Fill.Transparency = 1
    end
    if not cfg.toggle then return end
    local lpChar = LocalPlayer.Character
    local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
    if not lpHRP then return end
    for pl, d in pairs(drawings) do
        local c = pl.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        local hum = c and c:FindFirstChild("Humanoid")
        if hrp and hum and hum.Health > 0 then
            local root2d, on = Camera:WorldToViewportPoint(hrp.Position)
            if on then
                local boxCF, boxSize = c:GetBoundingBox()
                local half = boxSize * 0.5
                local minX, minY = math.huge, math.huge
                local maxX, maxY = -math.huge, -math.huge
                for i = 1, 8 do
                    local pt = boxCF:PointToWorldSpace(BBOX_OFFSETS[i] * half)
                    local sp, vis = Camera:WorldToViewportPoint(pt)
                    if vis then
                        minX = math.min(minX, sp.X)
                        minY = math.min(minY, sp.Y)
                        maxX = math.max(maxX, sp.X)
                        maxY = math.max(maxY, sp.Y)
                    end
                end
                if minX > maxX then
                    minX = root2d.X - 20
                    minY = root2d.Y - 50
                    maxX = root2d.X + 20
                    maxY = root2d.Y + 50
                end
                local w = maxX - minX
                local h = maxY - minY
                local col = pl.TeamColor.Color
                for _, ln in ipairs(d.Lines) do
                    ln.Thickness = cfg.boxThickness
                end
                if cfg.box then
                    local trans = cfg.boxFill and cfg.boxFillTransparency or 1
                    d.Fill.Position = Vector2.new(minX, minY)
                    d.Fill.Size = Vector2.new(w, h)
                    d.Fill.Transparency = trans
                    for _, ln in ipairs(d.Lines) do
                        ln.Color = col
                        ln.Visible = true
                    end
                end
                if cfg.showName then
                    local delta = hrp.Position - lpHRP.Position
                    if delta:Dot(delta) <= cfg.maxNameDistance * cfg.maxNameDistance then
                        local txt = pl.Name
                        if cfg.showTeamName then txt = txt .. " [" .. pl.Team.Name .. "]" end
                        d.Name.Text = txt
                        d.Name.Position = Vector2.new(minX + w/2, minY - 18)
                        d.Name.Color = col
                        d.Name.Size = cfg.nameTextSize
                        d.Name.Outline = cfg.nameTextOutline
                        d.Name.Visible = true
                    end
                end
            end
        end
    end
end)

return ESPModule
