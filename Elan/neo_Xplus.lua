function EDRV_Init()
	MAX_ZONES = 10
	ip_string = ELAN_GetIPString()
	ELAN_Trace("Initialising NeoX+ Driver for unit at " .. ip_string)
	zoneState = {}
	for i=0,(MAX_ZONES-1) do
		zoneState[i] = {}
		zoneState[i].sourceId = -1
		zoneState[i].powerState = 0
		zoneState[i].volume = 0
		zoneState[i].muted = false
		zoneState[i].waitForVolume = -1
	end
	socket = ELAN_CreateUDPMulticastSocket("224.0.0.1", 8811)
	if (socket > 0) then
		ELAN_Trace("Socket " .. tostring(socket) ..  " opened")
	else
		ELAN_Trace("Failed to open socket")
	end
end

function EDRV_SetIPConfig(sIPString, iPort)
	ip_string = ELAN_GetIPString() 
end

function EDRV_ZoneSetActiveSource(zone_index, source_index)
	ELAN_Trace("EDRV_ZoneSetActiveSourcefor zone: " .. zone_index .. " to " .. tostring(source_index) .. " From: " .. zoneState[zone_index].sourceId)

	if(source_index < 8) then
		ELAN_ConnectTCP()
		ELAN_SendHTTP("GET /CEC/on/output/" .. zone_index)
		ELAN_DisconnectTCP()
	end

	zoneState[zone_index].sourceId = source_index
	ELAN_ConnectTCP()
	ELAN_SendHTTP("GET /Port/Set/" .. source_index.. "/" .. zone_index)
	ELAN_DisconnectTCP()

	ELAN_ConnectTCP()
	ELAN_SendHTTP("GET /Audio/Mute/" .. zone_index .. "/" .. 0)
	zoneState[zone_index].muted = false
	ELAN_DisconnectTCP()

	ELAN_SetTimer(1,5)
end

function EDRV_ZonePower(zone_index, turn_on_off)
	ELAN_Trace("EDRV_ZonePower for zone: " .. zone_index .. " to " .. tostring(turn_on_off))
	ELAN_ConnectTCP()
	if (turn_on_off == 0) then
		ELAN_SendHTTP("GET /CEC/off/output/" .. zone_index)
		zoneOff(zone_index)
	end
	ELAN_DisconnectTCP()

	-- Always mute on power off
	if (turn_on_off == 0) then
		ELAN_ConnectTCP()
		ELAN_SendHTTP("GET /Audio/Mute/" .. zone_index .. "/" .. 1)
		zoneState[zone_index].muted = true
		ELAN_DisconnectTCP()
		ELAN_SetTimer(1,5)
	end

end

function EDRV_ZoneSetVolume(zone_index, volume_level)
	ELAN_Trace("EDRV_ZoneVolume: " .. zone_index .. " to " .. volume_level)
	ELAN_ConnectTCP()
	ELAN_SendHTTP("GET /Audio/Volume/" .. zone_index .. "/" .. volume_level)
	ELAN_DisconnectTCP()
	zoneState[zone_index].muted = false
	elanVolume(zone_index, volume_level)
	zoneState[zone_index].waitForVolume = volume_level
	ELAN_SetTimer(1,5)
end

function EDRV_ZoneSetMute(zone_index, mute_on_off)
	ELAN_Trace("EDRV_ZoneSetMute: " .. zone_index .. " to " .. tostring(mute_on_off))
	local state
	if (mute_on_off ~= 0) then
		zoneState[zone_index].muted = true
		state = 1
	else
		zoneState[zone_index].muted = false
		state = 0
	end
	ELAN_ConnectTCP()
	ELAN_SendHTTP("GET /Audio/Mute/" .. zone_index .. "/" .. state)
	ELAN_DisconnectTCP()
end


function EDRV_OnTimer(timer_id)
	if (timer_id == 1) then
		for i=0,MAX_ZONES-1 do
			if (zoneState[i].powerState == 1) then
				ELAN_Trace("zone " .. i)
				ELAN_RegisterZoneOn(i, 1)
				ELAN_RegisterZoneSource(i, zoneState[i].sourceId)
				elanMuteOff(i, zoneState[i].muted)
				elanVolume(i, zoneState[i].volume)

			else
				ELAN_RegisterZoneOn(i,0)
			end
		end
		ELAN_KillTimer(1)
	end
end

