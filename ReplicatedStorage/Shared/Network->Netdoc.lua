
--[[

	TITLE: Netdoc

	DESC: This module does nothing functionally but rather serves merely as a way to keep track of used events
		  within the game so that developers can easily identify which event does what. Everything should be
		  fully detailed in the framework's official documentation and/or in the game's official documentation,
		  however, this serves as a quick lookup guide.
		  
	AUTHOR: RoyallyFlushed
	
	CREATED: 03/16/2022
	MODIFIED: 03/16/2022

--]]


local module = {}


module.RemoteEvents = {
	"NetworkInternalEvent" --[[ Hardcoded and manually initiated network event used inside the Network service
								to bootstrap communication between client and server
						   --]]
}

module.RemoteFunctions = {
	"NetworkInternalRequest" --[[ Hardcoded and manually initiated network event used inside the Network service
								  to bootstrap communication between client and server
							 --]]
}

module.ServerBindableEvents = {
	
}

module.ServerBindableFunctions = {
	
}

module.ClientBindableEvents = {
	
}

module.ClientBindableFunctions = {
	
}


return module
