    function EDRV_ZoneSetActiveSource(zone_index, source_index)
		ELAN_ConnectTCP()
		ELAN_SendHTTP("GET /Port/Set/" .. source_index .. "/" .. zone_index)
		ELAN_DisconnectTCP()
    end

    function EDRV_ZonePower(zone_index, turn_on_off)
    -- power the zone on or off
		-- Nothing done yet, but we could potentially turn off the display?
    end

    function EDRV_ZoneSetVolume(zone_index, volume_level)
    -- set the discrete volume level for the specified zone
		-- We don't support this yet, but we could set the AVR Volume in the future?
    end


    function EDRV_ProcessIncoming(data)
    -- process data sent from the device
    end


