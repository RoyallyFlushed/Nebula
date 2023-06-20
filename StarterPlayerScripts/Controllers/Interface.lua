
--[[

	TITLE: Interface
	
	DESC: This module is responsible for handling generic GUI functions as well as setting up bindable events
		  for non-integrated scripts to use in order to access elements of the Client Framework. This module
		  will call sub-interface nebula and initialise them with their respective GUI objects.
		  
		  The idea behind this implementation is to extract key logical code from the UI itself and store it
		  inside the core interface controller where it can be easily found, accessed and maintained, while
		  also keeping basic functionality within the UI's handler scripts itself.
		  
		  GUI Objects should be moved from StarterGui into the Framework's UI folder within ReplicatedStorage
		  as this will allow the UI to load at the same time as all the other data, meaning no WaitForChild
		  yields need to be used, as ALL UI will be completely loaded before any client code is ran.
		  
		  Different UI elements should have their own GUI Objects as Roblox has a number of performance gains
		  from utilising different ScreenGui objects.
		  

	AUTHOR: RoyallyFlushed
	
	CREATED: 03/16/2022
	MODIFIED: 06/04/2022

--]]


local module = {}

module.Priority = 5 -- Low priority controller (UI should always be last thing)


function module.GiveInterfaces(nebula)
	for _, guiObject in next, game.ReplicatedStorage.UI:GetChildren() do
		guiObject:Clone().Parent = nebula.Client.Player.PlayerGui
	end
end


function module.Init(nebula)
	-- Initialise this controller
	
	module.GiveInterfaces(nebula)
	
	for _, guiObject in next, nebula.Client.Player.PlayerGui:GetChildren() do
		for _, guiModule in next, script:GetChildren() do
			if guiObject.Name == guiModule.Name then
				local module = require(guiModule)
				
				if typeof(module) ~= "table" then
					warn(("$ Interface -> Interface Controller %s is not of type table!"):format(guiModule.Name))
					return
				end
				
				if not module.Init then
					warn(("$ Interface -> Interface Controller %s does not have an init function!"):format(guiModule.Name))
					return
				end
				
				task.spawn(function()
					module.Init(guiObject)
				end)
			end
		end
	end
	
end


return module
