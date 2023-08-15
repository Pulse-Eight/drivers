--Copyright Pulse-Eight Limited 2021

require "lib.json"

local gP8ProxyId
local inputProxies = {
    INPUT0 = 0,
    INPUT1 = 0,
    INPUT2 = 0,
    INPUT3 = 0,
    INPUT4 = 0,
    INPUT5 = 0,
    INPUT6 = 0,
    INPUT7 = 0,
    INPUT8 = 0,
    INPUT9 = 0,
    INPUT10 = 0,
    INPUT11 = 0
}

local existingRouting = {
    OUTPUT0 = -1,
    OUTPUT1 = -1,
    OUTPUT2 = -1,
    OUTPUT3 = -1,
    OUTPUT4 = -1,
    OUTPUT5 = -1,
    OUTPUT6 = -1,
    OUTPUT7 = -1,
    OUTPUT8 = -1,
    OUTPUT9 = -1,
    AUDIOOUTPUT0 = -1,
    AUDIOOUTPUT1 = -1,
    AUDIOOUTPUT2 = -1,
    AUDIOOUTPUT3 = -1,
    AUDIOOUTPUT4 = -1,
    AUDIOOUTPUT5 = -1,
    AUDIOOUTPUT6 = -1,
    AUDIOOUTPUT7 = -1,
    AUDIOOUTPUT8 = -1,
    AUDIOOUTPUT9 = -1
}

local audioLocked = {
    AUDIOOUTPUT0 = 0,
    AUDIOOUTPUT1 = 0,
    AUDIOOUTPUT2 = 0,
    AUDIOOUTPUT3 = 0,
    AUDIOOUTPUT4 = 0,
    AUDIOOUTPUT5 = 0,
    AUDIOOUTPUT6 = 0,
    AUDIOOUTPUT7 = 0,
    AUDIOOUTPUT8 = 0,
    AUDIOOUTPUT9 = 0
}

local outputConsumers = {
    OUTPUT0 = nil,
    OUTPUT1 = nil,
    OUTPUT2 = nil,
    OUTPUT3 = nil,
    OUTPUT4 = nil,
    OUTPUT5 = nil,
    OUTPUT6 = nil,
    OUTPUT7 = nil,
    OUTPUT8 = nil,
    OUTPUT9 = nil
}

local outputRoom = {
    OUTPUT0 = nil,
    OUTPUT1 = nil,
    OUTPUT2 = nil,
    OUTPUT3 = nil,
    OUTPUT4 = nil,
    OUTPUT5 = nil,
    OUTPUT6 = nil,
    OUTPUT7 = nil,
    OUTPUT8 = nil,
    OUTPUT9 = nil
}

local roomPower = {
    OUTPUT0 = -3,
    OUTPUT1 = -3,
    OUTPUT2 = -3,
    OUTPUT3 = -3,
    OUTPUT4 = -3,
    OUTPUT5 = -3,
    OUTPUT6 = -3,
    OUTPUT7 = -3,
    OUTPUT8 = -3,
    OUTPUT9 = -3
}

function GetMyProxyId()
    local proxyIdList = C4:GetBoundConsumerDevices(0, DEFAULT_PROXY_BINDINGID)
    local proxyId
    if (proxyIdList ~= nil) then
        for id, name in pairs(proxyIdList) do
            LogWarn("Proxy Id Discovered: " .. id)
            gP8ProxyId = id --only 1?
        end
    end
end

function P8INT:SETUP()
    GetMyProxyId()
    for i = 0, (MAX_OUTPUTS - 1) do
        local sourceProxyId = C4:GetBoundProviderDevice(gP8ProxyId, 1000 + i)
        if (sourceProxyId == 0) then
            LogWarn("WARNING: Source " .. (i + 1) .. " is not mapped in Composer, if this input port is used, it must be bound correctly in Composer to a source device")
        else
            inputProxies["INPUT" .. i] = sourceProxyId
        end
    end
    GetConsumersForOutputs()
    CalculateRoomForOutput()
end

