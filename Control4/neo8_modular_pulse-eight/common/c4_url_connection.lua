--[[=============================================================================
    Base for a url connection driver

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]
require "common.c4_device_connection_base"

-- Set template version for this file
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.c4_url_connection = "2015.03.02"
end

UrlConnectionBase = inheritsFrom(DeviceConnectionBase)

function UrlConnectionBase:construct(Url)
	self.superClass():construct()
	self._Url = Url
end

function UrlConnectionBase:Initialize(ExpectAck, DelayInterval, WaitInterval)
	gControlMethod = "URL"
	self:superClass():Initialize(ExpectAck, DelayInterval, WaitInterval, self)
	OnURLConnectionChanged()
end

function UrlConnectionBase:ControlMethod()
	return "URL"
end

function UrlConnectionBase:SetUrl(Url)
	self._Url = Url
end

function UrlConnectionBase:SendCommand(sCommand, sHeader, ignoreConnect)
	ignoreConnect = ignoreConnect or false

	if(self._IsConnected or ignoreConnect) then
		if (sHeader ~= nil) then
			C4:urlPost(self._Url, sCommand, sHeader)
		else
			C4:urlPost(self._Url, sCommand)
		end
	else
		LogWarn("Not connected. Command not sent.")
	end
end

function UrlConnectionBase:ReceivedAsync(ticketId, sData, responseCode, tHeaders)
	self:ReceivedFromCom(sData)
end

function ConnectURL()
	gIsUrlConnected = true
	SetControlMethod()
end

function DisconnectURL()
	gIsUrlConnected = false
	SetControlMethod()
end
