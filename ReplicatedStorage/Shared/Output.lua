
--[[

	TITLE: Output
	
	DESC: This module is responsible for logging information about nebula in the output
		  it is designed so that functions calls can easily replace lengthy print
		  statements.
		  
		  
	AUTHOR: RoyallyFlushed
	
	CREATED: 09/02/2022
	MODIFIED: 01/31/2023
	
	
	API:
		void	Log(string message, table debugInfo, enum logType)
		void	Print(string message, integer level)
		void	Warn(string message, integer level)
		void	Error(string message, integer level)
		
	
	TODO:
	
	
--]]


--// Nebula
local Utility


local module = {}


--// Dependencies
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")


--// Enums
module.LogType = {
	PRINT = 0,
	WARN = 1,
	ERROR = 2
}


--// Globals
local ENVIRONMENT = RunService:IsServer() and "Server" or RunService:IsClient() and "Client"


---------------------------------------------------------------------------------------------------------------


--// Functions


--[[ 
	void Log(string message, table debugInfo, enum logType)

	@param string	message		: The message in which to log
	@param table	debugInfo	: A table consisting of `debug.info(stackLevel, flags)`
	@param enum		logType		: The type of log to use
	
	DESC: Custom implementation of global output functions (print, warn, error)
		  to allow for use of specific format and better handling of Nebula's
		  integrated environments
--]]
function module:Log(message: string, debugInfo: table, logType: number?): Nothing
	
	local logType = logType or module.LogType.PRINT
	local scriptPath, lineNumber = unpack(debugInfo)
	local resource = scriptPath:match("%.%w+$")
	local prefix = "$ "..ENVIRONMENT..resource.." -> "
	
	if logType == module.LogType.PRINT then
		print(prefix..message)
	elseif logType == module.LogType.WARN then
		warn(prefix..message.." : "..lineNumber)
	elseif logType == module.LogType.ERROR then
		error(prefix..message.." : "..lineNumber, 0)
	end
	
end


--[[ 
	void Print(string message, integer level)

	@param string	message		: The message in which to print
	@param integer	level		: The number of levels up in the stack to use
	
	DESC: Wrapper function for print mode of `module:Log`
--]]
function module:Print(message: string, level: number?): Nothing
	
	level = level or 1 -- Default to function that called this one
	module:Log(message, { debug.info(level + 1, "s") }, module.LogType.PRINT)
	
end


--[[ 
	void Warn(string message, integer level)

	@param string	message		: The message in which to warn
	@param integer	level		: The number of levels up in the stack to use
	
	DESC: Wrapper function for warn mode of `module:Log`
--]]
function module:Warn(message: string, level: number?): Nothing
	
	level = level or 1 -- Default to function that called this one
	module:Log(message, { debug.info(level + 1, "sl") }, module.LogType.WARN)
	
end


--[[ 
	void Error(string message, integer level)

	@param string	message		: The message in which to error
	@param integer	level		: The number of levels up in the stack to use
	
	DESC: Wrapper function for error mode of `module:Log`
--]]
function module:Error(message: string, level: number?): Nothing
	
	level = level or 1 -- Default to function that called this one
	module:Log(message, { debug.info(level + 1, "sl") }, module.LogType.ERROR)
	
end



function module.Init(nebula)
	
	Utility = nebula.Utility
	
end


return module
