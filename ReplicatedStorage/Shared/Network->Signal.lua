
--[[

	TITLE: Signal

	DESC: This module is responsible for providing an OOP class for custom script signals which will be
		  utilised in the Network module over Roblox's Bindable objects.
	
	AUTHOR: RoyallyFlushed
	
	CREATED: 03/23/2022
	MODIFIED: 09/05/2022

--]]



local module = {}


function module.new()
	local obj = setmetatable({}, {__index = module})
	return obj
end

function module:Connect(func)
	self.Function = func
end

function module:Disconnect()
	self.Function = nil
end

function module:Fire(...)
	if self.Function then
		task.spawn(self.Function, ...)
	end
end

function module:Invoke(...)
	if self.Function then
		return self.Function(...)
	end
end


return module
