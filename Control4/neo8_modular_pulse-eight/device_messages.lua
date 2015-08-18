--[[=============================================================================
    Get, Handle and Dispatch message functions

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]

-- This macro is utilized to identify the version string of the driver template version used.
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.device_messages = "2015.03.31"
end

--[[=============================================================================
    GetMessage()
  
    Description:
    Used to retrieve a message from the communication buffer. Each driver is
    responsible for parsing that communication from the buffer.
  
    Parameters:
    None
  
    Returns:
    A single message from the communication buffer
===============================================================================]]
function GetMessage()
	local message, pos
	
	--TODO: Implement a string using Lua captures and patterns which 
	--		will be used by string.match to parse out a single message
	--      from the receive buffer(gReceiveBuffer).
	--		The example shown here will return all characters from the beginning of 
	--		the gReceiveBuffer up until but not including the first carriage return.
	local pattern = "^(.-)\r()"
	
	if (gReceiveBuffer:len() > 0) then
		message, pos = string.match(gReceiveBuffer, pattern)
		if (message == nil) then
			--LOG:Info("Do not have a complete message")
			return ""
		end
		gReceiveBuffer = gReceiveBuffer:sub(pos)		
	end

	return message
	
end

--[[=============================================================================
    HandleMessage(message)]

    Description
    This is where we parse the messages returned from the GetMessage()
    function into a command and data. The call to 'DispatchMessage' will use the
    'name' variable as a key to determine which handler routine, function, should
    be called in the DEV_MSG table. The 'value' variable will then be passed as
    a string parameter to that routine.

    Parameters
    message(string) - Message string containing the function and value to be sent to
                      DispatchMessage

    Returns
    Nothing
===============================================================================]]
function HandleMessage(message)
	LogTrace(string.format("HandleMessage. Message is ==>%s<==", message))

	--TODO: Implement a string using Lua captures and patterns which 
	--		will be used by string.match to parse the message
	--      into a name / value pair.
	--		The example shown here will return all alpha characters 
	--		up to the first non-alpha character and store them in the "name" variable
	--		the remaining characters will be returned and stored in the "value" variable.
	local pattern =  "(%a+)(.+)()"

	local name, value, pos = string.match(message, pattern)
	name = name or message
	value = value or ""	

	DispatchMessage(name, value)
	
end

--[[=============================================================================
    DispatchMessage(MsgKey, MsgData)

    Description
    Parse routine that will call the routines to handle the information returned
    by the connected system.

    Parameters
    MsgKey(string)  - The function to be called from within DispatchMessage
    MsgData(string) - The parameters to be passed to the function found in MsgKey

    Returns
    Nothing
===============================================================================]]
function DispatchMessage(MsgKey, MsgData)
	if (DEV_MSG[MsgKey] ~= nil and (type(DEV_MSG[MsgKey]) == "function")) then
		LogInfo("DEV_MSG." .. tostring(MsgKey) .. ":  " .. tostring(MsgData))
		local status, err = pcall(DEV_MSG[MsgKey], MsgData)
		if (not status) then
			LogError("LUA_ERROR: " .. err)
		end
	else
		LogTrace("HandleMessage: Unhanded command = " .. MsgKey)
	end
end

--[[
TODO: Create DEV_MSG functions for all messages to call Notifies.
	  Sample functions are included below for all applicable notifications.
--]]

function DEV_MSG.INPUT(value)
	LogTrace("DEV_MSG.INPUT(), value = " .. value)
	local input = tInputConnMapByName[tInputResponseMap[value]].ID 	--mod 1000 value of Input Connection ID
	
	-- TODO: derive and set  "output" from value or create separate DEV_MSG functions for each Output Connection
	local output = 0 	--mod 1000 value of Output Connection ID		
	
	LogInfo("INPUT_OUTPUT_CHANGED, input = " .. tInputResponseMap[value] .. ", output = " .. tOutputConnMap[output])
	gAVSwitchProxy:dev_InputOutputChanged(input, output)
end

function DEV_MSG.POWER(value)
	LogTrace("DEV_MSG.POWER(), value = " .. value)
	
	-- TODO: derive and set  "output" from value or create separate DEV_MSG functions for each Output Connection
	local output = 0 	--mod 1000 value of Output Connection ID
	
	-- TODO: 01 & 00 values will need to be edited based upon the device protocol values 
	--indicating if the device is on or off
	if (value == "01") then
		gAVSwitchProxy:dev_PowerOn(output)
	elseif (value== "00") then
		gAVSwitchProxy:dev_PowerOff(output)
	else
		LogWarn("DEV_MSG.POWER(): value not valid - " .. value)
	end		
