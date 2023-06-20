
--[[

	TITLE: Action

	DESC: This module is responsible for handling Admin-script like actions using the shared table and a function
		  The idea is for developers to easily be able to perform common actions using a simple command syntax
		  on server aspects or on players.

	AUTHOR: RoyallyFlushed
	
	CREATED: 03/22/2022
	MODIFIED: 03/22/2022
	
--]]


local module = {}

local network = nil
local utility = nil

module.Commands = {
	KICK = 1,
	BAN = 2,
}

module.CommandWords = {
	["kick"] = module.Commands.KICK,
	["ban"] = module.Commands.BAN
}


function module.Init(nebula)
	
	network = nebula.Network
	utility = nebula.Utility
	
	network:CreateEvent("DevAction", "BindableFunction")
	
	shared.action = function(msg)
		
		local cmd = nil
		local args = {}
		
		if msg:len() == 0 then
			return
		end
		
		msg = msg:lower()
		cmd = msg:match("^%w+")
		msg = msg:gsub("^%w+", "", 1)
		
		for w in msg:gmatch("%S+") do
			table.insert(args, w)
		end
		
		if module.CommandWords[cmd] == module.Commands.KICK then
			-- Send kick request to Moderation Service
		elseif module.CommandWords[cmd] == module.Commands.BAN then
			-- Send ban request to Moderation Service
		end
		
	end
	
end


return module
