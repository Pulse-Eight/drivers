--Copyright Pulse-Eight Limited 2015

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
    INPUT7 = 0
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
	OUTPUT9 = -1
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
	   for id,name in pairs(proxyIdList) do
		  LogWarn("Proxy Id Discovered: " .. id)
		  gP8ProxyId = id --only 1?
	   end
    end
end	
	
function P8INT:SETUP()
    GetMyProxyId()
    for i = 0,(MAX_OUTPUTS-1) do
	   local sourceProxyId = C4:GetBoundProviderDevice(gP8ProxyId,1000+i)
	   if (sourceProxyId == 0) then
		  LogWarn("WARNING: Source " .. (i+1) .. " is not mapped in Composer, if this input port is used, it must be bound correctly in Composer to a source device")
	   else
		  inputProxies["INPUT"..i] = sourceProxyId
	   end
    end
    GetConsumersForOutputs()
    CalculateRoomForOutput()
end

function CalculateRoomForOutput()
    local rooms = C4:GetDevicesByC4iName("roomdevice.c4i")
    if rooms ~= nil then
	   for roomId,roomName in pairs(rooms) do
		  LogInfo("Scanning Room: " .. roomId .. " (" .. roomName .. ")")
		  local roomDevices = C4:RoomGetVideoDevices(roomId)
		  if roomDevices ~= nil then
			 for deviceId,deviceName in pairs(roomDevices) do
				LogTrace("Attempting to link device: " .. deviceId .. " (" .. deviceName .. ")")
				for i = 0, (MAX_OUTPUTS-1) do
				    if outputConsumers["OUTPUT" .. i] ~= nil and tonumber(deviceId) == outputConsumers["OUTPUT" .. i] then
					   LogInfo("Mapping Output " .. (i+1) .. " to Room: " .. roomId .. " (" .. roomName .. ")")
					   outputRoom["OUTPUT" .. i] = roomId
				    elseif outputConsumers["OUTPUT" .. i] == nil then
					   LogTrace("Device Id: " .. deviceId .. " cannot match Output " .. i .. " as there are no consumers linked")
				    else
					   LogTrace("Device Id: " .. deviceId .. " does not match Output " .. i .. " Consumer " .. outputConsumers["OUTPUT" .. i])
				    end
				end
			 end
		  end
	   end
    end
end

function GetConsumersForOutputs()
    for i = 0, (MAX_OUTPUTS-1) do
	   local consumerDevices = C4:GetBoundConsumerDevices(gP8ProxyId,2000+i)
	   if consumerDevices ~= nil then
		  for id,name in pairs(consumerDevices) do
			 LogTrace("Output " .. (i+1) .. " is connected to device " .. id .. " (" .. name .. ")")
			 outputConsumers["OUTPUT" .. i] = id
		  end
	   else
		  LogWarn("WARNING: No Sink connected to output " .. (i+1))
	   end
    end
end

function P8INT:PORT_SET(idBinding, tParams)
    local input = tonumber(tParams["INPUT"] % 1000)
    local output = tonumber(tParams["OUTPUT"] % 1000)
    local uri = P8INT:GET_MATRIX_URL() .. "/Port/Set/" .. input .. "/" .. output
    LogInfo("Changing Routing. Input: " .. input .. " -> Output: " .. output)
    existingRouting["OUTPUT" .. output] = input
    C4:urlGet(uri, {}, false, function(ticketId, strData, responseCode, tHeaders, strError)
		  local jsonResponse = JSON:decode(strData)
		  if jsonResponse.Result then
			 --self:GET_ROUTING(idBinding)
		  end
	   end)
end

function GetPowerState(data, mode, bay)
    for index,port in pairs(data.Ports) do
	   if port.Bay == bay and port.Mode == mode then
		  return port.DPS
	   end
    end
end

