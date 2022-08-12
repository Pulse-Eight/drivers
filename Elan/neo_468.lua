ZoneMaps = {
	["neo:XMR"] = {0,1,2,3,4,5,8,9},
	["neo:XSR"] = {0,1,2,3,8,9},
	["neo 8A Modular"] = {0,1,2,3,4,5,6,7,8,9},
	["neo 6A Modular"] = {0,1,2,3,4,5,8,9},
	["neo 4 Professional"] = {0,1,2,3},
	["default"] = {0,1,2,3,4,5,6,7,8,9,10,11,12}
}

SourceMaps = {
	["neo:XMR"] = {0,1,2,3,4,5,8,9,10,11},
	["neo:XSR"] = {0,1,2,3,4,5},
	["neo 8A Modular"] = {0,1,2,3,4,5,6,7},
	["neo 6A Modular"] = {0,1,2,3,4,5},
	["neo 4 Professional"] = {0,1,2,3},
	["default"] = {0,1,2,3,4,5,6,7,8,9,10,11,12}
}

function EDRV_ZoneSetActiveSource(zone_index, source_index)
	-- Input params are 0 indexed
    ELAN_ConnectTCP()
    ELAN_SendHTTP("GET /Port/Set/" .. SourceMap[source_index+1] .. "/" .. ZoneMap[zone_index+1])
    ELAN_DisconnectTCP()
end

function EDRV_ZonePower(zone_index, turn_on_off)
    -- power the zone on or off
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
    ELAN_ConnectTCP()
    ELAN_SendHTTP("GET /Audio/Volume/" .. zone_index .. "/" .. volume_level)
    ELAN_DisconnectTCP()
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
			if( Result == nil) then
				ELAN_SetDeviceState ( "RED", "Timed out", 10000)
			else 
				ELAN_SetDeviceState ( "GREEN", "OK", 10000)
			end
		else 
			ELAN_SetDeviceState("RED", "Not Connected", 10000)
		end
	end
end







