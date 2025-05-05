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
local hrp = character:WaitForChild("HumanoidRootPart", 5)

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GlobalConfig = require(ReplicatedStorage.GlobalReplicated.GlobalConfig)

getgenv().SeeMen = {
    autoFarm = false,
    startingPort = nil,
    targetPort = nil,
    serverHopOnTrustedPlayer = false,
    antiAFK = false,
    autoRefuel = false
}

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
    if not ship then return end
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

local function LookAt(part: Instance, targetPos: Vector3)
    assert(typeof(part) == "Instance" and part:IsA("BasePart"), "First argument must be a BasePart")
    assert(typeof(targetPos) == "Vector3", "Second argument must be a Vector3")
    part.CFrame = CFrame.new(part.Position, targetPos) * CFrame.Angles(0, math.rad(-90), 0)
end

local function DockShip(targetPosition: Vector3)
    local ShipControlGui = PlayerGui:WaitForChild("ShipControlGui", 5)
    local shipControllerScript = ShipControlGui:WaitForChild("Controller", 5)

    local InteractionZonesModule = require(shipControllerScript.Modules.InteractionZonesModule)

    local base = LocalPlayer.CurrentShip.Value.PrimaryPart
    local baseVelocity = base.BodyVelocity

    local shipSettings = getShipSettings(LocalPlayer.CurrentShip.Value.Name)

    local direction, isDocked, distance
    local speed = shipSettings["TopSpeed"]

    repeat
        distance = (targetPosition - base.Position).magnitude
        if distance > 50 then
            local argsStop = { "SetThrottle", 0 }
            game.Players.LocalPlayer.CurrentShip.Value.Storage.RemoteEvent:FireServer(unpack(argsStop))
            LookAt(base, targetPosition)
        end

        InteractionZonesModule.DockShip()
        isDocked = LocalPlayer.CurrentShip.Value:GetAttribute("IsDocked")

        task.wait()
    until isDocked == true or getgenv().SeeMen.autoFarm == false

    local portGui = PlayerGui:WaitForChild("PortGui", 15)
    if portGui then
        local EssentialData = require(portGui.Scripts.EssentialData)
        if EssentialData then
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
                task.wait(0.5)
            until isDocked == false or getgenv().SeeMen.autoFarm == false

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
        if getgenv().SeeMen.autoRefuel then
            local fuelNeeded = ship:GetAttribute("ShipFuelMax") - ship:GetAttribute("ShipFuel")
            local args = { "RefuelShip", fuelNeeded }
            ship.Storage.RemoteFunction:InvokeServer(unpack(args))
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

local function moveShip(targetPosition: Vector3)
    local curShip = LocalPlayer.CurrentShip.Value
    local base = curShip.PrimaryPart
    local baseGyro = base.BodyGyro
    local baseVelocity = base.BodyVelocity
    local shipSettings = getShipSettings(curShip.Name)

    assert(curShip and curShip:IsA("Model"), "Current ship must be a Model")
    assert(base and base:IsA("BasePart"), "Base must be a BasePart")
    assert(typeof(targetPosition) == "Vector3", "targetPosition must be a Vector3")
    assert(baseGyro and baseGyro:IsA("BodyGyro"), "Base part must have a BodyGyro")
    assert(shipSettings, "Ship settings not found")

    local topSpeed = shipSettings["TopSpeed"] or 10
    local distance, speed

    local argsGo = { "SetThrottle", topSpeed }
    curShip.Storage.RemoteEvent:FireServer(unpack(argsGo))

    repeat
        setCollisionState(curShip, false)

        LookAt(base, targetPosition)

        distance = (targetPosition - base.Position).magnitude

        local speedU = math.sqrt((baseVelocity.Velocity.X ^ 2) + (baseVelocity.Velocity.Z ^ 2))
        speed = speedU / 3

        task.wait()
    until distance < 30 * speed or getgenv().SeeMen.autoFarm == false

    local argsStop = { "SetThrottle", 0 }
    curShip.Storage.RemoteEvent:FireServer(unpack(argsStop))
end

