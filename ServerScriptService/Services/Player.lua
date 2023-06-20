local module = {}

module.Priority = 4

local network = nil
local timekeeper = nil


-- Handle client initialisation
function module.InitClient(player)
	
	local initialised = Instance.new("BoolValue")
	initialised.Name = "Initialised"
	initialised.Value = true
	initialised.Parent = player
	
end


function module.Init(nebula)
	network = nebula.Network
	
	-- Setup events
	network:CreateEvent("TestEvent", "BindableEvent")
	
	-- Init incoming players	
	game.Players.PlayerAdded:Connect(module.InitClient)
	task.spawn(function()
		for _, player in next, game.Players:GetPlayers() do
			if not player:FindFirstChild("Initialised") then
				module.InitClient(player)
			end
		end
	end)
	
end

return module
