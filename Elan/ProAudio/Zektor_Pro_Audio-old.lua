function EDRV_Init()
	--turns the zektor on, need to add a timer here to set this as on every 15 min
	
	ELAN_Trace ("Zektor Init - Power ON")
	ELAN_Trace ("Hello World")
	ELAN_Trace ("I'm turning the Zektor on")
	ELAN_Trace ("Will do this again in 15 min")
	local sCmd = string.format("^P 1$%c", 0x0D)
	--local sXIO = string.format("^XS +32768$", 0x0D)
	--local sSav = string.format("^SS 8$ ", 0x0D)
	--SendCommand(sCmd)
	--SendCommand(sXIO)
	--ELAN_Trace ("Turning Extended IO Mode On")
	--ELAN_Trace ("Saving Bitmap")
	--SendCommand(sSav)
	ELAN_SetTimer(1, 900000)
	ELAN_KillTimer(2)
	ELAN_KillTimer(3)
	

	
	driver = ELAN_GetDriverName()
	if string.find(driver, "IP")  then
	ELAN_Trace('Is IP Driver, Opening socket') 
	
		socket = ELAN_ConnectTCP()
		if (socket) then 
			ELAN_Trace('Socket Opened') 

		else
			ELAN_Trace("Can't Open Socket")
		end
	else ELAN_Trace('Is 232 Driver, not opening socket') 
	end

end

	
------------------------
function EDRV_ExecuteConfigProc(proc_id)

if proc_id == 1 then
	local sCmd = string.format("^V ?$%c", 0x0D)
	SendCommand(sCmd) 

elseif proc_id == 2 then
	local sCmd = string.format("^P 1$%c", 0x0D)
	local sXIO = string.format("^XS +32768$", 0x0D)
	local sSav = string.format("^SS 8$ ", 0x0D)
	SendCommand(sCmd)
	SendCommand(sXIO)
	ELAN_Trace ("Turning Extended IO Mode On")
	ELAN_Trace ("Saving Bitmap")
	SendCommand(sSav)end
end

--------------------------


function EDRV_OnTimer(timer_id)
		local sCmd = string.format("^P 1$%c", 0x0D)
		local sCmdV = string.format("^SS 256$%c", 0x0D)
		local sCmdB = string.format("^SS 512$%c", 0x0D)
if timer_id == 1
	then
	SendCommand(sCmd)
	ELAN_Trace("15 min Expired, Sending Zektor ON command")
	ELAN_Trace("Will do this again in 15 min")
---volume saving. time seperates last volume send.
elseif timer_id == 2
	then
	SendCommand(sCmdV)
	ELAN_Trace("Volume Settings Saved")
	ELAN_KillTimer(2)
	--ELAN_Sleep(500)
	--local checkvol = string.format("^VPZ @%d?$%c", z_by_index, 0x0D)
	--SendCommand(checkvol)

---saving bass/treb/lipsync settings
elseif timer_id == 3
	then
	SendCommand(sCmdB)
	ELAN_Trace("Volume Settings Saved")
	ELAN_KillTimer(3)
	end

end

----------------------
	

function EDRV_ZoneSetActiveSource(zone_index, source_index)

local sTrace = string.format("EDRV_SetActiveSource: zone %2d src %2d", zone_index, source_index)
	ELAN_Trace(sTrace)

src_by_index=(source_index+1)



z_by_index=(zone_index+1)
digzone=(z_by_index-48)
ELAN_Trace(string.format("OUTGOING ZONE/SOURCE: %s, %s", z_by_index, src_by_index))

if z_by_index <= 48 then 
	sCmd = string.format("^SZ @%d,%d$%c", z_by_index, src_by_index, 0x0D)
	elseif z_by_index > 48 then
	sCmd = string.format("^DSZ @%d,%d$%c", digzone, src_by_index, 0x0D) end
	--elseif src_by_index > 128 then
	-- sCmd = string.format("^DSZ @%d,%d$%c", digzone, src_by_index, 0x0D) end
	SendCommand(sCmd)
end


-----------------------------

function EDRV_ZonePower(zone_index, turn_on_off)
    -- power the zone on or off
	--zero volume in zektor is off, need to set a specific volume for on
local sTrace = string.format("EDRV_ZonePower: zone %d pwr %d", zone_index, turn_on_off)
	ELAN_Trace(sTrace)


		local z_by_index=(zone_index+1)
		local TurnOffsrc = 0
		--local TurnOnVol = 40
		--local sOn = string.format("^VPZ @%d,%d$,%c", z_by_index, TurnOnVol, 0x0D)
		local sOff = string.format("^SZ @%d,%d$%c", z_by_index, TurnOffsrc, 0x0D)
	if (turn_on_off == 0) then 						--off
		SendCommand(sOff)
	else											--on
		ELAN_Trace(string.format("No Zone Power ON command. Source Turns Zone On"))
		ELAN_Sleep(500)
		local checkvol = string.format("^VPZ @%d?$%c", z_by_index, 0x0D)
		SendCommand(checkvol)

		
		--ELAN_RegisterZoneVolume(zone_index, TurnOnVol)
	end
