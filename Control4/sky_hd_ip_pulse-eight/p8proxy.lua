--Copyright Pulse-Eight Limited 2017
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

function GetKeyForName(codeName)
    if (codeName == "DISMISS") then
	   return 2
    end
    if (codeName == "INTERACTIVE") then
	   return 8
    end
    if (codeName == "SIDEBAR") then
	   return 8
    end
    if (codeName == "HELP") then
	   return 9
    end
    if (codeName == "SERVICES") then
	   return 10
    end
    if (codeName == "SEARCH") then
	   return 10
    end
    if (codeName == "BOX OFFICE") then
	   return 240
    end
    if (codeName == "HOME") then
	   return 11
    end
    if (codeName == "TEXT") then
	   return 15
    end
    if (codeName == "Un-mapped") then
	   return -1
    end
end

function PRX_CMD.UP(idBinding, tParams)
    P8INT:SEND_KEY(16)
end

function PRX_CMD.DOWN(idBinding, tParams)
    P8INT:SEND_KEY(17)
end

function PRX_CMD.LEFT(idBinding, tParams)
    P8INT:SEND_KEY(18)
end

function PRX_CMD.RIGHT(idBinding, tParams)
    P8INT:SEND_KEY(19)
end

function PRX_CMD.PLAY(idBinding, tParams)
    P8INT:SEND_KEY(64)
end

function PRX_CMD.STOP(idBinding, tParams)
    P8INT:SEND_KEY(66)
end

function PRX_CMD.PAUSE(idBinding, tParams)
    P8INT:SEND_KEY(65)
end

function PRX_CMD.ENTER(idBinding, tParams)
    P8INT:SEND_KEY(1)
end

function PRX_CMD.SCAN_FWD(idBinding, tParams)
    P8INT:SEND_KEY(69)
end

function PRX_CMD.SCAN_REV(idBinding, tParams)
    P8INT:SEND_KEY(71)
end

function PRX_CMD.SKIP_FWD(idBinding, tParams)
    P8INT:SEND_KEY(69)
end

function PRX_CMD.SKIP_REV(idBinding, tParams)
    P8INT:SEND_KEY(71)
end

function PRX_CMD.RECORD(idBinding, tParams)
    P8INT:SEND_KEY(67)
end

function PRX_CMD.RECALL(idBinding, tParams)
    P8INT:SEND_KEY(2)
end

function PRX_CMD.CANCEL(idBinding, tParams)
    P8INT:SEND_KEY(GetKeyForName(Properties["Cancel Button"]))
end

function PRX_CMD.PROGRAM_A(idBinding, tParams)
    P8INT:SEND_KEY(32)
end

function PRX_CMD.PROGRAM_B(idBinding, tParams)
    P8INT:SEND_KEY(33)
end

function PRX_CMD.PROGRAM_C(idBinding, tParams)
    P8INT:SEND_KEY(34)
end

function PRX_CMD.PROGRAM_D(idBinding, tParams)
    P8INT:SEND_KEY(35)
end

function PRX_CMD.PAGE_UP(idBinding, tParams)
    P8INT:SEND_KEY(6)
end

function PRX_CMD.PAGE_DOWN(idBinding, tParams)
    P8INT:SEND_KEY(7)
end

function PRX_CMD.PULSE_CH_UP(idBinding, tParams)
    P8INT:SEND_KEY(6)
end

function PRX_CMD.PULSE_CH_DOWN(idBinding, tParams)
    P8INT:SEND_KEY(7)
end

function PRX_CMD.GUIDE(idBinding, tParams)
    P8INT:SEND_KEY(11)
end

function PRX_CMD.INFO(idBinding, tParams)
    P8INT:SEND_KEY(14)
end

function PRX_CMD.MENU(idBinding, tParams)
    P8INT:SEND_KEY(GetKeyForName(Properties["Menu Button"]))
end

function PRX_CMD.NUMBER_1(idBinding, tParams)
    P8INT:SEND_KEY(49)
end

function PRX_CMD.NUMBER_2(idBinding, tParams)
    P8INT:SEND_KEY(50)
end

function PRX_CMD.NUMBER_3(idBinding, tParams)
    P8INT:SEND_KEY(51)
end

function PRX_CMD.NUMBER_4(idBinding, tParams)
    P8INT:SEND_KEY(52)
end

function PRX_CMD.NUMBER_5(idBinding, tParams)
    P8INT:SEND_KEY(53)
end

function PRX_CMD.NUMBER_6(idBinding, tParams)
    P8INT:SEND_KEY(54)
end

function PRX_CMD.NUMBER_7(idBinding, tParams)
    P8INT:SEND_KEY(55)
end

function PRX_CMD.NUMBER_8(idBinding, tParams)
    P8INT:SEND_KEY(56)
end

function PRX_CMD.NUMBER_9(idBinding, tParams)
    P8INT:SEND_KEY(57)
end

function PRX_CMD.NUMBER_0(idBinding, tParams)
    P8INT:SEND_KEY(48)
end

function PRX_CMD.STAR(idBinding, tParams)
    P8INT:SEND_KEY(GetKeyForName(Properties["Star Button"]))
end

function PRX_CMD.POUND(idBinding, tParams)
    P8INT:SEND_KEY(GetKeyForName(Properties["Hash Button"]))
end

function PRX_CMD.PVR(idBinding, tParams)
    P8INT:SEND_KEY(11)
end

function PRX_CMD.CUSTOM_1(idBinding, tParams)
    P8INT:SEND_KEY(GetKeyForName(Properties["Custom 1 Button"]))
end

function PRX_CMD.CUSTOM_2(idBinding, tParams)
    P8INT:SEND_KEY(GetKeyForName(Properties["Custom 2 Button"]))
end

function PRX_CMD.CUSTOM_3(idBinding, tParams)
    P8INT:SEND_KEY(GetKeyForName(Properties["Custom 3 Button"]))
end

function PRX_CMD.OFF(idBinding, tParams)
    if (Properties["Allow Power Off"] == "Yes") then
        P8INT:SEND_KEY(0)
    else
        LogInfo("Power State Control Disabled [Off Prevented]")
    end
end

function PRX_CMD.ON(idBinding, tParams)
    P8INT:TURN_ON()
end

function EX_CMD.LUA_ACTION(tParams)
    if tParams["ACTION"] == "DISCOVER" then
	   P8INT:DISCOVER()
    end
end