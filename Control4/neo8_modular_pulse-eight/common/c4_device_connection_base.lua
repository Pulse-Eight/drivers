--[[=============================================================================
    DeviceConnectionBase Class

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]
require "common.c4_common"
require "lib.c4_object"
require "lib.c4_log"
require "lib.c4_timer"
require "lib.c4_queue"

-- Set template version for this file
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.c4_device_connection_base = "2015.03.02"
end

COMMAND_QUEUE_SIZE = 100
DEFAULT_COMMAND_DELAY_INTERVAL = 100            -- Don't send consecutive commands faster than this many milliseconds
DEFAULT_COMMAND_RESPONSE_INTERVAL = 3           -- If we haven't received and ACK after this many seconds, try again
DEFAULT_RETRY_COUNT_MAX = 3

function ON_DRIVER_EARLY_INIT.c4_device_connection_base()
	gReceiveBuffer = ""
	gIsUrlConnected = false
end

DeviceConnectionBase = inheritsFrom(nil)

function DeviceConnectionBase:construct()

	self._IsConnected = false
	self._SendTimer = nil
	self._WaitResponseTimer = nil
	self._CommandQueue = nil
	self._Priority1CommandQueue = nil
	self._Priority2CommandQueue = nil
	self._LastCommand = nil
	self._ExpectAck = false
	self._CommandRetryCount = 0
	self._RetryCountMax = DEFAULT_RETRY_COUNT_MAX

	self._SendCommandDelayMS = DEFAULT_COMMAND_DELAY_INTERVAL
	self._CommandResponseWaitS = DEFAULT_COMMAND_RESPONSE_INTERVAL
	
	-- Polling
	self._PollingInterval = 0
	self._PollingUnits = "SECONDS"
	self._PollingTimer = nil
end

function DeviceConnectionBase:Initialize(ExpectAck, CommandDelayInterval, CommandResponseInterval, CallbackParam)

	if (ExpectAck ~= nil) then
		self._ExpectAck = ExpectAck
	end

	if (CommandDelayInterval ~= nil) then
		self._SendCommandDelayMS = CommandDelayInterval
	end

	if (CommandResponseInterval ~= nil) then
		self._CommandResponseWaitS = CommandResponseInterval
	end

	self._CommandQueue = c4_queue:new()
	self._CommandQueue:SetMaxSize(COMMAND_QUEUE_SIZE)
	self._CommandQueue:SetName("Command Queue")

	self._Priority1CommandQueue = c4_queue:new()
	self._Priority1CommandQueue:SetMaxSize(COMMAND_QUEUE_SIZE)
	self._Priority1CommandQueue:SetName("P1 Queue")

	self._Priority2CommandQueue = c4_queue:new()
	self._Priority2CommandQueue:SetMaxSize(COMMAND_QUEUE_SIZE)
	self._Priority2CommandQueue:SetName("P2 Queue")

	-- usually only one of these timers will be used, but it's pretty low overhead to instantiate both of them
	self._SendTimer = c4_timer:new("SendCommand", self._SendCommandDelayMS, "MILLISECONDS", DeviceConnectionBase.OnSendTimeExpired, false, CallbackParam)
	self._WaitResponseTimer = c4_timer:new("WaitResponse", self._CommandResponseWaitS, "SECONDS", DeviceConnectionBase.OnWaitTimeExpired, false, CallbackParam)
end

function DeviceConnectionBase:InitPolling(PollingInterval, PollingUnits, CallbackParam)
	LogFatal("DeviceConnectionBase:InitPolling()")
	if (PollingInterval ~= nil) then
		self._PollingInterval = PollingInterval
	end
	
	self._PollingUnits = PollingUnits or self._PollingUnits

	LogFatal("self._PollingInterval: %s, self._PollingUnits: %s", tostring(self._PollingInterval), tostring(self._PollingUnits))
	
	-- create polling timer
	self._PollingTimer = c4_timer:new("Polling", self._PollingInterval, self._PollingUnits, DeviceConnectionBase.OnPollingTimerExpired, false, CallbackParam)
end

function DeviceConnectionBase:StartPolling(interval, units)
	LogFatal("DeviceConnectionBase:StartPolling()")
	LogFatal("self._PollingTimer: %s", tostring(self._PollingTimer))
	
	if (self._PollingTimer ~= nil) then
		self._PollingTimer:KillTimer()
		
		local timer_units = units or self._PollingTimer._units
		local timer_interval = interval or self._PollingInterval

		self._PollingTimer:StartTimer(timer_interval, timer_units)
	end
end

function DeviceConnectionBase:StopPolling()
	LogFatal("DeviceConnectionBase:StopPolling()")
	self._PollingTimer:KillTimer()
end

function DeviceConnectionBase:SetExpectACK(ExpectACK)
	self._ExpectAck = ExpectACK
end

function DeviceConnectionBase:SetCommandDelayInterval(DelayInterval)
	self._SendCommandDelayMS = DelayInterval
end

function DeviceConnectionBase:SetResponseWaitInterval(WaitInterval)
	self._CommandResponseWaitS = WaitInterval
end

function DeviceConnectionBase:ReceivedFromCom(sData)

	gReceiveBuffer = gReceiveBuffer .. sData
	LogTrace("ReceivedFromCom  ReceiveBuffer is now {{{%s}}}", gReceiveBuffer)

	message = self:GetMessage()
	while (message ~= nil and message ~= "") do
		status, err = pcall(HandleMessage, message)
		if (status) then
			message = self:GetMessage()
		else
			LogError("LUA_ERROR: " .. err)
			message = ""
			gReceiveBuffer = ""
		end
	end
end

function DeviceConnectionBase:SetConnection(IsConnected, method)
	self._IsConnected = IsConnected
	gControlMethod = method
end

function DeviceConnectionBase:ControlMethod()
	-- Override in derived class
	print("WARNING: Need to override ControlMethod - should never be called")
	
	return ""
end

function DeviceConnectionBase:StartCommandTimer(...)
	local value = select(1, ...)
	local units = select(2, ...)
	local command_name = select(3, ...) or ""

	self._WaitResponseTimer:KillTimer()
	self._SendTimer:KillTimer()

	if (self._ExpectAck) then
		-- expecting an ACK set the Response Wait timer
		local timer_units = units or self._WaitResponseTimer._units
		local timer_interval = value or self._CommandResponseWaitS

		self._WaitResponseTimer:StartTimer(timer_interval, timer_units)
		LogTrace(string.format("Starting wait Timer:  %d", self._WaitResponseTimer._timerID) .. " for " .. command_name)
	else
		-- no ACK expected, just wait the designated amount of time and send another command
		local timer_units = units or self._SendTimer._units
		local timer_interval = value or self._SendCommandDelayMS

		self._SendTimer:StartTimer(timer_interval, timer_units)
		LogTrace(string.format("Starting Send Timer:  %d for %s (timer_interval = %d, timer_units = %s)", self._SendTimer._timerID, command_name, timer_interval, timer_units))
	end
end

-- Note the '.' instead of the ':'
function DeviceConnectionBase.OnSendTimeExpired(Instance)
	LogTrace("Send Timer expired")
	Instance._SendTimer:KillTimer()

	local tCommand = Instance._LastCommand
	if (tCommand.command_name ~= nil) then
		LogTrace("Send Timer expired - Last Command: %s, Send Next Command", tostring(tCommand.command_name))
	elseif (type(tCommand) == "string") then
		LogTrace("Send Timer expired - Last Command: %s, Send Next Command", tostring(tCommand))
	end
	
	Instance._LastCommand = nil
	Instance:SendNextCommand()

	if (DoEvents ~= nil and type(DoEvents) == "function") then
		DoEvents()
	end
end

function DeviceConnectionBase.OnWaitTimeExpired(Instance)
	LogTrace("Wait Timer expired")
	Instance._WaitResponseTimer:KillTimer()
	Instance._CommandRetryCount = Instance._CommandRetryCount + 1

	if (Instance._CommandRetryCount >= Instance._RetryCountMax) then
		-- To many retries, pop the current command and try the next one
		Instance._CommandRetryCount = 0
		Instance:SendNextCommand()
	else
		Instance:SendLastCommand()
	end
end

function DeviceConnectionBase.OnPollingTimerExpired(Instance)
	LogTrace("Polling Timer expired")
	Instance._PollingTimer:KillTimer()

	OnPollingTimerExpired()
	
	Instance._PollingTimer:StartTimer(Instance._PollingInterval)
end

function DeviceConnectionBase:HandleACK()
	self._LastCommand = nil
	
	self._WaitResponseTimer:KillTimer()
	self._CommandRetryCount = 0
	self:SendNextCommand()
end

function DeviceConnectionBase:QueueEmpty()
	return (self._CommandQueue:empty() and self._Priority1CommandQueue:empty() and self._Priority2CommandQueue:empty())
end

function DeviceConnectionBase:QueueCommand(sCommand, ...)
--	LogTrace("QueueCommand(%s)", sCommand)
	local command_delay = select(1, ...)
	local delay_units = select(2, ...)
	local command_name = select(3, ...)

	if (sCommand == nil) or (sCommand == "") then
		return
	end

	if (self._LastCommand == nil) then
		self._CommandQueue:push(sCommand, command_delay, delay_units, command_name)
		self._LastCommand = self._CommandQueue:pop()
		self:SendCommand(sCommand, command_delay, delay_units, command_name)
	else
		self._CommandQueue:push(sCommand, command_delay, delay_units, command_name)
	end
end

function DeviceConnectionBase:QueuePriority1Command(sCommand, ...)
	LogTrace("QueuePriority1Command(%s)", sCommand)
	local command_delay = select(1, ...)
	local delay_units = select(2, ...)
	local command_name = select(3, ...)

	if (sCommand == nil) or (sCommand == "") then
		return
	end

	if (self._LastCommand == nil) then
		self._Priority1CommandQueue:push(sCommand, command_delay, delay_units, command_name)
		self._LastCommand = self._Priority1CommandQueue:pop()
		self:SendCommand(sCommand, command_delay, delay_units, command_name)
	else
		self._Priority1CommandQueue:push(sCommand, command_delay, delay_units, command_name)
	end
end

function DeviceConnectionBase:QueuePriority2Command(sCommand, ...)
	LogTrace("QueuePriority2Command(%s)", sCommand)
	local command_delay = select(1, ...)
	local delay_units = select(2, ...)
	local command_name = select(3, ...)

	if (sCommand == nil) or (sCommand == "") then
		return
	end

	if (self._LastCommand == nil) then
		self._Priority2CommandQueue:push(sCommand, command_delay, delay_units, command_name)
		self._LastCommand = self._Priority2CommandQueue:pop()
		self:SendCommand(sCommand, command_delay, delay_units, command_name)
	else
		self._Priority2CommandQueue:push(sCommand, command_delay, delay_units, command_name)
	end
end

function DeviceConnectionBase:SendNextCommand()
	LogTrace("DeviceConnectionBase:SendNextCommand")

	local tCommand = nil
	if (not self._Priority1CommandQueue:empty()) then
		tCommand = self._Priority1CommandQueue:pop()
		LogTrace(tostring(gCon._Priority1CommandQueue))
	elseif (not self._Priority2CommandQueue:empty()) then
		tCommand = self._Priority2CommandQueue:pop()
		LogTrace(tostring(gCon._Priority2CommandQueue))
	elseif (not self._CommandQueue:empty()) then
		tCommand = self._CommandQueue:pop()
		LogTrace(tostring(gCon._CommandQueue))
	end
	
	if (tCommand ~= nil) then
		self._LastCommand = tCommand
		local sCommand = tCommand.command
		local command_delay = tCommand.command_delay
		local delay_units = tCommand.delay_units
		local command_name = tCommand.command_name

		if (sCommand == nil or sCommand == "") then
			self._SendTimer:KillTimer()
			self._WaitResponseTimer:KillTimer()
		else
			LogTrace("SendCommand: %s", sCommand)
			self:SendCommand(sCommand, command_delay, delay_units, command_name)
		end
	end
end

function DeviceConnectionBase:SendLastCommand()
--	LogTrace("DeviceConnectionBase:SendLastCommand")

	local tCommand = self._LastCommand
	if (tCommand ~= nil) then
		local sCommand = tCommand.command
		local command_delay = tCommand.command_delay
		local delay_units = tCommand.delay_units
		local command_name = tCommand.command_name

		if (sCommand == nil or sCommand == "") then
			self._SendTimer:KillTimer()
			self._WaitResponseTimer:KillTimer()
		else
			LogTrace("SendCommand: %s", sCommand)
			self:SendCommand(sCommand, command_delay, delay_units, command_name)
		end
	end
end

function DeviceConnectionBase:SendCommand()
	-- Dummy routine.  Override in derived class
	print("Need to override SendCommand - should never be called")
end


function DeviceConnectionBase:GetMessage()
	
	-- Brain dead version of this routine. Just return the current receive buffer.
	-- It's very likely that a GetMessage() function will need to be created
	if (GetMessage ~= nil and type(GetMessage) == "function") then
		return GetMessage()
	else
		local ComMessage = gReceiveBuffer
		gReceiveBuffer = ""

		return ComMessage
	end
end

--[[=============================================================================
    Other Connection Functions
===============================================================================]]

function ReceivedFromSerial(idBinding, sData)
	if (gCon.ReceivedFromSerial == nil) then return end --serial is bound but not the current control method
	gCon:ReceivedFromSerial(idBinding, sData)
end

function ReceivedFromNetwork(idBinding, nPort, sData)
	gCon:ReceivedFromNetwork(idBinding, nPort, sData)
end

--[[=============================================================================
    The ReceivedAsync function is called in response to 'url_get_request'. 
    The ticketId is the number returned from the request.
===============================================================================]]
function ReceivedAsync(ticketId, strData, responseCode, tHeaders)
	strData = strData or ""
	responseCode = responseCode or 0
	tHeaders = tHeaders or {}

--	LogTrace("ReceivedAsync[" .. ticketId .. "]: Response Code: " .. responseCode .. " Length: " .. string.len(strData))
--	LogTrace(tHeaders)

	gCon:ReceivedAsync(ticketId, strData, responseCode, tHeaders)
end
	
--[[=============================================================================
    OnBindingChanged(idBinding, class, bIsBound)
  
    Description:
    Function called by Director when a binding changes state(bound or unbound).
  
    Parameters:
    idBinding(int) - ID of the binding whose state has changed.
    class(string)  - Class of binding that has changed.
                     A single binding can have multiple classes(i.e. COMPONENT,
                     STEREO, RS_232, etc).
                     This indicates which has been bound or unbound.
    bIsBound(bool) - Whether the binding has been bound or unbound.
  
    Returns:
    None
===============================================================================]]
function OnBindingChanged(idBinding, class, bIsBound)
	
	LogTrace("OnBindingChanged(): idBinding = " .. tostring(idBinding) .. ", class = " .. class .. ", bIsBound = " .. tostring(bIsBound))
	if (idBinding == SERIAL_BINDING_ID) then
		gIsSerialConnected = bIsBound
		SetControlMethod()
		OnSerialConnectionChanged(idBinding, class, bIsBound)
	elseif (idBinding == IR_BINDING_ID) then
		gIsIRConnected = bIsBound
		SetControlMethod()
		OnIRConnectionChanged(idBinding, class, bIsBound)
	end
end

--[[=============================================================================
    OnNetworkBindingChanged(idBinding, bIsBound)
  
    Description:
    Function called by Director when a network binding changes state(bound or unbound).
  
    Parameters:
    idBinding(int) - ID of the binding whose state has changed.
    bIsBound(bool) - Whether the binding has been bound or unbound.
  
    Returns:
    None
===============================================================================]]
function OnNetworkBindingChanged(idBinding, bIsBound)
	LogTrace('OnNetworkBindingChanged(): idBinding = ' .. tostring(idBinding) .. ' bIsBound = ' .. tostring(bIsBound))

	gIsNetworkConnected = bIsBound
	SetControlMethod()
	OnNetworkConnectionChanged(idBinding, bIsBound)
	if (bIsBound) then
		-- Start a special instance of reconnect timer to eventually do NetConnect if not done automatically
		gCon._NetworkReconnectTimer:StartTimer(gNetworkReconnectInterval) 	
	end	
end

--[[=============================================================================
    OnConnectionStatusChanged(idBinding, nPort, sStatus)
  
    Description:
    Sets the updated status of the specified binding
  
    Parameters:
    idBinding(int)  - ID of the binding whose status has changed
    nPort(int)      - The communication port of the specified bindings connection
    sStatus(string) - "ONLINE" if the connection status is to be set to Online,
                      any other value will set the status to Offline
  
    Returns:
    None
===============================================================================]]
function OnConnectionStatusChanged(idBinding, nPort, sStatus)
	LogTrace("OnConnectionStatusChanged[" .. idBinding .. " (" .. tostring(nPort) .. ")]: " .. sStatus)

	local isOnline = false

	gNetworkStatus = sStatus	
	if (sStatus == "ONLINE") then
		isOnline = true
	end

	gCon:SetOnlineStatus(isOnline)
	OnNetworkStatusChanged(idBinding, nPort, sStatus)
end

--[[=============================================================================
    SetControlMethod()
  
    Description:
    Sets the control method type for the drivers internal infrastructure
  
    Parameters:
    None
  
    Returns:
    The type of control method for the drivers connection(i.e. Network, Serial,
    IR, or (none))
===============================================================================]]
function SetControlMethod()
    if (gIsNetworkConnected == false) and (gCon._NetworkReconnectTimer ~= nil) then
		--housekeeping when changing from network control to serial or IR control
		gCon._NetworkReconnectTimer:KillTimer() 
	end
	
	if (gIsNetworkConnected) then
		-- connect to Network communicator if not already connected
		if (gCon == nil or gCon.ControlMethod() ~= "Network") then
			gCon = NetworkConnectionBase:new(NETWORK_BINDING_ID, NETWORK_PORT)
			gCon:Initialize(COM_USE_ACK, COM_COMMAND_DELAY_MILLISECONDS, COM_COMMAND_RESPONSE_TIMEOUT_SECONDS)
		end
		gCon:SetConnection(true, "Network")
	elseif (gIsUrlConnected) then
		-- connect to URL communicator if not already connected
		if (gCon == nil or gCon.ControlMethod() ~= "URL") then
			gCon = UrlConnectionBase:new()
			gCon:Initialize(COM_USE_ACK, COM_COMMAND_DELAY_MILLISECONDS, COM_COMMAND_RESPONSE_TIMEOUT_SECONDS)
		end
		gCon:SetConnection(true, "URL")
	elseif (gIsSerialConnected) then
		-- connect to Serial communicator if not already connected
		if (gCon == nil or gCon.ControlMethod() ~= "Serial") then
			gCon = SerialConnectionBase:new(SERIAL_BINDING_ID)
			gCon:Initialize(COM_USE_ACK, COM_COMMAND_DELAY_MILLISECONDS, COM_COMMAND_RESPONSE_TIMEOUT_SECONDS)
			gCon:InitPolling(tonumber(gPollingTimerInterval), "MINUTES", gCon)
		end
		gCon:SetConnection(true, "Serial")
	elseif (gIsIRConnected) then
		-- connect to IR communicator if not already connected
		if (gCon == nil or gCon.ControlMethod() ~= "IR") then
			gCon = IRConnectionBase:new(IR_BINDING_ID)
			gCon:Initialize(COM_USE_ACK, COM_COMMAND_DELAY_MILLISECONDS, COM_COMMAND_RESPONSE_TIMEOUT_SECONDS)
		end
		gCon:SetConnection(true, "IR")
	else
		if (gCon ~= nil) then
			gCon:SetConnection(false, "(none)")
		end
		-- gCon = nil
	end

	gCon._CommandQueue:clear()
	gCon._Priority1CommandQueue:clear()
	gCon._Priority2CommandQueue:clear()
end

--[[=============================================================================
    ValidateControlMethod(controlMethod)
  
    Description:
    Identifies whether the specified control method has a valid connection
  
    Parameters:
    controlMethod(string) - The communication we are validating against
                            Valid types are (Network, Serial, and IR)
  
    Returns:
    true if the controlMethod specified has been connected, false otherwise.
===============================================================================]]
function ValidateControlMethod(controlMethod)
	local isValid = false

	if (controlMethod == "Network") and (gIsNetworkConnected) then
		isValid = true
	elseif (controlMethod == "URL") and (gIsUrlConnected) then
		isValid = true
	elseif (controlMethod == "Serial") and (gIsSerialConnected) then
		isValid = true
	elseif (controlMethod == "IR") and (gIsIRConnected) then
		isValid = true
	end

	return isValid
end
