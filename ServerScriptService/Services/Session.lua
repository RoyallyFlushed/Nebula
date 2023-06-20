
--[[

	TITLE: Session

	DESC: This module is responsible for handling all players in a current server aka "Session". Any and all data change requests will
		  be handled by this service and will ensure synchronisity between all clients in the session as well as handling loading,
		  saving and setting up player's data.

	AUTHOR: RoyallyFlushed
	
	CREATED: 03/16/2022
	MODIFIED: 03/20/2022
	
	TODO:
		- Add support for save failure retrying
			- If the network fails to save a player's data, save it in a queue and try again later until it eventually works
			  that way, if a player leaves the game and their data doesn't save right away, we might still be able to save it
			  if the server continues to live
		- Convert ALL keys to strings either in here or Datastore module
	
--]]



local module = {}

module.Priority = 3

module.Session = {}
module.PERIODIC_SAVE_INTERVAL = 300

local Modules = nil
local network = nil
local datastore = nil
local datastoreDefaults = nil


local PlayerDataStore = "PlayerDataStore_0.1"


--// Recursively fill missing entries within user data against a template
local function fillMissingEntries(template, data)
	local changed = 0
	for key, value in next, template do
		if data[key] == nil then
			data[key] = value
			changed += 1
		elseif typeof(value) == "table" and typeof(data[key]) == "table" then
			local newData, changes = fillMissingEntries(value, data[key])
			data[key] = newData
			changed += changes
		end
	end
	
	return data, changed
end


function module.SessionSet(key, value)
	module.Session[key] = value
	Modules.Server.Session[key] = value
end


function module.LoadPlayer(player)
	-- Load player data
	-- Store it in session
	-- Tell all clients new player and their data
	local playerKey = tostring(player.UserId)
	local data = datastore:Load(PlayerDataStore, playerKey)
	
	if data == false then
		-- Data load error
		warn(("$ Session -> Error loading data for player %s"):format(tostring(playerKey)))
	elseif data == nil then
		-- New player, no data
		data = datastoreDefaults[PlayerDataStore]
		local success = datastore:Save(PlayerDataStore, playerKey, data)
		if not success then
			-- Data save error
			warn(("$ Session -> Error saving data for player %s"):format(tostring(playerKey)))
		end
	elseif typeof(data) == "table" then
		-- Player has data
		local changed = 0
		data, changed = fillMissingEntries(datastoreDefaults[PlayerDataStore], data)
		if changed > 0 then
			local success = datastore:Save(PlayerDataStore, playerKey, data)
			if not success then
				-- Data save error
				warn(("$ Session -> Error saving data for player %s"):format(tostring(playerKey)))
			end
		end
	end
	
	-- Add player data to session
	module.SessionSet(playerKey, data)
	
	-- Tell all clients
	network:FireAllClients({
		Event = "SessionDataUpdate",
		Data = {
			Session = module.Session
		}
	})
end

function module.SavePlayer(player)
	-- Save player data
	local playerKey = tostring(player.UserId)
	
	if module.Session[playerKey] then
		local success = datastore:Save(PlayerDataStore, playerKey, module.Session[playerKey])
		if not success then
			-- Data save error
			warn(("$ Session -> Error saving data for player %s"):format(tostring(playerKey)))
		end
	end
end

function module.PlayerAdded(player)
	-- New player joined server
	-- Run LoadPlayer on them
	module.LoadPlayer(player)
	task.spawn(function()
		local lastSave = 0
		network:Connect({
			Name = tostring(player.UserId).."_PeriodicDataSave",
			Event = "ServerUpTime",
			Function = function()
				lastSave += 1
				if lastSave >= 300 then
					module.SavePlayer(player)
					lastSave = 0
				end
			end
		})
	end)
end

function module.PlayerLeft(player)
	-- Player is leaving
	-- Run SavePlayer on their session data
	-- Remove player data from session
	local playerKey = tostring(player.UserId)
	
	module.SavePlayer(player)
	module.SessionSet(playerKey)
	
	network:Disconnect(tostring(player.UserId).."_PeriodicDataSave")
end

function module.UpdateClient(player)
	-- Client requested to have their session data updated
	-- Send them a copy
	return module.Session
end


function module.Init(nebula)
	-- Init all nebula
	Modules = nebula
	network = nebula.Network
	datastore = nebula.Datastore
	datastoreDefaults = nebula.DatastoreDefaults
	
	Modules.Server.Session = {}
	
	-- Connect listeners to events
	game.Players.PlayerAdded:Connect(module.PlayerAdded)
	game.Players.PlayerRemoving:Connect(module.PlayerLeft)

	-- Connect network connections
	network:CreateEvent("SessionDataUpdate", "RemoteEvent")
	network:CreateEvent("SessionDataUpdateRequest", "RemoteFunction")
	
	network:Connect({
		Event = "SessionDataUpdateRequest",
		Function = module.UpdateClient
	})
end


return module
