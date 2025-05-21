local SeeMenModule = {}

function SeeMenModule:Init(config)
    repeat task.wait(0.1) until game:IsLoaded()

    local SeeMenESP = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/That-Fella/SeeMen/refs/heads/main/Utils/SeeMen-ESP.luau"))()
    local PathFindingModule = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/That-Fella/SeeMen/refs/heads/main/Utils/SeeMen-PathFindingModule.luau"))()
    local AntiAFKModule = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/That-Fella/SeeMen/refs/heads/main/Utils/SeeMen-AntiAFK.luau"))()

    local espSettings = {
        enabled = false,
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
        showTeam = true,
        useTeamColor = true,
        fallbackColor = Color3.new(0.3, 0.5, 1),
        playerOverrides = {},
        showHealthBar = true,
        healthBarPosition = "Left",
        tracers = false,
        tracerTransparency = 0.5,
        tracerOrigin = "bottom",
    }

    SeeMenESP.settings = espSettings

    local WindUI = loadstring(game:HttpGetAsync("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

    local winCfg = config.window or {}
    local tabsCfg = config.tabs or {}
    local addVisuals = config.addVisualsTab ~= false
    local addSetting = config.addSettingsTab ~= false

    local Window = WindUI:CreateWindow(winCfg)

    local Tabs = {}

    for _, tabInfo in ipairs(tabsCfg) do
        local key = tabInfo.Key or tabInfo.title or tabInfo.Title
        local title = tabInfo.Title or tabInfo.title
        Tabs[key] = Window:Tab({Title = title, Icon = tabInfo.Icon, Locked = tabInfo.Locked})
    end

    if addVisuals then
        local vTab = Window:Tab({Title = "Visuals", Icon = "eye", Locked = false})
        Tabs.Visuals = vTab
        vTab:Toggle({Title = "ESP", Default = false, Callback = function(s) SeeMenESP.settings.enabled = s end})
        vTab:Toggle({Title = "Box", Default = true, Callback = function(s) SeeMenESP.settings.showBox = s end})
        vTab:Colorpicker({Title = "Color", Desc = "Only used if no team color", Default = Color3.fromRGB(0, 0, 0), Callback = function(c) SeeMenESP.settings.fallbackColor = c end})
        vTab:Slider({Title = "Box Thickness", Step = 1, Value = {Min = 1, Max = 5, Default = 2}, Callback = function(v) SeeMenESP.settings.boxThickness = v end})
        vTab:Toggle({Title = "Box Fill", Default = true, Callback = function(s) SeeMenESP.settings.fillBox = s end})
        vTab:Colorpicker({Title = "Box Fill Color", Default = Color3.fromRGB(0, 0, 0), Callback = function(c) SeeMenESP.settings.fillBoxColor = c end})
        vTab:Slider({Title = "Box Fill Transparency", Step = 0.1, Value = {Min = 0, Max = 1, Default = 0.3}, Callback = function(v) SeeMenESP.settings.fillTransparency = v end})
        vTab:Toggle({Title = "Show Name", Default = true, Callback = function(s) SeeMenESP.settings.showName = s end})
        vTab:Toggle({Title = "Use Display Name", Default = true, Callback = function(s) SeeMenESP.settings.useDisplayName = s end})
        vTab:Toggle({Title = "Show Team Name", Default = true, Callback = function(s) SeeMenESP.settings.showTeamName = s end})
        vTab:Toggle({Title = "Show Distance", Default = true, Callback = function(s) SeeMenESP.settings.showDistance = s end})
        vTab:Slider({Title = "Text Display Distance", Step = 1, Value = {Min = 0, Max = 1000, Default = 150}, Callback = function(v) SeeMenESP.settings.maxTextDistance = (v == 0) and math.huge or v end})
        vTab:Slider({Title = "Text Size", Step = 1, Value = {Min = 0, Max = 30, Default = 15}, Callback = function(v) SeeMenESP.settings.textSize = v end})
        vTab:Toggle({Title = "Text Outline", Default = true, Callback = function(s) SeeMenESP.settings.outlineText = s end})
        vTab:Toggle({Title = "Team Check", Default = true, Callback = function(s) SeeMenESP.settings.showTeam = s end})
        vTab:Toggle({Title = "Use Team Color", Default = true, Callback = function(s) SeeMenESP.settings.useTeamColor = s end})
        vTab:Toggle({Title = "Health Bar", Default = true, Callback = function(s) SeeMenESP.settings.showHealthBar = s end})
        vTab:Dropdown({Title = "Health Bar Position", Values = {"Left", "Right", "Bottom", "Top"}, Default = "Left", Callback = function(o) SeeMenESP.settings.healthBarPosition = o end})
        vTab:Toggle({Title = "Tracers", Default = false, Callback = function(s) SeeMenESP.settings.tracers = s end})
        vTab:Slider({Title = "Tracer Transparency", Step = 0.1, Value = {Min = 0, Max = 1, Default = 0.3}, Callback = function(v) SeeMenESP.settings.tracerTransparency = v end})
        vTab:Dropdown({Title = "Tracer Origin", Values = {"Left", "Right", "Bottom", "Top", "Middle", "Cursor"}, Default = "Bottom", Callback = function(o) SeeMenESP.settings.tracerOrigin = o end})
    end

    if addSetting then
        local sTab = Window:Tab({Title = "Settings", Icon = "settings", Locked = false})
        Tabs.Settings = sTab
        sTab:Toggle({Title = "Anti AFK", Default = true, Callback = function(s) AntiAFKModule.toggle = s end})
    end

    if winCfg.ToggleKey then
        Window:SetToggleKey(winCfg.ToggleKey)
    end

    if winCfg.DefaultTab then
        if type(winCfg.DefaultTab) == "number" then
            Window:SelectTab(winCfg.DefaultTab)
        elseif Tabs[winCfg.DefaultTab] then
            Window:SelectTab(Tabs[winCfg.DefaultTab])
        end
    end

    return {
        Window = Window,
        Tabs = Tabs,
        ESP = SeeMenESP,
        PathFinding = PathFindingModule,
        AntiAFK = AntiAFKModule
    }
end

return SeeMenModule
