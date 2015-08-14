--[[=============================================================================
    AVSwitch Protocol Initialization Functions

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]

-- This macro is utilized to identify the version string of the driver template version used.
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.device_messages = "2015.03.31"
end


PROTOCOL_DECLARATIONS = {}

function ON_DRIVER_EARLY_INIT.avswitch_init()

end

function ON_DRIVER_INIT.avswitch_init()
	--LogTrace("ON_DRIVER_INIT.ProtocolDeclarations()")
	for k,v in pairs(PROTOCOL_DECLARATIONS) do
		if (PROTOCOL_DECLARATIONS[k] ~= nil and type(PROTOCOL_DECLARATIONS[k]) == "function") then
			PROTOCOL_DECLARATIONS[k]()
		end
	end	
end

function ON_DRIVER_LATEINIT.avswitch_init()
end
	
function PROTOCOL_DECLARATIONS.CommandsTableInit_IR()
	LogTrace("PROTOCOL_DECLARATIONS.CommandsTableInit_IR()")

	CMDS_IR = {
		--index:  Proxy Command Name
		--value:  IR Code ID	 
		["ON"]             = "",
		["OFF"]            = "",
		["MUTE_ON"]        = "",
		["MUTE_OFF"]       = "",
		["MUTE_TOGGLE"]    = "",
		["INPUT_TOGGLE"]   = "",
		["NUMBER_0"]       = "", 	
		["NUMBER_1"]       = "",		
		["NUMBER_2"]       = "",	
		["NUMBER_3"]       = "",	
		["NUMBER_4"]       = "",	
		["NUMBER_5"]       = "",	
		["NUMBER_6"]       = "",	
		["NUMBER_7"]       = "",	
		["NUMBER_8"]       = "",	
		["NUMBER_9"]       = "",
		["STAR"]           = "",
		["DOT"]            = "",
		["INFO"]           = "", --Display
		["RECALL"]         = "",
		["PULSE_VOL_DOWN"] = "",
		["PULSE_VOL_UP"]   = "",
		["MENU"]           = "",
		["ENTER"]          = "",
		["UP"]             = "",
		["DOWN"]           = "",
		["LEFT"]           = "",
		["RIGHT"]          = "",
		["PREV"]           = "",
		["CANCEL"]         = "",
	}		
	
	--IR ZONE Commands
	CMDS_IR_ZONES = {}
	
	CMDS_IR_ZONES[0] = {
		--index:  Proxy Command Name
		--value:  IR Code ID
		["CONNECT_OUTPUT"] = "",
		["DISCONNECT_OUTPUT"] = "",	
		["VOLUME_UP"] = "",
		["VOLUME_DOWN"] = "",
		["MUTE_ON"] = "",
		["MUTE_OFF"] = "",
		["MUTE_TOGGLE"] = "",
	}	
	
	CMDS_IR_ZONES[1] = {
		["CONNECT_OUTPUT"] = "",
		["DISCONNECT_OUTPUT"] = "",
		["VOLUME_UP"] = "",
		["VOLUME_DOWN"] = "",
		["MUTE_ON"] = "",
		["MUTE_OFF"] = "",
		["MUTE_TOGGLE"] = "",
	}		
	
	CMDS_IR_ZONES[2] = {
		["CONNECT_OUTPUT"] = "",
		["DISCONNECT_OUTPUT"] = "",	
		["VOLUME_UP"] = "",
		["VOLUME_DOWN"] = "",
		["MUTE_ON"] = "",
		["MUTE_OFF"] = "",
		["MUTE_TOGGLE"] = "",		
	}	
	
	CMDS_IR_ZONES[3] = {
		["CONNECT_OUTPUT"] = "",
		["DISCONNECT_OUTPUT"] = "",	
		["VOLUME_UP"] = "",
		["VOLUME_DOWN"] = "",
		["MUTE_ON"] = "",
		["MUTE_OFF"] = "",
		["MUTE_TOGGLE"] = "",		
	}
	
	CMDS_IR[AVSWITCH_PROXY_BINDINGID] = {}	
	
end

function PROTOCOL_DECLARATIONS.CommandsTableInit_Serial()
	LogTrace("PROTOCOL_DECLARATIONS.CommandsTableInit_Serial()")

	CMDS = {
		--index:  Proxy Command Name
		--value:  Protocol Command Data
		
		--Power
		["ON"]             = "",
		["OFF"]            = "",
				
		--Menu
		["INFO"] = "",	--Display
		["GUIDE"] = "",
		["MENU"] = "",
		["CANCEL"] = "",
		["UP"] = "",
		["DOWN"] = "",
		["LEFT"] = "",
		["RIGHT"] = "",
		["ENTER"] = "",	
		["RECALL"]         = "",
		["PREV"]           = "",
		
		--Digits
		["NUMBER_0"]       = "", 	
		["NUMBER_1"]       = "",		
		["NUMBER_2"]       = "",	
		["NUMBER_3"]       = "",	
		["NUMBER_4"]       = "",	
		["NUMBER_5"]       = "",	
		["NUMBER_6"]       = "",	
		["NUMBER_7"]       = "",	
		["NUMBER_8"]       = "",	
		["NUMBER_9"]       = "",
		["STAR"]           = "",
		["DOT"]            = "",
	}
	
	CMDS[AVSWITCH_PROXY_BINDINGID] = {}
	
end

function PROTOCOL_DECLARATIONS.InputOutputTableInit()
	LogTrace("PROTOCOL_DECLARATIONS.InputOutputTableInit()")
	----------------------------------------- [*COMMAND/RESPONSE HELPER TABLES*] -----------------------------------------
	
	tOutputCommandMap = {
		--index:  mod 1000 value of Output Connection id
		--value:  Protocol Command Data
		[0] = "",
		[1] = "",
		[2] = "",
		[3] = "",
	}
	
	tInputCommandMap = {
		--index:  Connection Name
		--value:  Protocol Command Data	
		--["ADAPTER PORT"] = "33", 
		[""] = "",
	}
	
	tInputResponseMap = ReverseTable(tInputCommandMap)	-- Reverses the tInputCommandMap table
			
	
	tInputCommandMap_IR = { 
	}
	--Main Zone Input Selection Commands	
	tInputCommandMap_IR[0] = { 
		--index:  Connection Name
		--value:  IR Code ID
		--["ADAPTER PORT"] = "51362",
		[""] = "",
	}
	--Zone2 Input Selection Commands
	tInputCommandMap_IR[1] = { 	
		[""] = "",
	}
	--Zone3 Input Selection Commands
	tInputCommandMap_IR[2] = { 
		[""] = "",
	}
	--Zone4 Input Selection Commands	
	tInputCommandMap_IR[3] = { 
		[""] = "",
	}	
		
	----------------------------------------- [*I/O HELPER TABLES*] -----------------------------------------
	tOutputConnMap = {
		--index:  mod 1000 value of Output Connection id
		--value:  Output Connection Name
		[0] = "Main Output",
		[1] = "Zone2 Output",
		[2] = "Zone3 Output",
		[3] = "Zone4 Output",
	}

	tInputConnMapByID = {
		--index:  mod 1000 value of Input Connection id
		--[0] = {Name = "INPUT HDMI 1",BindingID = AVSWITCH_PROXY_BINDINGID,},
		[0] = {Name = "",BindingID = AVSWITCH_PROXY_BINDINGID,},
	}
	
	tInputConnMapByName = {
		--index:  Input Connection Name
		--ID: mod 1000 value of Input Connection id
		--["INPUT HDMI 1"] = {ID = 0,BindingID = AVSWITCH_PROXY_BINDINGID,},
		[""] = {ID = 0,BindingID = AVSWITCH_PROXY_BINDINGID,},
	}

end	

function PROTOCOL_DECLARATIONS.PowerCommandsTableInit_Serial()
	LogTrace("PROTOCOL_DECLARATIONS.PowerCommandsTableInit_Serial()")
	
	tPowerCommandMap = {
		--index:  mod 1000 value of Output Connection id
		--value:  Protocol Command Data (Power)
		[0] = "",
		[1] = "",
		[2] = "",
		[3] = "",
	}
end

function PROTOCOL_DECLARATIONS.VolumeCommandsTableInit_Serial()
	LogTrace("PROTOCOL_DECLARATIONS.VolumeCommandsTableInit_Serial()")
	
	tVolumeCommandMap = {
		--index:  mod 1000 value of Output Connection id
		--value:  Protocol Command Data (Pulse Volume - command prefix/suffix)
		[0] = "",
		[1] = "",
		[2] = "",
		[3] = "",	
	}

	tVolumeSetCommandMap = {
		--index:  mod 1000 value of Output Connection id
		--value:  Protocol Command Data (Discreet Volume - command prefix/suffix)	
		[0] = "",
		[1] = "",
		[2] = "",
		[3] = "", 
	}
	
	tVolumeQueryMap = {
		--index:  mod 1000 value of Output Connection id
		--value:  Protocol Command Data (Volume Query)		
		[0] = "",
		[1] = "",
		[2] = "",
		[3] = "", 	
	}	

	tMuteCommandMap = {
		--index:  mod 1000 value of Output Connection id
		--value:  Protocol Command Data (Mute - command prefix/suffix)		
		[0] = "",
		[1] = "",
		[2] = "",
		[3] = "",
	}	

	
	--[[
	TODO: Update tVolumeCurve table based upon devices volume range and optimal ramping steps
		tVolumeCurve is used to plot values that will be used
		to build volume commands during volume ramping.
		Specifically, they are used in GetNextVolumeCurveValue() which is 
		called from the ContinueVolumeRamping() function. 
		The values entered here should correlate to the volume parameters as defined in the device protocol.
		Below is an example, the table for your device may use different values.
		Also the number and size of steps may differ for your device. Adjust values to get 
		a smooth volume ramping from low to high volume.
		NOTE: values must be in decimal (i.e. not hexadecimal...)
	--]]
	tVolumeCurve = {
		-- 5 unit STEPS [0 to 20]
		0,5,10,15,20,
		-- 4 unit STEPS [24 to 58]
		24,28,32,36,38,
		42,46,49,52,55,58,
		-- 2 unit STEPS [60 to 90]
		60,62,64,66,68,
		70,72,74,76,78,
		80,82,84,86,88,90,           
		-- 1 unit STEPS [90 to 100] 
		91,92,93,94,95,
		96,97,98,99,100,                             
	}
	
end

function ReverseTable(a)
	local b = {}
	for k,v in pairs(a) do b[v] = k end
	return b
end