end


--------------------------


function EDRV_ZoneSetVolume(zone_index, volume_level)
	-- set the discrete volume level for the specified zone
	--using 40 as turn on vol.
	ELAN_KillTimer(2)
	local z_by_index=(zone_index+1)
	local sTrace = string.format("EDRV_SetVolume: zone %d src %d", zone_index, volume_level)
	ELAN_Trace(sTrace)		

	local sVol = string.format("^VPZ,@%d,%d$,%c", z_by_index, volume_level, 0x0D)
	SendCommand(sVol)
	ELAN_SetTimer(2, 3000)

    

end

------------------------------------------
    
function EDRV_ZoneSetMute(zone_index, mute_on_off)
	--mute a zone
	--zero is un-mute for zektor and core
	local sTrace = string.format("EDRV_ZoneSetMute: zone %d mute %d", zone_index, mute_on_off)
	ELAN_Trace(sTrace)

local z_by_index=(zone_index+1)
local sMut = string.format("^VMZ,@%d,%d$,%c", z_by_index, mute_on_off, 0x0D)
	SendCommand(sMut)
	

end


----------------------------
function EDRV_ZoneSetOption(zone_index, opt_name, opt_val)

--listening modes
--zone index is not used as only the main zone has listening modes
	ELAN_Trace('Send listening mode ' .. zone_index .. opt_name .. ' ' .. opt_val) --debug
	ELAN_KillTimer(3)
	if (opt_name == 'Zone Mix Down') then
		if (opt_val == 'Normal') then
			local z_by_index=(zone_index+1)
			local sCmd = string.format("^MXZ,@%d,0$,%c", z_by_index, 0x0D)
			SendCommand (sCmd)
			ELAN_SetTimer(3, 3000)

		elseif (opt_val == 'Swap LR') then
			local z_by_index=(zone_index+1)
			local sCmd = string.format("^MXZ,@%d,1$,%c", z_by_index, 0x0D)
			SendCommand (sCmd)
			ELAN_SetTimer(3, 3000)

			
		elseif (opt_val == 'Mono') then
			local z_by_index=(zone_index+1)
			local sCmd = string.format("^MXZ,@%d,2$,%c", z_by_index, 0x0D)
			SendCommand (sCmd)
			ELAN_SetTimer(3, 3000)

		elseif (opt_val == 'Mono L') then
			local z_by_index=(zone_index+1)
			local sCmd = string.format("^MXZ,@%d,3$,%c", z_by_index, 0x0D)
			SendCommand (sCmd)
			ELAN_SetTimer(3, 3000)
		
		elseif (opt_val == 'Mono R') then
			local z_by_index=(zone_index+1)
			local sCmd = string.format("^MXZ,@%d,4$,%c", z_by_index, 0x0D)
			SendCommand (sCmd)
			ELAN_SetTimer(3, 3000)

		elseif (opt_val == 'Mono Subtract L') then
			local z_by_index=(zone_index+1)
			local sCmd = string.format("^MXZ,@%d,5$,%c", z_by_index, 0x0D)
			SendCommand (sCmd)
			ELAN_SetTimer(3, 3000)
		
		elseif (opt_val == 'Mono Subtract R') then
			local z_by_index=(zone_index+1)
			local sCmd = string.format("^MXZ,@%d,5$,%c", z_by_index, 0x0D)
			SendCommand (sCmd)
			ELAN_SetTimer(3, 3000) end
	end
end
----------------------------

--function EDRV_SetVariableInt(var_name, val)
function EDRV_SetVariableIntZone(opt_name, zone_index , opt_val )
	--send bass and treble commands
		local zidx = zone_index+1
		local zek_val = (opt_val*2+128)	

