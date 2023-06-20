local module = {}

module.Priority = 2

local Modules = nil
local network = nil


function module.UpdateSessionInfo(data)
	if data and data.Session then
		Modules.Client.Session = data.Session
	end
end

function module.core()
	
end

function module.Init(nebula)
	Modules = nebula
	network = nebula.Network
	
	network:Connect({
		Name = "SessionDataUpdater",
		Event = "SessionDataUpdate",
		Function = module.UpdateSessionInfo
	})
	
	task.delay(1, module.core)
	
end

return module
