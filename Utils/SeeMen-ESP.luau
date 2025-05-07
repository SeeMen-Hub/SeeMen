local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local MAX_DISTANCE = 100
local MAX_DIST_SQR = MAX_DISTANCE * MAX_DISTANCE

if getgenv().ESPEnabled == nil then
    getgenv().SeeMen.Universal.ESP.enabled = false
end

local BBOX_OFFSETS = {
    Vector3.new(1, 1, 1),
    Vector3.new(1, 1, -1),
    Vector3.new(1, -1, 1),
    Vector3.new(1, -1, -1),
    Vector3.new(-1, 1, 1),
    Vector3.new(-1, 1, -1),
    Vector3.new(-1, -1, 1),
    Vector3.new(-1, -1, -1),
}

local ESP = {}

local function createESP(player)
    local lines = {}
    for i = 1, 8 do
        local L = Drawing.new("Line")
        L.Thickness = 2
        L.ZIndex = 2
        L.Visible = false
        lines[i] = L
    end
    local nameT = Drawing.new("Text")
    nameT.Center = true
    nameT.Outline = true
    nameT.Size = 14
    nameT.Visible = false
    ESP[player] = {Lines = lines, Name = nameT}
end

local function removeESP(player)
    local data = ESP[player]
    if not data then return end
    for _, L in ipairs(data.Lines) do L:Remove() end
    data.Name:Remove()
    ESP[player] = nil
end

for _, pl in ipairs(Players:GetPlayers()) do
    if pl ~= LocalPlayer then createESP(pl) end
end
Players.PlayerAdded:Connect(function(pl)
    if pl ~= LocalPlayer then createESP(pl) end
end)
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    if not getgenv().ESPEnabled then
        for _, data in pairs(ESP) do
            for _, L in ipairs(data.Lines) do L.Visible = false end
            data.Name.Visible = false
        end
        return
    end

    local lpChar = LocalPlayer.Character
    local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
    if not lpHRP then return end

    for player, data in pairs(ESP) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChild("Humanoid")
        if hrp and humanoid and humanoid.Health > 0 then
            local root2d, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local boxCFrame, boxSize = char:GetBoundingBox()
                local halfSize = boxSize * 0.5
                local minX, minY = math.huge, math.huge
                local maxX, maxY = -math.huge, -math.huge
                for i = 1, 8 do
                    local worldPt = boxCFrame:PointToWorldSpace(BBOX_OFFSETS[i] * halfSize)
                    local sp, vis = Camera:WorldToViewportPoint(worldPt)
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
                local w = maxX - minX
                local h = maxY - minY
                local x, y = minX, minY
                local cLen = math.clamp(w * 0.2, 4, 15)
                local col = player.TeamColor.Color
                data.Lines[1].From, data.Lines[1].To = Vector2.new(x, y), Vector2.new(x + cLen, y)
                data.Lines[2].From, data.Lines[2].To = Vector2.new(x, y), Vector2.new(x, y + cLen)
                data.Lines[3].From, data.Lines[3].To = Vector2.new(x + w - cLen, y), Vector2.new(x + w, y)
                data.Lines[4].From, data.Lines[4].To = Vector2.new(x + w, y), Vector2.new(x + w, y + cLen)
                data.Lines[5].From, data.Lines[5].To = Vector2.new(x, y + h), Vector2.new(x + cLen, y + h)
                data.Lines[6].From, data.Lines[6].To = Vector2.new(x, y + h - cLen), Vector2.new(x, y + h)
                data.Lines[7].From, data.Lines[7].To = Vector2.new(x + w - cLen, y + h), Vector2.new(x + w, y + h)
                data.Lines[8].From, data.Lines[8].To = Vector2.new(x + w, y + h - cLen), Vector2.new(x + w, y + h)
                for _, L in ipairs(data.Lines) do
                    L.Color = col
                    L.Visible = true
                end
                local delta = hrp.Position - lpHRP.Position
                local distSqr = delta:Dot(delta)
                if distSqr <= MAX_DIST_SQR then
                    data.Name.Text = player.Name
                    data.Name.Position = Vector2.new(x + w/2, y - 18)
                    data.Name.Color = col
                    data.Name.Visible = true
                else
                    data.Name.Visible = false
                end
            else
                for _, L in ipairs(data.Lines) do L.Visible = false end
                data.Name.Visible = false
            end
        else
            for _, L in ipairs(data.Lines) do L.Visible = false end
            data.Name.Visible = false
        end
    end
end)