task.spawn(function()
    while task.wait(1) do
        if getgenv().SeeMen.serverHopOnTrustedPlayer == true then
            for _, player in Players:GetPlayers() do
                if player ~= LocalPlayer and player:GetRankInGroup(2856522) > 10 then
                    LocalPlayer:Kick("Kicked due to trusted player joining: " .. player.Name)
                    break
                end
            end
        end
    end
end)

local toggleParagraphParagraph = Tabs.Main:CreateParagraph("toggleParagraphParagraph", {
    Title = "Ensure that you have spaned in a ship before toggling.",
    Content = "If this script does not work, ensure you run it AFTER you have spawned in a ship.",
})

local autoFarmToggle = Tabs.Main:CreateToggle("autoFarmToggle", {Title = "Auto Farm", Default = false })
autoFarmToggle:OnChanged(function() getgenv().SeeMen.autoFarm = autoFarmToggle.Value end)

local autoRefuelToggle = Tabs.Main:CreateToggle("autoRefuelToggle", {Title = "Auto Refuel", Default = true })
autoRefuelToggle:OnChanged(function() getgenv().SeeMen.autoRefuel = autoRefuelToggle.Value end)

local startingPortDropdown = Tabs.Main:CreateDropdown("startingPortDropdown", {
    Title = "Starting Port",
    Values = {},
    Multi = false,
    Default = nil,
})
startingPortDropdown:OnChanged(function(Value) getgenv().SeeMen.startingPort = Value end)

local targetPortDropdown = Tabs.Main:CreateDropdown("targetPortDropdown", {
    Title = "Target Port",
    Values = {},
    Multi = false,
    Default = nil,
})

targetPortDropdown:OnChanged(function(Value) getgenv().SeeMen.targetPort = Value end)

local trustedPlayerParagraph = Tabs.Main:CreateParagraph("trustedPlayerParagraph", {
    Title = "Trusted Player Leave",
    Content = "Automatically leaves when a trusted player joins the server.\n(ex: Admins, Moderators, etc.)",
})

local trustedPlayerToggle = Tabs.Main:CreateToggle("trustedPlayerToggle", {Title = "Anti Trusted Player", Default = true })
trustedPlayerToggle:OnChanged(function() getgenv().SeeMen.serverHopOnTrustedPlayer = trustedPlayerToggle.Value end)

local antiAFKToggle = Tabs.Main:CreateToggle("antiAFKToggle", {Title = "Anti AFK", Default = true })
antiAFKToggle:OnChanged(function() getgenv().SeeMen.antiAFK = antiAFKToggle.Value end)

Tabs.Main:CreateButton{
    Title = "Complete Tutorial",
    Description = "Respawn your ship once you use it.",
    Callback = function()
        ReplicatedStorage.RemoteStorage.RemoteEvent:FireServer("FinishedTutorial")
    end
}

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

local function updatePorts()
    local ports = findAvailablePorts()

    local portNames = {}
    for i, _ in ports do
        table.insert(portNames, i)
    end

    startingPortDropdown:SetValues(portNames)
    targetPortDropdown:SetValues(portNames)

    if getgenv().SeeMen.startingPort == nil then
        startingPortDropdown:SetValue(portNames[2])
    end
    if getgenv().SeeMen.targetPort == nil then
        targetPortDropdown:SetValue(portNames[1])
    end
end

while task.wait(0.5) do
    local ship = LocalPlayer.CurrentShip.Value
    local ports = findAvailablePorts()
    if ports then updatePorts() end

    if getgenv().SeeMen.autoFarm == true and ship then
        local AvailableSpace = getAvailableSpace()
        moveShip(ports[getgenv().SeeMen.startingPort])
        DockShip(ports[getgenv().SeeMen.startingPort])
        if AvailableSpace > 0 then
            loadCargo()
        else
            unloadCargo()
            loadCargo()
        end
        UndockShip()
        AvailableSpace = getAvailableSpace()
        moveShip(ports[getgenv().SeeMen.targetPort])
        DockShip(ports[getgenv().SeeMen.targetPort])
        if AvailableSpace > 0 then
            loadCargo()
        else
            unloadCargo()
            loadCargo()
        end
        UndockShip()
    end
end

LocalPlayer:Kick("Kicked to prevent a ban, please rejoin")
