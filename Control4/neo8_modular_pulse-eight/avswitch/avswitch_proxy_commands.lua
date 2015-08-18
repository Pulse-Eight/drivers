--[[=============================================================================
    ReceivedFromProxy Code for the AVSwitch Proxy

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]

-- This macro is utilized to identify the version string of the driver template version used.
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.properties = "2015.03.31"
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Power Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function PRX_CMD.ON(idBinding, tParams)
	--Handled by CONNECT_OUTPUT
	--gAVSwitchProxy:prx_ON(tParams)
end

function PRX_CMD.OFF(idBinding, tParams)
	--Handled by DISCONNECT_OUTPUT
	--gAVSwitchProxy:prx_OFF(tParams)
end

function PRX_CMD.CONNECT_OUTPUT(idBinding, tParams)
	gAVSwitchProxy:prx_CONNECT_OUTPUT(tParams)
end

function PRX_CMD.DISCONNECT_OUTPUT(idBinding, tParams)
	gAVSwitchProxy:prx_DISCONNECT_OUTPUT(tParams)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Input Selection Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function PRX_CMD.SET_INPUT(idBinding, tParams)
	gAVSwitchProxy:prx_SET_INPUT(idBinding, tParams)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Volume Control Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function PRX_CMD.MUTE_OFF(idBinding, tParams)
	gAVSwitchProxy:prx_MUTE_OFF(tParams)
end

function PRX_CMD.MUTE_ON(idBinding, tParams)
	gAVSwitchProxy:prx_MUTE_ON(tParams)	
end

function PRX_CMD.MUTE_TOGGLE(idBinding, tParams)
	gAVSwitchProxy:prx_MUTE_TOGGLE(tParams)
end

function PRX_CMD.SET_VOLUME_LEVEL(idBinding, tParams)
	gAVSwitchProxy:prx_SET_VOLUME_LEVEL(tParams)
end

function PRX_CMD.PULSE_VOL_DOWN(idBinding, tParams)
	gAVSwitchProxy:prx_PULSE_VOL_DOWN(tParams)
end

function PRX_CMD.PULSE_VOL_UP(idBinding, tParams)
	gAVSwitchProxy:prx_PULSE_VOL_UP(tParams)
end

function PRX_CMD.START_VOL_DOWN(idBinding, tParams)
	gAVSwitchProxy:prx_START_VOL_DOWN(tParams)
end

function PRX_CMD.START_VOL_UP(idBinding, tParams)
	gAVSwitchProxy:prx_START_VOL_UP(tParams)
end

function PRX_CMD.STOP_VOL_DOWN(idBinding, tParams)
	gAVSwitchProxy:prx_STOP_VOL_DOWN(tParams)
end

function PRX_CMD.STOP_VOL_UP(idBinding, tParams)
	gAVSwitchProxy:prx_STOP_VOL_UP(tParams)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Menu Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function PRX_CMD.INFO(idBinding, tParams)
	gAVSwitchProxy:prx_INFO(idBinding, tParams)
end

function PRX_CMD.GUIDE(idBinding, tParams)
	gAVSwitchProxy:prx_GUIDE(idBinding, tParams)
end

function PRX_CMD.MENU(idBinding, tParams)
	gAVSwitchProxy:prx_MENU(idBinding, tParams)
end

function PRX_CMD.CANCEL(idBinding, tParams)
	gAVSwitchProxy:prx_CANCEL(idBinding, tParams)
end

function PRX_CMD.UP(idBinding, tParams)
	gAVSwitchProxy:prx_UP(idBinding, tParams)
end

function PRX_CMD.DOWN(idBinding, tParams)
	gAVSwitchProxy:prx_DOWN(idBinding, tParams)
end

function PRX_CMD.LEFT(idBinding, tParams)
	gAVSwitchProxy:prx_LEFT(idBinding, tParams)
end

function PRX_CMD.RIGHT(idBinding, tParams)
	gAVSwitchProxy:prx_RIGHT(idBinding, tParams)
end

function PRX_CMD.ENTER(idBinding, tParams)
	gAVSwitchProxy:prx_ENTER(idBinding, tParams)
end

function PRX_CMD.RECALL(idBinding, tParams)
	gAVSwitchProxy:prx_RECALL(idBinding, tParams)
end

function PRX_CMD.OPEN_CLOSE(idBinding, tParams)
	gAVSwitchProxy:prx_OPEN_CLOSE(idBinding, tParams)
end

function PRX_CMD.PROGRAM_A(idBinding, tParams)
	gAVSwitchProxy:prx_PROGRAM_A(idBinding, tParams)
end

function PRX_CMD.PROGRAM_B(idBinding, tParams)
	gAVSwitchProxy:prx_PROGRAM_B(idBinding, tParams)
end

function PRX_CMD.PROGRAM_C(idBinding, tParams)
	gAVSwitchProxy:prx_PROGRAM_C(idBinding, tParams)
end

function PRX_CMD.PROGRAM_D(idBinding, tParams)
	gAVSwitchProxy:prx_PROGRAM_D(idBinding, tParams)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Digit Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function PRX_CMD.NUMBER_0(idBinding, tParams)
	gAVSwitchProxy:prx_NUMBER_0(idBinding, tParams)
end

function PRX_CMD.NUMBER_1(idBinding, tParams)
	gAVSwitchProxy:prx_NUMBER_1(idBinding, tParams)
end

function PRX_CMD.NUMBER_2(idBinding, tParams)
	gAVSwitchProxy:prx_NUMBER_2(idBinding, tParams)
end

function PRX_CMD.NUMBER_3(idBinding, tParams)
	gAVSwitchProxy:prx_NUMBER_3(idBinding, tParams)
end

function PRX_CMD.NUMBER_4(idBinding, tParams)
	gAVSwitchProxy:prx_NUMBER_4(idBinding, tParams)
end

function PRX_CMD.NUMBER_5(idBinding, tParams)
	gAVSwitchProxy:prx_NUMBER_5(idBinding, tParams)
end

function PRX_CMD.NUMBER_6(idBinding, tParams)
	gAVSwitchProxy:prx_NUMBER_6(idBinding, tParams)
end

function PRX_CMD.NUMBER_7(idBinding, tParams)
	gAVSwitchProxy:prx_NUMBER_7(idBinding, tParams)
end

function PRX_CMD.NUMBER_8(idBinding, tParams)
	gAVSwitchProxy:prx_NUMBER_8(idBinding, tParams)
end

function PRX_CMD.NUMBER_9(idBinding, tParams)
	gAVSwitchProxy:prx_NUMBER_9(idBinding, tParams)
end

function PRX_CMD.STAR(idBinding, tParams)
	gAVSwitchProxy:prx_STAR(idBinding, tParams)
end

function PRX_CMD.POUND(idBinding, tParams)
	gAVSwitchProxy:prx_POUND(idBinding, tParams)
end

function PRX_CMD.GET_VIDEO_PATH(idBinding, tParams)
    
end