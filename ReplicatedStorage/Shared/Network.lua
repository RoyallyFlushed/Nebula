
--[[

	TITLE: NETWORK
	
	DESC: Manages all communication between server and clients. All network traffic will utilise this module to create events,
		  connect to events, and much more. This module will aim to facilitate common features that may be required or useful
		  when maintaining the netcode of a game.


	AUTHOR: RoyallyFlushed
	
	CREATED: 03/12/2022
	MODIFIED: 09/05/2022
	
	
	API:
		void	CreateEvent( string name, enum typ )
		void	Connect( table data )
		void 	Disconnect( string connectionName )
		any		Request( table body )

	
	TODO:
		- Log network requests
		- Refactor codebase
		- Rework bindable events to use a Script implementation (Signal class)
	
--]]


--// Nebula
local Utility, Output

local n_assert, n_error, n_warn, n_print = nil, nil, nil


local module = {}
module.Priority = 1


--// Dependencies
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")


--// Variables
local Network = ReplicatedStorage.Network
local PrivateNetwork = nil


--// Enums
module.EventTypes = {
	REMOTE_EVENT = "RemoteEvent",
	REMOTE_FUNCTION = "RemoteFunction",
	BINDABLE_EVENT = "BindableEvent",
	BINDABLE_FUNCTION = "BindableFunction"
}
module.NIRTypes = {
	CREATE_EVENT = 1,
	REQUEST_EVENTS = 2
}



--[[
	DESC: Handles communication between Server Network and Client Network module versions
	
		  Because module scripts are local to the environment of which they are required in,
	      e.g., server and client, we need to continually facilitate updates in the network
		  across both the server and client. This function utilises a manually initiated
		  RemoteFunction to handle requests
--]]
function module.NetworkInternalRequest(data)
	--Utility.assertc(Utility.len(module.NIRTypes) == 2, Output:Log("Exhaustive handling of NIRTypes in function NetworkInternalRequest()"))
	n_assert(RunService:IsServer(), "Network function `NetworkInternalRequest` can only be run on the server!")
	
	-- Wrap in pcall so client doesn't hang if there is an error
	local success, result = pcall(function()
		n_assert(typeof(data) ~= nil, "Invoked function did not receive a body!")

		if data.RequestType == module.NIRTypes.CREATE_EVENT then
			
			-- Check to see if type is bindable, if so, throw error
			if data.EventType == module.EventTypes.BINDABLE_EVENT or data.EventType == module.EventTypes.BINDABLE_FUNCTION then
				n_error("Client tried to request server to create a bindable event or function!")
			end
			
			-- Only create event if one does not exist
			if module.Events[data.EventName] == nil then
				module:CreateEvent(data.EventName, data.EventType)
				module:FireAllClients({
					Event = "NetworkInternalEvent",
					Data = {
						RequestType = module.NIRTypes.CREATE_EVENT,
						EventName = data.EventName,
						Event = module.Events[data.EventName]
					}
				})
			end
			
			-- Return data from pcall
			return {
				EventName = data.EventName,
				Event = module.Events[data.EventName]
			}
		elseif data.RequestType == module.NIRTypes.REQUEST_EVENTS then
			
			module:FireAllClients({
				Event = "NetworkInternalEvent",
				Data = {
					RequestType = module.NIRTypes.REQUEST_EVENTS,
					Events = module.Events
				}
			})
			
			-- Return data from pcall
			return {
				Events = module.Events
			}
		end
	end)
	
	-- If pcall was unsuccessful, report error in new thread so we can return
	if not success then
		task.spawn(function()
			n_error(result)
		end)
		
		return {
			Success = success,
			Error = result
		}
	end
	
	result.Success = success
	
	-- Return data back to the client
	return result
end


--[[
	DESC: Handles communication between Server Network and Client Network module versions
	
		  Because module scripts are local to the environment of which they are required in,
		  e.g., server and client, we need to continually facilitate updates in the network
		  across both the server and client. This function utilises a manually initiated
		  RemoteEvent to handle requests
--]]
function module.NetworkInternalEvent(data)
	n_assert(Utility.len(module.NIRTypes) == 2, "Exhaustive handling of NIRTypes in function NetworkInternalEvent()")
	n_assert(typeof(data) == "table", "NetworkInternalRequest received no body!")
	
	if RunService:IsServer() then
		
		
	elseif RunService:IsClient() then
		-- Handle client request to load new event
		if data.RequestType == module.NIRTypes.CREATE_EVENT then
			if module.Events[data.EventName] == nil then
				module.Events[data.EventName] = data.Event
			end
		elseif data.RequestType == module.NIRTypes.REQUEST_EVENTS then
			module.Events = data.Events
		end
	end
end


