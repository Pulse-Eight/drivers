--Copyright Pulse-Eight Limited 2021
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
		LogDebug(tParams)
		if (sCommand == "IS_AV_OUTPUT_TO_INPUT_VALID") then
			local status, retval = pcall(PRX_CMD[sCommand], idBinding, tParams)
			if (status) then
				return retval
			end
        end

		if ((PRX_CMD[sCommand]) ~= nil) then
			local status, err = pcall(PRX_CMD[sCommand], idBinding, tParams)
			LogTrace(sCommand)
			if (not status) then
				LogError("LUA_ERROR: " .. err)
			end
		else
			LogInfo("ReceivedFromProxy: Unhandled command = " .. sCommand)
		end
	end
end

function ReceivedProxyIR(idBinding, strCommand, tParams)
	tParams = tParams or {}

		local printme = "\n \n----------------------------------\n(ReceivedProxyIR) BINDING[" .. idBinding .. "] COMMAND[" .. strCommand .. "]\n"
		for k,v in pairs(tParams) do
			printme = printme .. k .. ":" .. (v or "nil") .. "\n"
		end

		printme = printme .. "----------------------------------\n \n"
		LogInfo(printme)

	prontocode = tParams.data:match("<pattern>(.-)</pattern")
	repeatCount = tParams.data:match("<repeatcount>(.-)</repeatcount>")
	print("code = " .. prontocode)
	print("count = " .. repeatCount)
	if (prontocode ~= nil and repeatCount ~= nil) then
		for i=1,repeatCount do
			 LogInfo(prontocode)
			--SendIRToController(idBinding, prontocode)
		end
	end
end

function OnSystemEvent(event)
    print("System Event " .. event)
    local _, _, eventname = event:find('.-name="(.-)"') 
    print("Found event type: " .. eventname)
    local myIP = C4:GetMyNetworkAddress()
    local matchedUUID = 0
    if (eventname ~= nil) then
	   info = C4:GetDiscoveryInfo(6000)
	   if (info ~= nil) then
		  local startIndex, endIndex = event:find(info["uuid"], 0, true)
		  if(startIndex ~= nil) then
			 matchedUUID = 1
		  end
	   end
	   print("UUID Match status: " .. matchedUUID)
	   if     (eventname == "OnNetworkBindingAdded") then
		  if (matchedUUID == 1) then
			 UpdateNetworkAddress(myIP)
		  end
	   elseif (eventname == "OnSDDPDeviceStatus") then
		  if (matchedUUID == 1) then
			 UpdateNetworkAddress(myIP)
		  end
	   elseif (eventname == "OnDeviceIPAddressChanged") then
		  if (matchedUUID == 1) then
			 UpdateNetworkAddress(myIP)
		  end
	   end
    end
end

function UpdateNetworkAddress(ip) 
    print("Updating Network Address to " .. ip)
    UpdateProperty("Device IP Address", ip)
    FirstRun()
end

function PRX_CMD.PULSE(idBinding, tParams)
    local prontocode = tParams.data:match("<pattern>(.-)</pattern")
    local repeatCount = tParams.data:match("<repeatcount>(.-)</repeatcount>") or 0
    local delayAfter = tParams.data:match("<delayafter>(.-)</delayafter>") or 0
    local bindingNum = tonumber(idBinding)
    local mode = "input"
    local repeatCount = tonumber(repeatCount)
    if (bindingNum >= 300) then
	   mode = "output"
    end
    local bay = tonumber(bindingNum % 100) - 1
    local postData = "{\"pronto\": \"" .. prontocode .. "\", \"repeat\": " .. tonumber(repeatCount) .. ", \"delay_after\": " .. tonumber(delayAfter) .. "}"
	P8INT:POST_REMOTE_URL(mode, bay, SendProntoCommand, postData)
end

function SendProntoCommand(mode, bay, url, postData) 
	LogError("SendProntoCommand: " .. mode .. " " .. bay .. " " .. url);
	local PostURI = url .. "/ir/tx/" .. mode .. "/" .. bay
	C4:urlPost(PostURI, postData)
end

