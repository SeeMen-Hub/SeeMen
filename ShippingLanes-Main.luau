if game.PlaceId ~= 245440965 then return end

repeat task.wait(0.1) until game:IsLoaded()

local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()
 
local Window = Library:CreateWindow{
    Title = `SeeMen`,
    SubTitle = " | by That Fella",
    TabWidth = 160,
    Size = UDim2.fromOffset(550, 500),
    Resize = true,
    MinSize = Vector2.new(470, 380),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftAlt -- Used when theres no MinimizeKeybind
}

-- Fluent Renewed provides ALL 1544 Lucide 0.469.0 https://lucide.dev/icons/ Icons and ALL 9072 Phosphor 2.1.0 https://phosphoricons.com/ Icons for the tabs, icons are optional
local Tabs = {
    Main = Window:CreateTab{
        Title = "Main",
        Icon = "phosphor-users-bold"
    },
    Settings = Window:CreateTab{
        Title = "Settings",
        Icon = "settings"
    }
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")

local placeId = game.PlaceId
local jobId   = game.JobId

local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ShipControlGui = PlayerGui:WaitForChild("ShipControlGui", 5)
local shipControllerScript = ShipControlGui:WaitForChild("Controller")

local spawnRemote = game:GetService("ReplicatedStorage"):WaitForChild("RemoteStorage"):WaitForChild("RemoteFunction")

local GeneralFunctions = require(ReplicatedStorage.GlobalReplicated.GlobalModules.GeneralFunctions)
local InteractionZonesModule = require(shipControllerScript.Modules.InteractionZonesModule)
local GlobalConfig = require(ReplicatedStorage.GlobalReplicated.GlobalConfig)
local PortLocations = require(ReplicatedStorage.GlobalReplicated.GlobalModules.PortLocations)
local PortManager = ReplicatedStorage.GlobalReplicated.Storage.Guis.PortGui.PortManager

getgenv().SeeMen = {
    autoFarm = false,
    startingPort = nil,
    targetPort = nil,
    serverHopOnTrustedPlayer = false,
    antiAFK = false,
}

local function serverHop()
    local servers, cursor = {}, nil

    repeat
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100%s"):format(placeId, cursor and "&cursor=" .. HttpService:UrlEncode(cursor) or "")

        local success, res = pcall(HttpService.GetAsync, HttpService, url)
        if not success then
            LocalPlayer:Kick("Failed to fetch server list: " .. tostring(res))
            return
        end

        local data = HttpService:JSONDecode(res)
        for _, s in ipairs(data.data or {}) do
            if s.id ~= jobId and s.playing < s.maxPlayers then
                table.insert(servers, s.id)
            end
        end

        cursor = data.nextPageCursor
    until not cursor

    if #servers == 0 then
        LocalPlayer:Kick("No other servers available to hop to.")
    else
        local target = servers[math.random(1, #servers)]
        TeleportService:TeleportToPlaceInstance(placeId, target, LocalPlayer)
    end
end

local function getShipSettings(shipName: string)
    local shipSettings = GlobalConfig.Ships
    if shipSettings then
        for _, table in shipSettings do
            if table[1] == shipName then
                return table
            end
        end
    end
    return nil
end

local function findAvailablePorts()
    local ship = LocalPlayer.CurrentShip.Value
    local shipSettings = getShipSettings(ship.Name)
    local shipClass = shipSettings["Class"]
    local portFolder = workspace.Ports
    local ports = {}
    for _, port in portFolder:GetChildren() do
        local cargoLoaders = port:FindFirstChild("CargoLoaders")
        if cargoLoaders then
            for i, loader in cargoLoaders:GetChildren() do
                if loader:IsA("BasePart") and loader:FindFirstChild(shipClass) then
                    local portName = port.Name
                    local loaderPos = loader.Position
                    ports[portName] = loaderPos
                end
            end
        end
    end
    return ports
end

local function DockShip()
    repeat
        LocalPlayer.CurrentShip.Value.PrimaryPart.BodyVelocity.Velocity = Vector3.new(0, 0, 0)
        InteractionZonesModule.DockShip()
        local isDocked = LocalPlayer.CurrentShip.Value:GetAttribute("IsDocked")
        task.wait(0.1)
    until isDocked == true

    local portGui = PlayerGui:WaitForChild("PortGui", 15)
    if portGui then
        local EssentialData = require(portGui.Scripts.EssentialData)
        if EssentialData then
            -- Remove loading time wait
            EssentialData.ToggleLoading = function(time, name, gui)
                if time == 0 then
                    return
                else
                    local l_LoadingBar_0 = portGui.LoadingBar
                    local l_IntValue_0 = Instance.new("IntValue")
                    l_IntValue_0:GetPropertyChangedSignal("Value"):Connect(function()
                        portGui.LoadingBar.Bar.Percentage.Text = l_IntValue_0.Value .. "%"
                    end)
                    l_LoadingBar_0.Position = UDim2.new(0.5, 0, 1.1, 0)
                    l_LoadingBar_0:TweenPosition(UDim2.new(0.5, 0, 0.855, 0), "Out", "Quad", 0.3, true)
                    if gui then
                        gui.Visible = false
                    end
                    l_LoadingBar_0.Visible = true
                    l_LoadingBar_0.Bar.Percentage.Text = "0%"
                    l_LoadingBar_0.Title.Text = name
                    l_LoadingBar_0.Bar.Bar.Size = UDim2.new(0, 0, 1, 0)
                    l_LoadingBar_0.Bar.Bar:TweenSize(UDim2.new(1, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0, true)
                    TweenService:Create(l_IntValue_0, TweenInfo.new(0, Enum.EasingStyle.Linear), { Value = 100 }):Play()
                    task.wait(0)
                    l_LoadingBar_0:TweenPosition(UDim2.new(0.5, 0, 1.1, 0), "Out", "Quad", 0.3, true)
                    task.wait(0.3)
                    l_IntValue_0:Destroy()
                    l_LoadingBar_0.Visible = false
                    if gui then
                        gui.Visible = true
                    end
                    return
                end
            end
            return
        end
        warn("EssentialData not found")
    end
    warn("PortGui not found")
end

local function UndockShip()
    local portGui = PlayerGui:FindFirstChild("PortGui")
    if portGui then
        local EssentialData = require(portGui.Scripts.EssentialData)
        if EssentialData then
            LocalPlayer.CurrentShip.Value.Storage.RemoteEvent:FireServer(unpack({"Undock"}))
            local portMainMenu = portGui:FindFirstChild("PortMainMenu")
            portMainMenu.Visible = false
            EssentialData.ToggleLoading(6, "Undocking Ship...")
            if LocalPlayer.PlayerGui:FindFirstChild("ShipControlGui") then
                LocalPlayer.PlayerGui.ShipControlGui.Enabled = true
            end
            portGui:Destroy()

            repeat
                local isDocked = LocalPlayer.CurrentShip.Value:GetAttribute("IsDocked")
                task.wait(0.1)
            until isDocked == false

            return
        end
        warn("EssentialData not found")
    end
    warn("PortGui not found")
end

local function getAvailableSpace()
    local ship = LocalPlayer.CurrentShip.Value
    local cargoAmount = 0
    for _, v in ship.Cargo:GetChildren() do
        if v.Transparency == 1 then
            cargoAmount += 1
        end
    end
    return cargoAmount
end

local function loadCargo()
    local ship = LocalPlayer.CurrentShip.Value
    local shipSettings = getShipSettings(ship.Name)
    if shipSettings then
        local cargoType = shipSettings["Class"]
        if cargoType then
            local dockCargo = ship.Storage.RemoteFunction:InvokeServer("GetLoadingCargo", cargoType)
            for cargoIter, cargoTable in dockCargo do
                local capacity = getAvailableSpace()
                local cargoHolds = cargoTable["Holds"]
                if capacity > 0 and capacity >= cargoHolds then
                    local args = { "Load" .. cargoType, cargoIter, cargoHolds }
                    ship.Storage.RemoteFunction:InvokeServer(unpack(args))
                elseif  capacity > 0 and capacity < cargoHolds then
                    local args = { "Load" .. cargoType, cargoIter, capacity }
                    ship.Storage.RemoteFunction:InvokeServer(unpack(args))
                else
                    break
                end
            end
        end
    end
end

local function unloadCargo()
    local ship = LocalPlayer.CurrentShip.Value
    local shipSettings = getShipSettings(ship.Name)
    local cargoType = shipSettings["Class"]
    if shipSettings then
        local loads = ship.Storage.RemoteFunction:InvokeServer("GetLoads")[shipSettings["Class"]].Loads
        for loadIter, loadTable in loads do
            ship.Storage.RemoteFunction:InvokeServer("Unload" .. cargoType, loadIter);
        end
    end
end

local function setCollisionState(ship: Model, state: boolean)
    for _, part in ship:GetDescendants() do
        if part:IsA("BasePart") then
            part.CanCollide = state
        end
    end
    for _, part in character:GetDescendants() do
        if part:IsA("BasePart") then
            part.CanCollide = state
        end
    end
end

local function moveShip(targetPosition: CFrame)
    local curShip = LocalPlayer.CurrentShip.Value
    local base = curShip.PrimaryPart
    local baseVelocity = base.BodyVelocity
    local baseGyro = base.BodyGyro
    local shipSettings = getShipSettings(curShip.Name)

    assert(curShip and curShip:IsA("Model"), "Current ship must be a Model")
    assert(base and base:IsA("BasePart"), "Base must be a BasePart")
    assert(typeof(targetPosition) == "CFrame", "targetPosition must be a CFrame")
    assert(baseVelocity and baseVelocity:IsA("BodyVelocity"), "Base part must have a BodyVelocity")
    assert(baseGyro and baseGyro:IsA("BodyGyro"), "Base part must have a BodyGyro")
    assert(shipSettings, "Ship settings not found")

    local speed = shipSettings["TopSpeed"]
    local direction, distance, velocity

    local defForce = baseVelocity.MaxForce
    baseVelocity.MaxForce = Vector3.new(1e10, 1e10, 1e10)

    setCollisionState(curShip, false)

    repeat
        direction = (targetPosition.Position - base.Position).unit
        --baseGyro.CFrame = CFrame.new(base.Position, targetPosition.Position) * CFrame.Angles(0, math.rad(math.pi*0.5), 0)

        distance = (targetPosition.Position - base.Position).magnitude

        velocity = direction * speed * 3
        baseVelocity.Velocity = velocity

        task.wait(0.1)
    until distance < 50

    baseVelocity.MaxForce = defForce
    baseVelocity.Velocity = Vector3.new(0, 0, 0)

    setCollisionState(curShip, true)
end

task.spawn(function()
    while task.wait(1) do
        if getgenv().SeeMen.serverHopOnTrustedPlayer == true then
            for _, player in Players:GetPlayers() do
                if player ~= LocalPlayer and player:GetRankInGroup(2856522) > 10 then
                    LocalPlayer:Kick("Kicked due to: " .. player.Name)
                    break
                end
            end
        end
    end
end)

local ports = findAvailablePorts()

local portNames = {}
for i, _ in ports do
    table.insert(portNames, i)
end
    
local toggleParagraphParagraph = Tabs.Main:CreateParagraph("toggleParagraphParagraph", {
    Title = "Ensure that you have spaned in a ship before toggling.",
    Content = "If this script does not work, ensure you run it AFTER you have spawned in a ship.",
})

local autoFarmToggle = Tabs.Main:CreateToggle("autoFarmToggle", {Title = "Auto Farm", Default = false })
autoFarmToggle:OnChanged(function() getgenv().SeeMen.autoFarm = autoFarmToggle.Value end)

local portParagraph = Tabs.Main:CreateParagraph("portParagraph", {
    Title = "Recommended to use ports that are close to each other.",
})

local startingPortDropdown = Tabs.Main:CreateDropdown("startingPortDropdown", {
    Title = "Starting Port",
    Values = portNames,
    Multi = false,
    Default = nil,
})
startingPortDropdown:OnChanged(function(Value) getgenv().SeeMen.startingPort = Value end)

local targetPortDropdown = Tabs.Main:CreateDropdown("targetPortDropdown", {
    Title = "Target Port",
    Values = portNames,
    Multi = false,
    Default = nil,
})

targetPortDropdown:OnChanged(function(Value) getgenv().SeeMen.targetPort = Value end)

local trustedPlayerParagraph = Tabs.Main:CreateParagraph("trustedPlayerParagraph", {
    Title = "Trusted Player Leave",
    Content = "Automatically Leaves When a trusted player joins the server.\n(ex: Admins, Moderators, etc.)",
})

local trustedPlayerToggle = Tabs.Main:CreateToggle("trustedPlayerToggle", {Title = "Anti Trusted Player", Default = false })
trustedPlayerToggle:OnChanged(function() getgenv().SeeMen.serverHopOnTrustedPlayer = trustedPlayerToggle.Value end)

local antiAFKToggle = Tabs.Main:CreateToggle("antiAFKToggle", {Title = "Anti AFK", Default = false })
antiAFKToggle:OnChanged(function() getgenv().SeeMen.antiAFK = antiAFKToggle.Value end)

SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)

InterfaceManager:SetFolder("SeeMen")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)

Window:SelectTab(1)

Library:Notify{
    Title = "SeeMen",
    Content = "The script has been loaded.",
    Duration = 8
}

-- Setup VirtualUser & Player
local vu = game:GetService("VirtualUser")

LocalPlayer.Idled:Connect(function(time)
    if getgenv().SeeMen.antiAFK == false and time > 600 then return end
    vu:CaptureController()
    vu:ClickButton2(Vector2.new())
end)

while task.wait() do
    if getgenv().SeeMen.autoFarm == true then
        local AvailableSpace = getAvailableSpace()
        moveShip(CFrame.new(ports[getgenv().SeeMen.startingPort]))
        DockShip()
        if AvailableSpace > 0 then
            loadCargo()
        else
            unloadCargo()
            loadCargo()
        end
        UndockShip()
        moveShip(CFrame.new(ports[getgenv().SeeMen.targetPort]))
        print(getgenv().SeeMen.targetPort, type(getgenv().SeeMen.targetPort))
        AvailableSpace = getAvailableSpace()
        DockShip()
        if AvailableSpace > 0 then
            loadCargo()
        else
            unloadCargo()
            loadCargo()
        end
        UndockShip()
    end
end
