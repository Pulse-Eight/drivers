--[[=============================================================================
    c4_log Class

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]
require "common.c4_driver_declarations"
require "lib.c4_object"

-- Set template version for this file
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.c4_log = "2015.03.02"
end

c4_log = inheritsFrom(nil)

function c4_log:construct(logName)
	self._logLevel = tonumber(string.sub(Properties['Log Level'] or "", 1, 1)) or 5
	self._outputPrint = Properties['Log Mode']:find("Print") ~= nil
	self._outputC4Log = Properties['Log Mode']:find("Log") ~= nil
	self._logName = logName or ""

	-- make sure Property is up to date (no harm if absent)
	C4:UpdateProperty("Log Level", Properties['Log Level'])
end

function c4_log:SetLogLevel(level)
	self._logLevel = tonumber(string.sub(level or "", 1, 1)) or self._logLevel
end

function c4_log:LogLevel()
	return self._logLevel
end

function c4_log:OutputPrint(value)
	self._outputPrint = value
end

function c4_log:OutputC4Log(value)
	self._outputC4Log = value
end

function c4_log:SetLogName(logName)

	if (logName == nil or logName == "") then
		logName = ""
	else
		logName = logName .. ": "
	end

	self._logName = logName
end

function c4_log:LogName()
	return self._logName
end

function c4_log:Enabled()
	return (self._outputPrint or self._outputC4Log)
end

function c4_log:PrintEnabled()
	return self._outputPrint
end

function c4_log:C4LogEnabled()
	return self._outputC4Log
end

function c4_log:CreateTableText(tValue, tableText)
	tableText = tableText or ""

	if (type(tValue) == "table") then

		tableText = tableText .. "{"
		for k, v in pairs(tValue) do

			-- add key
			if (type(k) == "number") then
				tableText = tableText .. "[" .. tostring(k) .. "]="
			elseif (type(k) == "string") then
				tableText = tableText .. k .. "="
			else
				print (tostring(k) .. ": " .. tostring (v))
			end

			-- add value
			if (type(v) == "number") then
				tableText = tableText .. tostring(v) .. ","
			elseif (type(v) == "string") then
				tableText = tableText .. "'" .. v .. "',"
			elseif (type(v) == "table") then
				tableText = c4_log:CreateTableText(v, tableText)
				tableText = tableText .. ","
			elseif (type(v) == "boolean") then
				tableText = tableText .. tostring(v) .. ","
			end
		end

		tableText = tableText .. "}"
	end

	return tableText
end

function InsertIndent(indentLevel)
	local indentStr = ""

	for i=1, indentLevel do
		indentStr = indentStr .. "\t"
	end

	return indentStr
end

function c4_log:CreateTableTextFormatted(tValue, tableText, indentLevel)
	tableText = tableText or ""
	indentLevel = indentLevel or 0

	if (type(tValue) == "table") then

		indentLevel = indentLevel + 1
		tableText = tableText .. "{\n"
		for k, v in pairs(tValue) do

			-- add key
			if (type(k) == "number") then
				tableText = tableText .. InsertIndent(indentLevel) .. "[" .. tostring(k) .. "]="
			elseif (type(k) == "string") then
				tableText = tableText .. InsertIndent(indentLevel) .. k .. "="
			else
				print (tostring(k) .. ": " .. tostring (v))
			end

			-- add value
			if (type(v) == "number") then
				tableText = tableText .. tostring(v) .. ",\n"
			elseif (type(v) == "string") then
				tableText = tableText .. "'" .. v .. "',\n"
			elseif (type(v) == "table") then
				tableText = c4_log:CreateTableTextFormatted(v, tableText, indentLevel)
				tableText = tableText .. ",\n"
			elseif (type(v) == "boolean") then
				tableText = tableText .. tostring(v) .. ",\n"
			end
		end

		indentLevel = indentLevel - 1
		tableText = tableText .. InsertIndent(indentLevel) .. "}"
	end

	return tableText
end

MAX_TABLE_LEVELS = 10
function c4_log:PrintTable(tValue, tableText, sIndent, level)
	tableText = tableText or ""
	level = level + 1
	
	if (level <= MAX_TABLE_LEVELS) then
		if (type(tValue) == "table") then
			for k,v in pairs(tValue) do
				if (tableText == "") then
					tableText = sIndent .. tostring(k) .. ":  " .. tostring(v)
					if (sIndent == ".   ") then sIndent = "    " end
				else
					tableText = tableText .. "\n" .. sIndent .. tostring(k) .. ":  " .. tostring(v)
				end
				if (type(v) == "table") then
					tableText = self:PrintTable(v, tableText, sIndent .. "   ", level)
				end
			end
		else
			tableText = tableText .. "\n" .. sIndent .. tostring(tValue)
		end
	end
	
	return tableText
end

function c4_log:LogTable(tValue, sIndent, level)
	level = level + 1
	
	if (level <= MAX_TABLE_LEVELS) then
		if (type(tValue) == "table") then
			for k,v in pairs(tValue) do
				C4:ErrorLog(self._logName .. ": " .. sIndent .. tostring(k) .. ":  " .. tostring(v))
				if (type(v) == "table") then
					self:LogTable(v, sIndent .. "   ", level)
				end
			end
		else
			C4:ErrorLog(self._logName .. ": " .. sIndent .. tValue)
		end
	end
end

function c4_log:Print(logLevel, sLogText)

	if (self._logLevel >= logLevel) then
		if (type(sLogText) == "table") then
			if (self._outputPrint) then
				print (self:PrintTable(sLogText, tableText, ".   ", 0))
			end

			if (self._outputC4Log) then
				self:LogTable(sLogText, "   ", 0)
			end

			return
		end

		if (self._outputPrint) then
			print (sLogText)
		end

		if (self._outputC4Log) then
			C4:ErrorLog(self._logName .. ": " .. tostring(sLogText))
		end
	end
end

function c4_log:Fatal(sLogText, ...)
	self:LogOutput(0, sLogText, ...)
end

function c4_log:Error(sLogText, ...)
	self:LogOutput(1, sLogText, ...)
end

function c4_log:Warn(sLogText, ...)
	self:LogOutput(2, sLogText, ...)
end

function c4_log:Info(sLogText, ...)
	self:LogOutput(3, sLogText, ...)
end

function c4_log:Debug(sLogText, ...)
	self:LogOutput(4, sLogText, ...)
end

function c4_log:Trace(sLogText, ...)
	self:LogOutput(5, sLogText, ...)
end

function c4_log:LogOutput(level, sLogText, ...)
	if (LogEnabled()) then
		if (type(sLogText) == "string") then
			sLogText = string.format(sLogText, ...)
		end

		self:Print(level, sLogText)
	end
end

--[[=============================================================================
    c4_log wrapper functions
===============================================================================]]
function TryLog(level, sLogText, ...)
	LOG:LogOutput(level, sLogText, ...)
end

--[[=============================================================================
    SetLogLevel(level)

    Description: 
    Sets the desired log level to view

    Parameters:
    level(int) - The logging level to set the message to
                 0 = Fatal
                 1 = Error
                 2 = Warn
                 3 = Info
                 4 = Debug
                 5 = Trace

    Returns:
    None
===============================================================================]]
function SetLogLevel(level)
	LOG:SetLogLevel(level)
end

--[[=============================================================================
    LogLevel()

    Description: 
    Returns the currently set log level

    Parameters:
    None

    Returns:
    The current log level
        0 = Fatal
        1 = Error
        2 = Warn
        3 = Info
        4 = Debug
        5 = Trace
===============================================================================]]
function LogLevel()
	return LOG:LogLevel()
end

--[[=============================================================================
    OutputPrint(value)

    Description: 
    Specifies whether to output log messages or not

    Parameters:
    value(bool) - true to enable logging output, false otherwise

    Returns:
    None
===============================================================================]]
function OutputPrint(value)
	LOG:OutputPrint(value)
end

--[[=============================================================================
    OutputPrint(value)

    Description: 
    Specifies whether to output log messages to file or not

    Parameters:
    value(bool) - true to enable logging output, false otherwise

    Returns:
    None
===============================================================================]]
function OutputC4Log(value)
	LOG:OutputC4Log(value)
end

--[[=============================================================================
    SetLogName(logName)

    Description: 
    Sets the name of the log file where the messages will be written to

    Parameters:
    logName(string) - Sets the name of the log to write messages to

    Returns:
    None
===============================================================================]]
function SetLogName(logName)
	LOG:SetLogName(logName)
end

--[[=============================================================================
    LogName(logName)

    Description: 
    Gets the name of the log file where the messages will be written to

    Parameters:
    None

    Returns:
    The value of the log file that has been set
===============================================================================]]
function LogName()
	return LOG:LogName()
end

--[[=============================================================================
    LogEnabled()

    Description: 
    Identifies if logging or print has been enabled

    Parameters:
    None

    Returns:
    true if either logging or print has been enabled, false otherwise
===============================================================================]]
function LogEnabled()
	return LOG:Enabled()
end

--[[=============================================================================
    PrintEnabled()

    Description: 
    Gets the state of print output

    Parameters:
    None

    Returns:
    true if print has been enabled, false otherwise
===============================================================================]]
function PrintEnabled()
	return LOG:PrintEnabled()
end

--[[=============================================================================
    C4LogEnabled()

    Description: 
    Gets the state of logging

    Parameters:
    None

    Returns:
    true if logging has been enabled, false otherwise
===============================================================================]]
function C4LogEnabled()
	return LOG:C4LogEnabled()
end

--[[=============================================================================
    LogFatal(sLogText, ...)

    Description: 
    Formats and prints a series of characters and values to the enabled outputs
    when the set logging level is Fatal(0) or higher

    Parameters:
    sLogText(string) - Format control string
    ...              - Optional arguments which will replace all the format
                       specifiers contained in the format string

    Returns:
    None
===============================================================================]]
function LogFatal(sLogText, ...)
	local status, err = pcall(TryLog, 0, sLogText, ...)
	if (not status) then
		LOG:Print(1, "LUA_ERROR - LogFatal failed: " .. err)
	end
end

--[[=============================================================================
    LogError(sLogText, ...)

    Description: 
    Formats and prints a series of characters and values to the enabled outputs
    when the set logging level is Error(1) or higher

    Parameters:
    sLogText(string) - Format control string
    ...              - Optional arguments which will replace all the format
                       specifiers contained in the format string

    Returns:
    None
===============================================================================]]
function LogError(sLogText, ...)
	local status, err = pcall(TryLog, 1, sLogText, ...)
	if (not status) then
		LOG:Print(1, "LUA_ERROR - LogError failed: " .. err)
	end
end

--[[=============================================================================
    LogWarn(sLogText, ...)

    Description: 
    Formats and prints a series of characters and values to the enabled outputs
    when the set logging level is Warn(2) or higher

    Parameters:
    sLogText(string) - Format control string
    ...              - Optional arguments which will replace all the format
                       specifiers contained in the format string

    Returns:
    None
===============================================================================]]
function LogWarn(sLogText, ...)
	local status, err = pcall(TryLog, 2, sLogText, ...)
	if (not status) then
		LOG:Print(1, "LUA_ERROR - LogWarn failed: " .. err)
	end
end

--[[=============================================================================
    LogInfo(sLogText, ...)

    Description: 
    Formats and prints a series of characters and values to the enabled outputs
    when the set logging level is Info(3) or higher

    Parameters:
    sLogText(string) - Format control string
    ...              - Optional arguments which will replace all the format
                       specifiers contained in the format string

    Returns:
    None
===============================================================================]]
function LogInfo(sLogText, ...)
	local status, err = pcall(TryLog, 3, sLogText, ...)
	if (not status) then
		LOG:Print(1, "LUA_ERROR - LogInfo failed: " .. err)
	end
end

--[[=============================================================================
    LogDebug(sLogText, ...)

    Description: 
    Formats and prints a series of characters and values to the enabled outputs
    when the set logging level is Debug(5) or higher

    Parameters:
    sLogText(string) - Format control string
    ...              - Optional arguments which will replace all the format
                       specifiers contained in the format string

    Returns:
    None
===============================================================================]]
function LogDebug(sLogText, ...)
	local status, err = pcall(TryLog, 4, sLogText, ...)
	if (not status) then
		LOG:Print(1, "LUA_ERROR - LogDebug failed: " .. err)
	end
end

--[[=============================================================================
    LogTrace(sLogText, ...)

    Description: 
    Formats and prints a series of characters and values to the enabled outputs
    when the set logging level is Trace(4) or higher

    Parameters:
    sLogText(string) - Format control string
    ...              - Optional arguments which will replace all the format
                       specifiers contained in the format string

    Returns:
    None
===============================================================================]]
function LogTrace(sLogText, ...)
	local status, err = pcall(TryLog, 5, sLogText, ...)
	if (not status) then
		LOG:Print(1, "LUA_ERROR - LogTrace failed: " .. err)
	end
end

function dbgPrint(buf)
	if (LOG:PrintEnabled()) then
		print (buf)
	end
end

function dbgHexdump(buf)
	hexdump(buf, dbgPrint)
end

--[[=============================================================================
    c4_log unit tests
===============================================================================]]
function __test_c4_log()
	require "test.C4Virtual"
	
	local LOG = c4_log:new("test_c4_log")
	assert(LOG:LogName() == "test_c4_log", "_logName is not equal to 'test_c4_log' it is: " .. LOG:LogName())

	-- Test setting log level
	LOG:SetLogLevel("2 - Warning")
	assert(LOG:LogLevel() == 2, "_logLevel is not equal to '2' it is: " .. LOG:LogLevel())

	LOG:SetLogLevel(3)
	assert(LOG:LogLevel() == 3, "_logLevel is not equal to '3' it is: " .. LOG:LogLevel())

	-- Test enabling logs
	LOG:OutputPrint(false)
	assert(LOG:PrintEnabled() == false, "_outputPrint is not equal to 'false' it is: " .. tostring(LOG:PrintEnabled()))

	LOG:OutputC4Log(true)
	assert(LOG:C4LogEnabled() == true, "_outputC4Log is not equal to 'true' it is: " .. tostring(LOG:C4LogEnabled()))

	LOG:SetLogLevel(4)
	LogTrace("***** This is a test *****")
end

function __test_CreatTableText()
	local tTest = {}

	tTest[1] = {}
	tTest[2] = {}
	tTest[3] = 30
	tTest[4] = "Forty"
	
	LogTrace("----- tText -----")
	LogTrace(tTest)

	local tTest2 = { One = {},
					 Two = {},
					 Three = 30,
					 Four = "Forty" }
	LogTrace("----- tText2 -----")
	LogTrace(tTest2)
	
	local tTest3 = { [1] = {},
					 [2] = {},
					 [3] = 30,
					 [4] = "Forty" }
	LogTrace("----- tText3 -----")
	LogTrace(tTest3)

	local tTest4 = { [1] = {},
					 Two = {},
					 [3] = 30,
					 [4] = "Forty",
					 Five = "Fifty" }
	LogTrace("----- tText4 -----")
	LogTrace(tTest4)

	local tableText = LOG:CreateTableText(tTest4)
	LogTrace("----- tableText -----")
	LogTrace(tableText)
	
	--local tNew = {[1] = {},[3] = 30,[4] = 'Forty',Five = 'Fifty',Two = {},}
	--LogTrace(tNew)
end

function __TestCreateTableTextFormatted()
	require "test.C4Virtual"
	
	local LOG = c4_log:new("test_c4_log")
	local tButtons = {
		Name = 'heat',
		Attributes = {},
		ChildNodes = {
			[1] = {
				Name = 'button',
				Attributes = {},
				ChildNodes = {
					[1] = {
						Value = '51',
						Attributes = {},
						Name = 'id',
						ChildNodes = {},
					},
					[2] = {
						Value = 'Pool Heater',
						Attributes = {},
						Name = 'button_text',
						ChildNodes = {},
					},
					[3] = {
						Value = 'POOLHT',
						Attributes = {},
						Name = 'button_name',
						ChildNodes = {},
					},
				},
			},
			[2] = {
				Name = 'button',
				Attributes = {},
				ChildNodes = {
					[1] = {
						Value = '53',
						Attributes = {},
						Name = 'id',
						ChildNodes = {},
					},
					[2] = {
						Value = 'Spa Heater',
						Attributes = {},
						Name = 'button_text',
						ChildNodes = {},
					},
					[3] = {
						Value = 'SPAHT',
						Attributes = {},
						Name = 'button_name',
						ChildNodes = {},
					},
				},
			},
			[3] = {
				Name = 'button',
				Attributes = {},
				ChildNodes = {
					[1] = {
						Value = '54',
						Attributes = {},
						Name = 'id',
						ChildNodes = {},
					},
					[2] = {Value = 'Pool Solar Heater',
						Attributes = {},
						Name = 'button_text',
						ChildNodes = {}
					},
					[3] = {
						Value = 'SOLHT',
						Attributes = {},
						Name = 'button_name',
						ChildNodes = {},
					},
				}
			}
		}
	}

	print(LOG:CreateTableTextFormatted(tButtons))
end