function P8INT:POST_REMOTE_URL(mode, bay, callback, postData)
	LogError("Entered P8INT:POST_REMOTE_URL with " .. mode .. " " .. bay)
    if (bay == 0) then
        callback(mode, bay, P8INT:GET_MATRIX_URL(), postData)
    else
        local uri = P8INT:GET_MATRIX_URL() .. "/port/details/" .. mode .. "/" .. bay
        C4:urlGet(
            uri,
            {},
            false,
            function(ticketId, strData, responseCode, tHeaders, strError)
                if responseCode == 200 then
                    local jsonResponse = JSON:decode(strData)
                    if jsonResponse.Result then
                        LogError(strData)
                        if jsonResponse.P8 then
                            callback(mode, bay, "http://" .. jsonResponse.P8.RemoteIP, postData)
                        else
                            LogError("PRX_CMD.PULSE could not obtain Ip from port/details")
                        end
                    end
                else
                    LogError("PRX_CMD.PULSE did not get a valid response from port/details")
                end
            end
        )
    end
end

function PRX_CMD.BINDING_CHANGE_ACTION(idBinding, tParams)
    P8INT:FETCH_INSTALLER_ID()
end

function PRX_CMD.SET_INPUT(idBinding, tParams)
    P8INT:PORT_SET(idBinding, tParams)
end

function PRX_CMD.ON(idBinding, tParams)
    --No Action Required
end

function PRX_CMD.OFF(idBinding, tParams)
    --No Action Required
end

function PRX_CMD.CONNECT_OUTPUT(idBinding, tParams)
	 --No Action Required
end

function PRX_CMD.DISCONNECT_OUTPUT(idBinding, tParams)
	 --No Action Required
end

function PRX_CMD.GET_VIDEO_PATH(idBinding, tParams)
     --No Action Required
end

function PRX_CMD.GET_AUDIO_PATH(idBinding, tParams)
     --No Action Required
end

function EX_CMD.LUA_ACTION(tParams)
    if tParams["ACTION"] == "REBOOT" then
	   P8INT:REBOOT()
    elseif tParams["ACTION"] == "DISCOVER" then
	   P8INT:DISCOVER()
    elseif tParams["ACTION"] == "SENDPULSE" then
	   P8INT:SEND_PULSE()
    end
end

function PRX_CMD.SET_VOLUME_LEVEL(idBinding, tParams)
	 --No Action Required
end

function PRX_CMD.MUTE_TOGGLE(idBinding, tParams)
	 --No Action Required
end

function PRX_CMD.MUTE_ON(idBinding, tParams)
	 --No Action Required
end

function PRX_CMD.MUTE_OFF(idBinding, tParams)
	 --No Action Required
end

function PRX_CMD.LOUDNESS_ON(idBinding, tParams)
	 --No Action Required
end

function PRX_CMD.LOUDNESS_OFF(idBinding, tParams)
	 --No Action Required
end

function PRX_CMD.PULSE_VOL_UP(idBinding, tParams)
	 --No Action Required
end

function PRX_CMD.PULSE_VOL_DOWN(idBinding, tParams)
	 --No Action Required
end

function PRX_CMD.START_VOL_UP(idBinding, tParams)
    --No Action Required
end

function PRX_CMD.STOP_VOL_UP(idBinding, tParams)
    --No Action Required
end

function PRX_CMD.START_VOL_DOWN(idBinding, tParams)
    --No Action Required
end

function PRX_CMD.STOP_VOL_DOWN(idBinding, tParams)
    --No Action Required
end

function PRX_CMD.SET_ROOM_BINDING_NAME(idBinding, tParams)
    --No Action Required
end


function PRX_CMD.IS_AV_OUTPUT_TO_INPUT_VALID(idBinding, tParams)
	local retval = "False"
	local provider_class = tParams["Provider_sClass"]
	if provider_class == "VIDEO_SELECTION" or provider_class == "HDMI" then
		retval = "True"
	else
		retval = P8INT:IS_ROUTE_VALID(idBinding, tParams)
	end
	LogTrace("IS_AV_OUTPUT_TO_INPUT_VALID returned " .. retval .. " for path of class " .. tParams["Provider_sClass"] .. " from " .. tonumber(tParams["Consumer_idBinding"]) .. " to " .. tonumber(tParams["Provider_idBinding"]))
	return retval
end

--=============================
--=    Programming commands   =
--=============================

