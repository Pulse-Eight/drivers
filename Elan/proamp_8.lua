function EDRV_ZoneSetActiveSource(zone_index, source_index)

end

function EDRV_ZonePower(zone_index, turn_on_off)

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
	ELAN_SendHTTP("GET /Audio/Mute/" .. zone_index .. "/3/" .. state)
	ELAN_DisconnectTCP()
end


