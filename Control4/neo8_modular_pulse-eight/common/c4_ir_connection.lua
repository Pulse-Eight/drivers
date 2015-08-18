--[[=============================================================================
    Base for an IR connection driver

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]
require "common.c4_driver_declarations"
require "common.c4_device_connection_base"
require "lib.c4_log"
require "common.c4_common"

-- Set template version for this file
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.c4_ir_connection = "2015.03.02"
end

IRConnectionBase = inheritsFrom(DeviceConnectionBase)

function IRConnectionBase:construct(BindingID)
	self.superClass():construct()
	self._BindingID = BindingID
end

function IRConnectionBase:Initialize(ExpectAck, DelayInterval, WaitInterval)
	print("tSerConBase:Initialize")
	gControlMethod = "IR"
	self:superClass():Initialize(ExpectAck, DelayInterval, WaitInterval, self)
end

function IRConnectionBase:ControlMethod()
	return "IR"
end

function IRConnectionBase:SendCommand(sCommand, ...)
	if(self._IsConnected) then
		local command_delay = select(1, ...)
		local delay_units = select(2, ...)
		local command_name = select(3, ...)

		C4:SendIR(self._BindingID, sCommand)
		self:StartCommandTimer(command_delay, delay_units, command_name)
	else
		LogWarn("IR connection is not bound. Command not sent.")
	end
end
