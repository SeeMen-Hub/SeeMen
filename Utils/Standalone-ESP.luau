queue_on_teleport(game:HttpGet("https://raw.githubusercontent.com/That-Fella/SeeMen/refs/heads/main/Utils/Standalone-ESP.luau"))
 
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
    boxFillTransparency = 0.3,
    showName = true,
    showTeamName = true,
    maxNameDistance = 100,
    nameTextSize = 14,
    nameTextOutline = true,
    showTeamOnly = false
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
    sq.Visible = false
    data.Fill = sq

    drawings[pl] = data
end

local function removeESP(pl)
    local d = drawings[pl]
    if not d then return end
    for _,line in ipairs(d.Lines) do line:Remove() end
    d.Name:Remove()
    if d.Fill then d.Fill:Remove() end
    drawings[pl] = nil
end

for _,pl in ipairs(Players:GetPlayers()) do
    if pl ~= LocalPlayer then createESP(pl) end
end
Players.PlayerAdded:Connect(function(pl)
    if pl ~= LocalPlayer then createESP(pl) end
end)
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    local cfg = ESPModule.settings
    if not cfg.toggle then
        for _,d in pairs(drawings) do
            for _,line in ipairs(d.Lines) do line.Visible = false end
            if d.Fill then d.Fill.Visible = false end
            d.Name.Visible = false
        end
        return
    end
    local lpChar = LocalPlayer.Character
    local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
    if not lpHRP then return end
    for pl,d in pairs(drawings) do
        -- NEW: skip if same team and setting is off
        if cfg.showTeamOnly == false and pl.Team ~= nil and LocalPlayer.Team ~= nil and pl.Team == LocalPlayer.Team then
            for _,ln in ipairs(d.Lines) do ln.Visible = false end
            if d.Fill then d.Fill.Visible = false end
            d.Name.Visible = false
            continue
        end

        local c = pl.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        local hum = c and c:FindFirstChild("Humanoid")
        if hrp and hum and hum.Health>0 then
            local root2d,on = Camera:WorldToViewportPoint(hrp.Position)
            if on then
                local boxCF,boxSize = c:GetBoundingBox()
                local half = boxSize*0.5
                local minX,minY = math.huge,math.huge
                local maxX,maxY = -math.huge,-math.huge
                for i=1,8 do
                    local pt = boxCF:PointToWorldSpace(BBOX_OFFSETS[i]*half)
                    local sp,vis = Camera:WorldToViewportPoint(pt)
                    if vis then
                        minX = math.min(minX,sp.X)
                        minY = math.min(minY,sp.Y)
                        maxX = math.max(maxX,sp.X)
                        maxY = math.max(maxY,sp.Y)
                    end
                end
                if minX>maxX then
                    minX = root2d.X-20; minY = root2d.Y-50
                    maxX = root2d.X+20; maxY = root2d.Y+50
                end
                local w,h = maxX-minX, maxY-minY
                local col = pl.Team and pl.TeamColor.Color or Color3.new(1,1,1)
                for _,ln in ipairs(d.Lines) do ln.Thickness=cfg.boxThickness end
                if cfg.box then
                    if d.Fill then
                        d.Fill.Color = Color3.new(0.1,0.1,0.1)
                        d.Fill.Transparency = cfg.boxFillTransparency
                        d.Fill.Position = Vector2.new(minX,minY)
                        d.Fill.Size = Vector2.new(w,h)
                        d.Fill.Visible = cfg.boxFill
                    end
                    local cLen = math.clamp(w*0.2,4,15)
                    d.Lines[1].From,d.Lines[1].To = Vector2.new(minX,minY),Vector2.new(minX+cLen,minY)
                    d.Lines[2].From,d.Lines[2].To = Vector2.new(minX,minY),Vector2.new(minX,minY+cLen)
                    d.Lines[3].From,d.Lines[3].To = Vector2.new(maxX-cLen,minY),Vector2.new(maxX,minY)
                    d.Lines[4].From,d.Lines[4].To = Vector2.new(maxX,minY),Vector2.new(maxX,minY+cLen)
                    d.Lines[5].From,d.Lines[5].To = Vector2.new(minX,maxY),Vector2.new(minX+cLen,maxY)
                    d.Lines[6].From,d.Lines[6].To = Vector2.new(minX,maxY-cLen),Vector2.new(minX,maxY)
                    d.Lines[7].From,d.Lines[7].To = Vector2.new(maxX-cLen,maxY),Vector2.new(maxX,maxY)
                    d.Lines[8].From,d.Lines[8].To = Vector2.new(maxX,maxY-cLen),Vector2.new(maxX,maxY)
                    for _,ln in ipairs(d.Lines) do ln.Color=col; ln.Visible=true end
                else
                    for _,ln in ipairs(d.Lines) do ln.Visible=false end
                    if d.Fill then d.Fill.Visible=false end
                end
                d.Name.Size = cfg.nameTextSize
                d.Name.Outline = cfg.nameTextOutline
                if cfg.showName then
                    local distSqr = (hrp.Position - lpHRP.Position).Magnitude^2
                    if distSqr <= cfg.maxNameDistance^2 then
                        local txt = pl.Name
                        if cfg.showTeamName and pl.Team then
                            txt = txt .. " ["..pl.Team.Name.."]"
                        end
                        d.Name.Text = txt
                        d.Name.Position = Vector2.new(minX+w/2,minY-18)
                        d.Name.Color = col
                        d.Name.Visible = true
                    else
                        d.Name.Visible = false
                    end
                else
                    d.Name.Visible = false
                end
            else
                for _,ln in ipairs(d.Lines) do ln.Visible=false end
                if d.Fill then d.Fill.Visible=false end
                d.Name.Visible=false
            end
        else
            for _,ln in ipairs(d.Lines) do ln.Visible=false end
            if d.Fill then d.Fill.Visible=false end
            d.Name.Visible=false
        end
    end
end)
