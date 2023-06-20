
--[[

	TITLE: Datastore Manager

	DESC: This module is responsible for handling data requests to and from Roblox's DataStoreService. The main goal is
		  to ensure that all data requests are correctly handled and fallbacks are in place if something goes wrong


	AUTHOR: RoyallyFlushed
	
	CREATED: 03/16/2022
	MODIFIED: 01/31/2023
	
	
	TODO:
		-- Add support for other datastore types
		-- Add support for other request types
		-- Prioritise usage of UpdateAsync where possible as it handles race conditions
		-- Add support for new datastore features
		-- Add support for request caching
			- If a save fails then cache the request and try again later
				- Cache the request in here and have a max of 5 attempts
					1st Attempt - 2 mins after initial
					2nd Attempt - 4 mins after 1st
					3rd Attempt - 8 mins after 2nd
					4th Attempt - 16 mins after 3rd
					5th Attempt - 32 mins after 4th
		-- Implement a way to query datastores and return recently added records
			-- This is mostly important for purchase history entries so that if there is ever
			   an issue with a purchase, I can quickly get all purchases since a timestamp and do with it
			   what I please
		    -- Might be able to use MemoryStore for this, allows storing data in ordered maps for up to 45 days
		       so I could save transactions using unix mils, and then query x number of them when I need to.
			   
					
		
--]]

local DataStoreService = game:GetService("DataStoreService")

local module = {}
local utility = nil

module.Priority = 2
module.TRY_AMOUNT = 3


--[[
	any Load(module self, string datastoreName, string | number key)
	
	@param string			datastoreName	:	The name of the datastore to load from
	@param string | number	key				:	The key to load from the datastore
	
	@returns any	:	The data from the datastore, or false
	
	DESC: This function takes a given datastore name and attempts to load the
		  data from the given key. If the try amount is exceeded due to network
		  failures, then `false` is returned, otherwise the result of `GetAsync`
		  is returned.
--]]
function module:Load(datastoreName: string, key: string | number): any
	
	assert(typeof(datastoreName) == "string", "$ Datastore -> Function `Load` expected datastoreName to be a string!")
	assert(typeof(key) == "string" or typeof(key) == "number", "$ Datastore -> Function `Load` expected key to be a string or a number!")
	
	local datastore = DataStoreService:GetDataStore(datastoreName)
	local success, result = utility.try(module.TRY_AMOUNT, datastore.GetAsync, datastore, key)
	
	if success then
		return result
	end
	
	warn(("$ Datastore -> Unable to load requested key %s from datastore %s!"):format(key, datastoreName))
	return false
	
end


--[[
	string | boolean Save(string datastoreName, string | number key, any data)
	
	@param string			datastoreName	:	The name of the datastore to save to
	@param string | number	key				:	The key to save the data to
	@param any				data			:	The data to save
	
	@returns string | boolean	:	The identifier of the newly created version, or false
	
	DESC: This function takes the given datastore name and attempts to save the given
		  data to the given key. If the try amount is exceeded due to network failures,
		  then `false` is returned, otherwise the result of `SetAsync` is returned.
--]]
function module:Save(datastoreName: string, key: string | number, data: any): string | boolean
	assert(typeof(datastoreName) == "string", "$ Datastore -> Function `Save` expected datastoreName to be a string!")
	assert(typeof(key) == "string" or typeof(key) == "number", "$ Datastore -> Function `Save` expected key to be a string or a number!")
	assert(data ~= nil, "$ Datastore -> Function `Save` requires data to save!")
	
	local datastore = DataStoreService:GetDataStore(datastoreName)
	local success, result = utility.try(module.TRY_AMOUNT, datastore.SetAsync, datastore, key, data)
	
	if success then
		return result
	end
	
	warn(("$ Datastore -> Unable to save request data to key %s in datastore %s!"):format(key, datastoreName))
	return false
end


function module.Init(nebula)
	utility = nebula.Utility
end


return module