--[[
	void CreateEvent( string name, enum typ )
	
	@param string	name	: The name to be assigned to this this event
	@param enum		typ		: The type of event to be created (See `module.EventTypes`)
	
	DESC: Creates a new instance of the given event type and stores it in the appropriate
		  folder, as well as registering it with Nebula
--]]
function module:CreateEvent(name, typ)
	n_assert(Utility.find(module.EventTypes, typ) ~= nil, "Attempt to create an event with a non-supported type!")
	
	if RunService:IsServer() then
		if typ == module.EventTypes.BINDABLE_EVENT or typ == module.EventTypes.BINDABLE_FUNCTION then
			local event = Instance.new(typ, PrivateNetwork)
			event.Name = tostring(name)
			module.PrivateEvents[event.Name] = event
		else
			local event = Instance.new(typ, Network)
			event.Name = tostring(name)
			module.Events[event.Name] = event
		end
	else
		if typ == module.EventTypes.BINDABLE_EVENT or typ == module.EventTypes.BINDABLE_FUNCTION then
			local event = Instance.new(typ, PrivateNetwork)
			event.Name = tostring(name)
			module.PrivateEvents[event.Name] = event
		else
			n_error("Remote Events and Remote Functions can only be created by the server!")
			--local data = module:Request({
			--	Event = "NetworkInternalRequest",
			--	Data = {
			--		RequestType = module.NIRTypes.CREATE_EVENT,
			--		EventName = name,
			--		EventType = typ
			--	}
			--})
			
			--if data.Success then
			--	module.Events[name] = data.Event
			--end
		end
	end
end


function module:FireAllClients(body)
	n_assert(RunService:IsServer(), "Attempt to call function `FireAllClients` from the client!")
	n_assert(typeof(body) == "table", "Network function `FireAllClients` requires a body!")
	n_assert(body.Event ~= nil, "Attempt to call Network function `FireAllClients` without a specified event!")
	n_assert(body.Data ~= nil, "Attempt to call Network function `FireAllClients` with no data!")
	
	for _, player in next, game.Players:GetPlayers() do
		module.Events[body.Event]:FireClient(player, body.Data)
	end
end


function module:FireClient(body)
	n_assert(RunService:IsServer(), "Attempt to call function `FireClient` from the client!")
	n_assert(typeof(body) == "table", "Network function `FireClient` requires a body!")
	n_assert(body.Player ~= nil, "Attempt to call Network function `FireClient` with no player!")
	n_assert(body.Player:IsA("Player"), "Attempt to call Network function `FireClient` a non-player type!")
	n_assert(body.Event ~= nil, "Attempt to call Network function `FireClient` without a specified event!")
	n_assert(body.Data ~= nil, "Attempt to call Network function `FireClient` with no data!")
	
	module.Events[body.Event]:FireClient(body.Player, body.Data)
end


function module:FireServer(body)
	n_assert(RunService:IsClient(), "Attempt to call function `FireServer` from the server!")
	n_assert(body.Event ~= nil, "Attempt to call Network function `FireServer` without a specified event!")
	n_assert(body.Data ~= nil, "Attempt to call Network function `FireServer` with no data!")
	n_assert(typeof(body.Event) == "string", "Argument `Event` should be a string!")
	
	local eventName = body.Event
	
	-- If event doesn't exist during request, then ask server for an updated copy and yield
	if module.Events[eventName] == nil then
		local response = module.Events["NetworkInternalRequest"]:InvokeServer({
			RequestType = module.NIRTypes.REQUEST_EVENTS
		})

		if response.Success then
			module.Events = response.Data.Events
		end
	end

	module.Events[eventName]:FireServer(body.Data)
end


function module:Fire(body)
	n_assert(body.Event ~= nil, "Attempt to call Network function `Fire` without a specified event!")
	n_assert(body.Data ~= nil, "Attempt to call Network function `Fire` with no data!")
	n_assert(typeof(body.Event) == "string", "Argument `Event` should be a string!")

	module.PrivateEvents[body.Event]:Fire(body.Data)
end


function module:Invoke(body)
	n_assert(body.Event ~= nil, "Attempt to call Network function `Invoke` without a specified event!")
	n_assert(body.Data ~= nil, "Attempt to call Network function `Invoke` with no data!")
	n_assert(typeof(body.Event) == "string", "Argument `Event` should be a string!")
	
	return module.PrivateEvents[body.Event]:Invoke(body.Data)
end