function CalculateRoomForOutput()
    local rooms = C4:GetDevicesByC4iName("roomdevice.c4i")
    if rooms ~= nil then
        for roomId, roomName in pairs(rooms) do
            LogInfo("Scanning Room: " .. roomId .. " (" .. roomName .. ")")
            local roomDevices = C4:RoomGetVideoDevices(roomId)
            if roomDevices ~= nil then
                for deviceId, deviceName in pairs(roomDevices) do
                    LogTrace("Attempting to link device: " .. deviceId .. " (" .. deviceName .. ")")
                    for i = 0, (MAX_OUTPUTS - 1) do
                        if
                            outputConsumers["OUTPUT" .. i] ~= nil and
                                tonumber(deviceId) == outputConsumers["OUTPUT" .. i]
                         then
                            LogInfo("Mapping Output " .. (i + 1) .. " to Room: " .. roomId .. " (" .. roomName .. ")")
                            outputRoom["OUTPUT" .. i] = roomId
                        elseif outputConsumers["OUTPUT" .. i] == nil then
                            LogTrace(
                                "Device Id: " ..
                                    deviceId .. " cannot match Output " .. i .. " as there are no consumers linked"
                            )
                        else
                            LogTrace(
                                "Device Id: " ..
                                    deviceId ..
                                        " does not match Output " .. i .. " Consumer " .. outputConsumers["OUTPUT" .. i]
                            )
                        end
                    end
                end
            end
        end
    end
end

function GetConsumersForOutputs()
    for i = 0, (MAX_OUTPUTS - 1) do
        local consumerDevices = C4:GetBoundConsumerDevices(gP8ProxyId, 2000 + i)
        if consumerDevices ~= nil then
            for id, name in pairs(consumerDevices) do
                LogTrace("Output " .. (i + 1) .. " is connected to device " .. id .. " (" .. name .. ")")
                outputConsumers["OUTPUT" .. i] = id
            end
        else
            LogWarn("WARNING: No Sink connected to output " .. (i + 1))
        end
    end
end

function P8INT:PORT_SET(idBinding, tParams)
    local input = tonumber(tParams["INPUT"] % 1000)
    local output = tonumber(tParams["OUTPUT"] % 1000)
    local input_id = tonumber(tParams["INPUT"])
    local class = tParams["CLASS"]
    local output_id = tonumber(tParams["OUTPUT"])
    local bSwitchSeparate, bVideo, bAudio = false, false, false
    local bSwitchSeparate = tParams["SWITCH_SEPARATE"]
    CancelRoutingPoll()
    local ticket = C4:url():SetOption("timeout", 15)
    if class == "VIDEO_SELECTION" or class == "HDMI" or class == nil then
        LogInfo("Changing Routing. Input: " .. input .. " -> Output: " .. output)
        existingRouting["OUTPUT" .. output] = input
        ticket:OnDone(
            function(transfer, responses, errCode, errMsg)
				PermitRoutingPoll()
                if errCode == 0 then
                    SendNotify("INPUT_OUTPUT_CHANGED", tParams, idBinding)
                    MarkNetworkTransfer(true)
                else
                    MarkNetworkTransfer(false, "PORT_SET", -2501, "Failed to set port")
                end
            end
        ):Get(P8INT:GET_MATRIX_URL() .. "/Port/Set/" .. input .. "/" .. output)
    else
        -- Do not attempt audio routing in source mode
        if MODE_SINK == 1 and MODE_SINK_SUPPORTED == 1  then
			-- If the port is locked, force the input to the locked input.
			if portLocked(output) == 1 then
				input = existingRouting["AUDIOOUTPUT" .. output]
			end

            local uri = P8INT:GET_MATRIX_URL() .. "/Audio/Route/" .. input .. "/" .. output
            LogInfo("Changing Audio Routing. Input: " .. input .. " -> Output: " .. output)
            existingRouting["AUDIOOUTPUT" .. output] = input
            ticket:OnDone(
                function(transfer, responses, errCode, errMsg)
					PermitRoutingPoll()
                    if errCode == 0 then
                        SendNotify("INPUT_OUTPUT_CHANGED", tParams, idBinding)
                        PermitRoutingPoll()
                        MarkNetworkTransfer(true)
                    else
                        MarkNetworkTransfer(false, "PORT_SET", -2501, "Failed to set port")
                    end
                end
            ):Get(P8INT:GET_MATRIX_URL() .. "/Audio/Route/" .. input .. "/" .. output)
            -- Work around a firmware bug. If a cec off command has been sent to certain TV's the mute state gets locked on.
            local uri1 = P8INT:GET_MATRIX_URL() .. "/Audio/Volume/" .. output .. "/down"
            C4:urlGet(
                uri,
                {},
                false,
                function(ticketId, strData, responseCode, tHeaders, strError)
                    local uri2 = P8INT:GET_MATRIX_URL() .. "/Audio/Volume/" .. output .. "/up"
                    C4:urlGet(
                        uri,
                        {},
                        false,
                        function(ticketId, strData, responseCode, tHeaders, strError)
                        end
                    )
                end
            )
        end
    end
end

