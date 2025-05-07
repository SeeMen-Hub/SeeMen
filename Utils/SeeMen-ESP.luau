local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

if not (getgenv().SeeMen and getgenv().SeeMen.Utils and getgenv().SeeMen.Utils.ESP) then return end

local BBOX_OFFSETS = {
    Vector3.new(1,1,1), Vector3.new(1,1,-1), Vector3.new(1,-1,1), Vector3.new(1,-1,-1),
    Vector3.new(-1,1,1), Vector3.new(-1,1,-1), Vector3.new(-1,-1,1), Vector3.new(-1,-1,-1),
}

local ESP = {}

local function createESP(pl)
    local lines = {}
    for i = 1, 8 do
        local L = Drawing.new("Line")
        L.ZIndex = 2
        L.Visible = false
        lines[i] = L
    end
    local nameT = Drawing.new("Text")
    nameT.Center = true
    nameT.Visible = false
    local fill
    fill = Drawing.new("Square")
    fill.Filled = true
    fill.Thickness = 0
    fill.Visible = false
    ESP[pl] = {Lines = lines, Name = nameT, Fill = fill}
end

local function removeESP(pl)
    local d = ESP[pl]
    if not d then return end
    for _, L in ipairs(d.Lines) do L:Remove() end
    d.Name:Remove()
    if d.Fill then d.Fill:Remove() end
    ESP[pl] = nil
end

for _, pl in ipairs(Players:GetPlayers()) do
    if pl ~= LocalPlayer then createESP(pl) end
end
Players.PlayerAdded:Connect(function(pl)
    if pl ~= LocalPlayer then createESP(pl) end
end)
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    local cfg = getgenv().SeeMen.Utils.ESP
    if not cfg.toggle then
        for _, d in pairs(ESP) do
            for _, L in ipairs(d.Lines) do L.Visible = false end
            if d.Fill then d.Fill.Visible = false end
            d.Name.Visible = false
        end
        return
    end

    local lpChar = LocalPlayer.Character
    local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
    if not lpHRP then return end

    for pl, d in pairs(ESP) do
        local c = pl.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        local hum = c and c:FindFirstChild("Humanoid")
        if hrp and hum and hum.Health > 0 then
            local root2d, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local boxCFrame, boxSize = c:GetBoundingBox()
                local half = boxSize * 0.5
                local minX, minY = math.huge, math.huge
                local maxX, maxY = -math.huge, -math.huge
                for i = 1, 8 do
                    local pt = boxCFrame:PointToWorldSpace(BBOX_OFFSETS[i] * half)
                    local sp, vis = Camera:WorldToViewportPoint(pt)
                    if vis then
                        local x, y = sp.X, sp.Y
                        if x < minX then minX = x end
                        if y < minY then minY = y end
                        if x > maxX then maxX = x end
                        if y > maxY then maxY = y end
                    end
                end
                if minX > maxX then
                    minX = root2d.X - 20
                    minY = root2d.Y - 50
                    maxX = root2d.X + 20
                    maxY = root2d.Y + 50
                end
                local w, h = maxX - minX, maxY - minY
                local col = pl.TeamColor.Color

                for _, L in ipairs(d.Lines) do
                    L.Thickness = cfg.boxThickness
                end

                if cfg.box then
                    if d.Fill then
                        d.Fill.Color = Color3.new(0.5, 0.5, 0.5)
                        d.Fill.Transparency = cfg.boxFillTransparency
                        d.Fill.Position = Vector2.new(minX, minY)
                        d.Fill.Size = Vector2.new(w, h)
                        d.Fill.Visible = cfg.boxFill
                    end
                    local cLen = math.clamp(w * 0.2, 4, 15)
                    d.Lines[1].From, d.Lines[1].To = Vector2.new(minX, minY), Vector2.new(minX + cLen, minY)
                    d.Lines[2].From, d.Lines[2].To = Vector2.new(minX, minY), Vector2.new(minX, minY + cLen)
                    d.Lines[3].From, d.Lines[3].To = Vector2.new(maxX - cLen, minY), Vector2.new(maxX, minY)
                    d.Lines[4].From, d.Lines[4].To = Vector2.new(maxX, minY), Vector2.new(maxX, minY + cLen)
                    d.Lines[5].From, d.Lines[5].To = Vector2.new(minX, maxY), Vector2.new(minX + cLen, maxY)
                    d.Lines[6].From, d.Lines[6].To = Vector2.new(minX, maxY - cLen), Vector2.new(minX, maxY)
                    d.Lines[7].From, d.Lines[7].To = Vector2.new(maxX - cLen, maxY), Vector2.new(maxX, maxY)
                    d.Lines[8].From, d.Lines[8].To = Vector2.new(maxX, maxY - cLen), Vector2.new(maxX, maxY)
                    for _, L in ipairs(d.Lines) do L.Color = col; L.Visible = true end
                else
                    for _, L in ipairs(d.Lines) do L.Visible = false end
                    if d.Fill then d.Fill.Visible = false end
                end

                d.Name.Size = cfg.nameTextSize
                d.Name.Outline = cfg.nameTextOutline
                if cfg.showName then
                    local delta = hrp.Position - lpHRP.Position
                    local maxDistSqr = cfg.maxNameDistance * cfg.maxNameDistance
                    if delta:Dot(delta) <= maxDistSqr then
                        local txt = pl.Name
                        if cfg.showTeamName then txt = txt .. " [" .. pl.Team.Name .. "]" end
                        d.Name.Text = txt
                        d.Name.Position = Vector2.new(minX + w/2, minY - 18)
                        d.Name.Color = col
                        d.Name.Visible = true
                    else
                        d.Name.Visible = false
                    end
                else
                    d.Name.Visible = false
                end
            else
                for _, L in ipairs(d.Lines) do L.Visible = false end
                if d.Fill then d.Fill.Visible = false end
                d.Name.Visible = false
            end
        else
            for _, L in ipairs(d.Lines) do L.Visible = false end
            if d.Fill then d.Fill.Visible = false end
            d.Name.Visible = false
        end
    end
end)
