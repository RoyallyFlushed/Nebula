
--[[

	TITLE: Nebula
	
	DESC: This module is responsible for initiating the entire framework and all of its components. Both the server
		  and client must require this script in order for their respective environments to function.
		  
	AUTHOR: RoyallyFlushed

	CREATED: 03/12/2022
	MODIFIED: 09/05/2022
	
	TODO:
		- Add support for functions like main(), RenderStepped(), Heartbeat(), etc to go along with .Init
			- Init() should be for service and module startup to allow them to be used later
			- Main() should be for the start of service and module use
				- For example, the Player service may need to set up a network event, this would start in the Main()
				  as the Init() would be reserved for getting the Player Service setup to actually be used
		  	- RenderStepped() and Heartbeat() should simply be connected to their respective Roblox systems

--]]



--// Services
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = nil
local PlayerScripts = nil

--// Variables
local directories
local environment = ""

local nebula = {}
local initPriorities = {}
local initLock = true


-- Handle setup on client and server differently
if RunService:IsClient() then
	-- Wait for server to finish setting up client
	game.Players.LocalPlayer:WaitForChild("Initialised", 3600)
	
	PlayerScripts = game.Players.LocalPlayer.PlayerScripts
	directories = { ReplicatedStorage.Shared, PlayerScripts.Controllers, PlayerScripts.Modules }
	environment = "Client"
	
	nebula.Client = {}
	nebula.Client.Player = game.Players.LocalPlayer
	
	-- Load UI into PlayerGui
	for _, gui in ReplicatedStorage.UI:GetChildren() do
		gui.Parent = game.Players.LocalPlayer.PlayerGui
	end
elseif RunService:IsServer() then
	ServerScriptService = game:GetService("ServerScriptService")
	directories = { ReplicatedStorage.Shared, ServerScriptService.Services, ServerScriptService.Modules }
	environment = "Server"
	nebula.Server = {}
end


-- Initialise Core scripts with modules
local function initialise()
	local errors = {}
	
	-- Loop through the initialisation priorities and load modules
	for _, data in initPriorities do
		local module = nebula[data.moduleName]
		
		-- Check if module is a table, hasn't been initialised and has an init function
		if typeof(module) == "table" and not module._initialised and module.Init then
			-- Call the init function with protected call as to not mess up subsequent modules
			local success, result = pcall(module.Init, nebula)
			
			-- Set module initialised flag
			if success then
				module._initialised = true
				print(("$ %s -> Initialised"):format(environment), data.moduleName)
			else
				table.insert(errors, result)
				warn(("$ %s -> Initialisation of %s failed!"):format(environment, data.moduleName))
			end
		end
	end
	
	-- Check to see if any errors occured during initialisation
	if #errors == 0 then
		print(("$ %s -> All modules in queue initialised"):format(environment))
	else
		print(("$ %s -> All modules in queue initialised with the exception of %d"):format(environment, #errors))
	end
	
	-- If errors occured, post them
	for _, err in errors do
		task.spawn(function()
			error(err)
		end)
	end
end

-- Setup the directory by requiring all modules and adding them to the table
local function setup(directory)
	for _, moduleScript in directory:GetDescendants() do
		if moduleScript:IsA("ModuleScript") then
			local module = require(moduleScript)
			
			-- Error if module script returns a function
			if typeof(module) ~= "table" then
				error(("$ %s -> Attempt to setup module `%s`, `table` expected, got `%s`"):format(environment, moduleScript.Name, typeof(module)))
			end
			
			-- If _ignore flag is present, do not load the module
			if module._ignore then
				continue
			end
			
			-- If module uses a reserved name, then error
			if RunService:IsClient() and moduleScript.Name == "Client" then
				error("$ Client -> Attempt to setup module with reserved name `Client`!")
			elseif RunService:IsServer() and moduleScript.Name == "Server" then
				error("$ Server -> Attempt to setup module with reserved name `Server`!")
			end
			
			-- If module uses a name of a module already present, then error
			if nebula[moduleScript.Name] ~= nil then
				error(("$ %s -> Attempt to require module with already existing name %s!"):format(environment, moduleScript.Name))
			end
			
			-- Add the module to nebula and priorities table
			nebula[moduleScript.Name] = module
			table.insert(initPriorities, { 
				priority = module.Priority or 10, 
				module = module, 
				moduleName = moduleScript.Name 
			})
			print(("$ %s -> Required"):format(environment), moduleScript.Name)
		end
	end
end


-- Start timing load times
local loadtimer_start = os.clock()


-- Loop through directories and setup nebula
for _, directory in directories do
	-- call to setup directory (require modules)
	setup(directory)

	-- Handle future additions to the directory
	directory.DescendantAdded:Connect(function(moduleScript)
		if moduleScript:IsA("ModuleScript") then
			local module = require(moduleScript)
			
			-- Error if module script returns a function
			if typeof(module) ~= "table" then
				error(("$ %s -> Attempt to setup module `%s`, `table` expected, got `%s`"):format(environment, moduleScript.Name, typeof(module)))
			end
			
			-- If _ignore flag is present, then do not load
			if module._ignore then
				return
			end
			
			-- If module script uses a reserved name, then error
			if RunService:IsClient() and moduleScript.Name == "Client" then
				error("$ Client -> Attempt to setup module with reserved name `Client`!")
			elseif RunService:IsServer() and moduleScript.Name == "Server" then
				error("$ Server -> Attempt to setup module with reserved name `Server`!")
			end
			
			-- If module script uses a name of an already present module, then error
			if nebula[moduleScript.Name] ~= nil then
				error(("$ %s -> Attempt to require module with already existing name %s!"):format(environment, moduleScript.Name))
			end
			
			-- Add the module to nebula
			nebula[moduleScript.Name] = module
			print(("$ %s -> Required"):format(environment), moduleScript.Name)

			-- Initialise the module
			if not initLock and typeof(module) == "table" and not module._initialised and module.Init then
				module.Init(nebula)
				module._initialised = true
				print(("$ %s -> Initialised"):format(environment), module.Name)
			end
		end
	end)
end

-- Sort based on priority
table.sort(initPriorities, function(a, b)
	return (a.priority or 10) < (b.priority or 10)
end)

-- Allow initialisation
initLock = false
initialise()


local loadtimer_finish = os.clock()
local loadtimer_dxms = (loadtimer_finish - loadtimer_start) * 1000
print(("$ %s -> Process took %.2f ms to complete\n"):format(environment, loadtimer_dxms))


return 0