--[[
	any Request( table body )
	
	@param table	body		: The body of the request to pass to the server
	@param string	body.Event	: The name of the remote function to invoke
	@param any		body.Data	: The actual data to send to the server
	
	DESC: Handle RemoteFunction requests from client to server with given arguments
--]]
function module:Request(body)
	n_assert(RunService:IsClient(), "Function `Request` can only be used on the client!")
	n_assert(typeof(body) == "table", ("Request body must be of type `table`, got %s"):format(typeof(body)))
	n_assert(typeof(body.Event) == "string", "Argument `Event` should be a string!")
	n_assert(body.Data ~= nil, "Attempt to call Network function `Request` with no data!")
	
	local eventName = body.Event
	
	-- If event doesn't exist during request, then ask server for an updated copy and yield
	if module.Events[eventName] == nil then
		local response = module.Events["NetworkInternalRequest"]:InvokeServer({
			RequestType = module.NIRTypes.REQUEST_EVENTS
		})

		if response.Success then
			module.Events = response.Data.Events
		end
	end
	
	return module.Events[eventName]:InvokeServer(body.Data)
end
	

--[[
	void Connect( table data )
	
	@param table		data			: Information about the connection to establish
	@param Function		data.Function	: The function to connect with
	@param string		data.Event		: The name of the event to connect to
	@param string		data.Name		: (optional) Alias of the connection to store, defaults to `data.Event`
	
	DESC: Handle connections to events
--]]
function module:Connect(data)
	n_assert(typeof(data) == "table", "Network function `Connect` requires data in table form!")
	n_assert(typeof(data.Function) == "function", "Attempt to connect a non-function to an event!")
	
	local event = module.Events[data.Event] or module.PrivateEvents[data.Event]
	local name = data.Name or data.Event
	
	if not event then
		n_error("Attempt to connect function to a non-existant event!")
	end
	
	n_assert(Utility.len(module.EventTypes) == 4, "Exhaustive handling of EventTypes in function Connect()")
	-- Actually connect the event
	if event:IsA(module.EventTypes.REMOTE_FUNCTION) then
		if RunService:IsServer() then
			event.OnServerInvoke = data.Function
		else
			n_error("Attempt to invoke the client!")
		end
	elseif event:IsA(module.EventTypes.REMOTE_EVENT) then
		if RunService:IsServer() then
			module.Connections[name] = event.OnServerEvent:Connect(data.Function)
		else
			module.Connections[name] = event.OnClientEvent:Connect(data.Function)
		end
	elseif event:IsA(module.EventTypes.BINDABLE_EVENT) then
		module.Connections[name] = event.Event:Connect(data.Function)
	elseif event:IsA(module.EventTypes.BINDABLE_FUNCTION) then
		event.OnInvoke = data.Function
	end
end


--[[
	void Disconnect( string connectionName )
	
	@param string	connectionName	: The name of the connection in which to disconnect
	
	DESC: Disconnects the given connection
--]]
function module:Disconnect(connectionName)
	n_assert(typeof(connectionName) == "string", "Network function requires `connectionName` to be a string!")
	
	if typeof(module.Connections[connectionName]) == "RBXScriptConnection" then
		module.Connections[connectionName]:Disconnect()
	end
end


function module.Init(nebula)
	--// Nebula
	Utility = nebula.Utility
	Output = nebula.Output
	
	n_assert = Utility.assert
	n_error = Output.Error
	n_warn = Output.Warn
	n_print = Output.Print
	
	--// Service Init
	module.Events = {}
	module.PrivateEvents = {}
	module.Connections = {}
	
	
	-- Create internal event to facilitate replication of client requests if on server
	if RunService:IsServer() then
		PrivateNetwork = ServerScriptService.Network
		
		module:CreateEvent("NetworkInternalRequest", module.EventTypes.REMOTE_FUNCTION)
		module:Connect({
			Name = "NIR",
			Event = "NetworkInternalRequest",
			Function = function(player, data)
				data.Player = player
				return module.NetworkInternalRequest(data)
			end
		})
		
		module:CreateEvent("NetworkInternalEvent", module.EventTypes.REMOTE_EVENT)
		module:Connect({
			Name = "NIE",
			Event = "NetworkInternalEvent",
			Function = function(player, data)
				data.Player = player
				module.NetworkInternalEvent(data)
			end
		})
	else
		PrivateNetwork = game.Players.LocalPlayer.PlayerScripts.Network
		
		-- Manually store NIR so we can facilitate future network requests
		local NIR = Network:WaitForChild("NetworkInternalRequest")
		module.Events[NIR.Name] = NIR
		
		-- Manually connect NIE so we can facilitate future network requests
		local NIE = Network:WaitForChild("NetworkInternalEvent")
		module.Events[NIE.Name] = NIE
		module.Connections["NIE"] = NIE.OnClientEvent:Connect(module.NetworkInternalEvent)
		
		-- Ask server for any events it has
		local response = module:Request({
			Event = "NetworkInternalRequest",
			Data = {
				RequestType = module.NIRTypes.REQUEST_EVENTS
			}
		})
		
		if response.Success then
			module.Events = response.Events
		end
	end
end


return module
