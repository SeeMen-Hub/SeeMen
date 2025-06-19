local games = {
  95702387256198 = "https://raw.githubusercontent.com/SeeMen-Hub/SeeMen/refs/heads/main/Scripts/StealACar.luau"
}

if games[game.PlaceId] then
  loadstring(game:HttpGet(games[game.PlaceId]))()
end
