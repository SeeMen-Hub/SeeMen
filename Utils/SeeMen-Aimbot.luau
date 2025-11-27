I <3 vibe coding
-- LockOnModule.lua
-- Legitimate in-game lock-on / aim-assist for your own game (not an external exploit)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local lockOnModule = {}

lockOnModule.settings = {
    enabled = true,

    -- targeting
    maxDistance = 200,              -- studs
    maxFOV = 40,                    -- degrees (angle between camera look and target)
    teamCheck = true,               -- ignore same team
    requireLineOfSight = true,      -- raycast check

    -- input
    lockKey = Enum.UserInputType.MouseButton2,  -- RMB by default
    toggleMode = false,             -- false = hold button, true = toggle on/off

    -- smoothing
    smoothAim = true,
    smoothness = 0.2,               -- 0–1, closer to 1 = slower/smoother

    -- target part preference
    preferredPartName = "Head",     -- try lock to Head first, fallback to HumanoidRootPart

    -- debug / callbacks
    onTargetChanged = nil,          -- function(newTarget) end
}

local currentTarget = nil
local lockActive = false
local inputConnection
local renderConnection

-- Utility: check if we should ignore a player
local function isValidTarget(player)
    if not player or player == localPlayer then
        return false
    end

    local char = player.Character
    if not char then return false end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    if lockOnModule.settings.teamCheck then
        if player.Team and localPlayer.Team and player.Team == localPlayer.Team then
            return false
        end
    end

    return true
end

local function getTargetPart(player)
    local char = player.Character
    if not char then return end

    local part = char:FindFirstChild(lockOnModule.settings.preferredPartName)
    if not part then
        part = char:FindFirstChild("HumanoidRootPart")
    end
    return part
end

local function hasLineOfSight(origin, targetPos, ignoreList)
    if not lockOnModule.settings.requireLineOfSight then
        return true
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = ignoreList or {}

    local direction = (targetPos - origin)
    local result = workspace:Raycast(origin, direction, params)
    if result then
        -- we consider it LOS if we hit something very close to target point or part
        local hitPos = result.Position
        local distDelta = (hitPos - targetPos).Magnitude
        return distDelta < 3
    end

    -- nothing hit, so clear view
    return true
end

-- Find best target in front of camera within distance & FOV
local function getBestTarget()
    local localChar = localPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil end

    local camCF = camera.CFrame
    local camPos = camCF.Position
    local camLook = camCF.LookVector

    local bestPlayer = nil
    local bestScore = math.huge  -- lower is better

    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local part = getTargetPart(player)
            if part then
                local dir = (part.Position - camPos)
                local distance = dir.Magnitude
                if distance <= lockOnModule.settings.maxDistance then
                    local unitDir = dir.Unit
                    local dot = camLook:Dot(unitDir)
                    -- clamp value for acos
                    dot = math.clamp(dot, -1, 1)
                    local angle = math.deg(math.acos(dot))

                    if angle <= lockOnModule.settings.maxFOV then
                        -- (optional) LOS check
                        if hasLineOfSight(camPos, part.Position, {localChar}) then
                            -- scoring: prioritise closest angle, then distance
                            local score = angle + distance * 0.01
                            if score < bestScore then
                                bestScore = score
                                bestPlayer = player
                            end
                        end
                    end
                end
            end
        end
    end

    return bestPlayer
end

local function setTarget(newTarget)
    if currentTarget == newTarget then return end
    currentTarget = newTarget

    local cb = lockOnModule.settings.onTargetChanged
    if type(cb) == "function" then
        cb(currentTarget)
    end
end

local function updateCamera(dt)
    if not lockOnModule.settings.enabled or not lockActive then
        setTarget(nil)
        return
    end

    if not currentTarget or not isValidTarget(currentTarget) then
        setTarget(getBestTarget())
    end

    if not currentTarget then return end

    local part = getTargetPart(currentTarget)
    if not part then
        setTarget(nil)
        return
    end

    local camCF = camera.CFrame
    local camPos = camCF.Position

    local targetPos = part.Position

    -- recompute LOS; drop target if blocked
    if not hasLineOfSight(camPos, targetPos, {localPlayer.Character}) then
        setTarget(nil)
        return
    end

    local desired = CFrame.lookAt(camPos, targetPos)

    if lockOnModule.settings.smoothAim then
        local alpha = 1 - math.pow(1 - lockOnModule.settings.smoothness, dt * 60)
        camera.CFrame = camCF:Lerp(desired, alpha)
    else
        camera.CFrame = desired
    end
end

local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == lockOnModule.settings.lockKey then
        if lockOnModule.settings.toggleMode then
            lockActive = not lockActive
            if not lockActive then
                setTarget(nil)
            end
        else
            lockActive = true
        end
    end
end

local function onInputEnded(input, gameProcessed)
    if gameProcessed then return end
    if not lockOnModule.settings.toggleMode and input.UserInputType == lockOnModule.settings.lockKey then
        lockActive = false
        setTarget(nil)
    end
end

function lockOnModule.enable()
    if renderConnection then return end

    lockOnModule.settings.enabled = true

    inputConnection = {
        began = UserInputService.InputBegan:Connect(onInputBegan),
        ended = UserInputService.InputEnded:Connect(onInputEnded),
    }

    renderConnection = RunService.RenderStepped:Connect(function(dt)
        local success, err = pcall(updateCamera, dt)
        if not success then
            warn("[LockOnModule] Error in updateCamera:", err)
        end
    end)
end

function lockOnModule.disable()
    lockOnModule.settings.enabled = false
    lockActive = false
    setTarget(nil)

    if inputConnection then
        if inputConnection.began then inputConnection.began:Disconnect() end
        if inputConnection.ended then inputConnection.ended:Disconnect() end
        inputConnection = nil
    end

    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
end

function lockOnModule.setSettings(newSettings)
    for k, v in pairs(newSettings) do
        if lockOnModule.settings[k] ~= nil then
            lockOnModule.settings[k] = v
        end
    end
end

return lockOnModule
