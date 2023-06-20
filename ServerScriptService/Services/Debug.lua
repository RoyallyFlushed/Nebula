
--[[

	TITLE: Debug

	DESC: This module is responsible for handling all debug requests. The module will setup a function under
		  the shared library which any server script can access. Functions and command-line style requests
		  can be sent through as arguments to this function which will execute in the server's integrated
		  environment. The aim of this service is to provide developers with easy-to-use debug tools in live
		  game sessions.

	AUTHOR: RoyallyFlushed
	
	CREATED: 03/16/2022
	MODIFIED: 04/01/2022
	
--]]


local module = {}

local network = nil
local utility = nil

module.Flags = {
	{ 
		Letters = {
			"r"
		}, 
		
		Words = {
			"run"
		}
	},
	{ 
		Letters = {
			"o"
		}, 

		Words = {
			"output"
		}
	},
	{ 
		Letters = {
			"g"
		}, 

		Words = {
			"get"
		}
	},
}

module.FlagEnums = {
	RUN = 1,
	OUTPUT = 2,
	GET = 3
}

module.TypeEnums = {
	CUSTOM = 1,
	NETWORK_DUMP = 2,
	SESSION_DUMP = 3,
	DATA_DUMP = 4
}


local function printDebugHeader(text)
	local msg = "--"..(text:gsub("%s", "_")):upper().."--"
	local bar = string.rep("-", msg:len())
	if text:match("START") then
		print("")
	end
	print(bar)
	print(msg)
	print(bar)
	if text:match("END") then
		print("")
	end
end


function module.Init(nebula)
	
	network = nebula.Network
	utility = nebula.Utility
	
	
	network:CreateEvent("DevDebug", "BindableFunction")
	network:Connect({
		Event = "DevDebug",
		Function = function(data)
			
			if data.Function then
				return {
					Type = module.TypeEnums.CUSTOM,
					Data = data.Function(nebula)
				}
			end
			
			assert(utility.len(module.TypeEnums) == 4, "$ Debug -> Exhaustive handling of type enums in DevDebugEvent Listener!")
			if data.Arguments[1] == "networkdump" then
				return {
					Type = module.TypeEnums.NETWORK_DUMP,
					Data = nebula.Network.Events
				}
			elseif data.Arguments[1] == "sessiondump" then
				return {
					Type = module.TypeEnums.SESSION_DUMP,
					Data = nebula.Server.Session
				}
			elseif data.Arguments[1] == "datadump" and typeof(data.Arguments[2]) == "string" then
				local player = utility.findFirstChildNonCaseSensitive(game.Players, data.Arguments[2])
				if player then
					return {
						Type = module.TypeEnums.DATA_DUMP,
						Data = {
							PlayerName = player.Name,
							PlayerData = nebula.Server.Session[tostring(player.UserId)]
						}
					}
				end
			end
			
			return nil
		end
	})
	
	shared.debug = function(cmd, func)
		
		local flags = {}
		local args = {}
		local usedFlags = {}
		
		if cmd:len() == 0 then
			return
		end

		-- Get flags
		for arg in cmd:gmatch("%S+") do
			if arg:match("^-") then
				local flag = arg:sub(2)
				
				for f_index, f_data in next, module.Flags do
					if not table.find(usedFlags, f_index) then
						
						for _, word in next, f_data.Words do
							if flag == word then
								table.insert(flags, f_index)
								table.insert(usedFlags, f_index)
								break
							end
						end
					end
				end
				
				for f_letter in flag:gmatch("%w") do
					for f_index, f_data in next, module.Flags do
						if not table.find(usedFlags, f_index) then
							
							for _, letter in next, f_data.Letters do
								if f_letter == letter then
									table.insert(flags, f_index)
									table.insert(usedFlags, f_index)
								end
							end
						end
					end
				end
			else
				table.insert(args, arg)
			end
		end
		
		local runFlag = false
		local outputFlag = false
		local getFlag = false

		for _, flag in next, flags do
			if flag == module.FlagEnums.OUTPUT then
				outputFlag = true
			elseif flag == module.FlagEnums.RUN then
				runFlag = true
			elseif flag == module.FlagEnums.GET then
				getFlag = true
			end
		end
		
		if #args == 0 and not runFlag then
			return
		end
		
		local result = network:Invoke({
			Event = "DevDebug",
			Data = {
				Arguments = args,
				Function = runFlag and func
			}
		})
		
		if result == nil then
			return
		end
		
		if outputFlag then
			assert(utility.len(module.TypeEnums) == 4, "$ Debug -> Exhaustive handling of type enums in shared.debug()!")
			if result.Type == module.TypeEnums.NETWORK_DUMP then
				printDebugHeader("Network Dump Start")
				for i, v in next, result.Data do
					print(v.Name, ":", v.ClassName)
				end
				printDebugHeader("Network Dump End")
			elseif result.Type == module.TypeEnums.SESSION_DUMP then
				printDebugHeader("Session Dump Start")
				for name, _ in next, result.Data do
					print(name)
				end
				printDebugHeader("Session Dump End")
			elseif result.Type == module.TypeEnums.DATA_DUMP then
				printDebugHeader("Data Dump Start")
				print("DATA DUMP FOR PLAYER", result.Data.PlayerName:upper())
				utility.printOnNewLine(utility.prettyTable(result.Data.PlayerData))
				printDebugHeader("Data Dump End")
			end
		end
		
		if getFlag then
			return result.Data
		end
	end
	
end


return module
