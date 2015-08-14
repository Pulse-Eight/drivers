--[[=============================================================================
    AVSwitch Proxy Class Code

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]

-- This macro is utilized to identify the version string of the driver template version used.
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.properties = "2015.03.31"
end

AVSwitchProxy = inheritsFrom(nil)

function AVSwitchProxy:construct(avswitchBindingID, bProcessesDeviceMessages, tVolumeRampingTracking)
	-- member variables
	self._AVSwitchBindingID = avswitchBindingID
	self._PowerState = {}						--Valid Values: "ON", "OFF", "POWER_ON_SEQUENCE", "POWER_OFF_SEQUENCE"
	self._VolumeIsRamping = false
	self._VolumeRamping = tVolumeRampingTracking		--[0] = {state = false,mode = "",} ||	"state" is boolean, "mode" values: "VOLUME_UP" & "VOLUME_DOWN"
	self._LastVolumeStatusValue = {}	
	self._CurrentlySelectedInput = {}
	self._ProcessesDeviceMessages = bProcessesDeviceMessages
	self._ControlMethod = ""						--Valid Values: "NETWORK", "SERIAL", "IR" 
end

------------------------------------------------------------------------
-- AVSwitch Proxy Commands (PRX_CMD)
------------------------------------------------------------------------
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Power Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function AVSwitchProxy:prx_ON(tParams)
	--Handled by CONNECT_OUTPUT
	--ON()
end

function AVSwitchProxy:prx_OFF(tParams)
	--Handled by DISCONNECT_OUTPUT
	--OFF()
end

function AVSwitchProxy:prx_CONNECT_OUTPUT(tParams)
	local output = tonumber(tParams.OUTPUT) % 1000 
	if (self._PowerState[output] ~= nil) then
		if (self._PowerState[output] == 'ON') or (self._PowerState[output] == 'POWER_ON_SEQUENCE') then 
			LogInfo("Power State is '" .. self._PowerState[output] .. "', exiting CONNECT_OUTPUT")
			return 
		end	
	end	
	if (self._ProcessesDeviceMessages == false) then
		self._PowerState[output] = 'ON'
	else	
		self._PowerState[output] = 'POWER_ON_SEQUENCE'
	end	
	CONNECT_OUTPUT(output)
end

function AVSwitchProxy:prx_DISCONNECT_OUTPUT(tParams)
    local output = tonumber(tParams.OUTPUT) % 1000
    if (self._ProcessesDeviceMessages == false) then
	   self._PowerState[output] = 'OFF'
    else	
	   self._PowerState[output] = 'POWER_OFF_SEQUENCE'
    end	
    DISCONNECT_OUTPUT(output)
  
    self._CurrentlySelectedInput[output] = -1
    C4:SendToProxy(self._AVSwitchBindingID, 'INPUT_OUTPUT_CHANGED', {INPUT = -1, OUTPUT = 4000 + output})
    C4:SendToProxy(self._AVSwitchBindingID, 'INPUT_OUTPUT_CHANGED', {INPUT = -1, OUTPUT = 2000 + output})
end


--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Input Selection Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function AVSwitchProxy:prx_SET_INPUT(idBinding, tParams)
	local input = tonumber(tParams["INPUT"] % 1000)
	local output = tonumber(tParams["OUTPUT"] % 1000)
	self._CurrentlySelectedInput[output] = input
	if (gControlMethod == "IR") then			
		NOTIFY.INPUT_OUTPUT_CHANGED(self._AVSwitchBindingID, input, output)		
	end 		
	SET_INPUT(idBinding, output, input)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Volume Control Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function AVSwitchProxy:prx_MUTE_OFF(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) or DEFAULT_OUTPUT_ID
	if (gControlMethod == "IR") then			
		NOTIFY.MUTE_CHANGED(self._AVSwitchBindingID, output, "False")
	end 		
	MUTE_OFF(output)
end

function AVSwitchProxy:prx_MUTE_ON(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) or DEFAULT_OUTPUT_ID
	if (gControlMethod == "IR") then			
		NOTIFY.MUTE_CHANGED(self._AVSwitchBindingID, output, "True")
	end 		
	MUTE_ON(output)
end

function AVSwitchProxy:prx_MUTE_TOGGLE(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) 
	MUTE_TOGGLE(output)
end

function AVSwitchProxy:prx_SET_VOLUME_LEVEL(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) 
	local c4VolumeLevel = tonumber(tParams['LEVEL'])
	SET_VOLUME_LEVEL(output, c4VolumeLevel)
end

function AVSwitchProxy:prx_PULSE_VOL_DOWN(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) 
	PULSE_VOL_DOWN(output)
end

function AVSwitchProxy:prx_PULSE_VOL_UP(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) 
	PULSE_VOL_UP(output)
end

function AVSwitchProxy:prx_START_VOL_DOWN(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) 
	self:ChangeVolume(output, "START_VOL_DOWN")
end

function AVSwitchProxy:prx_START_VOL_UP(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000)
	self:ChangeVolume(output, "START_VOL_UP")
end

function AVSwitchProxy:prx_STOP_VOL_DOWN(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000)
	self:ChangeVolume(output, "STOP_VOL_DOWN")
end

function AVSwitchProxy:prx_STOP_VOL_UP(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000)
	self:ChangeVolume(output, "STOP_VOL_UP")
end

---------------------- Volume Helper Functions ----------------------
function AVSwitchProxy:ChangeVolume(output, command_name)
	if (command_name == "STOP_VOL_UP") or (command_name == "STOP_VOL_DOWN") then
		self._VolumeIsRamping = false
		self._VolumeRamping[output].state = false
		self._VolumeRamping[output].mode = ""
	elseif (command_name == "START_VOL_UP") then 
		self._VolumeIsRamping = true
		self._VolumeRamping[output].state = true
		self._VolumeRamping[output].mode = "VOLUME_UP" 
		PULSE_VOL_UP(output)	
	elseif (command_name == "START_VOL_DOWN") then 	
		self._VolumeIsRamping = true
		self._VolumeRamping[output].state = true
		self._VolumeRamping[output].mode = "VOLUME_DOWN"	
		PULSE_VOL_DOWN(output)		
	else
		LogWarn(command_name .. " not handled in ChangeVolume()")
	end
end

function AVSwitchProxy:ContinueVolumeRamping(output)
	local command
	if (gControlMethod == "IR") then   
		if (self._VolumeRamping[output].mode == "VOLUME_UP") then
			PULSE_VOL_UP(output)	
		elseif (self._VolumeRamping[output].mode == "VOLUME_DOWN") then
			PULSE_VOL_DOWN(output)	
		else
			LogWarn("ContinueVolumeRamping() ramping mode is not valid.")
		end	
	else
		local volume = self._LastVolumeStatusValue[output]
		local deviceVolumeLevel = self:GetNextVolumeCurveValue(output, volume)
		if (deviceVolumeLevel ~= nil) then
			self._LastVolumeStatusValue[output] = deviceVolumeLevel
			SET_VOLUME_LEVEL_DEVICE(output, deviceVolumeLevel)                                 
		else
			LogWarn("ContinueVolumeRamping() next value is nil")
			return
		end
	end 
end

function AVSwitchProxy:GetNextVolumeCurveValue(output, volume)
	local i, point
	volume=tonumber(volume)
	if (self._VolumeRamping[output].mode == "VOLUME_UP") then
		for i=1,table.maxn(tVolumeCurve) do
			point=tonumber(tVolumeCurve[i])
			if point > volume then		
				return tVolumeCurve[i]
			end
		end
	elseif (self._VolumeRamping[output].mode == "VOLUME_DOWN") then
		for i=table.maxn(tVolumeCurve),1,-1 do
			point=tonumber(tVolumeCurve[i])
			if point < volume then
				return tVolumeCurve[i]
			end
		end
	else
		LogWarn("Volume Ramping Mode not set for "  .. tOutputConnMap[output])
		return nil
	end 
end

function ConvertVolumeToC4(volume, minDeviceLevel, maxDeviceLevel)
	--to be used when converting a volume level from a device to a 
	--percentage value that can be used by C4 proxies
	--"volume" is the volume value from the device
	--"minDeviceLevel" & "maxDeviceLevel" are the minimum and maximum volume levels
	--as specified in the device protocol documentation
	return ProcessVolumeLevel(volume, minDeviceLevel, maxDeviceLevel, 0, 100)
end

function ConvertVolumeToDevice(volume, minDeviceLevel, maxDeviceLevel)
	--to be used when converting a volume level from a C4 proxy to a 
	--value that can be used by the device 
	--"volume" is the volume value from the C4 proxy
	--"minDeviceLevel" & "maxDeviceLevel" are the minimum and maximum volume levels
	--as specified in the device protocol documentation
	return ProcessVolumeLevel(volume, 0, 100, minDeviceLevel, maxDeviceLevel)
end

function ProcessVolumeLevel(volLevel, minVolLevel, maxVolLevel, minDeviceLevel, maxDeviceLevel)
	  local level = (volLevel-minVolLevel)/(maxVolLevel-minVolLevel)
	  --LogInfo("level = " .. level)
	  local vl=(level*(maxDeviceLevel-minDeviceLevel))+minDeviceLevel
	  --LogInfo("vl = " .. vl)
	  vl= tonumber(("%.".."0".."f"):format(vl))
	  --LogInfo("vl new = " .. vl)
	  LogInfo("ProcessVolumeLevel(level in=" .. volLevel .. ", level out=" .. vl .. ")")
	  return vl
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Menu Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function AVSwitchProxy:prx_INFO(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "INFO")
end

function AVSwitchProxy:prx_GUIDE(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "GUIDE")
end

function AVSwitchProxy:prx_MENU(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "MENU")
end

function AVSwitchProxy:prx_CANCEL(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "CANCEL")
end

function AVSwitchProxy:prx_UP(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "UP")
end

function AVSwitchProxy:prx_DOWN(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "DOWN")
end

function AVSwitchProxy:prx_LEFT(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "LEFT")
end

function AVSwitchProxy:prx_RIGHT(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "RIGHT")
end

function AVSwitchProxy:prx_ENTER(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "ENTER")
end

function AVSwitchProxy:prx_RECALL(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "RECALL")
end

function AVSwitchProxy:prx_OPEN_CLOSE(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "OPEN_CLOSE")
end

function AVSwitchProxy:prx_PROGRAM_A(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "PROGRAM_A")
end

function AVSwitchProxy:prx_PROGRAM_B(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "PROGRAM_B")
end

function AVSwitchProxy:prx_PROGRAM_C(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "PROGRAM_C")
end

function AVSwitchProxy:prx_PROGRAM_D(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "PROGRAM_D")
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Digit Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function AVSwitchProxy:prx_NUMBER_0(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_0")
end

function AVSwitchProxy:prx_NUMBER_1(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_1")
end

function AVSwitchProxy:prx_NUMBER_2(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_2")
end

function AVSwitchProxy:prx_NUMBER_3(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_3")
end

function AVSwitchProxy:prx_NUMBER_4(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_4")
end

function AVSwitchProxy:prx_NUMBER_5(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_5")
end

function AVSwitchProxy:prx_NUMBER_6(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_6")
end

function AVSwitchProxy:prx_NUMBER_7(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_7")
end

function AVSwitchProxy:prx_NUMBER_8(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_8")
end

function AVSwitchProxy:prx_NUMBER_9(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_9")
end

function AVSwitchProxy:prx_STAR(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "STAR")
end

function AVSwitchProxy:prx_POUND(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "POUND")
end

function get_output_with_nil_test(output)
	local id = nil
	if (output ~= nil) then
		id = tonumber(output % 1000)
	end
	return id
end

------------------------------------------------------------------------
-- AVSwitch Proxy Notifies
------------------------------------------------------------------------

function AVSwitchProxy:dev_InputOutputChanged(input, output)
	NOTIFY.INPUT_OUTPUT_CHANGED(self._AVSwitchBindingID, input, output)
end

function AVSwitchProxy:dev_PowerOn(output)
	self._PowerState[output] = "ON"
	NOTIFY.ON()	
end

function AVSwitchProxy:dev_PowerOff(output)
	self._PowerState[output] = "OFF"
	NOTIFY.OFF()
end

function AVSwitchProxy:dev_VolumeLevelChanged(output, c4Level, deviceLevel)
	NOTIFY.VOLUME_LEVEL_CHANGED(self._AVSwitchBindingID, output, c4Level)	
	
	if (self._VolumeIsRamping) then
		--do nothing
		--during volume ramping, LastVolumeStatusValue is set in ContinueVolumeRamping()
	else
		self._LastVolumeStatusValue[output] = deviceLevel
	end	
end

function AVSwitchProxy:dev_MuteChanged(output, state)
	NOTIFY.MUTE_CHANGED(self._AVSwitchBindingID, output, state)
end		

function AVSwitchProxy:dev_BassLevelChanged(output, level)
	NOTIFY.BASS_LEVEL_CHANGED(self._AVSwitchBindingID, output, level)
end	

function AVSwitchProxy:dev_TrebleLevelChanged(output, level)
	NOTIFY.TREBLE_LEVEL_CHANGED(self._AVSwitchBindingID, output, level)
end	

function AVSwitchProxy:dev_BalanceLevelChanged(output, level)
	NOTIFY.BALANCE_LEVEL_CHANGED(self._AVSwitchBindingID, output, level)
end	

function AVSwitchProxy:dev_LoudnessChanged(output, state)
	NOTIFY.LOUDNESS_CHANGED(self._AVSwitchBindingID, output, state)
end
