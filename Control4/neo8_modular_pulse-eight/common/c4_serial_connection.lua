--[[=============================================================================
    Base for a serial connection driver

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]
require "common.c4_driver_declarations"
require "common.c4_device_connection_base"
require "lib.c4_log"
require "common.c4_common"

-- Set template version for this file
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.c4_serial_connection = "2015.03.02"
end

SerialConnectionBase = inheritsFrom(DeviceConnectionBase)

function SerialConnectionBase:construct(BindingID)
	self.superClass():construct()
	self._BindingID = BindingID
end

function SerialConnectionBase:Initialize(ExpectAck, DelayInterval, WaitInterval)
	gControlMethod = "Serial"
	self:superClass():Initialize(ExpectAck, DelayInterval, WaitInterval, self)
end

function SerialConnectionBase:ControlMethod()
	return "Serial"
end

function SerialConnectionBase:SendCommand(sCommand, ...)
	if(self._IsConnected) then
		local command_delay = select(1, ...)
		local delay_units = select(2, ...)
		local command_name = select(3, ...)

		C4:SendToSerial(self._BindingID, sCommand)
		self:StartCommandTimer(command_delay, delay_units, command_name)
	else
		LogWarn("Not connected to serial. Command not sent.")
	end
end

function SerialConnectionBase:ReceivedFromSerial(idBinding, sData)
	self:ReceivedFromCom(sData)
end
