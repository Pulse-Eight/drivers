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
		
		--LogTrace("ReceivedFromProxy(): " .. sCommand .. " on binding " .. idBinding .. "; Call Function PRX_CMD." .. sCommand .. "()")
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

function PRX_CMD.UP(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x01\"}")
end

function PRX_CMD.DOWN(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x02\"}")
end

function PRX_CMD.LEFT(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x03\"}")
end

function PRX_CMD.RIGHT(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x04\"}")
end

function PRX_CMD.PLAY(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x44\"}")
end

function PRX_CMD.STOP(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x45\"}")
end

function PRX_CMD.PAUSE(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x46\"}")
end

function PRX_CMD.ENTER(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x00\"}")
end

function PRX_CMD.SCAN_FWD(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x49\"}")
end

function PRX_CMD.SCAN_REV(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x48\"}")
end

function PRX_CMD.SKIP_FWD(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x4B\"}")
end

function PRX_CMD.SKIP_REV(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x4C\"}")
end

function PRX_CMD.RECORD(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x62\"}")
end

function PRX_CMD.RECALL(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x0D\"}")
end

function PRX_CMD.CANCEL(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x0D\"}")
end

function PRX_CMD.PROGRAM_A(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x72\"}")
end

function PRX_CMD.PROGRAM_B(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x73\"}")
end

function PRX_CMD.PROGRAM_C(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x74\"}")
end

function PRX_CMD.PROGRAM_D(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x71\"}")
end

function PRX_CMD.PAGE_UP(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x37\"}")
end

function PRX_CMD.PAGE_DOWN(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x38\"}")
end

function PRX_CMD.PULSE_CH_UP(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x30\"}")
end

function PRX_CMD.PULSE_CH_DOWN(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x31\"}")
end

function PRX_CMD.GUIDE(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x53\"}")
end

function PRX_CMD.INFO(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x35\"}")
end

function PRX_CMD.MENU(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x09\"}")
end

function PRX_CMD.NUMBER_1(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x21\"}")
end

function PRX_CMD.NUMBER_2(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x22\"}")
end

function PRX_CMD.NUMBER_3(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x23\"}")
end

function PRX_CMD.NUMBER_4(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x24\"}")
end

function PRX_CMD.NUMBER_5(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x25\"}")
end

function PRX_CMD.NUMBER_6(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x26\"}")
end

function PRX_CMD.NUMBER_7(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x27\"}")
end

function PRX_CMD.NUMBER_8(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x28\"}")
end

function PRX_CMD.NUMBER_9(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x29\"}")
end

function PRX_CMD.NUMBER_0(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x20\"}")
end

function PRX_CMD.STAR(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x2A\"}")
end

function PRX_CMD.POUND(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x1D\"}")
end

function PRX_CMD.PVR(idBinding, tParams)
    P8INT:SEND_KEY("{\"Code\": \"0x52\"}")
end

function EX_CMD.LUA_ACTION(tParams)
    if tParams["ACTION"] == "DISCOVER" then
	   P8INT:DISCOVER()
    end
end