function GetPowerState(data, mode, bay)
    for index, port in pairs(data.Ports) do
        if port.Bay == bay and port.Mode == mode then
            return port.DPS
        end
    end
end

function P8INT:GET_ROUTING_STATE(transfer, responses, errCode, errMsg)
    --LogTrace("Updating System Routing + Power")
    if errCode ~= 0 or errMsg ~= nil then
        if errMsg == nil then
            errMsg = "Unknown Error"
        end
        MarkNetworkTransfer(false, "GET_ROUTING_STATE", errCode, errMsg)
        return
    end

    local jsonResponse = JSON:decode(responses[#responses].body)
    if jsonResponse.Result then
        for index, port in pairs(jsonResponse.Ports) do
            if port.Mode == "Output" then
                local outputNumber = tonumber(port.Bay)
                local outputName = "OUTPUT" .. outputNumber

                local powerStateChanged = false
                local powerStatePrevious
                local routingChanged = false
                -- No DPS value returned if CEC is disabled
                if port.DPS ~= nil then
                    if roomPower[outputName] ~= port.DPS and outputRoom[outputName] ~= nil then
                        -- Handle Power State
                        LogInfo(
                            "Output " ..
                                outputNumber ..
                                    " power state has changed, was " .. roomPower[outputName] .. " now " .. port.DPS
                        )
                        powerStateChanged = true
                        powerStatePrevious = roomPower[outputName]
                        roomPower[outputName] = port.DPS
                    end
                end
                if existingRouting[outputName] ~= port.ReceiveFrom and outputRoom[outputName] ~= nil then
					LogTrace("Output " .. outputNumber .. " routing has changed, was " .. existingRouting[outputName] .. " now " .. port.ReceiveFrom)
                    routingChanged = true
                end
				
				if MODE_MANUALMODE_SUPPORTED == 1 then
					-- We can only reliably track audio routing on matrices that support manual mode.
					if port.AudioReceived ~= nil then
						existingRouting["AUDIOOUTPUT" .. outputNumber] = tonumber(port.AudioRecieved)
					end
				end

                if routingChanged then
                    LogTrace("Output " .. outputNumber .. " routing has changed, was " .. existingRouting[outputName] .. " now " .. port.ReceiveFrom)
                    existingRouting[outputName] = port.ReceiveFrom
                    C4:SendToDevice(outputRoom[outputName], "SELECT_VIDEO_DEVICE", {deviceid = inputProxies["INPUT" .. port.ReceiveFrom]})
					if MODE_MANUALMODE_SUPPORTED == 1 then
						C4:SendToDevice(outputRoom[outputName], "SELECT_AUDIO_DEVICE", {deviceid = inputProxies["INPUT" .. port.AudioRecieved]})
					end
                elseif powerChanged then
					if roomPower[outputName] == 0 then
						--Tell Director to do a routing change and turn on any other items required
						if existingRouting[outputName] ~= nil and inputProxies["INPUT" .. port.ReceiveFrom] ~= nil then
							C4:SendToDevice(outputRoom[outputName], "SELECT_VIDEO_DEVICE", {deviceid = inputProxies["INPUT" .. port.ReceiveFrom]})
						else
							LogWarn("Output " .. outputNumber .. " Power State changed to on, however the source routed to this output is not mapped in composer. No notification will be sent to composer until it is correctly mapped.")
						end
					end
					if roomPower[outputName] == 1 then
						--Tell director this output has turned off
						-- Not implemented
					end
					if roomPower[outputName] < 0 then
                        -- Not implemented
					end
                end

                if powerChanged or routingChanged then
                    -- Update the view in composer
                    SendNotify(
                        "INPUT_OUTPUT_CHANGED",
                        {INPUT = (port.ReceiveFrom + 3000), OUTPUT = (4000 + outputNumber)},
                        DEFAULT_PROXY_BINDINGID
                    ) -- Audio
                    SendNotify(
                        "INPUT_OUTPUT_CHANGED",
                        {INPUT = (port.ReceiveFrom + 1000), OUTPUT = 2000 + outputNumber},
                        DEFAULT_PROXY_BINDINGID
                    ) -- Video
                end
            end
        end
        MarkNetworkTransfer(true)
    else
        MarkNetworkTransfer(false, "GET_ROUTING_STATE", -1, "Failed to parse response")
    end
end

function portLocked(port) 
	return audioLocked["AUDIOOUTPUT" .. port]
end

function portLockedGet(port) 
	return existingRouting["AUDIOOUTPUT" .. port]
end

function portLock(port, locked)
	audioLocked["AUDIOOUTPUT" .. port] = locked
end