function EDRV_RecvUDPfrom(socket_id, nMessageBytes, UDPmessage, sRemoteIp, iPort)
	local header
	local payload
	if(ip_string ~= sRemoteIp) then
		--ELAN_Trace("Got UDP Multicast from other source. ignoring")
	else
		--ELAN_Trace("Got UDP Multicast from " .. sRemoteIp .. ":" .. tostring(iPort) .. " of length: " .. nMessageBytes .. " on socket: " .. socket_id)
		if (nMessageBytes < 24) then
			ELAN_Trace("Message is too short to be a Pulse-Eight MX_Remote message")
			return
		else
			header, payload = parseMxMessage(nMessageBytes, UDPmessage)
			--ELAN_Trace(header.opcode)
			if(header.opcode ~= nil and (header.opcode == 18 or header.opcode == 16 or header.opcode == 15)) then
				-- volume change or mute
				local bay = payload.local_bay - 12
				ELAN_Trace("Volume Change requested via UDP")
				ELAN_Trace("Changing Volume on bay: " .. payload.local_bay .. " to " .. payload.volume)
				elanVolume(bay, payload.volume)
				if(payload.muted == 3 ) then
					elanMuteOn(bay)
				else
					elanMuteOff(bay)
				end
			elseif (header.opcode == 8) then
				-- Routing change
				local bay = payload.sink_bay - 12
				ELAN_Trace("Routing Change requested via UDP")
				ELAN_Trace("Sink: " .. payload.sink_bay .. " Selected: " .. payload.selected .. " Video: " .. payload.video .. " Scrambled: " .. payload.scrambled .. " Audio: " ..payload.audio)
				
				--if (zoneState[bay].sourceId ~= payload.selected ) then
					ELAN_RegisterZoneSource(bay, payload.selected )
					zoneState[bay].sourceId = payload.selected 
					zoneState[bay].powerState = 1
				--end
			elseif (header.opcode == 5) then
				-- Power Change
				local bay = payload.local_bay - 12
				ELAN_Trace("Power Change requested via UDP for zone " .. bay )
				if (payload.on == 1) then
					zoneOn(bay)
				else
					zoneOff(bay)
				end
			end
		
		end
	end
end

function parseMxMessage(nMessageBytes, UDPmessage)
	local header = {}
	local payload = {}

	if (string.sub(UDPmessage, 1,2) == 'P8') then
		-- Parse the header
		header.protocol = bit32.lshift(string.byte(UDPmessage,4),8) + string.byte(UDPmessage,3)
		header.box_id = {}
		header.box_id[1] = bit32.lshift(string.byte(UDPmessage,8),24) + bit32.lshift(string.byte(UDPmessage,7),16) + bit32.lshift(string.byte(UDPmessage,6),8) + string.byte(UDPmessage,5)
		header.box_id[2] = bit32.lshift(string.byte(UDPmessage,12),24) + bit32.lshift(string.byte(UDPmessage,11),16) + bit32.lshift(string.byte(UDPmessage,10),8) + string.byte(UDPmessage,9)
		header.box_id[3] = bit32.lshift(string.byte(UDPmessage,16),24) + bit32.lshift(string.byte(UDPmessage,15),16) + bit32.lshift(string.byte(UDPmessage,14),8) + string.byte(UDPmessage,13)
		header.box_id[4] = bit32.lshift(string.byte(UDPmessage,20),24) + bit32.lshift(string.byte(UDPmessage,19),16) + bit32.lshift(string.byte(UDPmessage,18),8) + string.byte(UDPmessage,17)
		header.opcode = bit32.lshift(string.byte(UDPmessage,22),8) + string.byte(UDPmessage,21)
		header.length = bit32.lshift(string.byte(UDPmessage,24),8) + string.byte(UDPmessage,23)
		
		--ELAN_Trace("Protocol: " .. header.protocol)
		--ELAN_Trace("Box ID: " .. header.box_id[1] .. " " .. header.box_id[2] .. " " .. header.box_id[3] .. " " .. header.box_id[4])
		--ELAN_Trace("Opcode: " .. header.opcode)
		--ELAN_Trace("Length: " .. header.length)

		if (header.opcode == 18 or header.opcode == 15 or header.opcode == 16) then 
			-- volume up/down/mute
			payload.local_bay = string.byte(UDPmessage,25)
			payload.volume = string.byte(UDPmessage,26)
			payload.volume_r = string.byte(UDPmessage,27)
			payload.muted = string.byte(UDPmessage,28)
		elseif (header.opcode == 8) then
			-- Routing Change
			payload.sink_bay = string.byte(UDPmessage,25)
			payload.selected = string.byte(UDPmessage,26)
			payload.video = string.byte(UDPmessage,27)
			payload.scrambled = string.byte(UDPmessage,28)
			payload.audio = string.byte(UDPmessage,29)
		elseif (header.opcode == 5) then
			-- Power change
			payload.local_bay = string.byte(UDPmessage,25)
			payload.on = string.byte(UDPmessage,26)
		end
	end
	
	return header, payload
end

function elanZone(zone)
	ELAN_Trace("elanZone(" .. tostring(zone) .. ")")
	if(zoneState[zone].sourceId >= 0) then
		ELAN_RegisterZoneSource(zone, zoneState[zone].sourceId)
	end
end

function zoneOff(zone)
	if(zoneState[zone].powerState ~= 0) then
		zoneState[zone].powerState = 0
		ELAN_RegisterZoneOn(zone, false)
	end
end

function zoneOn(zone)
	ELAN_Trace("ZoneOn("..zone..") " .. zoneState[zone].powerState)
	zoneState[zone].powerState = 1
	-- Delay and reset zone status
	ELAN_SetTimer(1,5)
end

function elanMuteOn(zone)
--	ELAN_Trace("elanMuteOn("..zone..")")
	ELAN_RegisterZoneMute(zone, 1)
	zoneState[zone].muted = true
end

function elanMuteOff(zone)
--	ELAN_Trace("elanMuteOff("..zone..")")
	ELAN_RegisterZoneMute(zone, 0)
	zoneState[zone].muted = false
end

function elanVolume(zone, volume)
	if(volume <= 100) then
		zoneState[zone].volume = volume
		ELAN_RegisterZoneVolume(zone, volume)
	end
end
