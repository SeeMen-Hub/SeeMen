-- Wait until game is loaded
repeat task.wait(0.1) until game:IsLoaded()

-- Setup VirtualUser & Player
local vu = game:GetService("VirtualUser")
local plr = game:GetService("Players").LocalPlayer

local antiAFK = {
  toggle = true
}

-- Connect an event so that if the player goes idle, it prevents the kick
plr.Idled:Connect(function(time)
    if antiAFK.toggle == false and time > 600 then return end
    vu:CaptureController()
    vu:ClickButton2(Vector2.new())
end)

return antiAFK
