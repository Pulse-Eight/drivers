--Copyright Pulse-Eight Limited 2016
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
		--LogInfo(tParams)
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

function ExecuteCommand(sCommand, tParams)
	--LogTrace("ExecuteCommand(" .. sCommand .. ")")
	--LogInfo(tParams)
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
		--LogInfo("ExecuteCommand: Unhandled command = " .. sCommand)
		status = true
	end
	
	if (not status) then
		LogError("LUA_ERROR: " .. err)
	end
    if (sCommand ~= nil) then
		if (sCommand == "Cycle Outlet 1") then
			P8INT:REBOOT_OUTLET(0)
		end
		if (sCommand == "Cycle Outlet 2") then
			P8INT:REBOOT_OUTLET(1)
		end
		if (sCommand == "Cycle Outlet 3") then
			P8INT:REBOOT_OUTLET(2)
		end
		if (sCommand == "Cycle Outlet 4") then
			P8INT:REBOOT_OUTLET(3)
		end
		if (sCommand == "Cycle Outlet 5") then
			P8INT:REBOOT_OUTLET(4)
		end
		if (sCommand == "Cycle Outlet 6") then
			P8INT:REBOOT_OUTLET(5)
		end
		if (sCommand == "Cycle Outlet 7") then
			P8INT:REBOOT_OUTLET(6)
		end
		if (sCommand == "Cycle Outlet 8") then
			P8INT:REBOOT_OUTLET(7)
		end
	end
end

function EX_CMD.LUA_ACTION(tParams)
    if tParams["ACTION"] == "DISCOVER" then
	   P8INT:DISCOVER()
    end
end