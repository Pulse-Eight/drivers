--Copyright Pulse-Eight Limited 2023
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
		if (sCommand == "IS_AV_OUTPUT_TO_INPUT_VALID") then
			local status, retval = pcall(PRX_CMD[sCommand], idBinding, tParams)
			if (status) then
				LogTrace("IS_AV_OUTPUT_TO_INPUT_VALID returned " .. retval .. " for path of class " .. tParams["Provider_sClass"] .. " from " .. tonumber(tParams["Consumer_idBinding"]) .. " to " .. tonumber(tParams["Provider_idBinding"]))
				return retval
			end
        end

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

function PRX_CMD.BINDING_CHANGE_ACTION(idBinding, tParams)
    P8INT:FETCH_INSTALLER_ID()
end

function PRX_CMD.SET_INPUT(idBinding, tParams)
    --No Action Required
end

function PRX_CMD.ON(idBinding, tParams)
    --No Action Required
end

function PRX_CMD.OFF(idBinding, tParams)
    --No Action Required
end

function PRX_CMD.CONNECT_OUTPUT(idBinding, tParams)
	if tonumber(tParams["OUTPUT"]) > -1 then
		local output = tonumber(tParams["OUTPUT"] % 1000)
		local uri = P8INT:GET_MATRIX_URL() .. "/Audio/Mute/" .. output .. "/3/0"
		LogInfo("Set Mute OFF Due to Connect. Output: " .. output)
		C4:urlGet(uri, {}, false, function(ticketId, strData, responseCode, tHeaders, strError)
			  local jsonResponse = JSON:decode(strData)
			  if jsonResponse.Result then
				P8INT:UPDATE_AUDIO(idBinding, tParams["OUTPUT"])
			  end
		   end)
	end
end

function PRX_CMD.GET_AUDIO_INPUTS(_, _) -- idBinding, tParams
end

function PRX_CMD.DISCONNECT_OUTPUT(idBinding, tParams)
	if tonumber(tParams["OUTPUT"]) > -1 then
		local output = tonumber(tParams["OUTPUT"] % 1000)
		local uri = P8INT:GET_MATRIX_URL() .. "/Audio/Mute/" .. output .. "/3/1"
		LogInfo("Set Mute ON Due to Disconnect. Output: " .. output)
		C4:urlGet(uri, {}, false, function(ticketId, strData, responseCode, tHeaders, strError)
			  local jsonResponse = JSON:decode(strData)
			  if jsonResponse.Result then
				P8INT:UPDATE_AUDIO(idBinding, tParams["OUTPUT"])
			  end
		   end)
	end
end

function PRX_CMD.GET_VIDEO_PATH(idBinding, tParams)
    --P8INT:GET_ROUTING(idBinding, tParams)
end

function PRX_CMD.GET_AUDIO_PATH(idBinding, tParams)
    --P8INT:GET_ROUTING(idBinding, tParams)
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
	if tonumber(tParams["OUTPUT"]) > -1 then
		local output = tonumber(tParams["OUTPUT"] % 1000)
		local level = tParams["LEVEL"]
		local uri = P8INT:GET_MATRIX_URL() .. "/Audio/Volume/" .. output .. "/" .. level
		LogInfo("Changing Volume. Output: " .. output .. " -> Level: " .. level)
		C4:urlGet(uri, {}, false, function(ticketId, strData, responseCode, tHeaders, strError)
			  local jsonResponse = JSON:decode(strData)
			  if jsonResponse.Result then
				P8INT:UPDATE_AUDIO(idBinding, tParams["OUTPUT"])
			  end
		   end)
	end
end

