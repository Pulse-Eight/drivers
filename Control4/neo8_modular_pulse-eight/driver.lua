--[[=============================================================================
    Basic Template for AVSwitch Driver

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]------------
require "common.c4_driver_declarations"
require "common.c4_common"
require "common.c4_init"
require "common.c4_property"
require "common.c4_command"
require "common.c4_notify"
require "common.c4_network_connection"
require "common.c4_serial_connection"
require "common.c4_ir_connection"
require "common.c4_utils"
require "lib.c4_timer"
require "actions"
require "device_specific_commands"
require "device_messages"
require "avswitch_init"
require "properties"
require "proxy_commands"
require "connections"
require "avswitch.avswitch_proxy_class"
require "avswitch.avswitch_proxy_commands"
require "avswitch.avswitch_proxy_notifies"


-- This macro is utilized to identify the version string of the driver template version used.
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.driver = "2015.03.31"
end

--[[=============================================================================
    Constants
===============================================================================]]
DRIVER_NAME = Properties["Driver Name"]
AVSWITCH_PROXY_BINDINGID = 5001


--[[=============================================================================
    Initialization Code
===============================================================================]]
function ON_DRIVER_EARLY_INIT.main()
	
end

function ON_DRIVER_INIT.main()
	SetLogName(DRIVER_NAME)

	-- TODO: If cloud based driver then uncomment the following line
	--ConnectURL()
end

function ON_DRIVER_LATEINIT.main()
	
end

function ON_DRIVER_EARLY_INIT.avswitch_driver()

end

function ON_DRIVER_INIT.avswitch_driver()
    -- TODO: Modify tVolumeRamping to have on entry per Output connection
    --index is mod 1000 value of output connection
    local tVolumeRamping = {
		[0] = {state = false,mode = "",},
		[1] = {state = false,mode = "",},
		[2] = {state = false,mode = "",},	
		[3] = {state = false,mode = "",},
	}
	
    -- Create an instance of the AVSwitchProxy class
    -- TODO: Change bProcessesDeviceMessages to false if Device Messages will not be processes
    local  bProcessesDeviceMessages = true
    gAVSwitchProxy = AVSwitchProxy:new(AVSWITCH_PROXY_BINDINGID, bProcessesDeviceMessages, tVolumeRamping)
	
end

function ON_DRIVER_LATEINIT.avswitch_driver()

end

--[[=============================================================================
    Driver Code
===============================================================================]]
function PackAndQueueCommand(...)
    local command_name = select(1, ...) or ""
    local command = select(2, ...) or ""
    local command_delay = select(3, ...) or tonumber(Properties["Command Delay Milliseconds"])
    local delay_units = select(4, ...) or "MILLISECONDS"
    LogTrace("PackAndQueueCommand(), command_name = " .. command_name .. ", command delay set to " .. command_delay .. " " .. delay_units)
    if (command == "") then
	   LogWarn("PackAndQueueCommand(), command_name = " .. command_name .. ", command string is empty - exiting PackAndQueueCommand()")
	   return
    end
	
	-- TODO: pack command with any any required starting or ending characters
    local cmd, stx, etx
    if (gControlMethod == "Network") then
		-- TODO: define any required starting or ending characters. 
		stx = ""
		etx = "\r"
		cmd = stx .. command .. etx
    elseif (gControlMethod == "Serial") then
		-- TODO: define any required starting or ending characters. 
		stx = ""
		etx = "\r"
		cmd = stx .. command .. etx
    elseif (gControlMethod == "IR") then
		cmd = command
    else
		LogWarn("PackAndQueueCommand(): gControlMethod is not valid, ".. gControlMethod)
		return
    end
    gCon:QueueCommand(cmd, command_delay, delay_units, command_name)	
	
end