function P8INT:GET_POWER_STATE(idBinding)
    --LogTrace("Updating Sink Power State")
    local uri = P8INT:GET_MATRIX_URL() .. "/Port/List"
    C4:urlGet(uri, {}, false, 
	   function(ticketId, strData, responseCode, tHeaders, strError)
   		  if responseCode ~= 200 or strError ~= nil then
			 LogWarn("Unable to refresh routing")
			 if strError ~= nil then
				 LogWarn("Error = " .. strError)
			 end
			 LogWarn("Response Code = " .. responseCode)
			 return
		  end
	   
		  local jsonResponse = JSON:decode(strData)
		  if jsonResponse.Result then
			 for i = 1,MAX_OUTPUTS do
				local dps = GetPowerState(jsonResponse, "Output", (i-1))
				if roomPower["OUTPUT" .. (i-1)] ~= dps and outputRoom["OUTPUT" .. (i-1)] ~= nil then
				    LogInfo("Output " .. i .. " power state has changed, was " .. roomPower["OUTPUT" .. (i-1)] .. " now " .. dps)
				    local outputsNewInput = existingRouting["OUTPUT" .. (i-1)]
				    local newSourceProxyId = inputProxies["INPUT" .. outputsNewInput]
				    local success = false
				    if dps == 0 then
					   --Tell Director to do a routing change and turn on any other items required
					   if outputsNewInput ~= nil and newSourceProxyId ~= nil then
						  success = true
						  C4:SendToDevice(outputRoom["OUTPUT" .. (i-1)], "SELECT_VIDEO_DEVICE", {deviceid = newSourceProxyId})
					   else
						  LogWarn("Output " .. i .. " Power State changed to on, however the source routed to this output is not mapped in composer. No notification will be sent to composer until it is correctly mapped.")
					   end
				    end
				    if dps == 1 then
					   --Tell director this output has turned off
					   if outputsNewInput ~= nil and newSourceProxyId ~= nil then
						  success = true
						  --TODO: Tell Director the sink has turned off
					   else
						  LogWarn("Output " .. i .. " Power State changed to off, however the source routed to this output is not mapped in composer. No notification will be sent to composer until it is correctly mapped.")
					   end
				    end
				    if dps < 0 then
					success = true
				    end
				    if success then
					   roomPower["OUTPUT" .. (i-1)] = dps
				    end
				end
			 end
		  end
	   end)
end


function P8INT:GET_ROUTING(idBinding)
    --LogTrace("Updating Current Routing")
    local uri = P8INT:GET_MATRIX_URL() .. "/Port/List/Concise"
    C4:urlGet(uri, {}, false, 
	   function(ticketId, strData, responseCode, tHeaders, strError)
   		  if responseCode ~= 200 or strError ~= nil then
			 LogWarn("Unable to refresh routing")
			 LogWarn("Error = " .. strError)
			 LogWarn("Response Code = " .. responseCode)
			 return
		  end
	   
		  local jsonResponse = JSON:decode(strData)
		  if jsonResponse.Result then
			 for i = 1,MAX_OUTPUTS do
				if jsonResponse["Output" .. i] == nil then
--					LogError("Error in output received, port " .. (i) .. " data is missing")
				else
					if existingRouting["OUTPUT" .. (i-1)] ~= jsonResponse["Output" .. i][1] and outputRoom["OUTPUT" .. (i-1)] ~= nil then
					    LogTrace("Output " .. i .. " routing has changed, was " .. existingRouting["OUTPUT" .. (i-1)] .. " now " .. jsonResponse["Output" .. i][1])
					    existingRouting["OUTPUT" .. (i-1)] = jsonResponse["Output" .. i][1]
					    --Tell Director to do a routing change
					    local outputsNewInput = existingRouting["OUTPUT" .. (i-1)]
					    local newSourceProxyId = inputProxies["INPUT" .. outputsNewInput]
					    C4:SendToDevice(outputRoom["OUTPUT" .. (i-1)], "SELECT_VIDEO_DEVICE", {deviceid = newSourceProxyId})
					    
					end
					local tParams = {INPUT = (jsonResponse["Output" .. i][1] + 3000), OUTPUT = (4000 + (i-1))}
					--According to @Piadas INPUT_OUTPUT_CHANGED is only used to update the 'Control' Control inside Composer and has little other effect (and may not even work)
					SendNotify("INPUT_OUTPUT_CHANGED", tParams, idBinding)
					tParams = {INPUT = (jsonResponse["Output" .. i][1] + 1000), OUTPUT = 2000 + (i-1)}
					SendNotify("INPUT_OUTPUT_CHANGED", tParams, idBinding)
				end
			 end
		  end
	   end)
end