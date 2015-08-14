--[[=============================================================================
    Received Proxy Notification Code

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]

-- This macro is utilized to identify the version string of the driver template version used.
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.properties = "2015.03.31"
end

--[[
	Notify: INPUT_OUTPUT_CHANGED
	Sent to the proxy to indicate the currently selected Input has changed on the specified Output
	Parameters
		bindingID - proxy id of proxy bound to input connection
		input - mod 1000 value of Input Connection ID
		output - mod 1000 value of Output Connection ID
--]]
function NOTIFY.INPUT_OUTPUT_CHANGED(bindingID, input, output)
	--NOTE: Need to handle cases where 7000 range output values are sent (when Room Binding is next in the path)
	--so out "output" is a mod 1000 integer. Also, need to handle audio and video legs of the input...
    local tParams = {INPUT = input + 3000, OUTPUT = 4000 + output}
    SendNotify("INPUT_OUTPUT_CHANGED", tParams, bindingID)
    tParams = {INPUT = input + 1000, OUTPUT = 2000 + output}
    SendNotify("INPUT_OUTPUT_CHANGED", tParams, bindingID)	
end
------------------------------ Power Notification Functions ------------------------------
function NOTIFY.ON()
	SendSimpleNotify("ON")
end

function NOTIFY.OFF()
	SendSimpleNotify("OFF")
end
------------------------------ Volume Notification Code ------------------------------
--[[
	Notify: VOLUME_LEVEL_CHANGED
	Sent to the AVSwitch proxy to indicate that the Volume level has changed on the specified Output
	Parameters
		bindingID - proxy id of AVSwitch proxy
		output - mod 1000 value of Output Connection ID
		level - C4 level uses a percentage scale: 0 - 100
--]]
function NOTIFY.VOLUME_LEVEL_CHANGED(bindingID, output, level)
    local tParams = {LEVEL = level, OUTPUT = output + 4000}
    SendNotify("VOLUME_LEVEL_CHANGED", tParams, bindingID)	
end

--[[
	Notify: BASS_LEVEL_CHANGED
	Sent to the AVSwitch proxy to indicate that the Bass level has changed on the specified Output
	Parameters
		bindingID - proxy id of AVSwitch proxy
		output - mod 1000 value of Output Connection ID
		level - C4 volume level uses a percentage scale: 0 - 100
--]]
function NOTIFY.BASS_LEVEL_CHANGED(bindingID, output, level)
    local tParams = {LEVEL = level, OUTPUT = output + 4000}
    SendNotify("BASS_LEVEL_CHANGED", tParams, bindingID)		
end

--[[
	Notify: TREBLE_LEVEL_CHANGED
	Sent to the AVSwitch proxy to indicate that the Treble level has changed on the specified Output
	Parameters
		bindingID - proxy id of AVSwitch proxy
		output - mod 1000 value of Output Connection ID
		level - C4 volume level uses a percentage scale: 0 - 100
--]]
function NOTIFY.TREBLE_LEVEL_CHANGED(bindingID, output, level)
    local tParams = {LEVEL = level, OUTPUT = output + 4000}
    SendNotify("TREBLE_LEVEL_CHANGED", tParams, bindingID)	
end

--[[
	Notify: BALANCE_LEVEL_CHANGED
	Sent to the AVSwitch proxy to indicate that the Balance level has changed on the specified Output
	Parameters
		bindingID - proxy id of AVSwitch proxy
		output - mod 1000 value of Output Connection ID
		level - C4 volume level uses a percentage scale: 0 - 100
--]]
function NOTIFY.BALANCE_LEVEL_CHANGED(bindingID, output, level)
    local tParams = {LEVEL = level, OUTPUT = output + 4000}
    SendNotify("BALANCE_LEVEL_CHANGED", tParams, bindingID)		
end

--[[
	Notify: LOUNDENSS_CHANGED
	Sent to the AVSwitch proxy to indicate that the Loudness state has changed on the specified Output
	Parameters
		bindingID - proxy id of AVSwitch proxy
		output - mod 1000 value of Output Connection ID
		state - represented as "True" or "False" (literal string, not boolean)
--]]
function NOTIFY.LOUDNESS_CHANGED(bindingID, output, state)
    local tParams = {LOUDNESS = state, OUTPUT = output + 4000}
    SendNotify("LOUDNESS_CHANGED", tParams, bindingID)		
end

--[[
	Notify: MUTE_LEVEL_CHANGED
	Sent to the AVSwitch proxy to indicate that the Mute state has changed on the specified Output
	Parameters
		bindingID - proxy id of AVSwitch proxy
		output - mod 1000 value of Output Connection ID
		state - represented as "True" or "False" (literal string, not boolean)
--]]
function NOTIFY.MUTE_CHANGED(bindingID, output, state)
    local tParams = {MUTE = state, OUTPUT = output + 4000}
    SendNotify("MUTE_CHANGED", tParams, bindingID)		
end
	