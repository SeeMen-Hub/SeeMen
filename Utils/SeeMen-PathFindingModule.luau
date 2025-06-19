local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PathFindingModule = {}

local player = Players.LocalPlayer
local character = player.Character
local humanoid = character:WaitForChild("Humanoid")

local TEST_DESTINATION = Vector3.new(100, 0, 100)

local waypoints
local nextWaypointIndex
local reachedConnection
local blockedConnection

PathFindingModule.followPath = function(destination: Vector3, parameters: table)
    local args = parameters or { AgentRadius = 3, AgentHeight = 6, AgentCanJump = true, AgentCanClimb = true, WaypointSpacing = 4, Costs = {}}
    local path = PathfindingService:CreatePath(args)
    
	-- Compute the path
	local success, errorMessage = pcall(function()
		path:ComputeAsync(character.PrimaryPart.Position, destination)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		waypoints = path:GetWaypoints()

		-- Detect if path becomes blocked
		blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
			-- Check if the obstacle is further down the path
			if blockedWaypointIndex >= nextWaypointIndex then
				-- Stop detecting path blockage until path is re-computed
				blockedConnection:Disconnect()
				-- Call function to re-compute new path
				PathFindingModule.followPath(destination)
			end
		end)

		-- Detect when movement to next waypoint is complete
		if not reachedConnection then
			reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
				if reached and nextWaypointIndex < #waypoints then
					-- Increase waypoint index and move to next waypoint
					nextWaypointIndex += 1
					humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
				else
					reachedConnection:Disconnect()
					blockedConnection:Disconnect()
				end
			end)
		end

		nextWaypointIndex = 2
		humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
	else
		warn("Path not computed!", errorMessage)
	end
end

return PathFindingModule