ELAN_Trace(string.format('Setting Zone Variale Interger Value: %s, ZONEIndex %d, Value %d', opt_name, zone_index, opt_val))
ELAN_KillTimer(3)	


	--assemble commands
		if string.match(opt_name, "BASS") then
			local sCmdB = string.format("^BAZ,@%d,%d$,%c", zidx, zek_val, 0x0D)
			SendCommand(sCmdB)
			ELAN_SetTimer(3, 3000)
			elseif
				string.match(opt_name, "TREBLE") then
				local sCmdT = string.format("^TRZ,@%d,%d$,%c", zidx, zek_val, 0x0D)
				SendCommand(sCmdT)
				ELAN_SetTimer(3, 3000)
			elseif
				--doing it for 100HZ now
				string.match(opt_name, "100HZ") then
				local sCmdT = string.format("^EQ1Z,@%d,%d$,%c", zidx, zek_val, 0x0D)
				SendCommand(sCmdT)
				ELAN_SetTimer(3, 3000)
			elseif
				--doing it for 330HZ now
				string.match(opt_name, "330HZ") then
				local sCmdT = string.format("^EQ2Z,@%d,%d$,%c", zidx, zek_val, 0x0D)
				SendCommand(sCmdT)
				ELAN_SetTimer(3, 3000)
			elseif
				--doing it for 1KHZ now
				string.match(opt_name, "1000HZ") then
				local sCmdT = string.format("^EQ3Z,@%d,%d$,%c", zidx, zek_val, 0x0D)
				SendCommand(sCmdT)
				ELAN_SetTimer(3, 3000)
			elseif
				--doing it for 3.3KHZ now
				string.match(opt_name, "3300HZ") then
				local sCmdT = string.format("^EQ4Z,@%d,%d$,%c", zidx, zek_val, 0x0D)
				SendCommand(sCmdT)
				ELAN_SetTimer(3, 3000)
			elseif
				string.match(opt_name, "10KHZ") then
				local sCmdT = string.format("^EQ5Z,@%d,%d$,%c", zidx, zek_val, 0x0D)
				SendCommand(sCmdT)
				ELAN_SetTimer(3, 3000)
			elseif
				--doing it for Lipsync now
				string.match(opt_name, "LIPSYNC") then
				local sCmdT = string.format("^LSZ,@%d,%d$,%c", zidx, zek_val, 0x0D)
				SendCommand(sCmdT)
				ELAN_SetTimer(3, 3000)
			end

end
 
		

-----------------



function EDRV_ProcessIncoming(data)
    -- process data sent from the device
	-- this is a 1 way device for now
	-- just tracing the response for troubleshooting
	--NEED TO ADD SOURCE
	ELAN_Trace(string.format("RX from Zektor %s", data))
----volume	
if string.find(data, "VPZ")  then
		local sZone 
		local volume_level 

		sZone = tonumber(string.sub(data, 9, 10))
		volume_level = string.sub(data, 12, 14)
		zone_index = sZone - 1

	
		ELAN_Trace(string.format("INCOMING ZONE: %s", sZone))
		ELAN_Trace(string.format("INCOMING VOL: %s", volume_level))
		ELAN_RegisterZoneVolume(zone_index, volume_level)
		-----need to validate proper parsing



---SOURCE
elseif string.find(data, "SZ")  then
		local sZone 
		local source

		sZone = tonumber(string.sub(data, 8, 9))
		source = tonumber(string.sub(data, 11, 13))
		zone_index = sZone - 1
		source_index = source - 1


	
		ELAN_Trace(string.format("INCOMING ZONE: %s", sZone))
		ELAN_Trace(string.format("INCOMING SRC: %s", source))
		ELAN_RegisterZoneSource(zone_index, source_index)
	

--- DIGITAL SOURCE
elseif string.find(data, "DSZ")  then
		local dZone 
		local dsource

		dZone = tonumber(string.sub(data, 9, 10))
		dsource = string.sub(data, 12, 14)
		zone_index = dZone - 1
		source_index = dsource - 1


	
		ELAN_Trace(string.format("INCOMING ZONE: %s", dZone))
		ELAN_Trace(string.format("INCOMING DSRC: %s", dsource))
		ELAN_RegisterZoneSource(zone_index, source_index)	

-----MUTE
elseif string.find(data, "VMZ")  then
		local sZone 
		local sMute

		sZone = tonumber(string.sub(data, 9, 10))
		sMute = string.sub(data, 12, 12)
		zone_index = sZone - 1

	
		ELAN_Trace(string.format("INCOMING ZONE: %s", sZone))
		ELAN_Trace(string.format("INCOMING MUTE: %s", sMute))
		ELAN_RegisterZoneMute(zone_index, sMute)
		-----need to validate proper parsing
----------Version Info
elseif string.find(data, "V ")  then

ELAN_SetConfigurationString("deviceinfo", data)
ELAN_Trace(data)end

end

function SendCommand(sCmd)
	

driver = ELAN_GetDriverName()
	if string.find(driver, "IP")  then
		ELAN_Trace('Is IP Driver, Opening socket')
		socket = ELAN_ConnectTCP()

		if (socket) then 
			ELAN_Trace('Socket Opened')
			ELAN_SendToDeviceString(sCmd)
			ELAN_Trace(string.format("TX to Zektor %s", sCmd)) 
		else
			ELAN_Trace("Can't Open Socket")
		end
 else
	ELAN_SendToDeviceString(sCmd)
	ELAN_Trace(string.format("TX to Zektor %s", sCmd))
end
	
		
end





































