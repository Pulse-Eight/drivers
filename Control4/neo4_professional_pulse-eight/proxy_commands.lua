--[[=============================================================================
    Commands received from the AVSwitch proxy (ReceivedFromProxy)

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]

-- This macro is utilized to identify the version string of the driver template version used.
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.device_messages = "2015.03.31"
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Power Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--[[
	Proxy Command: CONNECT_OUTPUT
	Parameters:
		output: mod 1000 value of Output Connection id
--]]
function CONNECT_OUTPUT(output)
    local command_delay = tonumber(Properties["Power On Delay Seconds"])
    local delay_units = "SECONDS"
    local command
    if (gControlMethod == "IR") then
		-- TODO: create packet/command to send to the device
		command = CMDS_IR_ZONES[output]["CONNECT_OUTPUT"]
		LogTrace("command = " .. command)
		PackAndQueueCommand("CONNECT_OUTPUT", command, command_delay, delay_units)
    else
		-- TODO: create packet/command to send to the device
		command = tPowerCommandMap[output] .. "01"
		LogTrace("command = " .. command)
		PackAndQueueCommand("CONNECT_OUTPUT", command, command_delay, delay_units)
		
		GetDeviceVolumeStatus(output)
		
		-- TODO: If the device will automatically report power status after
		--	the On command is sent, then the line below can be commented out		
		GetDevicePowerStatus(output)
		
    end
end

--[[
	Proxy Command: DISCONNECT_OUTPUT
	Parameters:
		output: mod 1000 value of Output Connection id
--]]
function DISCONNECT_OUTPUT(output)
    local command_delay = tonumber(Properties["Power Off Delay Seconds"])
    local delay_units = "SECONDS"
    local command 
    
    if (gControlMethod == "IR") then
		-- TODO: create packet/command to send to the device
		command = CMDS_IR_ZONES[output]["DISCONNECT_OUTPUT"]
		LogTrace("command = " .. command)
		PackAndQueueCommand("DISCONNECT_OUTPUT", command, command_delay, delay_units)		
    else
		-- TODO: create packet/command to send to the device
		command = tPowerCommandMap[output] .. '00' 
		LogTrace("command = " .. command)
		PackAndQueueCommand("DISCONNECT_OUTPUT", command, command_delay, delay_units)
	
		-- TODO: If the device will automatically report power status after
		--	the Off command is sent, then the line below can be commented out
		GetDevicePowerStatus(output)		
    end  
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Input Selection Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--[[
	Proxy Command: SET_INPUT
	Parameters:
		idBinding: proxybindingid of proxy bound to input connection
		output: mod 1000 value of Output Connection id	
		input: mod 1000 value of Input Connection id
--]]
function SET_INPUT(idBinding, output, input)
	local command
	if (gControlMethod == "IR") then		
		-- TODO: create packet/command to send to the device
		command = tInputCommandMap_IR[output][tInputConnMapByID[input].Name]	
	else
		-- TODO: create packet/command to send to the device
		--Edit the Input Selection command syntax based upon the protocol specification
		--if the tables referenced below are set up properly them no editing may be necessary 	
		command = tOutputCommandMap[output] .. tInputCommandMap[tInputConnMapByID[input].Name] 
	end 		
	LogTrace("command = " .. command)
	PackAndQueueCommand("SET_INPUT", command)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Volume Control Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--[[
	Proxy Command: MUTE_OFF
	Parameters:
		output: mod 1000 value of Output Connection id	
--]]
function MUTE_OFF(output)
	local command
	if (gControlMethod == "IR") then		
		-- TODO: create packet/command to send to the device
		command = CMDS_IR_ZONES[output]["MUTE_OFF"]	
	else
		-- TODO: create packet/command to send to the device
		command = tMuteCommandMap[output] .. "OFF"
	end 	
	LogTrace("command = " .. command)
	PackAndQueueCommand("MUTE_OFF", command)
end

--[[
	Proxy Command: MUTE_ON
	Parameters:
		output: mod 1000 value of Output Connection id	
--]]
function MUTE_ON(output)
	local command
	if (gControlMethod == "IR") then			
		command = CMDS_IR_ZONES[output]["MUTE_ON"]	
	else
		-- TODO: create packet/command to send to the device
		command = tMuteCommandMap[output] .. "ON"
	end 	
	LogTrace("command = " .. command)
	PackAndQueueCommand("MUTE_ON", command)		
end

--[[
	Proxy Command: MUTE_TOGGLE
	Parameters:
		output: mod 1000 value of Output Connection id	
--]]
function MUTE_TOGGLE(output)
	local command
	if (gControlMethod == "IR") then			
		command = CMDS_IR_ZONES[output]["MUTE_TOGGLE"]	
	else
		-- TODO: create packet/command to send to the device
		command = tMuteCommandMap[output] .. "TOGGLE"
	end 
	LogTrace("command = " .. command)
	PackAndQueueCommand("MUTE_TOGGLE", command)
end

--[[
	Proxy Command: SET_VOLUME_LEVEL
	Parameters:
		output: mod 1000 value of Output Connection id	
		c4VolumeLevel: volume level to be set represented in Control4 scale (0-100)
--]]
function SET_VOLUME_LEVEL(output, c4VolumeLevel)
	-- TODO: edit "minDeviceLevel" & "maxDeviceLevel" values, based upon the protocol specification for volume range
	local minDeviceLevel = -80
	local maxDeviceLevel = 20
	local deviceVolumeLevel = ConvertVolumeToDevice(c4VolumeLevel, minDeviceLevel, maxDeviceLevel)	
	
	---- TODO: uncomment and edit string padding, if required, based upon the protocol specification
    --deviceVolumeLevel = string.rep("0", 2 - string.len(deviceVolumeLevel)) .. deviceVolumeLevel
	
	LogInfo('deviceVolumeLevel: ' .. deviceVolumeLevel)
  
	-- TODO: create packet/command to send to the device
	local command = tVolumeSetCommandMap[output] .. deviceVolumeLevel
	LogTrace("command = " .. command)
	PackAndQueueCommand("SET_VOLUME_LEVEL", command)
end

--[[
	Helper Function: SET_VOLUME_LEVEL_DEVICE
	Parameters:
		output: mod 1000 value of Output Connection id	
		deviceVolumeLevel: volume level to be set represented in device scale (as sepcified in the device's control protocol)
--]]
function SET_VOLUME_LEVEL_DEVICE(output, deviceVolumeLevel)
	--Called from ContinueVolumeRamping()
	
	-- TODO: create packet/command to send to the device
	local command = tVolumeSetCommandMap[output] .. deviceVolumeLevel
	
	LogTrace("command = " .. command)
	local command_delay = tonumber(Properties["Volume Ramp Delay Milliseconds"])
	PackAndQueueCommand("SET_VOLUME_LEVEL_DEVICE", command, command_delay)
end

--[[
	Proxy Command: PULSE_VOL_DOWN
	Parameters:
		output: mod 1000 value of Output Connection id	
--]]
function PULSE_VOL_DOWN(output)
	local command
	if (gControlMethod == "IR") then		
		-- TODO: create packet/command to send to the device
		command = CMDS_IR_ZONES[output]["VOLUME_DOWN"]	
	else
		-- TODO: create packet/command to send to the device
		command = tVolumeCommandMap[output] .. 'D'
	end 		
	LogTrace("command = " .. command)
	local command_delay = tonumber(Properties["Volume Ramp Delay Milliseconds"])
	PackAndQueueCommand("PULSE_VOL_DOWN", command, command_delay)
end

--[[
	Proxy Command: PULSE_VOL_UP
	Parameters:
		output: mod 1000 value of Output Connection id	
--]]
function PULSE_VOL_UP(output)
	local command
	if (gControlMethod == "IR") then	
		-- TODO: create packet/command to send to the device
		command = CMDS_IR_ZONES[output]["VOLUME_UP"]	
	else
		-- TODO: create packet/command to send to the device
		command = tVolumeCommandMap[output] .. 'U'
	end 		
	LogTrace("command = " .. command)
	local command_delay = tonumber(Properties["Volume Ramp Delay Milliseconds"])
	PackAndQueueCommand("PULSE_VOL_UP", command, command_delay)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Helper Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

--[[
	Helper Function: SEND_COMMAND_FROM_COMMAND_TABLE
	Parameters:
		idBinding: proxy id	
		output: mod 1000 value of Output Connection id
		command_name: name of command to be sent
--]]
function SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, command_name)
    local output_for_log = output or "nil"
    LogTrace("SEND_COMMAND_FROM_COMMAND_TABLE(), idBinding=" .. idBinding .. ", output=" .. output_for_log .. ", command_name=" .. command_name)
	
	-- TODO: create packet/command to send to the device
	local command = GetCommandFromCommandTable(idBinding, output, command_name)
	
	if (command == nil) then
		LogTrace("command is nil")
	else
		LogTrace("command = " .. command)
	end	
	PackAndQueueCommand(command_name, command)		
end

--[[
	Helper Function: GetCommandFromCommandTable
	Parameters:
		idBinding: proxy id	
		output: mod 1000 value of Output Connection id
		command_name: name of command to be returned
--]]
function GetCommandFromCommandTable(idBinding, output, command_name)
	LogTrace("GetCommand()")
	local t = {}
	
	-- TODO: select/create appropriate commands table structure
	
	if (gControlMethod == "IR") then
		t = CMDS_IR
	else
		t = CMDS
	end	

	if (t[idBinding][command_name] ~= nil) then
		return t[idBinding][command_name]
	elseif (t[command_name] ~= nil) then
		return t[command_name]
	else
		LogWarn('GetCommandFromCommandTable: command not defined - '.. command_name)
		return nil
	end	
	
end


--[[
	Helper Function: GetDeviceVolumeStatus
--]]
function GetDeviceVolumeStatus(output)
    LOG:Trace("GetDeviceVolumeStatus(), output = " .. output)
	
	-- TODO: verify table entries in tVolumeQueryMap for all zones
	local command = tVolumeQueryMap[output] 
	LOG:Trace("command = " .. command)
	PackAndQueueCommand("GetDeviceVolumeStatus: Volume", command)
	
	-- TODO: verify table entries in tMuteCommandMap for all zones, modify line below if needed
	command = tMuteCommandMap[output] .. "?"
	LOG:Trace("command = " .. command)
	PackAndQueueCommand("GetDeviceVolumeStatus: Mute", command)	
end

--[[
	Helper Function: GetDevicePowerStatus
--]]
function GetDevicePowerStatus(output)
    LOG:Trace("GetDevicePowerStatus()")
	
	-- TODO: verify table entry in Volume in QUERY table
	local command = tPowerCommandMap[output] .. "?"
	LOG:Trace("command = " .. command)
	PackAndQueueCommand("GetDevicePowerStatus: Volume", command)	
end
