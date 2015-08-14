--[[=============================================================================
    Functions for handling and executing commands and actions

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]
require "common.c4_driver_declarations"

-- Set template version for this file
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.c4_command = "2015.03.02"
end

--[[=============================================================================
    ExecuteCommand(sCommand, tParams)

    Description
    Function called by Director when a command is received for this DriverWorks
    driver. This includes commands created in Composer programming.

    Parameters
    sCommand(string) - Command to be sent
    tParams(table)   - Lua table of parameters for the sent command

    Returns
    Nothing
===============================================================================]]
function ExecuteCommand(sCommand, tParams)
	LogTrace("ExecuteCommand(" .. sCommand .. ")")
	LogInfo(tParams)

	-- Remove any spaces (trim the command)
	local trimmedCommand = string.gsub(sCommand, " ", "")
	local status, err

	-- if function exists then execute (non-stripped)
	if (EX_CMD[sCommand] ~= nil and type(EX_CMD[sCommand]) == "function") then
		status, err = pcall(EX_CMD[sCommand], tParams)
	-- elseif trimmed function exists then execute
	elseif (EX_CMD[trimmedCommand] ~= nil and type(EX_CMD[trimmedCommand]) == "function") then
		status, err = pcall(EX_CMD[trimmedCommand], tParams)
	elseif (EX_CMD[sCommand] ~= nil) then
		QueueCommand(EX_CMD[sCommand])
		status = true
	else
		LogInfo("ExecuteCommand: Unhandled command = " .. sCommand)
		status = true
	end
	
	if (not status) then
		LogError("LUA_ERROR: " .. err)
	end
end

--[[=============================================================================
    EX_CMD.LUA_ACTION(tParams)

    Description
    Function called for any actions executed by the user from the Actions Tab
    in Composer.

    Parameters
    tParams(table) - Lua table of parameters for the command option

    Returns
    Nothing
===============================================================================]]
function EX_CMD.LUA_ACTION(tParams)
	if (tParams ~= nil) then
		for cmd, cmdv in pairs(tParams) do
			if (cmd == "ACTION" and cmdv ~= nil) then
				local status, err = pcall(LUA_ACTION[cmdv])
				if (not status) then
					LogError("LUA_ERROR: " .. err)
				end
				break
			end
		end
	end
end

--[[=============================================================================
    ReceivedFromProxy(idBinding, sCommand, tParams)

    Description
    Function called for any actions executed by the user from the Actions Tab
    in Composer.

    Parameters
    idBinding(int)   - Binding ID of the proxy that sent a BindMessage to the
                       DriverWorks driver.
    sCommand(string) - Command that was sent
    tParams(table)   - Lua table of received command parameters

    Returns
    Nothing
===============================================================================]]
function ReceivedFromProxy(idBinding, sCommand, tParams)

	if (sCommand ~= nil) then

		-- initial table variable if nil
		if (tParams == nil) then
			tParams = {}
		end
		
		LogTrace("ReceivedFromProxy(): " .. sCommand .. " on binding " .. idBinding .. "; Call Function PRX_CMD." .. sCommand .. "()")
		LogInfo(tParams)

		if ((PRX_CMD[sCommand]) ~= nil) then
			local status, err = pcall(PRX_CMD[sCommand], idBinding, tParams)
			if (not status) then
				LogError("LUA_ERROR: " .. err)
			end
		else
			LogInfo("ReceivedFromProxy: Unhandled command = " .. sCommand)
		end
	end
end