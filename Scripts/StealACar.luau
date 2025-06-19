if game.PlaceId ~= 6428267216 then return warn("Incorrect Game") end

local SeeMenGameStates = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/SeeMen-Hub/SeeMen/refs/heads/main/SeeMen-Game-States.luau"))()
if SeeMenGameStates.DriftingOnABrick == false then return warn("Script is not currently supported.") end

local SeeMenUIModule = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/SeeMen-Hub/SeeMen/refs/heads/main/Utils/SeeMen-UI.luau"))()

local MarketplaceService = game:GetService("MarketplaceService")

local placeId = game.PlaceId
local info = MarketplaceService:GetProductInfo(placeId, Enum.InfoType.Asset)

local UIResults = SeeMenUIModule:Init({
    window = {
        Title = "SeeMen | " .. info.Name,
        Icon = "door-open",
        Author = "That Fella",
        Folder = "SeeMen",
        Size = UDim2.fromOffset(800, 800),
        Transparent = true,
        Theme = "Dark",
        SideBarWidth = 200,
        Background = "",
        User = { Enabled = false },
        ToggleKey = Enum.KeyCode.LeftAlt,
        DefaultTab = 1,
    },
    tabs = {
        {
            Key = "Main",
            Title = "Main",
            Icon = "house",
            Locked = false,
        },
    },
    addVisualsTab = true,
    addSettingsTab = true
})

local Window = UIResults.Window
local tabs = UIResults.Tabs