function PRX_CMD.MUTE_TOGGLE(idBinding, tParams)
	--OUTPUT (7000)
	--ROOM_ID (604)
	--DEVICE_ID (230)
	if tonumber(tParams["OUTPUT"]) > -1 then
		local output = tonumber(tParams["OUTPUT"] % 1000)
		local uri = P8INT:GET_MATRIX_URL() .. "/Audio/Mute/" .. output .. "/0"
		LogInfo("Toggle Mute. Output: " .. output)
		C4:urlGet(uri, {}, false, function(ticketId, strData, responseCode, tHeaders, strError)
			  local jsonResponse = JSON:decode(strData)
			  if jsonResponse.Result then
				P8INT:UPDATE_AUDIO(idBinding, tParams["OUTPUT"])
			  end
		   end)
	end
end

function PRX_CMD.MUTE_ON(idBinding, tParams)
	--OUTPUT (7000)
	--ROOM_ID (604)
	--DEVICE_ID (230)
	if tonumber(tParams["OUTPUT"]) > -1 then
		local output = tonumber(tParams["OUTPUT"] % 1000)
		local uri = P8INT:GET_MATRIX_URL() .. "/Audio/Mute/" .. output .. "/3/1"
		LogInfo("Mute On. Output: " .. output)
		C4:urlGet(uri, {}, false, function(ticketId, strData, responseCode, tHeaders, strError)
			  local jsonResponse = JSON:decode(strData)
			  if jsonResponse.Result then
				P8INT:UPDATE_AUDIO(idBinding, tParams["OUTPUT"])
			  end
		   end)
	end
end

function PRX_CMD.MUTE_OFF(idBinding, tParams)
	--OUTPUT (7000)
	--ROOM_ID (604)
	--DEVICE_ID (230)
	if tonumber(tParams["OUTPUT"]) > -1 then
		local output = tonumber(tParams["OUTPUT"] % 1000)
		local uri = P8INT:GET_MATRIX_URL() .. "/Audio/Mute/" .. output .. "/3/0"
		LogInfo("Mute Off. Output: " .. output)
		C4:urlGet(uri, {}, false, function(ticketId, strData, responseCode, tHeaders, strError)
			  local jsonResponse = JSON:decode(strData)
			  if jsonResponse.Result then
				P8INT:UPDATE_AUDIO(idBinding, tParams["OUTPUT"])
			  end
		   end)
	end
end

function PRX_CMD.LOUDNESS_ON(idBinding, tParams)
	--OUTPUT (7000)
	--ROOM_ID (604)
	--DEVICE_ID (230)
	if tonumber(tParams["OUTPUT"]) > -1 then
		local output = tonumber(tParams["OUTPUT"] % 1000)
		local uri = P8INT:GET_MATRIX_URL() .. "/Audio/Mute/" .. output .. "/3/0"
		LogInfo("Toggle Mute. Output: " .. output)
		C4:urlGet(uri, {}, false, function(ticketId, strData, responseCode, tHeaders, strError)
			  local jsonResponse = JSON:decode(strData)
			  if jsonResponse.Result then

			  end
		   end)
	end
end

function PRX_CMD.LOUDNESS_OFF(idBinding, tParams)
	--OUTPUT (7000)
	--ROOM_ID (604)
	--DEVICE_ID (230)
	if tonumber(tParams["OUTPUT"]) > -1 then
		local output = tonumber(tParams["OUTPUT"] % 1000)
		local uri = P8INT:GET_MATRIX_URL() .. "/Audio/Mute/" .. output .. "/3/1"
		LogInfo("Toggle Mute. Output: " .. output)
		C4:urlGet(uri, {}, false, function(ticketId, strData, responseCode, tHeaders, strError)
			  local jsonResponse = JSON:decode(strData)
			  if jsonResponse.Result then

			  end
		   end)
	end
end

