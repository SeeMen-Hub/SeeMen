local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local LocalPlayer  = Players.LocalPlayer
local Camera       = workspace.CurrentCamera
-- we up baby
local ESPModule = {}
ESPModule.settings = {
    toggle             = true,
    box                = true,
    boxThickness       = 2,
    boxFill            = true,
    boxFillTransparency= 0.3,
    showName           = true,
    showTeamName       = true,
    maxNameDistance    = 100,
    nameTextSize       = 14,
    nameTextOutline    = true,
    showTeamOnly       = false,
}

local BBOX_OFFSETS = {
    Vector3.new(1,1,1), Vector3.new(1,1,-1), Vector3.new(1,-1,1), Vector3.new(1,-1,-1),
    Vector3.new(-1,1,1),Vector3.new(-1,1,-1),Vector3.new(-1,-1,1),Vector3.new(-1,-1,-1),
}

-- holds Drawing objects for every non‑local player
local drawings = {}
local highlightedPlayer = nil

function ESPModule.createESP(pl)
    local data = { Lines = {}, Name = nil, Fill = nil }
    -- 8 corner lines
    for i = 1, 8 do
        local line = Drawing.new("Line")
        line.ZIndex = 2
        line.Visible = false
        data.Lines[i] = line
    end
    -- name text
    local text = Drawing.new("Text")
    text.Center = true
    text.Visible = false
    data.Name = text
    -- fill square
    local sq = Drawing.new("Square")
    sq.Filled = true
    sq.Thickness = 0
    sq.Visible = false
    data.Fill = sq

    drawings[pl] = data
end

function ESPModule.removeESP(pl)
    local d = drawings[pl]
    if not d then return end
    for _, line in ipairs(d.Lines) do line:Remove() end
    d.Name:Remove()
    d.Fill:Remove()
    drawings[pl] = nil
end

function ESPModule.highlightPlayer(pl)
    highlightedPlayer = pl
end

function ESPModule.clearHighlight()
    highlightedPlayer = nil
end

-- initialize and cleanup
for _, pl in ipairs(Players:GetPlayers()) do
    if pl ~= LocalPlayer then ESPModule.createESP(pl) end
end
Players.PlayerAdded:Connect(function(pl)
    if pl ~= LocalPlayer then ESPModule.createESP(pl) end
end)
Players.PlayerRemoving:Connect(ESPModule.removeESP)

-- Main render loop
RunService.RenderStepped:Connect(function()
    local cfg = ESPModule.settings
    if not cfg.toggle then
        -- hide everything if ESP globally off
        for _, d in pairs(drawings) do
            for _, ln in ipairs(d.Lines) do ln.Visible = false end
            d.Fill.Visible = false
            d.Name.Visible = false
        end
        return
    end

    local target = highlightedPlayer
    -- hide all except the one target
    for pl, d in pairs(drawings) do
        if pl ~= target then
            for _, ln in ipairs(d.Lines) do ln.Visible = false end
            d.Fill.Visible = false
            d.Name.Visible = false
        end
    end

    -- if there's no highlighted player, nothing to draw
    if not target then
        return
    end

    -- ensure target is still valid
    local char = target.Character
    if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChild("Humanoid")
    if not (hrp and hum and hum.Health > 0) then return end

    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then return end

    -- get the 3D bounding box corners in screen space
    local boxCF, boxSize = char:GetBoundingBox()
    local half = boxSize * 0.5
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    for i = 1, 8 do
        local worldPt = boxCF:PointToWorldSpace(BBOX_OFFSETS[i] * half)
        local sp, vis = Camera:WorldToViewportPoint(worldPt)
        if vis then
            minX = math.min(minX, sp.X)
            minY = math.min(minY, sp.Y)
            maxX = math.max(maxX, sp.X)
            maxY = math.max(maxY, sp.Y)
        end
    end
    if minX > maxX then
        -- fallback box
        minX = screenPos.X - 20; minY = screenPos.Y - 50
        maxX = screenPos.X + 20; maxY = screenPos.Y + 50
    end

    local w, h = maxX - minX, maxY - minY
    local color = target.Team and target.TeamColor.Color or Color3.new(1,1,1)

    -- team filter
    if cfg.showTeamOnly and target.Team and LocalPlayer.Team and target.Team ~= LocalPlayer.Team then
        return
    end

    -- do the box
    local d = drawings[target]
    for _, ln in ipairs(d.Lines) do ln.Thickness = cfg.boxThickness end
    if cfg.box then
        d.Fill.Color       = Color3.new(0.1,0.1,0.1)
        d.Fill.Transparency= cfg.boxFillTransparency
        d.Fill.Position    = Vector2.new(minX, minY)
        d.Fill.Size        = Vector2.new(w, h)
        d.Fill.Visible     = cfg.boxFill

        local cornerLen = math.clamp(w * 0.2, 4, 15)
        -- top-left
        d.Lines[1].From, d.Lines[1].To = Vector2.new(minX, minY), Vector2.new(minX+cornerLen, minY)
        d.Lines[2].From, d.Lines[2].To = Vector2.new(minX, minY), Vector2.new(minX, minY+cornerLen)
        -- top-right
        d.Lines[3].From, d.Lines[3].To = Vector2.new(maxX-cornerLen, minY), Vector2.new(maxX, minY)
        d.Lines[4].From, d.Lines[4].To = Vector2.new(maxX, minY), Vector2.new(maxX, minY+cornerLen)
        -- bottom-left
        d.Lines[5].From, d.Lines[5].To = Vector2.new(minX, maxY), Vector2.new(minX+cornerLen, maxY)
        d.Lines[6].From, d.Lines[6].To = Vector2.new(minX, maxY-cornerLen), Vector2.new(minX, maxY)
        -- bottom-right
        d.Lines[7].From, d.Lines[7].To = Vector2.new(maxX-cornerLen, maxY), Vector2.new(maxX, maxY)
        d.Lines[8].From, d.Lines[8].To = Vector2.new(maxX, maxY-cornerLen), Vector2.new(maxX, maxY)

        for _, ln in ipairs(d.Lines) do
            ln.Color   = color
            ln.Visible = true
        end
    else
        for _, ln in ipairs(d.Lines) do ln.Visible = false end
        d.Fill.Visible = false
    end

    -- draw the name/text
    d.Name.Size    = cfg.nameTextSize
    d.Name.Outline = cfg.nameTextOutline
    if cfg.showName then
        local dist2 = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude^2
        if dist2 <= cfg.maxNameDistance^2 then
            local txt = target.Name
            if cfg.showTeamName and target.Team then
                txt = txt .. " ["..target.Team.Name.."]"
            end
            d.Name.Text     = txt
            d.Name.Position = Vector2.new(minX + w/2, minY - 18)
            d.Name.Color    = color
            d.Name.Visible  = true
        else
            d.Name.Visible = false
        end
    else
        d.Name.Visible = false
    end
end)

return ESPModule