local multiviewer_commands = {
    ["Set Multiviewer Layout"] = {
        endpoint = "/multiviewer/view",
        value_map = {
            ["Single"]              = 1,
            ["Picture in Picture"]  = 2,
            ["Two Screen Large"]    = 3,
            ["Two Screen Small"]    = 4,
            ["Three Screen Large"]  = 5,
            ["Three Screen Small"]  = 6,
            ["Four Screen Equal"]   = 7,
            ["Four Screen Small"]   = 8,
        }
    },
    ["Set Multiviewer PIP Position"] = {
        endpoint = "/multiviewer/position",
        value_map = {
            ["Left Top"]     = 1,
            ["Left Bottom"]  = 2,
            ["Right Top"]    = 3,
            ["Right Bottom"] = 4,
        }
    },
    ["Set Multiviewer PIP Size"] = {
        endpoint = "/multiviewer/size",
        value_map = {
            ["Small"]  = 1,
            ["Medium"] = 2,
            ["Large"]  = 3,
        }
    },
    ["Set Multiviewer Audio Source"] = {
        endpoint = "/multiviewer/audio",
        value_map = nil   -- direct integer, 1-4 in UI → 0-3 on wire
    }
}

local function SendMultiviewerCommand(cmdName, tParams)
    LogTrace("SendMultiviewerCommand: " .. cmdName)

    if not tParams then
        LogWarn(cmdName .. ": Nil Params")
        return
    end

    local zoneParam = tonumber(tParams["Zone"])
    if not zoneParam or zoneParam < 1 or zoneParam > 32 then
        LogWarn(cmdName .. ": Invalid or missing Zone (must be 1-32)")
        return
    end

    local zone = zoneParam - 1   -- firmware is 0-based

    local cmdDef = multiviewer_commands[cmdName]
    if not cmdDef then
        LogError(cmdName .. ": Unknown command definition")
        return
    end

    local value
    local paramName = (cmdName == "Set Multiviewer Audio Source") and "Source" or "Layout"

    if cmdDef.value_map then
        -- string list -> index
        local rawValue = tParams[paramName]
        value = cmdDef.value_map[rawValue]
        if not value then
            LogWarn(cmdName .. ": Invalid " .. paramName .. " value: " .. tostring(rawValue))
            return
        end
    else
        -- direct integer (Audio Source)
        value = tonumber(tParams[paramName])
        if not value or value < 1 or value > 4 then
            LogWarn(cmdName .. ": Invalid Source (must be 1-4)")
            return
        end
        value = value - 1
    end

    local url = P8INT:GET_MATRIX_URL() .. cmdDef.endpoint .. "/" .. zone .. "/" .. value
    LogInfo(cmdName .. ": Sending " .. url)

    C4:url()
        :SetOption("timeout", 15)
        :OnDone(function(transfer, responses, errCode, errMsg)
            if errCode ~= 0 then
                LogError(string.format("%s failed - transport error (errCode=%s, msg=%s)",
                    cmdName, tostring(errCode), tostring(errMsg or "")))
                return
            end

            if not responses or #responses == 0 then
                LogWarn(cmdName .. ": No response received")
                return
            end

            local body = responses[#responses].body
            if not body or body == "" then
                LogWarn(cmdName .. ": empty response body")
                return
            end

            local success, jsonResponse = pcall(JSON.decode, JSON, body)
            if not success then
                LogError(cmdName .. ": JSON decode failed")
                LogDebug("Body snippet: " .. (body:sub(1, 250) or ""))
                return
            end

            if not jsonResponse.Result then
                LogWarn(cmdName .. ": Failed - " .. (jsonResponse.ErrorMessage or "unknown error"))
            else
                LogInfo(cmdName .. ": Success")
            end
        end)
        :Get(url)
end

function EX_CMD.SetMultiviewerLayout(tParams)
    SendMultiviewerCommand("Set Multiviewer Layout", tParams)
end

function EX_CMD.SetMultiviewerPIPPosition(tParams)
    SendMultiviewerCommand("Set Multiviewer PIP Position", tParams)
end

function EX_CMD.SetMultiviewerPIPSize(tParams)
    SendMultiviewerCommand("Set Multiviewer PIP Size", tParams)
end

function EX_CMD.SetMultiviewerAudioSource(tParams)
    SendMultiviewerCommand("Set Multiviewer Audio Source", tParams)
end