function PRX_CMD.PULSE_VOL_UP(idBinding, tParams)
	if tonumber(tParams["OUTPUT"]) > -1 then
		local output = tonumber(tParams["OUTPUT"] % 1000)
		local uri = P8INT:GET_MATRIX_URL() .. "/Audio/Volume/" .. output .. "/up"
		LogInfo("Volume Up. Output: " .. output)
		C4:urlGet(uri, {}, false, function(ticketId, strData, responseCode, tHeaders, strError)
			  local jsonResponse = JSON:decode(strData)
			  if jsonResponse.Result then
				P8INT:UPDATE_AUDIO(idBinding, tParams["OUTPUT"])
			  else
			     LogWarn("System not set to control volume on this zone")
			  end
		   end)
	end
end

function PRX_CMD.PULSE_VOL_DOWN(idBinding, tParams)
	if tonumber(tParams["OUTPUT"]) > -1 then
		local output = tonumber(tParams["OUTPUT"] % 1000)
		local uri = P8INT:GET_MATRIX_URL() .. "/Audio/Volume/" .. output .. "/down"
		--LogInfo("Volume Down. Output: " .. output)
		C4:urlGet(uri, {}, false, function(ticketId, strData, responseCode, tHeaders, strError)
			  local jsonResponse = JSON:decode(strData)
			  --if jsonResponse.Result then
				P8INT:UPDATE_AUDIO(idBinding, tParams["OUTPUT"])
			  --end
		   end)
	end
end

local outputVolumeTimers = {
	OUTPUT0 = 1,
	OUTPUT1 = 1,
	OUTPUT2 = 1,
	OUTPUT3 = 1,
	OUTPUT4 = 1,
	OUTPUT5 = 1,
	OUTPUT6 = 1,
	OUTPUT7 = 1,
	OUTPUT8 = nil,
	OUTPUT9 = nil
}

function PRX_CMD.START_VOL_UP(idBinding, tParams)
	local speed = tonumber(Properties["Volume Ramp Speed"]) or 200 
	local output = tonumber(tParams["OUTPUT"]) % 1000
	local outputName = tostring("OUTPUT" .. output)
     LogTrace("Start Vol Up " .. output)
    
	if outputVolumeTimers[outputName] then
		outputVolumeTimers[outputName] = C4:SetTimer(speed, function(timer, skips) 
		   PRX_CMD.PULSE_VOL_UP(idBinding, tParams)
		end, true)
	end
end

function PRX_CMD.STOP_VOL_UP(idBinding, tParams)
	local output = tonumber(tParams["OUTPUT"]) % 1000
	LogTrace("Stop Vol Up " .. output)
	local outputName = tostring("OUTPUT" .. output)
	if outputVolumeTimers[outputName] ~= 1 then
		outputVolumeTimers[outputName]:Cancel()
		outputVolumeTimers[outputName] = 1
	end
end

function PRX_CMD.END_VOL_UP(idBinding, tParams)
	LogTrace("Vol Up End")
	local output = tonumber(tParams["OUTPUT"]) % 1000
	local outputName = tostring("OUTPUT" .. output)
	if outputVolumeTimers[outputName] ~= 1 then
		outputVolumeTimers[outputName]:Cancel()
		outputVolumeTimers[outputName] = 1
	end
end

function PRX_CMD.START_VOL_DOWN(idBinding, tParams)
    local speed = tonumber(Properties["Volume Ramp Speed"]) or 200 
    local output = tonumber(tParams["OUTPUT"]) % 1000
    LogTrace("Start Vol Down " .. output)
    local outputName = tostring("OUTPUT" .. output)
    if outputVolumeTimers[outputName] then
	    outputVolumeTimers[outputName] = C4:SetTimer(speed, function(timer, skips) 
		   PRX_CMD.PULSE_VOL_DOWN(idBinding, tParams)
	    end, true)
    end
end

function PRX_CMD.STOP_VOL_DOWN(idBinding, tParams)
	local output = tonumber(tParams["OUTPUT"]) % 1000
	local outputName = tostring("OUTPUT" .. output)
	LogTrace("Stop Vol Down " .. output)
	if outputVolumeTimers[outputName] ~= 1 then
		outputVolumeTimers[outputName]:Cancel()
		outputVolumeTimers[outputName] = 1
	end
