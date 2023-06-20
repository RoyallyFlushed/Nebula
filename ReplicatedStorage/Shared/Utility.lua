
--[[

	TITLE: Utility
	
	DESC: This module is responsible for housing all useful generic functions which can be used throughout
		  the game.
		  
		  
	AUTHOR: RoyallyFlushed
	
	CREATED: 03/16/2022
	MODIFIED: 09/04/2022

--]]


local module = {}

module._error = error
module._warn  = warn
module._print = print


--// Dependencies
local HttpService = game:GetService("HttpService")


--// Types
type Function = (any?) -> (any?)


--// index/key find( table t, object any )

-- @t : The table in which to search (haystack)
-- @q : The query in which to find (needle)

-- Similar to `table.find` but with non-numeric key support
function module.find(t: table, q: any): any?
	for k, v in t do
		if v == q then
			return k
		end
	end
end


--[[
	Find function to find values in a table with regex expressions
	Similar to table.find and custom implimentation above
	
	@t   table: table to search
	@ex string: expression to find
	
	-->> index/key or nil
--]]
function module.rfind(t: table, ex: string): any?
	for k, v in t do
		if typeof(v) == "string" and v:match(ex) then
			return k
		end
	end
end


--[[ 
	findPlayer function to find a player in the game whose name matches the given string
	Similar to FindFirstChild but not case sensitive
	
	@d Instance: object to search
	@q   string: name to find
	
	-->> Instance or nil
--]]
function module.findFirstChildNonCaseSensitive(d, q): Instance?
	for _, v in d:GetChildren() do
		if v.Name:lower() == q:lower() then
			return v
		end
	end
end


--[[ 
	extractInto function to extract key value pairs from t2 and store them in t1
	Similar to table.unpack
	
	@dst table: table to extract to
	@src table: table to extract from
	
	-->> table
--]]
function module.extractInto(dst: table, src: table): table
	for k, v in src do
		dst[k] = v
	end
	return dst
end


--[[ 
	prettyTable function to format a table to look good when outputted
	
	@t table: table to prettyify

	-->> string
--]]
function module.prettyTable(t: table): string
	assert(typeof(t) == "table", "$ Utility -> Function prettyTable expected argument of type `table`!")
	local output = "\n"
	local depth = 0

	local newLineLetters = {"{", "}", "[", "]", ","}
	local openingLetters = {"{", "["}
	local closingLetters = {"}", "]"}
	
	local success, result = pcall(HttpService.JSONEncode, HttpService, t)
	
	if success then
		for i = 1, #result do
			local letter = result:sub(i, i)
			local nextLetter = i < #result and result:sub(i + 1, i + 1) or ""

			if table.find(openingLetters, letter) and not table.find(closingLetters, nextLetter) then
				depth += 1
				output ..= letter.."\n"..string.rep("  ", depth)
			elseif letter == "," then
				output ..= letter.."\n"..string.rep("  ", depth)
			elseif not table.find(newLineLetters, letter) and table.find(closingLetters, nextLetter) then
				depth -= 1
				output ..= letter.."\n"..string.rep("  ", depth)
			elseif table.find(closingLetters, letter) and table.find(closingLetters, nextLetter) then
				depth -= 1
				output ..= letter.."\n"..string.rep("  ", depth)
			elseif letter == ":" then
				output ..= letter.." "
			else
				output ..= letter
			end
		end
	else
		warn("$ Utility -> Function prettyTable() unable to convert table to JSON!")
	end
	
	return output
end


--[[ 
	printOnNewLine function to remove new lines from a string and instead, print them
	
	@s string: string to parse
	
	-->> nil
--]]
function module.printOnNewLine(s: string): Nothing
	assert(typeof(s) == "string", "$ Utility -> Function printOnNewLine() expected argument to be a `string`!")
	
	for line in s:gmatch("[^\n]+") do
		print(line)
	end
end


--[[ 
	len function to get the length of a table with non-numerical indicies
	Similar to #table
	
	@t table: table to get length of
	
	-->> number
--]]
function module.len(t: table): number
	local count = 0
	for k, v in t do
		count += 1
	end
	return count
end


--[[ 
	try function to try a particular function x number of times until it works or exceeds limit
	
	@max number: maximum number of tries
	@func function: function to run in protected mode
	@... tuple: arguments to pass to func
	
	-->> boolean & any?
--]]
function module.try(max: number, func: Function, ...: any...): (boolean, any?)
	local attempts = 0
	local success, result = false, nil
	repeat
		success, result = pcall(func, ...)
		attempts += 1
	until success or attempts >= max
	return success, result
end


--// void assert( bool expression, string message )

-- @expression : The condition to assert
-- @message : The message to error with
function module.assert( expression: boolean, message: string? ): Nothing
	if not expression then
		local message = message or "Assertion Failed!"
		module._error(message, 2)
	end
end


--// void assertc( bool expression, function func, Variant ... )

-- @expression : The condition to assert
-- @func : The function to call if assertion failed
-- @... : The args to pass to the function
function module.assertc( expression: boolean, func: Function, ...: any... ): Nothing
	if not expression then
		func(...)
	end
end


--// int getHighestStackLevel()

-- this function loops through function environments until the highest stack level has been reached
function module.getHighestStackLevel()
	local stackLevel = 1
	
	-- Loop through stack levels until we reach the highest one
	while true do
		local success = (pcall(getfenv, stackLevel + 3)) -- +3 to test next stack level, plus the pcall function env, plus the getHighestStackLevel function env

		if success then
			stackLevel += 1
		else
			break
		end
	end
	
	return stackLevel
end


--// void printf( string fmt, Variant ... )

-- @fmt : The string in which to format
-- @... : The args to pass to the format
function module.printf( fmt: string, ...: any... )
	print(fmt:format(...))
end


	
	
return module
