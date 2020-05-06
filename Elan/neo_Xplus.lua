function EDRV_ZoneSetActiveSource(zone_index, source_index)
	ELAN_ConnectTCP()
	ELAN_SendHTTP("GET /Port/Set/" .. source_index .. "/" .. zone_index)
	ELAN_DisconnectTCP()
end

function EDRV_ZonePower(zone_index, turn_on_off)
	ELAN_ConnectTCP()
	local state
	if (turn_on_off) then
		state = "on"
	else
		state = "off"
	end
	ELAN_SendHTTP("GET /CEC/" .. state .. "/output/" .. zone_index)
	ELAN_DisconnectTCP()
end

function EDRV_ZoneSetVolume(zone_index, volume_level)
	ELAN_ConnectTCP()
	ELAN_SendHTTP("GET /Audio/Volume/" .. zone_index .. "/" .. volume_level)
	ELAN_DisconnectTCP()
end


function EDRV_ZoneSetMute(zone_index, mute_on_off)
	local state
	if (mute_on_off) then
		state = 0
	else
		state = 1
	end

	ELAN_ConnectTCP()
	ELAN_SendHTTP("GET /Audio/Mute/" .. zone_index .. "/" .. state)
	ELAN_DisconnectTCP()
end