end

function PRX_CMD.END_VOL_DOWN(idBinding, tParams)
	LogTrace("End Vol Down")
	local output = tonumber(tParams["OUTPUT"]) % 1000
	local outputName = tostring("OUTPUT" .. output)
	if outputVolumeTimers[outputName] ~= 1 then
		outputVolumeTimers[outputName]:Cancel()
		outputVolumeTimers[outputName] = 1
	end
end

function P8INT:UPDATE_AUDIO(idBinding, output)
	--LogTrace("Updating Audio for Output: " .. output)
	local adjust = 3000;
	local p8output = tonumber(output % 1000)
	local uri = P8INT:GET_MATRIX_URL() .. "/Audio/Volume/" .. p8output
	C4:urlGet(uri, {}, false, function(ticketId, strData, responseCode, tHeaders, strError)
		if responseCode ~= 200 or strError ~= nil then
			LogWarn("Unable to fetch audio settings")
			LogWarn("Error = " .. strError)
			LogWarn("Response Code = " .. responseCode)
			return
		end

		local jsonResponse = JSON:decode(strData)
		if jsonResponse.Result then
			local volLevel = tonumber(jsonResponse["volLeft"]) or tonumber(jsonResponse["dolbyvolume"])
			local muteState = tonumber(jsonResponse["muted"]) ~= 0
			if volLevel > 100 then
				volLevel = 100
			end
			if volLevel < 0 then
				volLevel = 0
			end
			LogTrace("Volume Level Changed = " .. volLevel .. " Output (" .. output .. ") = " .. (tonumber(output)-adjust))
			local volChangedParams = { LEVEL = volLevel, OUTPUT = (tonumber(output)-adjust) }
			--local muteChangedParams = { MUTE = muteState, OUTPUT = (tonumber(output)-adjust) }
			local volChangedParams1 = { LEVEL = volLevel, OUTPUT = (tonumber(output)) }
			local muteChangedParams1 = { MUTE = muteState, OUTPUT = (tonumber(output)) }
			local volChangedParams2 = { LEVEL = volLevel, OUTPUT = (tonumber(output)-4000) }
			--local muteChangedParams2 = { MUTE = muteState, OUTPUT = (tonumber(output)-4000) }
			C4:SendToProxy(idBinding, "VOLUME_LEVEL_CHANGED", volChangedParams)
			--C4:SendToProxy(idBinding, "MUTE_CHANGED", muteChangedParams)
			C4:SendToProxy(idBinding, "VOLUME_LEVEL_CHANGED", volChangedParams1)
			C4:SendToProxy(idBinding, "MUTE_CHANGED", muteChangedParams1)
			C4:SendToProxy(idBinding, "VOLUME_LEVEL_CHANGED", volChangedParams2)
			--C4:SendToProxy(idBinding, "MUTE_CHANGED", muteChangedParams2)
		end
	end)
end


function PRX_CMD.SET_ROOM_BINDING_NAME(idBinding, tParams)
    --PartnerDevice
    --OUTPUT
end

function PRX_CMD.IS_AV_OUTPUT_TO_INPUT_VALID(idBinding, tParams)
    local pathIsValid =  "True"
    local provider_class    	= tParams["Provider_sClass"]
    local consumer_idBinding 	= tonumber(tParams["Consumer_idBinding"])	-- we are consuming the source, so the consumer binding is the source
    local provider_idBinding 	= tonumber(tParams["Provider_idBinding"]) 	-- we are providing the output, to the output is the provider binding    
    local consumer_class    	= tParams["Consumer_sClass"]
    local roomID			= tonumber(tParams["Params_idRoom"])
    if (consumer_idBinding % 1000) ~= (provider_idBinding % 1000) then
	   pathIsValid = "False"
    end
    return pathIsValid
end