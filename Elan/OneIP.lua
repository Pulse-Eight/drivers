ZoneMaps = {
	["default"] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31}
}

SourceMaps = {
	["default"] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31}
}
MODE_CEC = -1

function EDRV_ZoneSetActiveSource(zone_index, source_index)
	-- Input params are 0 indexed
    ELAN_ConnectTCP()
    ELAN_SendHTTP("GET /Port/Set/" .. SourceMap[source_index+1] .. "/" .. ZoneMap[zone_index+1])
    ELAN_DisconnectTCP()
end

function EDRV_ZonePower(zone_index, turn_on_off)
    -- power the zone on or off
	-- Currently only works on local bay. All other bays respond with Failed to Send
    ELAN_ConnectTCP()
    if (turn_on_off == 0) then
        ELAN_SendHTTP("GET /CEC/off/output/" .. zone_index)
    else
        ELAN_SendHTTP("GET /CEC/on/output/" .. zone_index)
    end
    ELAN_DisconnectTCP()
end

function EDRV_ZoneSetVolume(zone_index, volume_level)
    -- set the discrete volume level for the specified zone
	-- Not supported
end

function EDRV_ZoneVolumeUp(zone_index)
	-- Not supported
	-- Could use /cec/volume/up/{mode}/{bay} once remote bays supported by firmware
end

function EDRV_ZoneVolumeDown(zone_index)
	-- Not supported
	-- Could use /cec/volume/down/{mode}/{bay} once remote bays supported by firmware
end


function EDRV_ZoneSetMute(zone_index, mute_on_off)
    local state
    if (mute_on_off ~= 0) then
        state = 1
    else
        state = 0
    end

    ELAN_ConnectTCP()
    ELAN_SendHTTP("GET /Audio/Mute/" .. zone_index .. "/" .. state)
    ELAN_DisconnectTCP()
end

function EDRV_ProcessIncoming(data)
    -- process data sent from the device
end


function EDRV_Init()
    ip_string = ELAN_GetIPString()
	driver_name = ELAN_GetDriverName()
	if(type(ZoneMaps[driver_name]) == "table") then
		ZoneMap = ZoneMaps[driver_name]
	else 
		ZoneMap = ZoneMaps["default"]
	end
	if(type(SourceMaps[driver_name]) == "table") then
		SourceMap = SourceMaps[driver_name]
	else 
		SourceMap = SourceMaps["default"]
	end
	ELAN_SetTimer(1,5000)
end

function EDRV_OnTimer(timer_id)
	if (timer_id == 1) then
	    if (ELAN_ConnectTCP()) then
	    	ELAN_SendHTTP("GET /System/Details")
			Result = ELAN_WaitResponseString("result", 1000)
	    	ELAN_DisconnectTCP()
			if(Result == '' or Result == nil) then
				ELAN_SetDeviceState ( "RED", "Timed out", 10000)
			else 
				ELAN_SetDeviceState ( "GREEN", "OK", 10000)
			end
		else 
			ELAN_SetDeviceState("RED", "Not Connected", 10000)
		end
	end
end


function EDRV_SetConfigDropDown(sTag, ItemName, ItemIndex)
-- string sTag
-- string ItemName
-- int ItemIndex
	if sTag == "DDTag_CECSupport" then
		if     ItemName == "Off" then
			SET_CEC_ENABLED(0)
		elseif ItemName == "On" then
			SET_CEC_ENABLED(1)
		end
	end
end

function SET_CEC_ENABLED(value)
	MODE_CEC = value
	if value == 1 then
		url = "/CEC/enable"
	else
		url = "/CEC/disable"
	end

	ELAN_ConnectTCP()
	ELAN_SendHTTP("GET " .. url)
    ELAN_DisconnectTCP()
end

--function EDRV_ExecuteConfigProc(proc_id)
--	if (proc_id == 1) then
--		LOAD_ZONE_MAP()
--	end
--end

-- This works, but locks up the elan controller and requires a reboot
--function LOAD_ZONE_MAP() 
--    if (ELAN_ConnectTCP()) then
--   		ELAN_SendHTTP("GET /Port/List")
--		Result = ELAN_WaitResponseString("result", 1000)
--   		ELAN_DisconnectTCP()
--		if( Result ~= nil) then
--			hJSON = ELAN_CreateJSONMsg( Result)
--			portNode = ELAN_FindJSONNode(hJSON, hJSON, "Ports", "ARRAY", true)
--			if (portNode ~= nil) then
--				inputCount = 0
--				outputCount = 0
--				numNodes = ELAN_GetJSONSubNodeCount(hJSON, portNode )
--				if(numNodes ~= nil and numNodes > 0) then
--					for i=0, numNodes-1 do
--						hNode = ELAN_GetJSONSubNode(hJSON, portNode, i)
--						Bay, Mode, Name = PARSE_PORT_LIST_ENTRY(hJSON, hNode)
--						if (Mode == "Input") then 
--							inputCount = inputCount + 1
--							ELAN_SetZoneCtlrSourceName(Bay, Name)
--						end
--						if (Mode == "Output") then 
--							outputCount = outputCount + 1
--							ELAN_SetZoneCtlrZoneName(Bay, Name)
--						end
--					end
--				end
--
--				if(inputCount > 0 and outputCount > 0) then
--					ELAN_ResetNumZoneCtlrZones(outputCount)
--					ELAN_ResetNumZoneCtlrSources(inputCount)
--				end
--			end
--			ELAN_DeleteJSONMsg(hJSON)
--		end
--	end
--end

function PARSE_PORT_LIST_ENTRY(hJSON, hNode)
	Bay, Type = ELAN_FindJSONValueByKey(hJSON, hNode, "Bay", false)
	Mode, Type = ELAN_FindJSONValueByKey(hJSON, hNode, "Mode", false)
	Name, Type = ELAN_FindJSONValueByKey(hJSON, hNode, "Name", false)
	return Bay, Mode, Name
end

function GET_REMOTE_IP(mode, bay)
	if (ELAN_ConnectTCP()) then
   		ELAN_SendHTTP("GET /Port/List")
		Result = ELAN_WaitResponseString("result", 1000)
   		ELAN_DisconnectTCP()

	end
end