end

function DEV_MSG.VOLUME(value)
	LogTrace("DEV_MSG.VOLUME(), value = " .. value)
	
	-- TODO: derive and set "output" and "deviceLevel" from "value"
	--			in the lua code example below string.match is assuming 
	--			that the device's output and volume level are separated by a colon
	--			you will need to adjust your parsing based upon the device protocol
	local deviceOutput, deviceLevel =  string.match(value, "^(%d+),(%d+)")
	
	local output =  deviceOutput --mod 1000 value of Output Connection ID
	--[[
	TODO: You may need to adjust deviceOutput. 
			Keep in mind that "output" needs to be the mod 1000 value of Output Connection ID
			The example below assumes that the device output ids start at 1 
			but your driver start connection id starts at 0
	--]]		
	--local output =  deviceOutput -1.	
			
			
	local c4Level = deviceLevel
	--[[
	TODO: If the device does not handle volume on a scale of 0 - 100 then the value will need to be converted
			since C4 volume level uses a percentage scale: 0 - 100
			The ConvertVolumeToC4() function is included in this template to handle this conversion.
			Edit "minDeviceLevel" & "maxDeviceLevel" values, based upon the protocol specification for volume range
	--]]
	--local minDeviceLevel = -80
	--local maxDeviceLevel = 20
	--local c4Level = ConvertVolumeToC4(deviceLevel, minDeviceLevel, maxDeviceLevel)

	gAVSwitchProxy:dev_VolumeLevelChanged(output, c4Level, deviceLevel)		
end

function DEV_MSG.MUTE(value)
	LogTrace("DEV_MSG.MUTE(), value = " .. value)
	
	-- TODO: derive and set  "output" from value or create separate DEV_MSG functions for each Output Connection
	local output    --mod 1000 value of Output Connection ID
	
	local state   	--Mute state represented as "True" or "False"
	-- TODO: values "01" & "00" will need to be modified based upon the device protocol specification
	if (value == "01") then 
		state = "True"
	elseif (value == "00") then
		state = "False"
	else
		LogWarn("DEV_MSG.MUTE(), value not valid, exiting...")
		return
	end
	gAVSwitchProxy:dev_MuteChanged(output, state)
end		

function DEV_MSG.BASS(value)
	LogTrace("DEV_MSG.BASS(), value = " .. value)
	
	-- TODO: derive and set  "output" from value or create separate DEV_MSG functions for each Output Connection
	local output  --mod 1000 value of Output Connection ID
	
	-- TODO: set "level", Bass level is represented as a percentage value
	local level  
	
	gAVSwitchProxy:dev_BassLevelChanged(output, level)
end	

function DEV_MSG.TREBLE(value)
	LogTrace("DEV_MSG.TREBLE(), value = " .. value)
	
	-- TODO: derive and set  "output" from value or create separate DEV_MSG functions for each Output Connection
	local output  --mod 1000 value of Output Connection ID
	
	-- TODO: set "level", Treble level is represented as a percentage value
	local level   
	
	gAVSwitchProxy:dev_TrebleLevelChanged(output, level)
end	

function DEV_MSG.BALANCE(value)
	LogTrace("DEV_MSG.BALANCE(), value = " .. value)
	
	-- TODO: derive and set  "output" from value or create separate DEV_MSG functions for each Output Connection
	local output  --mod 1000 value of Output Connection ID
	
	-- TODO: set "level", Bass level is represented as a percentage value
	local level  
	
	gAVSwitchProxy:dev_BalanceLevelChanged(output, level)
end	

function DEV_MSG.LOUDNESS(value)
	LogTrace("DEV_MSG.LOUDNESS(), value = " .. value)
	
	-- TODO: derive and set  "output" from value or create separate DEV_MSG functions for each Output Connection
	local output  --mod 1000 value of Output Connection ID
	
	-- TODO: set "state", Loudness state is represented as "True" or "False" (literal string, not boolean)
	local state  
	gAVSwitchProxy:dev_LoudnessChanged(output, state)
end
