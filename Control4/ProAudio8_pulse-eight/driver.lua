
---[[
-- Start of LUA code --
-- Global Variables
DbgPrintF = false
DbgLogF = false
DbgTimer = 0        -- Debug settings get 30 minutes before reverting to no-debug mode.
ResetF = 0

IPMode = 1

IPAddr1 = 0
IPAddr2 = 0
IPAddr3 = 0
IPAddr4 = 0

IPMask1 = 255
IPMask2 = 255
IPMask3 = 255
IPMask4 = 255

IPGate1 = 0
IPGate2 = 0
IPGate3 = 0
IPGate4 = 0

IpBackupF = false      -- If set, then IP parameters need to be backup up when an "=IPSET" command is received

InputData = ""
SelectOut = 1
SelectIn = 1
SelectComposite = 1
SelectVolume = 51
SelectPgVolMode = 1
SelectPgLevel = 1

HSelectOut = 1
HSelectIn = 1

AudioRampStep = 0
AudioRampZone = 0
AudioRampCmd = ""
AudioRampDir = ""
AudioRampTimer = 0
AudioRampRange = 0

--AudioRampTimeout = tonumber( Properties["Ramp Delay (ms)"])

--AudioVolStep = 1        -- Each step of a volume ramp is 1 percent
--AudioBalStep = 2        -- Each step of a balance ramp is 1dB
--AudioToneStep = 1       -- Each step of a tone ramp step is 0.5dB
--AudioFadeSpeed = 160    -- mute fade changes at 80dB per second (speed is given in 0.5dB per second increments)

LastCmd = ""           -- In case of error, this is the last string sent to the switch

CommType = "None"      -- This can be set to "Serial", Network_Online", or "Network_Offline"
SerialBoundF = false    -- If true, then the serial port is bound to the switch
NetBoundF = false      -- If true, then the network is bound to the switch
NetCheckTimer = 0      -- Used to check for a disconnected, but bound, network

RefreshTimer = 0      -- If a refresh is sent immediately after binding, C4 will ignore the SendToProxy() commands, wait for awhile

--CompositeInput = { 1, 1, 1}  -- Keep track of composite inputs

function ListEvent( strEvent, Param1, Param2)
  local outstr = ""
  if (nil ~= Param1) then
    outstr = outstr .. Param1
  end
  
  if (nil ~= Param2) then
    outstr = outstr .. " -- " .. Param2
  end
  
  print("List Event: " .. strEvent .. " (" .. outstr .. ")")
end

--============================================================================
-- Debug printing
--============================================================================
function dbg( dbgStr)
  if (DbgPrintF) then
    print( dbgStr)
  end
  
  if (DbgLogF) then
    C4:ErrorLog( dbgStr)
  end
end

--============================================================================
-- Initialize on startup
--============================================================================
--function OnDriverInit()
--end

function OnDriverLateInit()
  for zone=1,8 do
    -- Notify director that the eq should not be hidden
    local binding = 3999 + zone
    C4:SendToProxy(5001, "HIDEEQFROMNAVS_CHANGED", { OUTPUT = binding, ENABLED = false }, "NOTIFY")
  end
  -- send a list query commands to pull the eq bands
  sendToDevice( "BAZ@1:80$")
  sendToDevice( "TRZ@1:80$")
end

--function OnVariableChanged( strName)
--end

--============================================================================
-- This function is called by a proxy (from Control4) to communicate with the
-- driver.
--
-- Called with:
--    idBinding  = Binding enumeration -- or, which proxy is calling (integer)
--    strCommand = Name of the command (string)
--    tParams    = Table of the command's parameters (table)
--
-- Returns:
--    NONE
--============================================================================
function ReceivedFromProxy( idBinding, strCommand, tParams)

  if (idBinding == 5001) then
    cmdRtn = ProxyACmdT[strCommand]    -- Call an Audio command
  elseif (idBinding == 5002) then
    cmdRtn = ProxyHCmdT[strCommand]    -- Call an HDMI video command
--  elseif (idBinding == 5003) then
--    cmdRtn = ProxyHACmdT[strCommand]    -- Call an HDMI audio command
  else
    cmdRtn = nil
  end

  if (cmdRtn ~= nil) then
  ---[[
    if (DbgPrintF or DbgLogF) then
      dbg( "RcvFromProxy: " .. idBinding .. ": " .. strCommand)
   
      if tParams ~= nil then
        local ii = 1
        for param, pvalue in pairs(tParams) do
          dbg( "...with parameter #" .. ii .. ": " .. param .. ", value = " .. pvalue .. ", type = " .. type(pvalue))
          ii = ii + 1
        end
      else
        print( "...table of parameters is empty")
      end
    end
  --]]
    -- If command is in table, just call the handler with the given parameters
    cmdRtn( tParams)
  ---[[
  else
    if (DbgPrintF or DbgLogF) then
      -- if not in table, print the name of the command and its parameters
      dbg( "Proxy command not found: " .. strCommand .. " Received from proxy on Binding: " .. idBinding)

      if tParams ~= nil then
        local ii = 1
        for param, pvalue in pairs(tParams) do
          dbg( "...with parameter #" .. ii .. ": " .. param .. ", value = " .. pvalue .. ", type = " .. type(pvalue))
          ii = ii + 1
        end
      else
        dbg( "...table of parameters is empty")
      end
    end
  --]]
  end
end

--============================================================================
-- When a property value is changed, this routine is called.
--
-- This routine simply looks up the property in the PropertyCmdT and calls
-- routine (if it exists). The routine is called with the property name as the
-- 1st parameter, and it's value as the 2nd.
--============================================================================
function OnPropertyChanged( strProperty)
  -- Look for routine in table
  if (PropertyCmdT[strProperty] ~= nil) then
    dbg( "Property=" .. strProperty .. ", Setting=" .. Properties[strProperty])
    PropertyCmdT[strProperty]( strProperty, Properties[strProperty])
  else
    print( "Property change command not found: " .. strProperty)
  end
end

--============================================================================
-- When new character(s) are received from the serial or IP port, this
-- routine is called.
--
-- This routine buffers characters as they are received, and extracts anything
-- between the '^' and '$' characters. It then parses the string into the
-- command name, breakaway value (if it exists), and all remaining parameters.
-- If a response string is found (strings that start with the '=' character)
-- then the parameters are placed into a table and a routine with the same
-- name as the command is called.
--
-- To cut down on the number of error checks for 'nil' values by each of the
-- command handlers, this routine will pad the table with trailing '0' values
-- to create a table of at least 3 parameters. Routines that can have more
-- that three parameters will have to do their own checks for the number of
-- parameters in the table, as well as commands where '0' is not a legit
-- value.
--
-- Called with:
--    idBinding = Binding ID of proxy (integer)
--    strData   = One or more chars received from the serial port (string)
--============================================================================
function NewDataFromDevice( strData)
  InputData = InputData .. strData              -- add to receive buffer
  
--[[
  if (DbgPrintF or DbgLogF) then
    if (CommType == "Serial") then
      dbg( "ReceivedFromSerial:")
    else
      dbg( "ReceivedFromNetwork:")
    end
    dbg( strData)
  end
--]]
  -- Search for the end of a command
  ixEnd = string.find( InputData, "$", 1, true)

  -- Command buffer may include more than one command, loop until all commands
  -- have been executed.
  while (ixEnd ~= nil) do

    -- Look for the start of a response string
    ixStart = string.find( InputData, "^", 1, true)

    -- If there is a '^' before the '$' character, then ignore everything before the '^'
    -- otherwise, set the start of command to the start of the string
    if (ixStart ~= nil) then
      if (ixStart > ixEnd) then
        ixStart = 0
      end
    else
      ixStart = 0
    end

    respStr = string.sub( InputData, ixStart+1, ixEnd-1)  -- get everything between the "^" and the "$"
    if (DbgPrintF or DbgLogF) then
      if (CommType == "Serial") then
        dbg( "ReceivedFromSerial: " .. respStr)
      else
        dbg( "ReceivedFromNetwork: " .. respStr)
      end
    end
    -- There are only 3 types of responses from the switch:
    --   '+' = Acknowledgement of command received
    --   '=' = The response string of a command
    --   '!' = An error of some type
    -- Look for the type of response being receive by looking at the 1st character of the response
    local cc = string.sub( respStr, 1, 1)        -- get 1st character of response

    if (cc == "+") then
      -- When the "Setup Driver" action is executed by the user, we turn off acknowledgements, in
      -- the meantime, we just ignore them
    
    elseif (cc == "!") then
      -- Get error number
	  for ccA in string.gmatch(string.sub( respStr, 2, -1), '([^,]+)') do
		  errorNum = tonumber(ccA)
		  -- Check to see if error is in table (incase later firmware adds an error)
		  if (ErrMsgT[errorNum] ~= nil) then
			print( "Error " .. errorNum ..": " .. ErrMsgT[errorNum])
		  else
			print( "Error number: " .. errorNum)
		  end
	  end

      print( "Last command: " .. LastCmd)

    elseif (cc == "=") then
      -- If a response string is found, parse it into a table of parameters.
      -- Look for the space after the name of the command.
      -- If there's a space, the command has parameters, get the name of the command,
      -- and build a table of parameters. (If there were no parameters, then there's
      -- nothing to report to Control4, so ignore it. There shouldn't be any response
      -- strings without parameters, but that's no reason to behave badly, if for some
      -- reason something bad shows up as a response string. Therefore we always look
      -- for the space.)
      ixSpace = string.find( respStr, " ", 1, true)

      if (ixSpace ~= nil) then
        -- if a space exist, then there must be parameters
        key = 1
        paramT = {}

        -- Check for the breakaway parameter
        ixDP = string.find( respStr, ".", 1, true)

        if (ixDP ~= nil and ixDP < ixSpace) then
          -- if a breakaway value exist, get command and set breakaway as 1st parameter
          cmdStr = string.sub( respStr, 2, ixDP-1)
--          print( key .. ": " .. string.sub( respStr, ixDP, ixSpace-1))
          paramT[key] = string.sub( respStr, ixDP, ixSpace-1)
          key = key + 1
        else
          -- if no breakaway parameter, just get the command string
          cmdStr = string.sub( respStr, 2, ixSpace-1)    -- get name of command without the trailing space
        end

        -- Look to see if the command is in the RespCmdT, if so, parse the response string,
        -- otherwise, don't waste the time.
        if (RespCmdT[cmdStr] ~= nil) then
          parm = ixSpace+1

          -- There are many ways to parse a comma seperate value line, here we have chosen to return an
          -- index of each comma's position, from that we can extract the parameters. But more importantly
          -- it allows us to leave the loop pointing to the last parameter, which doesn't end with a ','.
          for nextParm in string.gmatch( respStr, ".-(),") do
            paramT[key] = string.sub( respStr, parm, nextParm-1)
--            print( "Key=" .. key .. ", Param=" .. paramT[key])
            parm = nextParm + 1                  -- point to next parameter, skipping over ','
            key = key + 1
          end

          -- The last parameter extends to the end of the line (there is no trailing ',')
          paramT[key] = string.sub( respStr, parm)
--          print( "Key=" .. key .. ", Param=" .. paramT[key])
          key = key + 1

          -- To keep all the notify routines from having to check for the presence
          -- of non 'nil' table entries, make sure there are at least four parameters
          -- in any given parameter table.
          while (key <= 4) do
            paramT[key] = 0
            key = key + 1
          end

          -- Once we have the name of the command, and its parameters, we can lookup the command
          -- in the RespCmdT table, and call it with the parsed parameters.
          RespCmdT[cmdStr]( paramT)
        else
          dbg( "Command \"" .. cmdStr .. "\" not found in \"RespCmdT\"")
        end
      end

    else
      -- Anything that's not a '+', '!' or a '=' is assumed an error, print it
      print( "Unknown response string: " .. respStr)
      print( "Last command: " .. LastCmd)
    end

    -- Remove command (and trailing '$') from the input buffer
    InputData = string.sub( InputData, ixEnd+1)

    -- Check if there are any more commands in buffer
    ixEnd = string.find( InputData, "$", 1, true)
  end
end

--============================================================================
-- Treat data coming from the network the same as serial port data.
--============================================================================
function ReceivedFromNetwork( idBinding, nPort, strData)
  if (CommType == "Network_Online") then
    NewDataFromDevice( strData)
  elseif (CommType ~= "Serial") then
    -- If data has come in from the network, and the serial port is not
    -- in use (someone hasn't bound both the network and serial port)
    -- then our global variables have gotten trashed.
    -- If data has come in on the network, it is obviously bound and online.
    -- Go ahead and indicate the network port is bound, and set the current
    -- communication type to "Network_Online".
    CommType = "Network_Online"
    NetBoundF = true
    NewDataFromDevice( strData)
-- print( ComType)
  end
end

--============================================================================
-- Treat data coming from the serial port the same as network data.
--============================================================================
function ReceivedFromSerial( idBinding, strData)
  if (CommType == "Serial") then
    NewDataFromDevice( strData)
  elseif (CommType ~= "Network_Online") then
    -- If data has come in from the serial port, and the network is not
    -- online (someone hasn't bound both the network and serial port)
    -- then our global variables have gotten trashed.
    -- If data has come in on a serial port, and the network is not online,
    -- then indicate the serial port is bound, and set the current
    -- communication type to "Serial".
    CommType = "Serial"
    SerialBoundF = true
    NewDataFromDevice( strData)
-- print( ComType)
  end
end

--============================================================================
-- Deal with all the possible changing states.
--============================================================================
function OnBindingChanged( idBinding, strClass, bIsBound)
  -- Binding type of '1' is 'Serial'
  if (idBinding == 1) then
    InputData = ""
    -- if NetCheckTimer was running, kill it
    NetCheckTimer = NetCheckTimer or 0
      
    if (NetCheckTimer ~= 0) then
        NetCheckTimer = C4:KillTimer( NetCheckTimer)
    end
  
    if (bIsBound == true) then
      dbg( "Serial connection bound")
      SerialBoundF = true    -- must precede the NetDisconnect call!
      CommType = "Serial"    --   "     "      "        "        "
      C4:NetDisconnect( 6001, 50005)
      -- C4 apparently cannot handle data sent to SendToProxy() it this time, so set a timer and do it later
      RefreshTimer = C4:AddTimer( 1000, "MILLISECONDS", false)
    else
      dbg( "Serial connection unbound")
      SerialBoundF = false
      -- Check to see if the network is bound and offline, if so, restart network timer
      if (NetBoundF) then
        if (CommType ~= "Network_Online") then
          CommType = "Network_Offline"
          NetCheckTimer = C4:AddTimer( 2, "SECONDS", true)
        end
      else
        CommType = "None"
      end
    end
  end
end

function OnNetworkBindingChanged( idBinding, bIsBound)
  -- Binding '6001' is 'Network'
  if (idBinding == 6001) then
    if (bIsBound == true) then
      dbg( "Network connection bound")
      NetBoundF = true
      CommType = "Network_Offline"

      -- if new binding, then assume we want to use the network connection, even if serial is bound
      -- if no connection in made in 10 seconds, start trying to make a connection manually
      NetCheckTimer = NetCheckTimer or 0
      
      if (NetCheckTimer ~= 0) then
        C4:KillTimer( NetCheckTimer)
      end
      
      NetCheckTimer = C4:AddTimer( 10, "SECONDS", true)

    else
      dbg( "Network connection unbound")
      NetBoundF = false
      
      -- kill NetCheckTimer if no network bound
      NetCheckTimer = NetCheckTimer or 0
      
      if (NetCheckTimer ~= 0) then
        NetCheckTimer = C4:KillTimer( NetCheckTimer)
      end
      
      if (SerialBoundF) then
        CommType = "Serial"
      else
        CommType = "None"
      end
    end
  end
end

function OnConnectionStatusChanged( idBinding, nPort, strStatus)
  -- Verify that it's the network connection we're referring to
  if (idBinding == 6001) then
    InputData = ""
    
    -- online or offline, either way we kill the timer
    NetCheckTimer = NetCheckTimer or 0
      
    if (NetCheckTimer ~= 0) then
      NetCheckTimer = C4:KillTimer( NetCheckTimer)
    end
  
    if (strStatus == "ONLINE") then
      dbg( "Network connection online")
      CommType = "Network_Online"
      -- C4 apparently cannot handle data sent to SendToProxy() it this time, so set a timer and do it later
      RefreshTimer = C4:AddTimer( 3000, "MILLISECONDS", false)
    else
      dbg( "Network connection offline")

      if (SerialBoundF) then
        CommType = "Serial"      -- fall back to serial if we can
      else
        -- Setting CommType to "Network_Offline", will keep any
        -- data from being sent to the switch.
        CommType = "Network_Offline"
        -- Make sure the controller also knows we're disconnected (weird, but done by "other" drivers)
        C4:NetDisconnect( 6001, 50005)
        -- we don't like being offline, if offline, then try once every couple of seconds to get back online
        NetCheckTimer = C4:AddTimer( 2, "SECONDS", true)
      end
    end
  end
end

--============================================================================
-- Called when an "Action" button is pressed in the Lua tab.
-- Or when an "<Commands>" command is executed.
--============================================================================
--[[function ExecuteCommand(sCommand, tParams)
  LogTrace("ExecuteCommand(" .. sCommand .. ")")
  LogInfo(tParams)

  -- Remove any spaces (trim the command)
  local trimmedCommand = string.gsub(sCommand, " ", "")
  local status, ret

  -- if function exists then execute (non-stripped)
  if (EX_CMD[sCommand] ~= nil and type(EX_CMD[sCommand]) == "function") then
    status, ret = pcall(EX_CMD[sCommand], tParams)
  -- elseif trimmed function exists then execute
  elseif (EX_CMD[trimmedCommand] ~= nil and type(EX_CMD[trimmedCommand]) == "function") then
    status, ret = pcall(EX_CMD[trimmedCommand], tParams)
  elseif (EX_CMD[sCommand] ~= nil) then
    QueueCommand(EX_CMD[sCommand])
    status = true
  else
    LogInfo("ExecuteCommand: Unhandled command = " .. sCommand)
    status = true
  end
  
  if (not status) then
    LogError("LUA_ERROR: " .. ret)
  end
  
  return ret -- Return whatever the function returns because it might be xml, a return code, and so on
end
--]]

function ExecuteCommand( strCommand, tParams)
  if (tParams == nil) then
    if (strCommand == "GET_PROPERTIES") then
      -- do nothing, this just stops an error message from being displayed
    else
      print ("From ExecuteCommand Function - Unutilized command: " .. strCommand)
    end
  end

  if (strCommand == "LUA_ACTION") then
    if tParams ~= nil then
      for cmd,cmdv in pairs(tParams) do
        if cmd == "ACTION" then
          -- Check action table for command
          if (ActionT[cmdv] ~= nil) then
            -- if in table, call routine
            ActionT[cmdv]( tParams)
          else
            print( "Action: \"" .. cmdv .. "\" not found in \"ActionT\"")
          end
        else
--          print( "From ExecuteCommand Function - Undefined Lua Command")
--          print( "Key: " .. cmd .. "  Value: " .. cmdv)
        end
      end
    end
  elseif (strCommand == "Set 12V Trigger") then
    cSetTrigger( tParams)
  elseif (strCommand == "Set Page") then
    cSetPageLevel( tParams)
  end
end

--============================================================================
-- When any C4 timer expires, this routine is called. Verify the timer, and
-- execute the proper functions.
--============================================================================
function OnTimerExpired( timerID)
  if (timerID == AudioRampTimer) then
    -- The maximum range of any audio step function is the balance command
    -- which can range from -200 to +200.  If we've stepped beyond that range
    -- we've pegged the needle, just stop the timer.
    if (AudioRampRange > 400) then
      AudioRampTimer = C4:KillTimer( AudioRampTimer)
      AudioRampRange = 0    -- since we've killed the timer without warning, cleanup a little
    else
      -- Add the current step to the range count, to keep track of how many times we've
      -- been called.
      AudioRampRange = AudioRampRange + AudioRampStep
      -- The command, zone, step and direction have all been preset (or should have been!)
      sendZoneLevel( AudioRampCmd, AudioRampZone, AudioRampDir, AudioRampStep)
    end
    
  elseif (timerID == NetCheckTimer) then
    -- If the network goes down, and the network is our preferred connection, then try to reconnect
    if (NetBoundF and (CommType == "Network_Offline")) then
      dbg( "Network connection lost, attempting to reconnect...")
      C4:NetConnect( 6001, 50005)
    end
    
  elseif (timerID == DbgTimer) then
    dbg( "Debug timeout, 30 minutes have passed")
    DbgTimer = C4:KillTimer( DbgTimer)
    DbgPrintF = false
    DbgLogF = false
    C4:UpdateProperty( "Debug", "Off")
    
  elseif (timerID == RefreshTimer) then
    RefreshTimer = C4:KillTimer( RefreshTimer)
    aInitialSetup()
    
  else
    -- if we don't know what timer this is, kill it!
    C4:KillTimer( timerID)
  end
end

--============================================================================
-- When the driver is deleted (destroyed) we need to kill all the timers in
-- use.
--============================================================================
function OnDriverDestroyed()
  AudioRampTimer = AudioRampTimer or 0
  
  if (AudioRampTimer ~= 0) then
    AudiorRampTimer = C4:KillTimer( AudioRampTimer)
  end
  
  NetCheckTimer = NetCheckTimer or 0
  
  if (NetCheckTimer ~= 0) then
    NetCheckTimer = C4:KillTimer( NetCheckTimer)
  end
  
  DbgTimer = DbgTimer or 0
  
  if (DbgTimer ~= 0) then
    DbgTimer = C4:KillTimer( DbgTimer)
  end
  
  RefreshTimer = RefreshTimer or 0
  
  if (RefreshTimer ~= 0) then
    RefreshTimer = C4:KillTimer( RefreshTimer)
  end
end

--============================================================================
-- All functions call this routine to send data to the device.
-- Send data to the serial or TCP/IP port.
--============================================================================
function sendToDevice( ss)
  LastCmd = ss                          -- save command string in case of error
  dbg( "Send: Connection=" .. CommType .. ", Command: " .. ss)
  
  if (CommType == "Serial") then
    C4:SendToSerial( 1, ss)
  elseif (CommType == "Network_Online") then
    C4:SendToNetwork( 6001, 50005, ss)
  else
    -- If we're trying to send something, but nothing is connected, then
    -- it won't hurt to start a timer and try to connect every 10 seconds or so...
    -- ...but only if a timer is not already running.
    NetCheckTimer = NetCheckTimer or 0
    
    if (NetCheckTimer == 0) then
      C4:NetDisconnect( 6001, 50005)          -- make sure we're not in some weird state where we're connected
                              -- but our globals are wrong. Disconnect just in case.
      CommType = "Network_Offline"          -- allow timer routine to try and connect
      NetBoundF = true
      NetCheckTimer = C4:AddTimer( 10, "SECONDS", true)
    end
  end
end

function sendZoneSource( cmd, zone, source, audioF, videoF)
  breakaway = 0

  if (videoF == "True") then
    breakaway = bit.bor( breakaway, 1)        -- set video breakaway bit
  end

  if (audioF == "True") then
    breakaway = bit.bor( breakaway, 14)        -- set audio breakaway bits
  end

  -- build command string
  ss = "^" .. cmd .. "." .. breakaway .. " @" .. zone .. "," .. source .. "$"

  if (breakaway ~= 0) then
    sendToDevice( ss)
  end
end

function sendZoneLevel( cmd, zone, prefix, level)
  zone = (zone % 1000) + 1                  -- convert binding to zone
  -- build command string
  ss = "^" .. cmd .. " @" .. zone .. "," .. prefix .. level .. "$"
--  print( ss)
  sendToDevice( ss)
end

function startAudioRamp( cmd, zone, prefix, step)
  -- Set the global variables
  AudioRampCmd = cmd
  AudioRampZone = tonumber( zone)
  AudioRampDir = prefix
--  print( "Step=" .. step)
  AudioRampStep = tonumber( step)
  
  -- Reset the range counter
  AudioRampRange = 0
  
  -- Start by pulsing the audio
  sendZoneLevel( AudioRampCmd, AudioRampZone, AudioRampDir, AudioRampStep)
  
  -- Check if the timer is already in use. There's apparently no way to
  -- restart a timer once created. So if it is in use, kill it and
  -- re-create it with new timeout.
  if (AudioRampTimer ~= 0) then
    AudioRampTimer = C4:KillTimer( AudioRampTimer)
  end
  -- Start (or restart) the audio timer
--  AudioRampTimeout = tonumber( Properties["Ramp Delay (ms)"])
--  AudioRampTimer = C4:AddTimer( AudioRampTimeout, "MILLISECONDS", true)
  AudioRampTimer = C4:AddTimer( 100, "MILLISECONDS", true)
end

function stopAudioRamp()
  -- We share one timer for all audio ramp functions, so just kill the
  -- timer and all audio ramping will come to a halt.
  if (AudioRampTimer ~= 0) then
    AudioRampTimer = C4:KillTimer( AudioRampTimer)
  end
end

--============================================================================
-- Some helper routines to convert between the normal and XIO modes.
-- These are needed because Control4 will crash if there are more than
-- 100 sources (0-99).
--
-- These routines are switch dependent since the native numbers change
-- per switch.
--============================================================================
-- xxx
-- Translate Native IO to Extended IO
function xN2X( source)
--  if (source > 72) then
--    source = source + 8
--  end

  return source
end

-- xxx
-- Translate Extended IO to Native IO
function xX2N( source)
--  if (source >= 81) then
--    source = source - 8
--  end

  return source
end

--============================================================================
-- These functions are called when a proxy command is received from Control4.
--
-- They are called through the table "ProxyCmdT". To add a handler, add an
-- entry to "ProxyCmdT", and create a function to handle the proxy command.
--
-- Routines called with:
--    paramT = Table of parameters given by the Control4 proxy call.
--============================================================================

--============================================================================
-- P = Turn power on/off.  Handle power state.
--============================================================================
function pxPON( paramT)
  sendToDevice( "^P1$")
end

function pxPOFF( paramT)
--  sendToDevice( "^P0$")    -- never turn off device
end

--============================================================================
-- SZ = Set Zones.  Handle source / zone mappings.
--============================================================================
function pxSZ( paramT)
  -- build zone command w/breakaway and send it to the serial port
  input = paramT["INPUT"]
  input = xN2X((input % 1000) + 1)
  zone = paramT["OUTPUT"]
  zone = (zone % 1000) + 1
  videoF = "False"
  audioF = "False"

  -- Start by looking for a CLASS specifier
  if (paramT["CLASS"] == "VIDEO_SELECTION") then
    videoF = "True"
  elseif (paramT["CLASS"] == "HDMI") then
    videoF = "True"
    audioF = "True"
  elseif (paramT["CLASS"] == "AUDIO_SELECTION") then
    audioF = "True"
  elseif (paramT["CLASS"] == "AUDIO_VOLUME") then
    audioF = "True"
  elseif (paramT["CLASS"] == "STEREO") then
    audioF = "True"
  elseif (paramT["CLASS"] == "DIGITAL_COAX") then
    audioF = "True"
  elseif (paramT["CLASS"] == "DIGITAL_OPTICAL") then
    audioF = "True"
  end

  -- If no CLASS specifier, use AUDIO and VIDEO parameters to set flags
  if (videoF == "False" and audioF == "False") then
    if (paramT["VIDEO"] == "True") then
      videoF = "True"
    end

    if (paramT["AUDIO"] == "True") then
      audioF = "True"
    end
  end
  
  -- If no AUDIO or VIDEO selected, we don't know what C4 is asking, just set both
  if (videoF == "False" and audioF == "False") then
    videoF = "True"
    audioF = "True"
  end

   -- xxx
  -- Differentiate between analog stereo and digital coax zones
  if (zone > 8) then
    if (input >= 1 and input <= 8) then
      print( "Digital outputs cannot be switched to analog inputs, output " .. zone .. " muted.")
    end

    sendZoneSource( "DSZ", zone - 8, input, audioF, videoF)
    sendZoneSource( "DMZ", zone - 8, 0, audioF, videoF)
    
  else
    sendZoneSource( "SZ", zone, input, audioF, videoF)
    sendZoneSource( "PZ", zone, 1, audioF, videoF)
  end
end

--============================================================================
-- Disconnect Output.
-- Called by C4 to disconnect the output of a zone.
-- Uses the 'PZ' command to disconnect a zone.
--============================================================================
function pxDO( paramT)
  -- build zone command w/breakaway and send it to the serial port
  zone = paramT["OUTPUT"]
  zone = (zone % 1000) + 1
  videoF = "False"
  audioF = "False"

  -- Start by looking for a CLASS specifier
  if (paramT["CLASS"] == "VIDEO_SELECTION") then
    videoF = "True"
  elseif (paramT["CLASS"] == "HDMI") then
    videoF = "True"
    audioF = "True"
  elseif (paramT["CLASS"] == "AUDIO_SELECTION") then
    audioF = "True"
  elseif (paramT["CLASS"] == "AUDIO_VOLUME") then
    audioF = "True"
  elseif (paramT["CLASS"] == "STEREO") then
    audioF = "True"
  elseif (paramT["CLASS"] == "DIGITAL_COAX") then
    audioF = "True"
  elseif (paramT["CLASS"] == "DIGITAL_OPTICAL") then
    audioF = "True"
  end

  -- If no CLASS specifier, use AUDIO and VIDEO parameters to set flags
  if (videoF == "False" and audioF == "False") then
    if (paramT["VIDEO"] == "True") then
      videoF = "True"
    end

    if (paramT["AUDIO"] == "True") then
      audioF = "True"
    end
  end
  
  -- If no AUDIO of VIDEO selected, we don't know what C4 is asking, just set both
  if (videoF == "False" and audioF == "False") then
    videoF = "True"
    audioF = "True"
  end

  -- xxx
  if (zone > 8) then
    sendZoneSource( "DMZ", zone - 8, 1, audioF, videoF)
  else
    sendZoneSource( "PZ", zone, 0, audioF, videoF)
  end
end

--============================================================================
-- Connect Output.
-- Called by C4 to connect the output of a zone.
-- Uses the 'PZ' command to connect a zone.
--
-- Any call to SET_INPUT will also connect the output.
--============================================================================
function pxCO( paramT)
  -- build zone command w/breakaway and send it to the serial port
  zone = paramT["OUTPUT"]
  zone = (zone % 1000) + 1
  videoF = "False"
  audioF = "False"

  -- Start by looking for a CLASS specifier
  if (paramT["CLASS"] == "VIDEO_SELECTION") then
    videoF = "True"
  elseif (paramT["CLASS"] == "HDMI") then
    videoF = "True"
    audioF = "True"
  elseif (paramT["CLASS"] == "AUDIO_SELECTION") then
    audioF = "True"
  elseif (paramT["CLASS"] == "AUDIO_VOLUME") then
    audioF = "True"
  elseif (paramT["CLASS"] == "STEREO") then
    audioF = "True"
  elseif (paramT["CLASS"] == "DIGITAL_COAX") then
    audioF = "True"
  elseif (paramT["CLASS"] == "DIGITAL_OPTICAL") then
    audioF = "True"
  end

  -- If no CLASS specifier, use AUDIO and VIDEO parameters to set flags
  if (videoF == "False" and audioF == "False") then
    if (paramT["VIDEO"] == "True") then
      videoF = "True"
    end

    if (paramT["AUDIO"] == "True") then
      audioF = "True"
    end
  end
  
  -- If no AUDIO of VIDEO selected, we don't know what C4 is asking, just set both
  if (videoF == "False" and audioF == "False") then
    videoF = "True"
    audioF = "True"
  end
  
  -- xxx
  if (zone > 8) then
    sendZoneSource( "DMZ", zone - 8, 0, audioF, videoF)
  else
    sendZoneSource( "PZ", zone, 1, audioF, videoF)
  end
end

--============================================================================
-- LDZ = Loudness settings.
--============================================================================
function pxLDZE( paramT)
  zone = paramT["OUTPUT"]
  zone = (zone % 1000) + 1
  sendToDevice( "^LDZ@" .. zone .. ",1$")
end

function pxLDZD( paramT)
  zone = paramT["OUTPUT"]
  zone = (zone % 1000) + 1
  sendToDevice( "^LDZ@" .. zone .. ",0$")
end

function pxLDZT( paramT)
  zone = paramT["OUTPUT"]
  zone = (zone % 1000) + 1
  sendToDevice( "^LDZ@" .. zone .. "+$")
end

--============================================================================
-- VMZ = Mute Zones using volume control.  Handle audio muting.
--============================================================================
function pxVMZE( paramT)
  -- mute just the audio channel
  zone = paramT["OUTPUT"]
  zone = (zone % 1000) + 1
  sendToDevice( "^VMZ@" .. zone .. ",1$")
end

function pxVMZD( paramT)
  -- unmute just the audio channel
  zone = paramT["OUTPUT"]
  zone = (zone % 1000) + 1
  sendToDevice( "^VMZ@" .. zone .. ",0$")
end

function pxVMZT( paramT)
  -- toggle mute on just the audio channel
  zone = paramT["OUTPUT"]
  zone = (zone % 1000) + 1
  sendToDevice( "^VMZ@" .. zone .. "+$")
end

--============================================================================
-- VPZ = Volume percent of Zone.  Handle zone's volume percentage level.
--============================================================================
function pxVPZ( paramT)
  -- build zone command w/breakaway and send it to the serial port
  vlevel = paramT["LEVEL"]            -- Percent volume (0-100)
  sendZoneLevel( "VPZ", paramT["OUTPUT"], "", vlevel)
end

function pxVPZU( paramT)
--  print( "AudioVolStep =" .. AudioVolStep)
  sendZoneLevel( "VPZ", paramT["OUTPUT"], "+", 1)
end

function pxVPZD( paramT)
  sendZoneLevel( "VPZ", paramT["OUTPUT"], "-", 1)
end

function pxVPZRU( paramT)
  startAudioRamp( "VPZ", paramT["OUTPUT"], "+", 1)
end

function pxVPZSU( paramT)
  stopAudioRamp()
end

function pxVPZRD( paramT)
  startAudioRamp( "VPZ", paramT["OUTPUT"], "-", 1)
end

function pxVPZSD( paramT)
  stopAudioRamp()
end

--============================================================================
-- BLZ = Balance of Zone.  Handle zone's balance.
--============================================================================
function pxBLZ( paramT)
  -- build zone command w/breakaway and send it to the serial port
  vlevel = paramT["LEVEL"]
  vlevel = vlevel * 4         -- convert 0-99 to 0-396 (50 = midrange)
  sendZoneLevel( "BLZ", paramT["OUTPUT"], "", vlevel)
end

function pxBLZU( paramT)
  sendZoneLevel( "BLZ", paramT["OUTPUT"], "+", 2)
end

function pxBLZD( paramT)
  sendZoneLevel( "BLZ", paramT["OUTPUT"], "-", 2)
end

function pxBLZRU( paramT)
  startAudioRamp( "BLZ", paramT["OUTPUT"], "+", 2)
end

function pxBLZSU( paramT)
  stopAudioRamp()
end

function pxBLZRD( paramT)
  startAudioRamp( "BLZ", paramT["OUTPUT"], "-", 2)
end

function pxBLZSD( paramT)
  stopAudioRamp()
end

--============================================================================
-- BAZ = Set Zone's Bass level.
--============================================================================
function pxBAZ( paramT)
  vlevel = paramT["LEVEL"]
  -- C4 now has the ability to show equalizer in navigators
  -- Frustratingly, the range is settable there and is correctly reported (-40 to +40)
  -- The traditional option of 'Volume Control' within composer has a range of 0-100 only
  -- Both methods call the same proxy method with no means of distinguishing them.
  -- Thankfully the 'Volume control' option within composer can be hidden 
  -- using a secret capability 'hide_volume_control'
  vlevel = vlevel + 128         -- convert -40-40 to 88-168
  sendZoneLevel( "BAZ", paramT["OUTPUT"], "", vlevel)
end

function pxBAZU( paramT)
  sendZoneLevel( "BAZ", paramT["OUTPUT"], "+", 1)
end

function pxBAZD( paramT)
  sendZoneLevel( "BAZ", paramT["OUTPUT"], "-", 1)
end

function pxBAZRU( paramT)
  startAudioRamp( "BAZ", paramT["OUTPUT"], "+", 1)
end

function pxBAZSU( paramT)
  stopAudioRamp()
end

function pxBAZRD( paramT)
  startAudioRamp( "BAZ", paramT["OUTPUT"], "-", 1)
end

function pxBAZSD( paramT)
  stopAudioRamp()
end

--============================================================================
-- TRZ = Set Zone's Treble level.
--============================================================================
function pxTRZ( paramT)
  vlevel = paramT["LEVEL"]
  -- Convert to switch values
  vlevel = vlevel + 128         -- convert -40+40 to 88-168
  sendZoneLevel( "TRZ", paramT["OUTPUT"], "", vlevel)
end

function pxTRZU( paramT)
  sendZoneLevel( "TRZ", paramT["OUTPUT"], "+", 1)
end

function pxTRZD( paramT)
  sendZoneLevel( "TRZ", paramT["OUTPUT"], "-", 1)
end

function pxTRZRU( paramT)
  startAudioRamp( "TRZ", paramT["OUTPUT"], "+", 1)
end

function pxTRZSU( paramT)
  stopAudioRamp()
end

function pxTRZRD( paramT)
  startAudioRamp( "TRZ", paramT["OUTPUT"], "-", 1)
end

function pxTRZSD( paramT)
  stopAudioRamp()
end

--============================================================================
-- Query Output Status.
-- Called by C4 to determine the status of outputs.
--============================================================================
function pxQOS( paramT)
  audioF = "False"                  -- set to false
  videoF = "False"                  -- set to false
  output = tonumber( paramT["OUTPUT"])    -- get the output binding ID

  if (output >= 2000 and output <= 2999) then
    -- 2000 through 2999 are video outputs, set the breakaway flag to query the video output
    videoF = "True"
  elseif (output >= 4000 and output <= 4999) then
    -- 4000 through 4999 are audio ouputs, set the breakaway glag to query the audio ouput
    audioF = "True"
  end

  -- query the current zone settings
  output = (zone % 1000) + 1
  sendZoneSource( "PZ", output, "?", audioF, videoF)
end

--============================================================================
-- Proxy Command table. A table of C4 proxy commands, mapped to Lua handlers.
-- 
-- Takes advantage of Lua's hashed tables. Chances are real good that Lua's
-- table lookups will be faster than "if then elseif" statements. Using tables
-- also makes it easier to add new commands to the driver.
--
-- To add a new handler, add an entry to this table, along with the
-- corresponding function.
--    The key is the name of the Control4 proxy command
--    The data element is the function used to handle the command
--
-- Each routine is called with the table of parameters given by the original
-- Control4 proxy call. It is up to the individual fuctions to decipher this
--============================================================================
ProxyACmdT =
{  -- ProxyCommand = HandlerFunction
  ["ON"] = pxPON,              -- Turn on switch
  ["OFF"] = pxPOFF,              -- Turn off switch
  ["SET_INPUT"] = pxSZ,          -- Set Zone mapping
  ["MUTE_ON"] = pxVMZE,          -- Mute enabled (output muted)
  ["MUTE_OFF"] = pxVMZD,          -- Mute disabled (output not muted)
  ["MUTE_TOGGLE"] = pxVMZT,        -- Mute toggled
  ["SET_VOLUME_LEVEL"] = pxVPZ,      -- Set Zone's Volume
  ["PULSE_VOL_DOWN"] = pxVPZD,      -- Dec Zone's Volume
  ["PULSE_VOL_UP"] = pxVPZU,        -- Inc Zone's Volume
  ["START_VOL_UP"] = pxVPZRU,      -- Start volume ramping up
  ["STOP_VOL_UP"] = pxVPZSU,        -- Stop volume ramping up
  ["START_VOL_DOWN"] = pxVPZRD,      -- Start volume ramping down
  ["STOP_VOL_DOWN"] = pxVPZSD,      -- Stop volume ramping down
--  ["LOUDNESS_ON"] = pxLDZE,        -- Loudness enable
--  ["LOUDNESS_OFF"] = pxLDZD,        -- Loudness disable
--  ["LOUDNESS_TOGGLE"] = pxLDZT,      -- Loudness toggle
  ["SET_BALANCE"] = pxBLZ,        -- Set Zone's Balance
  ["PULSE_BALANCE_DOWN"] = pxBLZD,    -- Dec Zone's Balance
  ["PULSE_BALANCE_UP"] = pxBLZU,    -- Inc Zone's Balance
  ["START_BALANCE_UP"] = pxBLZRU,    -- Start balance ramping up (right)
  ["STOP_BALANCE_UP"] = pxBLZSU,    -- Stop balance ramping up (right)
  ["START_BALANCE_DOWN"] = pxBLZRD,  -- Start balance ramping down (left)
  ["STOP_BALANCE_DOWN"] = pxBLZSD,    -- Stop balance ramping down (left)
  ["SET_BASS_LEVEL"] = pxBAZ,      -- Set Zone's Bass Level
  ["PULSE_BASS_UP"] = pxBAZU,      -- Inc Zone's Bass Level
  ["PULSE_BASS_DOWN"] = pxBAZD,      -- Dec Zone's Bass Level
  ["START_BASS_UP"] = pxBAZRU,      -- Start bass ramping up
  ["STOP_BASS_UP"] = pxBAZSU,      -- Stop bass ramping up
  ["START_BASS_DOWN"] = pxBAZRD,    -- Start bass ramping down
  ["STOP_BASS_DOWN"] = pxBAZSD,      -- Stop bass ramping down
  ["SET_TREBLE_LEVEL"] = pxTRZ,      -- Set Zone's Treble Level
  ["PULSE_TREBLE_UP"] = pxTRZU,      -- Inc Zone's Treble Level
  ["PULSE_TREBLE_DOWN"] = pxTRZD,    -- Dec Zone's Treble Level
  ["START_TREBLE_UP"] = pxTRZRU,    -- Start treble ramping up
  ["STOP_TREBLE_UP"] = pxTRZSU,      -- Stop treble ramping up
  ["START_TREBLE_DOWN"] = pxTRZRD,    -- Start treble ramping down
  ["STOP_TREBLE_DOWN"] = pxTRZSD,    -- Stop treble ramping down
  ["QUERY_OUTPUT_STATUS"] = pxQOS,    -- Query Output Status
  ["DISCONNECT_OUTPUT"] = pxDO,      -- Disconnect the output of a zone
  ["CONNECT_OUTPUT"] = pxCO        -- Connect output
}

--============================================================================
-- HSZ = Set Zones.  Handle source / zone mappings.
--============================================================================
function pxHSZ( paramT)
  -- build zone command w/breakaway and send it to the serial port
  input = paramT["INPUT"]
  input = (input % 1000) + 1
  zone = paramT["OUTPUT"]
  zone = (zone % 1000) + 1
--[[
-- Control4 doesn't have a way of separating HDMI audio from video,
-- so for we just treat them both like a single block.

  videoF = "False"
  audioF = "False"

  -- Start by looking for a CLASS specifier
  if (paramT["CLASS"] == "VIDEO_SELECTION") then
    videoF = "True"
  elseif (paramT["CLASS"] == "HDMI") then
    videoF = "True"
    audioF = "True"
  elseif (paramT["CLASS"] == "AUDIO_SELECTION") then
    audioF = "True"
  elseif (paramT["CLASS"] == "AUDIO_VOLUME") then
    audioF = "True"
  elseif (paramT["CLASS"] == "STEREO") then
    audioF = "True"
  elseif (paramT["CLASS"] == "DIGITAL_COAX") then
    audioF = "True"
  elseif (paramT["CLASS"] == "DIGITAL_OPTICAL") then
    audioF = "True"
  end

  -- If no CLASS specifier, use AUDIO and VIDEO parameters to set flags
  if (videoF == "False" and audioF == "False") then
    if (paramT["VIDEO"] == "True") then
      videoF = "True"
    end

    if (paramT["AUDIO"] == "True") then
      audioF = "True"
    end
  end
  
  -- If no AUDIO or VIDEO selected, we don't know what C4 is asking, just set both
  if (videoF == "False" and audioF == "False") then
    videoF = "True"
    audioF = "True"
  end
--]]

  -- always set both for now
  videoF = "True"
  audioF = "True"
  
  sendZoneSource( "HSZ", zone, input, audioF, videoF)
  sendZoneSource( "HMZ", zone, 0, audioF, videoF)
end

--============================================================================
-- Disconnect Output.
-- Called by C4 to disconnect the output of a zone.
-- Uses the 'HMZ' command to disconnect a zone.
--============================================================================
function pxHDO( paramT)
  zone = paramT["OUTPUT"]
  zone = (zone % 1000) + 1
--[[
-- Control4 doesn't have a way of separating HDMI audio from video,
-- so for we just treat them both like a single block.

  -- build zone command w/breakaway and send it to the serial port
  videoF = "False"
  audioF = "False"

  -- Start by looking for a CLASS specifier
  if (paramT["CLASS"] == "VIDEO_SELECTION") then
    videoF = "True"
  elseif (paramT["CLASS"] == "HDMI") then
    videoF = "True"
    audioF = "True"
  elseif (paramT["CLASS"] == "AUDIO_SELECTION") then
    audioF = "True"
  elseif (paramT["CLASS"] == "AUDIO_VOLUME") then
    audioF = "True"
  elseif (paramT["CLASS"] == "STEREO") then
    audioF = "True"
  elseif (paramT["CLASS"] == "DIGITAL_COAX") then
    audioF = "True"
  elseif (paramT["CLASS"] == "DIGITAL_OPTICAL") then
    audioF = "True"
  end

  -- If no CLASS specifier, use AUDIO and VIDEO parameters to set flags
  if (videoF == "False" and audioF == "False") then
    if (paramT["VIDEO"] == "True") then
      videoF = "True"
    end

    if (paramT["AUDIO"] == "True") then
      audioF = "True"
    end
  end

  -- If no AUDIO of VIDEO selected, we don't know what C4 is asking, just set both
  if (videoF == "False" and audioF == "False") then
    videoF = "True"
    audioF = "True"
  end
--]]

  -- always set both for now
  videoF = "True"
  audioF = "True"

  sendZoneSource( "HMZ", zone, 1, audioF, videoF)
end

--============================================================================
-- Connect Output.
-- Called by C4 to connect the output of a zone.
-- Uses the 'HMZ' command to connect a zone.
--
-- Any call to SET_INPUT will also connect the output.
--============================================================================
function pxHCO( paramT)
  zone = paramT["OUTPUT"]
  zone = (zone % 1000) + 1
--[[
-- Control4 doesn't have a way of separating HDMI audio from video,
-- so for we just treat them both like a single block.

  -- build zone command w/breakaway and send it to the serial port
  input = 0
  videoF = "False"
  audioF = "False"
  -- Start by looking for a CLASS specifier
  if (paramT["CLASS"] == "VIDEO_SELECTION") then
    videoF = "True"
  elseif (paramT["CLASS"] == "HDMI") then
    videoF = "True"
    audioF = "True"
  elseif (paramT["CLASS"] == "AUDIO_SELECTION") then
    audioF = "True"
  elseif (paramT["CLASS"] == "AUDIO_VOLUME") then
    audioF = "True"
  elseif (paramT["CLASS"] == "STEREO") then
    audioF = "True"
  elseif (paramT["CLASS"] == "DIGITAL_COAX") then
    audioF = "True"
  elseif (paramT["CLASS"] == "DIGITAL_OPTICAL") then
    audioF = "True"
  end

  -- If no CLASS specifier, use AUDIO and VIDEO parameters to set flags
  if (videoF == "False" and audioF == "False") then
    if (paramT["VIDEO"] == "True") then
      videoF = "True"
    end

    if (paramT["AUDIO"] == "True") then
      audioF = "True"
    end
  end
  -- If no AUDIO of VIDEO selected, we don't know what C4 is asking, just set both
  if (videoF == "False" and audioF == "False") then
    videoF = "True"
    audioF = "True"
  end
--]]  

  -- always set both for now
  videoF = "True"
  audioF = "True"

  sendZoneSource( "HMZ", zone, 0, audioF, videoF)
end

--============================================================================
-- HMZ = Mute Zones.  Handle audio muting.
--============================================================================
function pxHMZE( paramT)
  -- mute just the audio channel
  zone = paramT["OUTPUT"]
  zone = (zone % 1000) + 1
  sendToDevice( "^HMZ.4@" .. zone .. ",1$")
end

function pxHMZD( paramT)
  -- unmute just the audio channel
  zone = paramT["OUTPUT"]
  zone = (zone % 1000) + 1
  sendToDevice( "^HMZ.4@" .. zone .. ",0$")
end

function pxHMZT( paramT)
  -- toggle mute on just the audio channel
  zone = paramT["OUTPUT"]
  zone = (zone % 1000) + 1
  sendToDevice( "^HMZ.4@" .. zone .. "+$")
end

--============================================================================
-- Proxy Command table. A table of C4 proxy commands, mapped to Lua handlers.
-- 
-- Takes advantage of Lua's hashed tables. Chances are real good that Lua's
-- table lookups will be faster than "if then elseif" statements. Using tables
-- also makes it easier to add new commands to the driver.
--
-- To add a new handler, add an entry to this table, along with the
-- corresponding function.
--    The key is the name of the Control4 proxy command
--    The data element is the function used to handle the command
--
-- Each routine is called with the table of parameters given by the original
-- Control4 proxy call. It is up to the individual fuctions to decipher this
-- table.
--============================================================================
ProxyHCmdT =
{  -- ProxyCommand = HandlerFunction
  ["SET_INPUT"] = pxHSZ,          -- Set Zone mapping

-- There doesn't seem to be any real-life examples of why you would want
-- to mute video zones (blank the video), it just seems like a way to
-- to create service calls.

--  ["MUTE_ON"] = pxHMZE,          -- Mute enabled (output muted)
--  ["MUTE_OFF"] = pxHMZD,          -- Mute disabled (output not muted)
--  ["MUTE_TOGGLE"] = pxHMZT,        -- Mute toggled
  ["DISCONNECT_OUTPUT"] = pxHDO,    -- Disconnect the output of a zone
  ["CONNECT_OUTPUT"] = pxHCO        -- Connect output
}

--============================================================================
-- Routine to parse the "zone" responses from the switch.
-- These are the response strings that can have a breakaway value, followed
-- by a zone value, following by an integer value.
--
-- Called with:
--    paramT = Table of parameters
--
-- Returns:
--    1) zone (or in some cases an input)
--    2) value (source, or timing, or level, etc)
--    3) videoF - Non-zero if video bit set in breakaway, or breakaway not given
--    4) aAudioF - Non-zero if analog audio bit set in breakaway, or breakaway not given
--    5) dAudioF - Non-zero if digital audio bit set in breakaway, or breakaway not given
--============================================================================
function parseZoneResp( paramT)
  local  videoF = 1                      -- if not given, assume video changed
  local aAudioF = 2                      -- if not given, assume audio changed
  local dAudioF = 12                    -- if not given, assume audio changed
  local zone = 0
  local source = 0
  local key = 1

  -- Check if 1st parameter is the breakaway parameter (this should always be
  -- the case if the initialize action button has been pressed, but we should
  -- not fail if data is being sent to the driver before pressing the button).
  if (string.sub( paramT[key], 1, 1) == ".") then
    -- If breakaway parameter, then setup the audio and video select flags
    avflags = tonumber( string.sub( paramT[1], 2))

    videoF = bit.band( avflags, 1)          -- look for the video bit of the breakaway value
    aAudioF = bit.band( avflags, 2)          -- look for the analog audio bit
    dAudioF = bit.band( avflags, 12)          -- look for the digital audio bits
    key = key + 1                      -- skip over 1st parameter
--    print( "avflags = " .. avflags .. ", aAudioF = " .. aAudioF .. ", dAudioF = " .. dAudioF)
  end

  zone = tonumber( string.sub( paramT[key], 2))  -- skip over '@', get zone
  source = tonumber( paramT[key+1])          -- get source
  zone = zone or 0
  source = source or 0
  return zone,source,videoF,aAudioF,dAudioF
end

--============================================================================
-- These functions are called when a full response string has been received
-- over the communications port (IP or Serial).
--
-- They are called through the table "RespCmdT". To add a handler, add a table
-- entry, and create a function to handle the response string.
--
-- Routines called with:
--    paramT = Table of parameters found in original response string.
--             All entries are strings and include prefix characters.
--============================================================================

--============================================================================
-- SZ = Set Zones. Handle the responses to the "SZ" command.
--============================================================================
function rSZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,source,videoF,aAudioF,dAudioF = parseZoneResp( paramT)
  -- zone = zone
  -- source = source
  -- Send a notify message back to the C4

--  if ((aAudioF + dAudioF) ~= 0) then
    loczone = zone + 3999        -- audio output bindings: 1=4000,2=4001,etc
    
    if (SelectOut == zone) then
      C4:UpdateProperty( "...Analog Source", source)
    end

    if (source == 0) then
      locsource = -1            -- a DISCONNECT_OUTPUT = -1
    else
      locsource = xX2N( source) + 2999    -- audio input bindings: 1=3000,2=3001,etc
    end
    
    C4:SendToProxy( 5001, "INPUT_OUTPUT_CHANGED", {INPUT = locsource, OUTPUT = loczone})
    dbg( "SendToProxy: INPUT_OUTPUT_CHANGED, INPUT=" .. locsource .. ", OUTPUT=" .. loczone)
--  end
end

--============================================================================
-- DSZ = Set Zones. Handle the responses to the "DSZ" command.
--============================================================================
function rDSZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,source,videoF,aAudioF,dAudioF = parseZoneResp( paramT)
  -- zone = zone
  -- source = source
  -- Send a notify message back to the C4

--  if ((aAudioF + dAudioF) ~= 0) then
    -- xxx The digital outputs start after the analog outputs.
    --     Add the number of analog zones to create the digital zone's binding.
    loczone = zone + 3999 + 8      -- audio output bindings
    
    if (SelectOut == zone) then
      C4:UpdateProperty( "...Coax Source", source)
    end

    if (source == 0) then
      locsource = -1            -- a DISCONNECT_OUTPUT = -1
    else
      locsource = xX2N( source) + 2999    -- audio input bindings: 1=3000,2=3001,etc
    end
    
    C4:SendToProxy( 5001, "INPUT_OUTPUT_CHANGED", {INPUT = locsource, OUTPUT = loczone})
    dbg( "SendToProxy: INPUT_OUTPUT_CHANGED, INPUT=" .. locsource .. ", OUTPUT=" .. loczone)
--  end
end

--============================================================================
-- PZ = Power Zones. Handle the responses to the "PZ" command.
--============================================================================
function rPZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,source,videoF,aAudioF,dAudioF = parseZoneResp( paramT)
  -- zone = zone
  -- source = source
  -- Send a notify message back to the C4
  
  queryF = 0
  audioF = aAudioF + dAudioF

--  if (audioF ~= 0) then
    audioF = "True"
    loczone = zone + 3999        -- audio output bindings: 1=4000,2=4001,etc
    
    if (source == 0) then
      locsource = -1            -- a DISCONNECT_OUTPUT = -1
      C4:SendToProxy( 5001, "INPUT_OUTPUT_CHANGED", {INPUT = locsource, OUTPUT = loczone})
      dbg( "SendToProxy: INPUT_OUTPUT_CHANGED, INPUT=" .. locsource .. ", OUTPUT=" .. loczone)
    else
      queryF = 1
    end
--  end

  if (queryF == 1) then
    -- query the current zone settings to return the source value to C4 to indicate a reconnect
    sendZoneSource( "SZ", zone, "?", audioF, videoF)
  end
end

--============================================================================
-- DMZ = Mute Zones. Handle the responses to the "DMZ" command.
--============================================================================
function rDMZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,source,videoF,aAudioF,dAudioF = parseZoneResp( paramT)
  -- zone = zone
  -- source = source
  -- Send a notify message back to the C4
  
  queryF = 0
  audioF = aAudioF + dAudioF

--  if (audioF ~= 0) then
    audioF = "True"
    -- xxx The digital outputs start after the analog outputs.
    --     Add the number of analog zones to create the digital zone's binding.
    loczone = zone + 3999 + 8      -- audio output bindings
    
    if (source == 1) then
      locsource = -1            -- a DISCONNECT_OUTPUT = -1
      C4:SendToProxy( 5001, "INPUT_OUTPUT_CHANGED", {INPUT = locsource, OUTPUT = loczone})
      dbg( "SendToProxy: INPUT_OUTPUT_CHANGED, INPUT=" .. locsource .. ", OUTPUT=" .. loczone)
    else
      queryF = 1
    end
--  end

  if (queryF == 1) then
    -- query the current zone settings to return the source value to C4 to indicate a reconnect
    sendZoneSource( "DSZ", zone, "?", audioF, videoF)
  end
end

--============================================================================
-- DZ = Handle the responses to the "DZ", switch delay times, command.
--============================================================================
function rDZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,dtime,videoF,aAudioF,dAudioF = parseZoneResp( paramT)
  -- if zone is the same as the select property zone, update properties
  if (SelectOut == zone) then
--    if (videoF ~= 0) then
--      C4:UpdateProperty( "...Video Switch Time", dtime)
--    end
    if (aAudioF ~= 0) then
      C4:UpdateProperty( "...Analog Audio Switch Time", dtime)
    end
    if (dAudioF ~= 0) then
      C4:UpdateProperty( "...Digital Audio Switch Time", dtime)
    end
  end
end

--============================================================================
-- P = Power. Handle responses to the "P" command.
--============================================================================
function rP( paramT)
  setting = tonumber( paramT[1])
  
  if (setting == 0) then
    C4:SendToProxy( 5001, "OFF", {})
    ss = "Off"
  elseif (setting == 1) then
    C4:SendToProxy( 5001, "ON", {})
    ss = "On"
  else
    ss = "Locked"
  end

  -- Send a notify message back to C4
  C4:UpdateProperty( "Power", ss)
end

--============================================================================
-- XS = Control Settings. Handle responses to the "XS" command.
--============================================================================
function rXS( paramT)
--[[
  bitmask = tonumber( paramT[1])
  
  if (bit.band( bitmask, 4096) == 0) then
    ss = "Enabled"
  else
    ss = "Disabled"
  end
  C4:UpdateProperty( "Front Panel", ss)

  if (bit.band( bitmask, 1024) == 0) then
    ss = "Disabled"
  else
    ss = "Enabled"
  end
  C4:UpdateProperty( "IR Sensor", ss)
--]]
end

--============================================================================
-- LI = Light Settings. Handle responses to the "LI" command.
--============================================================================
function rLI( paramT)
  dimLevel = tonumber( paramT[2])
  briLevel = tonumber( paramT[3])
  C4:UpdateProperty( "Front Panel Dim Intensity", dimLevel)
  C4:UpdateProperty( "Front Panel Bright Intensity", briLevel)
end

--============================================================================
-- MV = Master Volume. Handle responses to the "MV" command.
--============================================================================
function rMV( paramT)
  vLevel = tonumber( paramT[1])
  C4:UpdateProperty( "Master Volume", vLevel)
end

--============================================================================
-- VZ = Set Zone Volume. Handle the responses to the "VZ" command.
-- Commented out. Now using the new "VPZ" command.
-- This dummy function is, left here, to prevent an error when the "VZ"
-- command is returned from the switch.
--============================================================================
function rVZ( paramT)
--[[
  -- Decode the parameters assuming a "zone" type command
  zone,vlevel = parseZoneResp( paramT)
  loczone = zone + 4000            -- binding: 1=4001,2=4002,etc
  loclevel = (vlevel / 2) - 1        -- convert 200-0 to 99-0
  -- Send a notify message back to the C4
  C4:SendToProxy( 5001, "VOLUME_LEVEL_CHANGED", {LEVEL = loclevel, OUTPUT = loczone})
  -- if zone is the same as the select property zone, update properties as well
  if (SelectOut == zone) then
    C4:UpdateProperty( "...Volume", vlevel-200)
  end
--]]
end

--============================================================================
-- VPZ = Set Zone Volume. Handle the responses to the "VPZ" command.
--============================================================================
function rVPZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,vlevel = parseZoneResp( paramT)
  loczone = zone + 3999            -- binding: 1=4000,2=4001,etc
   loclevel = vlevel                      -- use as is (0-100)
  -- Send a notify message back to the C4
  C4:SendToProxy( 5001, "VOLUME_LEVEL_CHANGED", {LEVEL = loclevel, OUTPUT = loczone})
  -- if zone is the same as the select property zone, update properties as well
  if (SelectOut == zone) then
    C4:UpdateProperty( "...Volume", vlevel)
  end
end

--============================================================================
-- VMIZ = Set minimum volume level for zone.
-- Handle the responses to the "VMIZ" command.
--============================================================================
function rVMIZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,vlevel = parseZoneResp( paramT)
  -- if zone is the same as the select property zone, update properties
  if (SelectOut == zone) then
    C4:UpdateProperty( "...Min Volume", vlevel-200)
  end
end

--============================================================================
-- VMAZ = Set minimum volume level for zone.
-- Handle the responses to the "VMAZ" command.
--============================================================================
function rVMAZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,vlevel = parseZoneResp( paramT)
  -- if zone is the same as the select property zone, update properties
  if (SelectOut == zone) then
    C4:UpdateProperty( "...Max Volume", vlevel-200)
  end
end

--============================================================================
-- LDZ = Set Zone's loudness. Handle the responses to the "LDZ" command.
--============================================================================
function rLDZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,flag,videoF,aAudioF,dAudioF = parseZoneResp( paramT)

  loczone = zone + 3999            -- binding: 1=4000,2=4001,etc

  -- If audio has changed, send a notify message back to the C4
  if ((aAudioF + dAudioF) ~= 0) then
    if (tonumber( flag) ~= 0) then
      C4:SendToProxy( 5001, "LOUDNESS_CHANGED", {MUTE = "True", OUTPUT = loczone})
      C4:UpdateProperty( "...Loudness", "1 - Enabled")
    else
      C4:SendToProxy( 5001, "LOUDNESS_CHANGED", {MUTE = "False", OUTPUT = loczone})
      C4:UpdateProperty( "...Loudness", "0 - Disabled")
    end
  end
end

--============================================================================
-- VMZ = Set Zone's mute. Handle the responses to the "VMZ" command.
--============================================================================
function rVMZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,flag,videoF,aAudioF,dAudioF = parseZoneResp( paramT)

  loczone = zone + 3999            -- binding: 1=4000,2=4001,etc

  -- If audio has changed, send a notify message back to the C4
  if ((aAudioF + dAudioF) ~= 0) then
    if (tonumber( flag) ~= 0) then
      C4:SendToProxy( 5001, "MUTE_CHANGED", {MUTE = "True", OUTPUT = loczone})
    else
      C4:SendToProxy( 5001, "MUTE_CHANGED", {MUTE = "False", OUTPUT = loczone})
    end
  end
end

--============================================================================
-- BLZ = Set Zone Balance. Handle the responses to the "BLZ" command.
--============================================================================
function rBLZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,vlevel = parseZoneResp( paramT)
  loczone = zone + 3999            -- binding: 1=4000,2=4001,etc
  loclevel = vlevel / 4            -- convert 0-400 to 0-100
  -- Send a notify message back to the C4
  C4:SendToProxy( 5001, "BALANCE_LEVEL_CHANGED", {LEVEL = loclevel, OUTPUT = loczone})
  -- if zone is the same as the select property zone, update properties as well
  if (SelectOut == zone) then
    C4:UpdateProperty( "...Balance", vlevel-200)
  end
end

--============================================================================
-- VMLZ = Set Volume Mute Level. Handle the responses to the "VMLZ" command.
--============================================================================
function rVMLZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,vlevel = parseZoneResp( paramT)
  -- if zone is the same as the select property zone, update properties
  if (SelectOut == zone) then
      -- Look for fading
      if (vlevel >= 1000) then
         fadetype = "2 - Mute fading"
         vlevel = vlevel % 1000;
      else
         fadetype = "1 - No fading"
      end
   
    C4:UpdateProperty( "...Mute Level", vlevel)
      C4:UpdateProperty( "...Mute Fading", fadetype)
  end
end

--============================================================================
-- MXZ = Stereo mix for zone. Handle the responses to the "MXZ" command.
--============================================================================
function rMXZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,mix = parseZoneResp( paramT)
  -- if zone is the same as the select property zone, update properties
  if (SelectOut == zone) then
    -- Build list table (it'd be easier if I could specify a list item by index number)
    local listT =
    {  "0 - None",
      "1 - Swap Left and Right",
      "2 - Mono (Left + Right)",
      "3 - Mono (All Left)",
      "4 - Mono (All Right)",
      "5 - Mono (Left - Right)",
      "6 - Mono (Right - Left)"
    }
    C4:UpdateProperty( "...Stereo Mix (O)", listT[mix+1])
  end
end

--============================================================================
-- MXPZ = Mix polarity for zone. Handle the responses to the "MXPZ" command.
--============================================================================
function rMXPZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,pol = parseZoneResp( paramT)
  -- if zone is the same as the select property zone, update properties
  if (SelectOut == zone) then
    -- Build list table (it'd be easier if I could specify a list item by index number)
    local listT =
    {  "0 - Normal",
      "1 - Invert right channel",
      "2 - Invert left channel",
      "3 - Invert left and right",
    }
    C4:UpdateProperty( "...Channel Polarity", listT[pol+1])
  end
end

--============================================================================
-- BAZ = Set Zone Bass level. Handle the responses to the "BAZ" command.
--============================================================================
function rBAZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,vlevel = parseZoneResp( paramT)
  loczone = zone + 3999               -- binding: 1=4000,2=4001,etc
  loclevel = vlevel - 128              -- convert 88-168 to -40-40
  -- Send a notify message back to the C4
  C4:SendToProxy( 5001, "BASS_LEVEL_CHANGED", {LEVEL = loclevel, OUTPUT = loczone})
  -- if zone is the same as the select property zone, update properties as well
  if (SelectOut == zone) then
    C4:UpdateProperty( "...Bass", vlevel-128)
  end
end

--============================================================================
-- TRZ = Set Zone Treble level. Handle the responses to the "TRZ" command.
--============================================================================
function rTRZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,vlevel = parseZoneResp( paramT)
  loczone = zone + 3999               -- binding: 1=4000,2=4001,etc
  loclevel = vlevel - 128              -- convert 88-168 to -40-40
  -- Send a notify message back to the C4
  C4:SendToProxy( 5001, "TREBLE_LEVEL_CHANGED", {LEVEL = loclevel, OUTPUT = loczone})
  -- if zone is the same as the select property zone, update properties as well
  if (SelectOut == zone) then
    C4:UpdateProperty( "...Treble", vlevel-128)
  end
end

--============================================================================
-- EQ1Z = Set EQ1 level for zone. Handle the responses to the "EQ1Z" command.
--============================================================================
function rEQ1Z( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,vlevel = parseZoneResp( paramT)
  -- if zone is the same as the select property zone, update properties
  if (SelectOut == zone) then
    C4:UpdateProperty( "...EQ1 (100Hz)", vlevel-128)
  end
end

--============================================================================
-- EQ2Z = Set EQ2 level for zone. Handle the responses to the "EQ2Z" command.
--============================================================================
function rEQ2Z( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,vlevel = parseZoneResp( paramT)
  -- if zone is the same as the select property zone, update properties
  if (SelectOut == zone) then
    C4:UpdateProperty( "...EQ2 (330Hz)", vlevel-128)
  end
end

--============================================================================
-- EQ3Z = Set EQ3 level for zone. Handle the responses to the "EQ3Z" command.
--============================================================================
function rEQ3Z( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,vlevel = parseZoneResp( paramT)
  -- if zone is the same as the select property zone, update properties
  if (SelectOut == zone) then
    C4:UpdateProperty( "...EQ3 (1,000Hz)", vlevel-128)
  end
end

--============================================================================
-- EQ4Z = Set EQ4 level for zone. Handle the responses to the "EQ4Z" command.
--============================================================================
function rEQ4Z( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,vlevel = parseZoneResp( paramT)
  -- if zone is the same as the select property zone, update properties
  if (SelectOut == zone) then
    C4:UpdateProperty( "...EQ4 (3,300Hz)", vlevel-128)
  end
end

--============================================================================
-- EQ5Z = Set EQ5 level for zone. Handle the responses to the "EQ5Z" command.
--============================================================================
function rEQ5Z( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,vlevel = parseZoneResp( paramT)
  -- if zone is the same as the select property zone, update properties
  if (SelectOut == zone) then
    C4:UpdateProperty( "...EQ5 (10,000Hz)", vlevel-128)
  end
end

--============================================================================
-- LZ = Handle the lock zone responses.
--============================================================================
function rLZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,zoneLck = parseZoneResp( paramT)
  -- if zone is the same as the select property zone, update properties
  if (SelectOut == zone) then
    C4:UpdateProperty( "...Lock Zone", zoneLck)
  end
end

--============================================================================
-- FTYPZ = Handle the filter type responses.
--============================================================================
function rFTYPZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,ftype = parseZoneResp( paramT)

  if (ftype > 0) then
    ftype = ftype - 1
  end
  
  if (SelectOut == zone) then
    -- Build list table (it'd be easier if I could specify a list item by index number)
    local listT =
    {  "0 - Disabled",
      "2 - 12dB/oct Low Pass Filter",
      "3 - 12dB/oct High Pass Filter",
      "4 - 24dB/oct Low Pass Filter",
      "5 - 24dB/oct High Pass Filter"
    }
    C4:UpdateProperty( "...Sub Filter", listT[ftype+1])
  end
end

--============================================================================
-- FFRQZ = Handle the filter frequency responses.
--============================================================================
function rFFRQZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,freq = parseZoneResp( paramT)
  
  if (SelectOut == zone) then
    -- Build list table (it'd be easier if I could specify a list item by index number)
    local listT =
    {  "0 - Disabled",
      "1 - 50Hz",
      "2 - 53Hz",
      "3 - 56Hz",
      "4 - 59Hz",
      "5 - 63Hz",
      "6 - 67Hz",
      "7 - 71Hz",
      "8 - 75Hz",
      "9 - 79Hz",
      "10 - 84Hz",
      "11 - 94Hz",
      "12 - 100Hz",
      "13 - 106Hz",
      "14 - 112Hz",
      "15 - 119Hz",
      "16 - 126Hz",
      "17 - 133Hz",
      "18 - 141Hz",
      "19 - 150Hz",
      "20 - 159Hz",
      "21 - 168Hz",
      "22 - 178Hz",
      "23 - 189Hz",
      "24 - 200Hz",
      "25 - 212Hz",
      "26 - 224Hz",
      "27 - 238Hz",
      "28 - 252Hz",
      "29 - 267Hz",
      "30 - 283Hz",
      "31 - 300Hz"
    }
    C4:UpdateProperty( "...Sub Freq", listT[freq+1])
  end
end

--============================================================================
-- GAZ = Handle the responses to the "GAZ" command.
--============================================================================
function rGAZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,vlevel = parseZoneResp( paramT)
  -- if zone is the same as the select property zone, update properties
  if (SelectOut == zone) then
    C4:UpdateProperty( "...Output Level", vlevel-200)
  end
end

--============================================================================
-- LSZ = Set Lip Sync Delay for zone. Handle the responses to the "LSZ" command.
--============================================================================
function rLSZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,delay = parseZoneResp( paramT)
  -- if zone is the same as the select property zone, update properties
  if (SelectOut == zone) then
    C4:UpdateProperty( "...Lip Sync Delay (O)", delay)
  end
end

--============================================================================
-- DRZ = Local Digital Routing for zone. Handle the responses to the "DRZ" command.
--============================================================================
function rDRZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,route = parseZoneResp( paramT)
  -- if zone is the same as the select property zone, update properties
  if (SelectOut == zone) then
    -- Build list table (it'd be easier if I could specify a list item by number)
    local listT =
    {  "0 - Coax output is switched independent of analog",
      "1 - Coax output mirrors analog output",
      "2 - Coax is independent, uses stereo mix if available for source"
    }
--    print( route..": "..listT[route+1])
    C4:UpdateProperty( "...Coax Audio", listT[route+1])
  end
end

--============================================================================
-- TRGZ = Zone's trigger association.
--============================================================================
function rTRGZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,trg = parseZoneResp( paramT)
  -- if zone is the same as the select property zone, update properties
  if (SelectOut == zone) then
    C4:UpdateProperty( "...Assign 12V Trigger", trg)
  end
end

--============================================================================
-- STRG = The trigger current setting.
--============================================================================
function rSTRG( paramT)
--[[
  -- Decode the parameters assuming a "zone" type command, where the "zone"
  -- is the trigger number.
  trg,set = parseZoneResp( paramT)
  var = "TRIGGER_" .. trg

  print( "Variable = " .. var .. ", Setting = " .. trg)

for VariableName, VariableValue in pairs(Variables) do
  print(VariableName, VariableValue)
end

  -- if setting is different than variable, update variable
  print( "  Old = " .. Variables[tostring( var)])

  if (Variables[var] ~= set) then
    C4:SetVariable( var, set)
    print( "  New = " .. set)
  end
--]]
end

--============================================================================
-- HDRZ = HDMI Digital Routing for zone. Handle the responses to the
-- "HDRZ" command.
--============================================================================
function rHDRZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,route = parseZoneResp( paramT)
  -- if zone is the same as the select property zone, update properties
  if (HSelectOut == zone) then
    -- Build list table (it'd be easier if I could specify a list item by number)
    local listT =
    {  "0 - HDMI audio is passed through",
      "1 - HDMI audio uses stereo downmix if available for source"
    }
--    print( route..": "..listT[route+1])
    C4:UpdateProperty( "...HDMI Audio Mix", listT[route+1])
  end
end

--============================================================================
-- GAI = Input Gain Control. Handle the responses to the "GAI" command.
--============================================================================
function rGAI( paramT)
  -- Decode the parameters assuming a "zone" type command
  source,level,videoF,aAudioF,dAudioF = parseZoneResp( paramT)
  -- if source is the same as the select property source, update properties
  if (SelectIn == source) then
    C4:UpdateProperty( "...Input Gain", level-200)
  end
end

--============================================================================
-- HMI = HDMI Mute Input. Handle the responses to the "HMI" command.
--============================================================================
function rHMI( paramT)
  -- Decode the parameters assuming a "zone" type command
  source,level,videoF,aAudioF,dAudioF = parseZoneResp( paramT)
  -- if source is the same as the select property source, update properties
  if (SelectIn == source) then
    C4:UpdateProperty( "...HDMI Input Mute", level)
  end
end

--============================================================================
-- MXI = Stereo mix for input. Handle the responses to the "MXI" command.
--============================================================================
function rMXI( paramT)
  -- Decode the parameters assuming a "zone" type command
  source,mix = parseZoneResp( paramT)
  -- if source is the same as the select property source, update properties
  if (SelectIn == source) then
    -- Build list table (it'd be easier if I could specify a list item by index number)
    local listT =
    {  "0 - None",
      "1 - Swap Left and Right",
      "2 - Mono (Left + Right)",
      "3 - Mono (All Left)",
      "4 - Mono (All Right)",
      "5 - Mono (Left - Right)",
      "6 - Mono (Right - Left)"
    }
    C4:UpdateProperty( "...Stereo Mix (I)", listT[mix+1])
  end
end

--============================================================================
-- LSI = Set Lip Sync Delay for input. Handle the responses to the "LSI" command.
--============================================================================
function rLSI( paramT)
  -- Decode the parameters assuming a "zone" type command
  source,delay = parseZoneResp( paramT)
  -- if source is the same as the select property source, update properties
  if (SelectIn == source) then
    C4:UpdateProperty( "...Lip Sync Delay (I)", delay)
  end
end

--============================================================================
-- Send the current IP settings to the " --- TCP/IP Settings ---"
--============================================================================
function pIPSettings()
  local ss = ''

  if (IPMode == 0) then
    ss = "Static:"
  else
    ss = "DHCP:"
  end
  
  ss = ss .. "   Address=" .. IPAddr1 .. "." .. IPAddr2 .. "." .. IPAddr3 .. "." .. IPAddr4
  ss = ss .. ",   Mask=" .. IPMask1 .. "." .. IPMask2 .. "." .. IPMask3 .. "." .. IPMask4
  ss = ss .. ",   Gateway=" .. IPGate1 .. "." .. IPGate2 .. "." .. IPGate3 .. "." .. IPGate4
  C4:UpdateProperty( "IP Settings:", ss)
end
  
--============================================================================
-- IPAX = Currently used IP address.
-- Update the " --- IP Settings ---" Property with the new IP address.
--============================================================================
function rIPAX( paramT)
  IPAddr1 = tonumber(paramT[1])
  IPAddr2 = tonumber(paramT[2])
  IPAddr3 = tonumber(paramT[3])
  IPAddr4 = tonumber(paramT[4])
  pIPSettings()
end

--============================================================================
-- IPMX = Currently used IP mask.
-- Update the " --- IP Settings ---" Property with the new IP mask.
--============================================================================
function rIPMX( paramT)
  IPMask1 = tonumber(paramT[1])
  IPMask2 = tonumber(paramT[2])
  IPMask3 = tonumber(paramT[3])
  IPMask4 = tonumber(paramT[4])
  pIPSettings()
end

--============================================================================
-- IPGX = Currently used IP gateway.
-- Update the " --- IP Settings ---" Property with the new IP mask.
--============================================================================
function rIPGX( paramT)
  IPGate1 = tonumber(paramT[1])
  IPGate2 = tonumber(paramT[2])
  IPGate3 = tonumber(paramT[3])
  IPGate4 = tonumber(paramT[4])
  pIPSettings()
end

--============================================================================
-- IPA = Static IP address.
--============================================================================
function rIPA( paramT)
  local  a1,a2,a3,a4,ss
  
  a1 = tonumber(paramT[1])
  a2 = tonumber(paramT[2])
  a3 = tonumber(paramT[3])
  a4 = tonumber(paramT[4])
  ss = a1 .. "." .. a2 .. "." .. a3 .. "." .. a4
  C4:UpdateProperty( "...Static IP Address", ss)
end

--============================================================================
-- IPM = Static mask.
--============================================================================
function rIPM( paramT)
  local  a1,a2,a3,a4,ss
  
  a1 = tonumber(paramT[1])
  a2 = tonumber(paramT[2])
  a3 = tonumber(paramT[3])
  a4 = tonumber(paramT[4])
  ss = a1 .. "." .. a2 .. "." .. a3 .. "." .. a4
  C4:UpdateProperty( "...Static IP Mask", ss)
end

--============================================================================
-- IPG = Static gateway.
--============================================================================
function rIPG( paramT)
  local  a1,a2,a3,a4,ss
  
  a1 = tonumber(paramT[1])
  a2 = tonumber(paramT[2])
  a3 = tonumber(paramT[3])
  a4 = tonumber(paramT[4])
  ss = a1 .. "." .. a2 .. "." .. a3 .. "." .. a4
  C4:UpdateProperty( "...Static IP Gateway", ss)
end

--============================================================================
-- IPSET = IP Mode.
--============================================================================
function rIPSET( paramT)
  local  mode,ss
  
  mode = tonumber(paramT[1])
  
  if (mode == 0) then
    ss = "Static"
    IPMode = 0
  else
    ss = "DHCP"
    IPMode = 1
  end
  C4:UpdateProperty( "...IP Mode", ss)
  pIPSettings()
  
  -- Check if this is the first time we've received this command since
  -- a mode change. If so, back up the new parameters in EEPROM.
  
  if (IpBackupF) then
    sendToDevice( "^SS32$");
    IpBackupF = false;
  end
end

--============================================================================
-- V = Version. Print the firmware version to the Lua window.
--============================================================================
function rV( paramT)
  print( "Model: " .. paramT[1])
  print( "Firmware version: " .. paramT[2])
  print( "Firmware serial number: " .. paramT[3])
  C4:UpdateProperty( "Model", "Model: " .. paramT[1] .. " -- Firmware Version: " .. paramT[2])
end

--============================================================================
-- HSZ = Set Zones. Handle the responses to the "HSZ" command.
--============================================================================
function rHSZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,source,videoF,aAudioF,dAudioF = parseZoneResp( paramT)
  -- zone = zone
  -- source = source
  -- Send a notify message back to the C4

--  if (videoF ~= 0) then
    loczone = zone + 1999        -- video output bindings: 1=2000,2=2001,etc
    
    if (HSelectOut == zone) then
      C4:UpdateProperty( "...HDMI Source", source)
    end

    if (source == 0) then
      locsource = -1            -- a DISCONNECT_OUTPUT = -1
    else
      locsource = source + 999    -- video input bindings: 1=1000,2=1001,etc
    end
    
    C4:SendToProxy( 5002, "INPUT_OUTPUT_CHANGED", {INPUT = locsource, OUTPUT = loczone})
    dbg( "SendToProxy 5002: INPUT_OUTPUT_CHANGED, INPUT=" .. locsource .. ", OUTPUT=" .. loczone)
--  end
end

--============================================================================
-- HMZ = Set Zone's mute. Handle the responses to the "HMZ" command.
--============================================================================
function rHMZ( paramT)
  -- Decode the parameters assuming a "zone" type command
  zone,source,videoF,aAudioF,dAudioF = parseZoneResp( paramT)
  -- zone = zone
  -- source = source
  -- Send a notify message back to the C4
  
  queryF = 0
  audioF = aAudioF + dAudioF

--  if (videoF ~= 0) then
    videoF = "True"
    loczone = zone + 1999        -- video output bindings: 1=2000,2=2001,etc
    
    if (source == 1) then
      locsource = -1            -- a DISCONNECT_OUTPUT = -1
      C4:SendToProxy( 5002, "INPUT_OUTPUT_CHANGED", {INPUT = locsource, OUTPUT = loczone})
      dbg( "SendToProxy: INPUT_OUTPUT_CHANGED, INPUT=" .. locsource .. ", OUTPUT=" .. loczone)
    else
      queryF = 1
    end
--  end

  if (queryF == 1) then
    -- query the current zone settings to return the source value to C4 to indicate a reconnect
    sendZoneSource( "HSZ", zone, "?", audioF, videoF)
  end
end

--============================================================================
-- EAS = EDID Audio Support. Print the EDID Audio support info to the
-- Lua window.
--============================================================================
AudioFmtT =
{  [0] = "-",
  [1] = "PCM",
  [2] = "Dolby5.1",
  [3] = "MPEG-1",
  [4] = "MP3",
  [5] = "MPEG2",
  [6] = "AAC-LC",
  [7] = "DTS",
  [8] = "ATRAC",
  [9] = "DSD",
  [10] = "DolbyDigital+",
  [11] = "DTS-HD",
  [12] = "DolbyTrueHD",
  [13] = "DST",
  [14] = "WMA-Pro",
}

-- Return a string of an audio type

function audTypeS( param)
  ss = AudioFmtT[bit.band( param, 15)]
  ss = ss .. "(" .. bit.rshift( bit.band( param, 112), 4) .. ")"
  return (ss)
end
  
function rEAS( paramT)

  if (tonumber( paramT[2]) == 0) then
    print( "Zone " .. tonumber( paramT[1]) .. " Audio: None")
    return
  end
    
  for ii, param in ipairs( paramT) do
    if (tonumber( param) == 0 and ii == 1) then
      ss = "Global Audio: " .. audTypeS( paramT[2])
    elseif ii == 1 then
      ss = "Zone " .. tonumber( param) .. " Audio: " .. audTypeS( paramT[2])
    elseif ii == 2 then
    elseif (bit.band( param, 15) ~= 0) then
      ss = ss .. "," .. audTypeS( param)
    end
  end
  
  print( ss)
  sendToDevice( "^EALO?$")    -- hack to get real version of lockouts after boot up
end

--============================================================================
-- EALO = EDID Audio Lockout.
--============================================================================
function rEALO( paramT)
  if (bit.band( tonumber(paramT[1]), 1) == 0) then
    C4:UpdateProperty( "EDID Audio Zone 1", "Use")
  else
    C4:UpdateProperty( "EDID Audio Zone 1", "Ignore")
  end

  if (bit.band( tonumber(paramT[1]), 2) == 0) then
    C4:UpdateProperty( "EDID Audio Zone 2", "Use")
  else
    C4:UpdateProperty( "EDID Audio Zone 2", "Ignore")
  end

  if (bit.band( tonumber(paramT[1]), 4) == 0) then
    C4:UpdateProperty( "EDID Audio Zone 3", "Use")
  else
    C4:UpdateProperty( "EDID Audio Zone 3", "Ignore")
  end

  if (bit.band( tonumber(paramT[1]), 8) == 0) then
    C4:UpdateProperty( "EDID Audio Zone 4", "Use")
  else
    C4:UpdateProperty( "EDID Audio Zone 4", "Ignore")
  end

  if (bit.band( tonumber(paramT[1]), 16) == 0) then
    C4:UpdateProperty( "EDID Audio Zone 5", "Use")
  else
    C4:UpdateProperty( "EDID Audio Zone 5", "Ignore")
  end

  if (bit.band( tonumber(paramT[1]), 32) == 0) then
    C4:UpdateProperty( "EDID Audio Zone 6", "Use")
  else
    C4:UpdateProperty( "EDID Audio Zone 6", "Ignore")
  end

  if (bit.band( tonumber(paramT[1]), 64) == 0) then
    C4:UpdateProperty( "EDID Audio Zone 7", "Use")
  else
    C4:UpdateProperty( "EDID Audio Zone 7", "Ignore")
  end

  if (bit.band( tonumber(paramT[1]), 128) == 0) then
    C4:UpdateProperty( "EDID Audio Zone 8", "Use")
  else
    C4:UpdateProperty( "EDID Audio Zone 8", "Ignore")
  end

  if (bit.band( tonumber(paramT[1]), 256) == 0) then
    C4:UpdateProperty( "EDID Audio Zone 9", "Use")
  else
    C4:UpdateProperty( "EDID Audio Zone 9", "Ignore")
  end

  if (bit.band( tonumber(paramT[1]), 512) == 0) then
    C4:UpdateProperty( "EDID Audio Zone 10", "Use")
  else
    C4:UpdateProperty( "EDID Audio Zone 10", "Ignore")
  end

  if (bit.band( tonumber(paramT[1]), 1024) == 0) then
    C4:UpdateProperty( "EDID Audio Zone 11", "Use")
  else
    C4:UpdateProperty( "EDID Audio Zone 11", "Ignore")
  end

  if (bit.band( tonumber(paramT[1]), 2048) == 0) then
    C4:UpdateProperty( "EDID Audio Zone 12", "Use")
  else
    C4:UpdateProperty( "EDID Audio Zone 12", "Ignore")
  end

  if (bit.band( tonumber(paramT[1]), 4096) == 0) then
    C4:UpdateProperty( "EDID Audio Zone 13", "Use")
  else
    C4:UpdateProperty( "EDID Audio Zone 13", "Ignore")
  end

  if (bit.band( tonumber(paramT[1]), 8192) == 0) then
    C4:UpdateProperty( "EDID Audio Zone 14", "Use")
  else
    C4:UpdateProperty( "EDID Audio Zone 14", "Ignore")
  end

  if (bit.band( tonumber(paramT[1]), 16384) == 0) then
    C4:UpdateProperty( "EDID Audio Zone 15", "Use")
  else
    C4:UpdateProperty( "EDID Audio Zone 15", "Ignore")
  end

  if (bit.band( tonumber(paramT[1]), 32768) == 0) then
    C4:UpdateProperty( "EDID Audio Zone 16", "Use")
  else
    C4:UpdateProperty( "EDID Audio Zone 16", "Ignore")
  end
end

--============================================================================
-- EDLO = EDID Lock.
--============================================================================
function rEDLO( paramT)
  if (tonumber(paramT[1]) == 0) then
    C4:UpdateProperty( "EDID Lock", "Unlocked")
  else
    C4:UpdateProperty( "EDID Lock", "Locked")
  end
end

--============================================================================
-- KSIZI = Key Size for input.
--============================================================================
function rKSIZI( paramT)
--[[
  -- Decode the parameters assuming a "zone" type command
  source,keys,videoF,aAudioF,dAudioF = parseZoneResp( paramT)
  
  if (keys == 0) then
    keys = "Auto"
  end
  
  property = "HDCP Keys Source " .. tostring( source)
  C4:UpdateProperty( property, keys)
--]]
end

--============================================================================
-- pASZ = Paging source.
--============================================================================
function rpASZ( paramT)
  switch = tonumber( paramT[1])              -- get switch number
  zone = tonumber( string.sub( paramT[2], 2))    -- skip over '@', get zone
  source = tonumber( paramT[3])
  switch = switch or 0
  zone = zone or 0
  source = source or 0

  if (switch == SelectPgLevel and zone == SelectOut) then
    C4:UpdateProperty( "...Page - Source", source)
  end
end

--============================================================================
-- pVPZ = Paging volume.
--============================================================================
function rpVPZ( paramT)
  switch = tonumber( paramT[1])              -- get switch number
  zone = tonumber( string.sub( paramT[2], 2))    -- skip over '@', get zone
  volume = tonumber( paramT[3])
  switch = switch or 0
  zone = zone or 0
  volume = volume or 0

  if (switch == SelectPgLevel and zone == SelectOut) then
    C4:UpdateProperty( "...Page - Volume", volume - 00000)

    if (volume < 0) then
      sendToDevice( "^pAXSZ"..SelectPgLevel.."@"..SelectOut.."+512$")
    end
  end
end

--============================================================================
-- pAXSZ = Paging Volume Relative.
--============================================================================
function rpAXSZ( paramT)
  local  flags

  switch = tonumber( paramT[1])              -- get switch number
  zone = tonumber( string.sub( paramT[2], 2))    -- skip over '@', get zone
  mute = tonumber( paramT[3])
  switch = switch or 0
  zone = zone or 0
  mute = mute or 0
  flags = bit.band( mute, 3584)

  if (switch == SelectPgLevel and zone == SelectOut) then
    -- Test volume flags
    if (flags == 0) then
      C4:UpdateProperty( "...Page - Volume Mode", "0 - Absolute")
    elseif (flags == 1024) then
      C4:UpdateProperty( "...Page - Volume Mode", "1 - Absolute Ramped")
    elseif (flags == 512) then
      C4:UpdateProperty( "...Page - Volume Mode", "2 - Relative")
    elseif (flags == 1536) then
      C4:UpdateProperty( "...Page - Volume Mode", "3 - Relative Ramped")
    end

    -- Test Do Not Disturb flag
    if (bit.band( mute, 1) == 0) then
      C4:UpdateProperty( "...Page - Do Not Disturb", "0 - Allow page")
    else
      C4:UpdateProperty( "...Page - Do Not Disturb", "1 - Do not disturb")
    end

    -- Test Volume Mute flag
     if (bit.band( mute, 4096) ~= 0) then
      C4:UpdateProperty( "...Page - Mute", "0 - No change to mute")
    elseif (bit.band( mute, 256) ~= 0) then
      C4:UpdateProperty( "...Page - Mute", "1 - Always mute")
    else
      C4:UpdateProperty( "...Page - Mute", "2 - Always unmute")
    end

    -- Test Source change flag
    if (bit.band( mute, 4) == 0) then
      C4:UpdateProperty( "...Page - Source Change", "0 - Allow source to change")
    else
      C4:UpdateProperty( "...Page - Source Change", "1 - Source does not change")
    end
  end
end

--============================================================================
-- pVPMIZ = Paging min volume.
--============================================================================
function rpVPMIZ( paramT)
  switch = tonumber( paramT[1])              -- get switch number
  zone = tonumber( string.sub( paramT[2], 2))    -- skip over '@', get zone
  volume = tonumber( paramT[3])
  switch = switch or 0
  zone = zone or 0
  volume = volume or 0

  if (switch == SelectPgLevel and zone == SelectOut) then
    C4:UpdateProperty( "...Page - Minimum Volume", volume)
  end
end

--============================================================================
-- pVMZ = Paging mute.
--============================================================================
function rpVMZ( paramT)
--[[ This is done using the pASXZ command now, so ignore this

  switch = tonumber( paramT[1])              -- get switch number
  zone = tonumber( string.sub( paramT[2], 2))    -- skip over '@', get zone
  mute = tonumber( paramT[3])
  switch = switch or 0
  zone = zone or 0
  mute = mute or 0

  if (switch == SelectPgLevel and zone == SelectOut) then
    if (mute == 0) then
      C4:UpdateProperty( "...Page - Mute", "0 - Do not mute")
    else
      C4:UpdateProperty( "...Page - Mute", "1 - Mute during page")
    end
  end
--]]
end

--============================================================================
-- pADNDZ = Paging do not disturb.
--============================================================================

function rpADNDZ( paramT)
--[[ This is done using the pASXZ command now, so ignore this

  switch = tonumber( paramT[1])              -- get switch number
  zone = tonumber( string.sub( paramT[2], 2))    -- skip over '@', get zone
  dndF = tonumber( paramT[3])
  switch = switch or 0
  zone = zone or 0
  dndF = dndF or 0

  if (switch == SelectPgLevel and zone == SelectOut) then
    if (dndF == 0) then
      C4:UpdateProperty( "...Page - Do Not Disturb", "0 - Allow page")
    else
      C4:UpdateProperty( "...Page - Do Not Disturb", "1 - Do not disturb")
    end
  end
--]]
end

--============================================================================
-- pDSW = Paging mute.
--============================================================================
function rpDSW( paramT)
  switch = tonumber( paramT[1])              -- get switch number
  action = tonumber( paramT[2])
  page = tonumber( paramT[3])
  pTime = tonumber( paramT[4])
  switch = switch or 0
  action = action or 0
  page = page or 0
  pTime = pTime or 0

  if (switch == SelectPgLevel and page == SelectPgLevel) then
    -- Build list table (it'd be easier if I could specify a list item by index number)
    local listT =
    { "0 - Disabled",
      "1 - Play while pressed (Paging) N.O.",
      "2 - Play while pressed (Paging) N.C.",
      "3 - Press to trigger (Doorbell) N.O.",
      "4 - Press to trigger (Doorbell) N.C."
    }
    C4:UpdateProperty( "Page - DB SW Action", listT[action+1])
    C4:UpdateProperty( "Page - DB SW Timeout", pTime / 1000)
  end
end

--============================================================================
-- pTIME = Paging times.
--============================================================================
function rpTIME( paramT)
  page = tonumber( paramT[1])              -- get page number
  timeDly = tonumber( paramT[2])
  timeMin = tonumber( paramT[3])
  timeDly = timeDly or 0
  timeMin = timeMin or 0

  if (page == SelectPgLevel) then
    C4:UpdateProperty( "Page - Startup Delay", timeDly / 1000)
    C4:UpdateProperty( "Page - Min Page Time", timeMin / 1000)
  end
end

--============================================================================
-- rDummy = Do nothing routine.
--============================================================================
function rDummy( paramT)
end

--============================================================================
-- Table of response commands. These commands are called when a response
-- string from the switch is found and parsed.
--
-- To add a new handler, just add an entry to this table.
--   The key is the command returned from the switch.
--   The element is the name of the function to handle the response string.
--
-- Each routine is called with a table of parameters found in the original
-- switch response string.
--============================================================================
RespCmdT =
{  -- ["SwitchCommand"] = HandlerFunction
  ["SZ"] = rSZ,                -- Set Zone mapping has changed
  ["DSZ"] = rDSZ,              -- Digital Set Zone mapping has changed
  ["PZ"] = rPZ,                -- Power Zone status has changed
  ["DMZ"] = rDMZ,              -- Digital Mute Zone status has changed
  ["P"] = rP,                  -- Power state has changed
  ["XS"] = rXS,                -- Control status has changed
  ["LI"] = rLI,                -- Lighting modes have changed
  ["MV"] = rMV,                -- Master Volume has changed
  ["VZ"] = rVZ,                -- Zone's Volume has changed
  ["VPZ"] = rVPZ,              -- Zone's Volume has changed
  ["VMAZ"] = rVMAZ,              -- Zone's Min Volume has changed
  ["VMIZ"] = rVMIZ,              -- Zone's Max Volume has changed
  ["BLZ"] = rBLZ,              -- Zone's Balance has changed
--  ["LDZ"] = rLDZ,              -- Zone's Loudness setting has changed
  ["VMZ"] = rVMZ,              -- Zone's Volume Mute setting has changed

  ["VMLZ"] = rVMLZ,              -- Zone's Volume Mute Level has changed
  ["MXZ"] = rMXZ,              -- Zone's stereo mix has changed
  ["MXPZ"] = rMXPZ,              -- Zone's mix polarity has changed
  ["BAZ"] = rBAZ,              -- Zone's Bass level has changed
  ["TRZ"] = rTRZ,              -- Zone's Treble level has changed
  ["EQ1Z"] = rEQ1Z,              -- Zone's EQ1 level has changed
  ["EQ2Z"] = rEQ2Z,              -- Zone's EQ2 level has changed
  ["EQ3Z"] = rEQ3Z,              -- Zone's EQ3 level has changed
  ["EQ4Z"] = rEQ4Z,              -- Zone's EQ4 level has changed
  ["EQ5Z"] = rEQ5Z,              -- Zone's EQ5 level has changed
  ["LZ"] = rLZ,                -- Zone's lock has changed
  ["FTYPZ"] = rFTYPZ,            -- Zone's filter type has changed
  ["FFRQZ"] = rFFRQZ,            -- Zone's filter frequency has changed
  ["GAZ"] = rGAZ,              -- Zone's output level has changed
  ["LSZ"] = rLSZ,              -- Zone's EQ5 level has changed
  ["DRZ"] = rDRZ,              -- Zone's local digital routing has changed
  ["HDRZ"] = rHDRZ,              -- Zone's HDMI digital routing has changed
  ["DZ"] = rDZ,                -- Zone's switch delays have changed
  ["GAI"] = rGAI,              -- Input's gain settings has changed
  ["HMI"] = rHMI,              -- HDMI input's mute settings has changed
  ["MXI"] = rMXI,              -- Input's stereo mix has changed
  ["LSI"] = rLSI,              -- Input's lip sync delay has changed
  ["IPAX"] = rIPAX,              -- Update current IP address
  ["IPMX"] = rIPMX,              -- Update current IP mask
  ["IPGX"] = rIPGX,              -- Update current IP gateway
  ["IPA"] = rIPA,              -- Update static IP address
  ["IPM"] = rIPM,              -- Update static IP mask
  ["IPG"] = rIPG,              -- Update static IP gateway
  ["IPSET"] = rIPSET,            -- Update IP mode
  ["V"] = rV,                  -- Firmware version string

  ["HSZ"] = rHSZ,              -- HDMI Set Zone mapping has changed
  ["HMZ"] = rHMZ,              -- HDMI Mute Zone setting has changed
  ["EAS"] = rEAS,              -- Audio support information
  ["EALO"] = rEALO,              -- Audio lockout information
  ["EDLO"] = rEDLO,              -- EDID lockout information
  ["KSIZI"] = rKSIZI,            -- Key sizes for sources

  ["pASZ"] = rpASZ,
  ["pVPZ"] = rpVPZ,
  ["pVPMIZ"] = rpVPMIZ,
  ["pVMZ"] = rpVMZ,
  ["pAXSZ"] = rpAXSZ,
  ["pADNDZ"] = rpADNDZ,
  ["pDSW"] = rpDSW,
  ["pTIME"] = rpTIME,

  ["STRG"] = rSTRG,
  ["TRGZ"] = rTRGZ,

  ["pSET"] = rDummy,
  ["KP"] = rDummy,
}

--============================================================================
-- "Properties" commands.  These routines are called when a property is
-- changed in the drivers "Properties" tab.
--
-- To add a property handler, add a property to the XML table, add a routine
-- here to handle it, and add an entry into the "PropertyCmdT".
--
-- Routines are called with:
--    pName  = Property name (string)
--    pValue = Property value
--============================================================================

--============================================================================
-- Handle "Power" changes
--============================================================================
function pcPower( pName, pValue)
  if (pValue == "On") then
    sendToDevice( "^P1$")
  elseif (pValue == "Off") then
    sendToDevice( "^P2$")
  elseif (pValue == "Locked") then
    sendToDevice( "^P3$")
  end
end

--[[
--============================================================================
-- Handle "Front Panel" changes
--============================================================================
function pcFrontPanel( pName, pValue)
  if (pValue == "Enabled") then
    sendToDevice( "^XS-4096$XS+256$")
    
  else
    sendToDevice( "^XS+4096$")
  end
end

--============================================================================
-- Handle "IR Sensor" changes
--============================================================================
function pcIRSensor( pName, pValue)
  if (pValue == "Enabled") then
    sendToDevice( "^XS+1024$")
    
  else
    sendToDevice( "^XS-1024$")
  end
end

--]]

--============================================================================
-- Handle "Bright Intensity" changes, backup new settings in eeprom
--============================================================================
function pcBrightIntensity( pName, pValue)
  sendToDevice( "^LI 3,," .. pValue .. "$SS 4$")
end

--============================================================================
-- Handle "Dimmed Intensity" changes, backup new settings in eeprom
--============================================================================
function pcDimmedIntensity( pName, pValue)
  sendToDevice( "^LI 3," .. pValue .. "$SS 4$")
end

--============================================================================
-- Handle "Master Volume" changes
--============================================================================
function pcMasterVolume( pName, pValue)
  sendToDevice( "^MV " .. pValue+200 .. "$")
end

--============================================================================
-- Handle "Ramp Delay (ms)" changes
--============================================================================
function pcRampDelay( pName, pValue)
  AudioRampTimeout = pValue
end

--============================================================================
-- Handle "Volume/Balance Step Size" changes
--============================================================================
function pcVolumeBalanceStepSize( pName, pValue)
  AudioVolStep = pValue
end

--============================================================================
-- Handle "Tone Step Size" changes
--============================================================================
function pcToneStepSize( pName, pValue)
  AudioToneStep = pValue
end

--============================================================================
-- Handle "Select Audio Output:" changes
--============================================================================
function pcSettingsforOUT( pName, pValue)
  SelectOut = tonumber( pValue)
--  print( "Zone = "..SelectOut)
  refZoneData( SelectOut)
  refPageData( SelectOut, SelectPgLevel)
end

--============================================================================
-- Handle "Select HDMI Output:" changes
--============================================================================
function pcSettingsforHOUT( pName, pValue)
  HSelectOut = tonumber( pValue)
--  print( "HZone = "..HSelectOut)
  refHZoneData( HSelectOut)
end

-- xxx
function refZoneData( zone)
  -- Request all info for a zone, from the switch

  sendToDevice( "^PZ@"..zone.."$")
  sendToDevice( "VPZ@"..zone.."$")
  sendToDevice( "LDZ@"..zone.."$")
  sendToDevice( "VMZ@"..zone.."$")
  sendToDevice( "VMAZ@"..zone.."$")
  sendToDevice( "VMIZ@"..zone.."$")
  sendToDevice( "BLZ@"..zone.."$")
  sendToDevice( "MXZ@"..zone.."$")
  sendToDevice( "MXPZ@"..zone.."$")
  sendToDevice( "BAZ@"..zone.."$")
  sendToDevice( "VMLZ@"..zone.."$")
  sendToDevice( "TRZ@"..zone.."$")
  sendToDevice( "EQ1Z@"..zone.."$")
  sendToDevice( "EQ2Z@"..zone.."$")
  sendToDevice( "EQ3Z@"..zone.."$")
  sendToDevice( "EQ4Z@"..zone.."$")
  sendToDevice( "EQ5Z@"..zone.."$")
  sendToDevice( "LZ@"..zone.."$")
  sendToDevice( "FTYPZ@"..zone.."$")
  sendToDevice( "FFRQZ@"..zone.."$")
  sendToDevice( "GAZ@"..zone.."$")
  sendToDevice( "LSZ@"..zone.."$")
--  sendToDevice( "DZ@"..zone.."$")
  sendToDevice( "DRZ@"..zone.."$")
  sendToDevice( "^DMZ@"..zone.."$")
end

-- xxx
function refPageData( zone, pg)
  -- Request all paging info for a zone, from the switch
  sendToDevice( "^pASZ"..pg.."@"..zone.."$")
  sendToDevice( "pVPZ"..pg.."@"..zone.."$")
--  sendToDevice( "pVMZ"..pg.."@"..zone.."$")
  sendToDevice( "pVPMIZ"..pg.."@"..zone.."$")
--  sendToDevice( "pADNDZ"..pg.."@"..zone.."$")
  sendToDevice( "pAXSZ"..pg.."@"..zone.."$")
  sendToDevice( "pDSW"..pg.."$")
  sendToDevice( "pTIME"..pg.."$")
end

function refHZoneData( zone)
end

--============================================================================
-- Handle "...Analog Source" changes
--============================================================================
function pcAudSource( pName, pValue)
  source = tonumber( string.sub( pValue, 1, 2))

--[[
  if (source > 9) then
    lockF = 1
  else
    lockF = 0
  end
--]]
    
  source = xN2X( source)
  sendToDevice( "^SZ@"..SelectOut..","..source.."$")
end

--============================================================================
-- Handle "...Coax Source" changes
--============================================================================
function pcDigSource( pName, pValue)
  source = tonumber( string.sub( pValue, 1, 2))

  source = xN2X( source)
  sendToDevice( "^DSZ@"..SelectOut..","..source.."$")
end

--============================================================================
-- Handle "...HDMI Source" changes
--============================================================================
function pcVidSource( pName, pValue)
  source = tonumber( string.sub( pValue, 1, 2))
  sendToDevice( "^HSZ@"..HSelectOut..","..source.."$")
end

--============================================================================
-- Handle "...Volume" changes
--============================================================================
function pcVolume( pName, pValue)
  sendToDevice( "^VPZ@".. SelectOut .. "," .. pValue .. "$")
end

--============================================================================
-- Handle "...Loudness" changes
--============================================================================
function pcLoudness( pName, pValue)
  if pValue == "0 - Disabled" then
    sendToDevice( "^LDZ@".. SelectOut .. ",0$")
  else
    sendToDevice( "^LDZ@".. SelectOut .. ",1$")
  end
end

--============================================================================
-- Handle "...Min Volume" changes
--============================================================================
function pcMinVolume( pName, pValue)
  sendToDevice( "^VMIZ@".. SelectOut .. "," .. pValue+200 .. "$")
end

--============================================================================
-- Handle "...Max Volume" changes
--============================================================================
function pcMaxVolume( pName, pValue)
  sendToDevice( "^VMAZ@".. SelectOut .. "," .. pValue+200 .. "$")
end

--============================================================================
-- Handle "...Balance" changes
--============================================================================
function pcBalance( pName, pValue)
  sendToDevice( "^BLZ@".. SelectOut .. "," .. pValue+200 .. "$")
end

--============================================================================
-- Handle "...Mute Level" changes
--============================================================================
function pcMuteLevel( pName, pValue)
   fadetype = tonumber( string.sub( Properties["...Mute Fading"], 1, 1))
   
   if (fadetype ~= 1) then
      fadeval = pValue + 20000
   else
      fadeval = pValue
   end
    
   sendToDevice( "^VMLZ@".. SelectOut .. "," .. fadeval .. "$")
end

--============================================================================
-- Handle "...Mute Fading" changes
--============================================================================
function pcMuteFading( pName, pValue)
   fadeval = tonumber( Properties["...Mute Level"])
   fadetype = tonumber( string.sub( pValue, 1, 1))
   
   if (fadetype ~= 1) then
      fadeval = fadeval + 20000
   end
    
   sendToDevice( "^VMLZ@".. SelectOut .. "," .. fadeval .. "$")
end

--============================================================================
-- Handle "...Stereo Mix (O)" changes
--============================================================================
function pcStereoMixO( pName, pValue)
  mix = tonumber( string.sub( pValue, 1, 1))
  sendToDevice( "^MXZ@".. SelectOut .. "," .. mix .. "$")
end

--============================================================================
-- Handle "...Channel Polarity" changes
--============================================================================
function pcMixPol( pName, pValue)
  pol = tonumber( string.sub( pValue, 1, 1))
  sendToDevice( "^MXPZ@".. SelectOut .. "," .. pol .. "$")
end

--============================================================================
-- Handle "...Bass" changes
--============================================================================
function pcBass( pName, pValue)
  sendToDevice( "^BAZ@".. SelectOut .. "," .. pValue+128 .. "$")
end

--============================================================================
-- Handle "...Treble" changes
--============================================================================
function pcTreble( pName, pValue)
  sendToDevice( "^TRZ@".. SelectOut .. "," .. pValue+128 .. "$")
end

--============================================================================
-- Handle "...EQ1" changes
--============================================================================
function pcEQ1( pName, pValue)
  sendToDevice( "^EQ1Z@".. SelectOut .. "," .. pValue+128 .. "$")
end

--============================================================================
-- Handle "...EQ2" changes
--============================================================================
function pcEQ2( pName, pValue)
  sendToDevice( "^EQ2Z@".. SelectOut .. "," .. pValue+128 .. "$")
end

--============================================================================
-- Handle "...EQ3" changes
--============================================================================
function pcEQ3( pName, pValue)
  sendToDevice( "^EQ3Z@".. SelectOut .. "," .. pValue+128 .. "$")
end

--============================================================================
-- Handle "...EQ4" changes
--============================================================================
function pcEQ4( pName, pValue)
  sendToDevice( "^EQ4Z@".. SelectOut .. "," .. pValue+128 .. "$")
end

--============================================================================
-- Handle "...EQ5" changes
--============================================================================
function pcEQ5( pName, pValue)
  sendToDevice( "^EQ5Z@".. SelectOut .. "," .. pValue+128 .. "$")
end

--============================================================================
-- Handle "...LZ" changes
--============================================================================
function pcLZ( pName, pValue)
  sendToDevice( "^LZ@".. SelectOut .. "," .. pValue .. "$")
end

--============================================================================
-- Handle "...Sub Filter" changes
--============================================================================
function pcFTYPZ( pName, pValue)
  ftype = tonumber( string.sub( pValue, 1, 1))
  sendToDevice( "^FTYPZ@".. SelectOut .. "," .. ftype .. "$")
end

--============================================================================
-- Handle "...Sub Freq" changes
--============================================================================
function pcFFRQZ( pName, pValue)
  freq = tonumber( string.sub( pValue, 1, 2))
  sendToDevice( "^FFRQZ@".. SelectOut .. "," .. freq .. "$")
end

--============================================================================
-- Handle "...Output Level" changes
--============================================================================
function pcGAZ( pName, pValue)
  sendToDevice( "^GAZ@".. SelectOut .. "," .. pValue+200 .. "$")
end

--============================================================================
-- Handle "...Video Switch Time" changes
--============================================================================
function pcVideoDZ( pName, pValue)
  sendToDevice( "^DZ.1@".. SelectOut .. "," .. pValue .. "$")
end

--============================================================================
-- Handle "...Analog Audio Switch Time" changes
--============================================================================
function pcAAudioDZ( pName, pValue)
  sendToDevice( "^DZ.2@".. SelectOut .. "," .. pValue .. "$")
end

--============================================================================
-- Handle "...Digital Audio Switch Time" changes
--============================================================================
function pcDAudioDZ( pName, pValue)
  sendToDevice( "^DZ.4@".. SelectOut .. "," .. pValue .. "$")
end

--============================================================================
-- Handle "...Coax Audio" changes
--============================================================================
function pcLocalNonPCMRouting( pName, pValue)
  flag = tonumber( string.sub( pValue, 1, 1))
--  print( "flag = " .. flag)
  sendToDevice( "^DRZ@".. SelectOut .. "," .. flag .. "$")
end

--============================================================================
-- Handle "...Lip Sync Delay (O)" changes
--============================================================================
function pcLipSyncDelayO( pName, pValue)
  sendToDevice( "^LSZ@".. SelectOut .. "," .. pValue .. "$")
end

--============================================================================
-- Handle "...HDMI Audio Mix" changes
--============================================================================
function pcHDMINonPCMRouting( pName, pValue)
  flag = tonumber( string.sub( pValue, 1, 1))
--  print( "flag = " .. flag)
  sendToDevice( "^HDRZ@".. HSelectOut .. "," .. flag .. "$")
end

--============================================================================
-- Handle "...Assign 12V Trigger" changes
--============================================================================
function pcTrigger( pName, pValue)
  sendToDevice( "^TRGZ@".. SelectOut .. "," .. pValue .. "$")
end

--============================================================================
-- Handle "Select Input:" changes
--============================================================================
function pcSettingsforIN( pName, pValue)
  SelectIn = tonumber( pValue)
  -- Refresh the zone's data
  refSourceData( SelectIn)
end

-- xxx
function refSourceData( source)
  -- Request all info for a source, from the switch
  sendToDevice( "^GAI@"..source.."?$")
  sendToDevice( "^MXI@"..source.."?$")
  sendToDevice( "^LSI@"..source.."?$")
end

--============================================================================
-- Handle "Input Gain" changes
--============================================================================
function pcInputGain( pName, pValue)
  sendToDevice( "^GAI@"..SelectIn..",".. pValue+200 .. "$")
end

--============================================================================
-- Handle "HDMI Audio Mute" changes
--============================================================================
function pcHDMIInputMute( pName, pValue)
  if (SelectIn <= 0) then
    sendToDevice( "^HMI.8@"..SelectIn..",".. pValue .. "$")
  end
end

--============================================================================
-- Handle "...Stereo Mix (I)" changes
--============================================================================
function pcStereoMixI( pName, pValue)
  mix = tonumber( string.sub( pValue, 1, 1))
  sendToDevice( "^MXI@".. SelectIn .. "," .. mix .. "$")
end

--============================================================================
-- Handle "Lip Sync Delay (I)" changes
--============================================================================
function pcLipSyncDelayI( pName, pValue)
  sendToDevice( "^LSI@"..SelectIn..","..pValue.."$")
end

--============================================================================
-- Handle "...IP Mode" changes
--============================================================================
function pcIPMode( pName, pValue)
  local  mode
  
  if (pValue == "DHCP") then
    mode = 1
  else
    mode = 0
  end
  
  sendToDevice( "^IPSET" .. mode .. "$")
  
  -- Once the mode is changed we lose the connection with the switch,
  -- so we can't send a backup command here.
  -- Set a flag that indicates the new IP values need to be backed
  -- up in EEPROM, when the next "=IPSET" command is received.
  
  IpBackupF = true
end

function parseIP( ipstr)
  local ipaT = {0,0,0,0}
  local  key, idx1, idx2
  local ss = ''
  
  key = 1;
  idx1 = 1;        -- start of string
  idx2 = 0;        -- end of substring when found
    
  -- There are many ways to parse a '.' separate value line, here we have chosen to return an
  -- index of each '.'s position, from that we can extract the parameters. But more importantly
  -- it allows us to leave the loop pointing to the last parameter, which may not end with a '.'.
  for idx2 in string.gmatch( ipstr, ".-()%.") do
    ipaT[key] = tonumber( string.sub( ipstr, idx1, idx2-1))
--    print( "Key=" .. key .. ", Value=" .. ipaT[key])
    idx1 = idx2 + 1  -- point to next parameter, skipping over '.'
    key = key + 1    -- point to next table entry
  end
  ipaT[key] = tonumber( string.sub( ipstr, idx1))  -- point to last entry
  
--  print( "Key=" .. key .. ", Value=" .. ipaT[key])
  ss = ipaT[1] .. ',' .. ipaT[2] .. ',' .. ipaT[3] .. ',' .. ipaT[4] .. '$'
  
  return ss
end

--============================================================================
-- Handle "...Static IP Address" changes
--============================================================================
function pcIPA( pName, pValue)
  local  ss
  
  ss = parseIP( pValue)
  ss = "^IPA" .. ss
  sendToDevice( ss)
end

--============================================================================
-- Handle "...Static IP Mask" changes
--============================================================================
function pcIPM( pName, pValue)
  local  ss
  
  ss = parseIP( pValue)
  ss = "^IPM" .. ss
  sendToDevice( ss)
end

--============================================================================
-- Handle "...Static IP Gateway" changes
--============================================================================
function pcIPG( pName, pValue)
  local  ss
  
  ss = parseIP( pValue)
  ss = "^IPG" .. ss
  sendToDevice( ss)
end

--============================================================================
-- Handle "Debug" settings
--============================================================================
function pcDebug( pName, pValue)
  DbgTimer = DbgTimer or 0
  
  if (DbgTimer ~= 0) then
    DbgTimer = C4:KillTimer( DbgTimer)
  end

  if (pValue == "Off") then
    print( "Debug=Off")
    DbgPrintF = false
    DbgLogF = false
  elseif (pValue == "Print") then
    print( "Debug=Print")
    DbgPrintF = true
    DbgLogF = false
    DbgTimer = C4:AddTimer( 1800, "SECONDS", false)
  elseif (pValue == "Log") then
    print( "Debug=Log")
    DbgPrintF = false
    DbgLogF = true
    DbgTimer = C4:AddTimer( 1800, "SECONDS", false)
  elseif (pValue == "Print and Log") then
    print( "Debug=Print and Log")
    DbgPrintF = true
    DbgLogF = true
    DbgTimer = C4:AddTimer( 1800, "SECONDS", false)
  end
end

--============================================================================
-- Handle HDMI settings
--============================================================================
function pcOut1AudioLock( pName, pValue)
  if pValue == "Use" then
    sendToDevice( "^EALO -1$")
  else
    sendToDevice( "^EALO +1$")
  end
end

function pcOut2AudioLock( pName, pValue)
  if pValue == "Use" then
    sendToDevice( "^EALO -2$")
  else
    sendToDevice( "^EALO +2$")
  end
end

function pcOut3AudioLock( pName, pValue)
  if pValue == "Use" then
    sendToDevice( "^EALO -4$")
  else
    sendToDevice( "^EALO +4$")
  end
end

function pcOut4AudioLock( pName, pValue)
  if pValue == "Use" then
    sendToDevice( "^EALO -8$")
  else
    sendToDevice( "^EALO +8$")
  end
end

function pcOut5AudioLock( pName, pValue)
  if pValue == "Use" then
    sendToDevice( "^EALO -16$")
  else
    sendToDevice( "^EALO +16$")
  end
end

function pcOut6AudioLock( pName, pValue)
  if pValue == "Use" then
    sendToDevice( "^EALO -32$")
  else
    sendToDevice( "^EALO +32$")
  end
end

function pcOut7AudioLock( pName, pValue)
  if pValue == "Use" then
    sendToDevice( "^EALO -64$")
  else
    sendToDevice( "^EALO +64$")
  end
end

function pcOut8AudioLock( pName, pValue)
  if pValue == "Use" then
    sendToDevice( "^EALO -128$")
  else
    sendToDevice( "^EALO +128$")
  end
end

function pcOut9AudioLock( pName, pValue)
  if pValue == "Use" then
    sendToDevice( "^EALO -256$")
  else
    sendToDevice( "^EALO +256$")
  end
end

function pcOut10AudioLock( pName, pValue)
  if pValue == "Use" then
    sendToDevice( "^EALO -512$")
  else
    sendToDevice( "^EALO +512$")
  end
end

function pcOut11AudioLock( pName, pValue)
  if pValue == "Use" then
    sendToDevice( "^EALO -1024$")
  else
    sendToDevice( "^EALO +1024$")
  end
end

function pcOut12AudioLock( pName, pValue)
  if pValue == "Use" then
    sendToDevice( "^EALO -2048$")
  else
    sendToDevice( "^EALO +2048$")
  end
end

function pcOut13AudioLock( pName, pValue)
  if pValue == "Use" then
    sendToDevice( "^EALO -4096$")
  else
    sendToDevice( "^EALO +4096$")
  end
end

function pcOut14AudioLock( pName, pValue)
  if pValue == "Use" then
    sendToDevice( "^EALO -8192$")
  else
    sendToDevice( "^EALO +8192$")
  end
end

function pcOut15AudioLock( pName, pValue)
  if pValue == "Use" then
    sendToDevice( "^EALO -16384$")
  else
    sendToDevice( "^EALO +16384")
  end
end

function pcOut16AudioLock( pName, pValue)
  if pValue == "Use" then
    sendToDevice( "^EALO -32768$")
  else
    sendToDevice( "^EALO +32768$")
  end
end

--============================================================================
-- Handle "HDCP Keys Source x" changes
--============================================================================
function pcHDPCKeysSrc1( pName, pValue)
  if (pValue == "Auto") then
    pValue = 0
  end
  
  sendToDevice( "^KSIZI@1," .. tostring( pValue) .. "$")
end

function pcHDPCKeysSrc2( pName, pValue)
  if (pValue == "Auto") then
    pValue = 0
  end
  
  sendToDevice( "^KSIZI@2," .. tostring( pValue) .. "$")
end

function pcHDPCKeysSrc3( pName, pValue)
  if (pValue == "Auto") then
    pValue = 0
  end
  
  sendToDevice( "^KSIZI@3," .. tostring( pValue) .. "$")
end

function pcHDPCKeysSrc4( pName, pValue)
  if (pValue == "Auto") then
    pValue = 0
  end
  
  sendToDevice( "^KSIZI@4," .. tostring( pValue) .. "$")
end

function pcHDPCKeysSrc5( pName, pValue)
  if (pValue == "Auto") then
    pValue = 0
  end
  
  sendToDevice( "^KSIZI@5," .. tostring( pValue) .. "$")
end

function pcHDPCKeysSrc6( pName, pValue)
  if (pValue == "Auto") then
    pValue = 0
  end
  
  sendToDevice( "^KSIZI@6," .. tostring( pValue) .. "$")
end

function pcHDPCKeysSrc7( pName, pValue)
  if (pValue == "Auto") then
    pValue = 0
  end
  
  sendToDevice( "^KSIZI@7," .. tostring( pValue) .. "$")
end

function pcHDPCKeysSrc8( pName, pValue)
  if (pValue == "Auto") then
    pValue = 0
  end
  
  sendToDevice( "^KSIZI@8," .. tostring( pValue) .. "$")
end

--============================================================================
-- Handle "EDID Lock" changes
--============================================================================
function pcEDIDLock( pName, pValue)
  if pValue == "Unlocked" then
    sendToDevice( "^EDLO 0$")
  else
    sendToDevice( "^EDLO 1$")
  end
end

--============================================================================
-- Handle " --- Page Select ---" changes
--============================================================================
function pcPgLevel( pName, pValue)
  SelectPgLevel = pValue + 0
  refPageData( SelectOut, SelectPgLevel)
end

--============================================================================
-- Handle "...Page - Source" changes
--============================================================================
function pcPgSource( pName, pValue)
  sendToDevice( "^pASZ"..SelectPgLevel.."@"..SelectOut..","..pValue.."$")
end

--============================================================================
-- Handle "...Page - Source Change" changes
--============================================================================
function pcPgSrcChg( pName, pValue)
  if (pValue == "1 - Source does not change") then
    sendToDevice( "^pAXSZ"..SelectPgLevel.."@"..SelectOut.."+4$")
  else
    sendToDevice( "^pAXSZ"..SelectPgLevel.."@"..SelectOut.."-4$")
  end
end

--============================================================================
-- Handle "...Page - Volume" changes
--============================================================================
function pcPgVolume( pName, pValue)
  pValue = pValue + 0
  sendToDevice( "^pVPZ" .. SelectPgLevel .. "@" .. SelectOut .. "," .. pValue .. "$")
end

--============================================================================
-- Handle "...Page - Minimum Volume" changes
--============================================================================
function pcPgPVolMin( pName, pValue)
  sendToDevice( "^pVPMIZ"..SelectPgLevel.."@"..SelectOut..","..pValue.."$")
end

--============================================================================
-- Handle "...Page - Mute" changes
--============================================================================
function pcPgMute( pName, pValue)
--[[
  if (pValue == "0 - Do not mute") then
    sendToDevice( "^pVMZ" .. SelectPgLevel .. "@" .. SelectOut .. ",0$")
  else
    sendToDevice( "^pVMZ" .. SelectPgLevel .. "@" .. SelectOut .. ",1$")
  end
--]]
  if (pValue == "0 - No change to mute") then
    sendToDevice( "^pAXSZ"..SelectPgLevel.."@"..SelectOut.."+4096")
  elseif (pValue == "1 - Always mute") then 
    sendToDevice( "^pAXSZ"..SelectPgLevel.."@"..SelectOut.."-4096,+256$")
  else
    sendToDevice( "^pAXSZ"..SelectPgLevel.."@"..SelectOut.."-4352$")
  end
 end

--============================================================================
-- Handle "...Page - Do Not Disturb" changes
--============================================================================
function pcPgADND( pName, pValue)
--[[
  if (pValue == "0 - Allow page") then
    sendToDevice( "^pADNDZ" .. SelectPgLevel .. "@" .. SelectOut .. ",0$")
  else
    sendToDevice( "^pADNDZ" .. SelectPgLevel .. "@" .. SelectOut .. ",1$")
  end
--]]
  if (pValue == "0 - Allow page") then
    sendToDevice( "^pAXSZ"..SelectPgLevel.."@"..SelectOut.."-1$")
  else
    sendToDevice( "^pAXSZ"..SelectPgLevel.."@"..SelectOut.."+1$")
  end
end

--============================================================================
-- Handle "...Page - Analog Zone Control Flags" changes
--============================================================================
function pcPgVolMode( pName, pValue)
  if (pValue == "0 - Absolute") then
    sendToDevice( "^pAXSZ"..SelectPgLevel.."@"..SelectOut.."-3584$")
  elseif (pValue == "1 - Absolute Ramped") then
    sendToDevice( "^pAXSZ"..SelectPgLevel.."@"..SelectOut.."-3584+1024$")
  elseif (pValue == "2 - Relative") then
    sendToDevice( "^pAXSZ"..SelectPgLevel.."@"..SelectOut.."-3584+512$")
  elseif (pValue == "3 - Relative Ramped") then
    sendToDevice( "^pAXSZ"..SelectPgLevel.."@"..SelectOut.."-3584+1536$")
  end

  -- Always reset the volume when changing modes
  sendToDevice( "^pVPZ"..SelectPgLevel.."@"..SelectOut..",0$")
end

--============================================================================
-- Handle "Page - Startup Delay" changes
--============================================================================
function pcPgStartDly( pName, pValue)
  pValue = pValue * 1000
  sendToDevice( "^pTIME" .. SelectPgLevel .. "," .. pValue .. "$")
end

--============================================================================
-- Handle "Page - Min Page Time" changes
--============================================================================
function pcPgMinTime( pName, pValue)
  pValue = pValue * 1000
  sendToDevice( "^pTIME" .. SelectPgLevel .. ",," .. pValue .. "$")
end

--============================================================================
-- Handle "Page - DB SW Action" changes
--============================================================================
function pcPgDBAction( pName, pValue)
  if (pValue == "0 - Disabled") then 
    sendToDevice( "^pDSW"..SelectPgLevel..",0,"..SelectPgLevel.."$")
  elseif (pValue == "1 - Play while pressed (Paging) N.O.") then 
    sendToDevice( "^pDSW"..SelectPgLevel..",1,"..SelectPgLevel.."$")
  elseif (pValue == "2 - Play while pressed (Paging) N.C.") then 
    sendToDevice( "^pDSW"..SelectPgLevel..",2,"..SelectPgLevel.."$")
  elseif (pValue == "3 - Press to trigger (Doorbell) N.O.") then 
    sendToDevice( "^pDSW"..SelectPgLevel..",3,"..SelectPgLevel.."$")
  elseif (pValue == "4 - Press to trigger (Doorbell) N.C.") then 
    sendToDevice( "^pDSW"..SelectPgLevel..",4,"..SelectPgLevel.."$")
  end
end

--============================================================================
-- Handle "Page - DB SW Timeout" changes
--============================================================================
function pcPgDBTime( pName, pValue)
  pValue = pValue * 1000
  sendToDevice( "^pDSW"..SelectPgLevel..",,,"..pValue.."$")
end

--============================================================================
-- Table of commands that are called when a property has changed.
--============================================================================
PropertyCmdT =
{  ["Debug"] = pcDebug,
  ["Power"] = pcPower,
--  ["Front Panel"] = pcFrontPanel,
--  ["IR Sensor"] = pcIRSensor,
  ["Front Panel Bright Intensity"] = pcBrightIntensity,
  ["Front Panel Dim Intensity"] = pcDimmedIntensity,
  ["Master Volume"] = pcMasterVolume,
--  ["Ramp Delay (ms)"] = pcRampDelay,
  ["Volume/Balance Step Size"] = pcVolumeBalanceStepSize,
  ["Tone Step Size"] = pcToneStepSize,

  ["Select Audio Output:"] = pcSettingsforOUT,
  ["...Analog Source"] = pcAudSource,
  ["...Coax Source"] = pcDigSource,
  ["...Volume"] = pcVolume,
--  ["...Loudness"] = pcLoudness,
  ["...Max Volume"] = pcMaxVolume,
  ["...Min Volume"] = pcMinVolume,
  ["...Balance"] = pcBalance,
--  ["...Mute"] = pcAudMute,
  ["...Mute Level"] = pcMuteLevel,
  ["...Mute Fading"] = pcMuteFading,
  ["...Stereo Mix (O)"] = pcStereoMixO,
  ["...Channel Polarity"] = pcMixPol,
  ["...Bass"] = pcBass,
  ["...Treble"] = pcTreble,
  ["...EQ1 (100Hz)"] = pcEQ1,
  ["...EQ2 (330Hz)"] = pcEQ2,
  ["...EQ3 (1,000Hz)"] = pcEQ3,
  ["...EQ4 (3,300Hz)"] = pcEQ4,
  ["...EQ5 (10,000Hz)"] = pcEQ5,
  ["...Lock Zone"] = pcLZ,
  ["...Sub Filter"] = pcFTYPZ,
  ["...Sub Freq"] = pcFFRQZ,
  ["...Output Level"] = pcGAZ,
  ["...Lip Sync Delay (O)"] = pcLipSyncDelayO,
  ["...Coax Audio"] = pcLocalNonPCMRouting,
  ["...Assign 12V Trigger"] = pcTrigger,
--  ["...Video Switch Time"] = pcVideoDZ,
--  ["...Digital Audio Switch Time"] = pcDAudioDZ,
--  ["...Analog Audio Switch Time"] = pcAAudioDZ,

  ["Select Audio Input:"] = pcSettingsforIN,
  ["...Input Gain"] = pcInputGain,
  ["...HDMI Input Mute"] = pcHDMIInputMute,
  ["...Stereo Mix (I)"] = pcStereoMixI,
  ["...Lip Sync Delay (I)"] = pcLipSyncDelayI,

  ["Select HDMI Output:"] = pcSettingsforHOUT,
  ["...HDMI Source"] = pcVidSource,
  ["...HDMI Audio Mix"] = pcHDMINonPCMRouting,

  ["...IP Mode"] = pcIPMode,
  ["...Static IP Address"] = pcIPA,
  ["...Static IP Mask"] = pcIPM,
  ["...Static IP Gateway"] = pcIPG,
  
  ["EDID Audio Zone 1"] = pcOut1AudioLock,
  ["EDID Audio Zone 2"] = pcOut2AudioLock,
  ["EDID Audio Zone 3"] = pcOut3AudioLock,
  ["EDID Audio Zone 4"] = pcOut4AudioLock,
  ["EDID Audio Zone 5"] = pcOut5AudioLock,
  ["EDID Audio Zone 6"] = pcOut6AudioLock,
  ["EDID Audio Zone 7"] = pcOut7AudioLock,
  ["EDID Audio Zone 8"] = pcOut8AudioLock,
  ["EDID Audio Zone 9"] = pcOut9AudioLock,
  ["EDID Audio Zone 10"] = pcOut10AudioLock,
  ["EDID Audio Zone 11"] = pcOut11AudioLock,
  ["EDID Audio Zone 12"] = pcOut12AudioLock,
  ["EDID Audio Zone 13"] = pcOut13AudioLock,
  ["EDID Audio Zone 14"] = pcOut14AudioLock,
  ["EDID Audio Zone 15"] = pcOut15AudioLock,
  ["EDID Audio Zone 16"] = pcOut16AudioLock,
  
  ["HDCP Keys Source 1"] = pcHDPCKeysSrc1,
  ["HDCP Keys Source 2"] = pcHDPCKeysSrc2,
  ["HDCP Keys Source 3"] = pcHDPCKeysSrc3,
  ["HDCP Keys Source 4"] = pcHDPCKeysSrc4,
  ["HDCP Keys Source 5"] = pcHDPCKeysSrc5,
  ["HDCP Keys Source 6"] = pcHDPCKeysSrc6,
  ["HDCP Keys Source 7"] = pcHDPCKeysSrc7,
  ["HDCP Keys Source 8"] = pcHDPCKeysSrc8,
  
  ["EDID Lock"] = pcEDIDLock,

  [" --- Page Select ---"] = pcPgLevel,
  ["...Page - Source"] = pcPgSource,
  ["...Page - Source Change"] = pcPgSrcChg,
  ["...Page - Volume"] = pcPgVolume,
  ["...Page - Volume Mode"] = pcPgVolMode,
  ["...Page - Minimum Volume"] = pcPgPVolMin,
  ["...Page - Mute"] = pcPgMute,
  ["...Page - Do Not Disturb"] = pcPgADND,
  ["Page - Startup Delay"] = pcPgStartDly,
  ["Page - Min Page Time"] = pcPgMinTime,
  ["Page - DB SW Action"] = pcPgDBAction,
  ["Page - DB SW Timeout"] = pcPgDBTime,
}

--============================================================================
-- Lua "Action" commands.  These commands are called when an installer
-- presses one of the "Action" buttons.  They're mostly used to setup the
-- switch after its initial install.
--============================================================================

--============================================================================
-- Initialize the serial commands of the switch.
-- This routines sets up the serial commands for use with the C4 controller
-- It sets up the following:
--    * Request the firmware version number.
--    * Turns off the "^+$" acknowledgement string ("^+$" is useful for polled
--      serial drivers)
--    * Turns on status echo of any changed serial command, this allows true
--      2-way support. After each command is issued, the updated value is
--      returned and is used to notify C4.
--    * Turn on auto-response strings for the commands that are used by the
--      driver, and turn off the ones that are not.
--============================================================================
function aInitialSetup()

  -- Reset the Property page values to keep them in-sync with the globals

  SelectOut = 1
  C4:UpdateProperty( "Select Audio Output:", 1)

  HSelectOut = 1
  C4:UpdateProperty( "Select HDMI Output:", 1)

  SelectPgLevel = 1
  C4:UpdateProperty( " --- Page Select ---", 1)

  SelectIn = 1
  C4:UpdateProperty( "Select Audio Input:", 1)

  -- Setup the serial protocol to best talk with the Control4 Director.
  --   Set asynchronous mode (+1).
  --   Turn off the "^+$" acknowledgment response (-2), ("^+$" is more useful in polling mode).
  --   Set commands to echo changes back to driver (+4).
  --   Always send the breakaway bitmask with zone commands (+8).
  --   Send CR,LF after response strings (+16)(ignored by driver, but makes debugging easier w/terminal).
  --   Set to normal I/O mode (-32768).
   --   Make sure ErP mode is turned off (-16384).
  --   Save settings in EEPROM.

  -- xxx
  sendToDevice( "^XS+29$XS-49154$SS8$V?$")
  
  -- xxx
  -- Read the information needed for the current properties page
  sendToDevice( "^P?$XS?$MV?$IPAX?$IPMX?$IPGX?$IPA?$IPM?$IPG?$IPSET?$")
  sendToDevice( "^pDSW1?$pTIME1$")

  -- Refresh / Re-synchronize the driver to the switch

  -- xxx
  -- Get parameters for each zone
  for zone=1,8 do
    -- For each zone, send requests for all pertinent data
    local binding = 3999 + zone
    C4:SendToProxy(5001, "HIDEEQFROMNAVS_CHANGED", { OUTPUT = binding, ENABLED = false }, "NOTIFY")
    if (zone == SelectOut) then
      -- If current zone is the currently selected zone, ask
      -- for additional information by calling 'refZoneData()'
      refZoneData( SelectOut)
      refPageData( SelectOut, SelectPgLevel)
      -- Query the parameters that are not properties
    end
  end
  -- send a list query commands
  sendToDevice( "^PZ@1:80$")
  sendToDevice( "^VPZ@1:80$")
  sendToDevice( "^VMZ@1:80$")
  sendToDevice( "^BLZ@1:80$")
  sendToDevice( "^BAZ@1:80$")
  sendToDevice( "^TRZ@1:80$")
  sendToDevice( "^DMZ@1:80$")

  refSourceData( SelectIn)        -- Get source parameters
end

--============================================================================
-- Backup Source to Zone mappings.
-- After a full power failure, the Input to Output mappings will be restored
-- to the mappings that are present when this action button is pressed.
-- Also save the power setting of the zone.
--============================================================================
function aBackupPwrSel()
  sendToDevice( "^SS1$")
end

--============================================================================
-- Backup zone volume levels.
-- After a full power failure, the volume of each zone will be set to the
-- values being used when this action button is pressed.
--============================================================================
function aBackupVolume()
  sendToDevice( "^SS256$")
  print( "Volume levels backed up to non-volatile memory.")
end

--============================================================================
-- Backup audio settings.
-- After a full power failure, all the audio settings except volume, will be
-- set to the values being used when this action button is pressed.
--============================================================================
function aBackupAudio()
  sendToDevice( "^SS3584$")
  print( "All audio settings, except volume levels, backed up to non-volatile memory.")
end

--============================================================================
-- Backup paging settings.
-- After a full power failure, all the audio settings except volume, will be
-- set to the values being used when this action button is pressed.
--============================================================================
function aBackupPaging()
  sendToDevice( "^SS4096$")
  print( "Paging settings backed up to non-volatile memory.")
end

--============================================================================
-- Backup switch timings.
-- After a full power failure, all the video settings will be
-- set to the values being used when this action button is pressed.
--============================================================================
function aBackupTiming()
  sendToDevice( "^SS2$")
end

--============================================================================
-- Backup current EDID settings.
--============================================================================
function aBackupEDID()
  sendToDevice( "^SS32768$")
  print( "EDID and HDCP keys and settings backed up to non-volatile memory.")
end

--============================================================================
-- Clear EDID settings, back to default behavior.
--============================================================================
function aClearEDID()
  if (ResetF == 3) then
    ResetF = 0
    sendToDevice( "^FS32768$")
    aInitialSetup()
    print( "All EDIDs and HDCP keys and settings cleared.")
  end
end

--============================================================================
-- Display EDID Audio Support.
-- After a full power failure, the Input to Output mappings will be restored
-- to the mappings that are present when this action button is pressed.
--============================================================================
function aEAS()
  print( " ")
  sendToDevice( "^EAS1?$")
  sendToDevice( "^EAS2?$")
  sendToDevice( "^EAS3?$")
  sendToDevice( "^EAS4?$")
  sendToDevice( "^EAS5?$")
  sendToDevice( "^EAS6?$")
  sendToDevice( "^EAS7?$")
  sendToDevice( "^EAS8?$")
  sendToDevice( "^EAS0?$")
end

--============================================================================
-- Reset options. The Reset tabs must be pressed 1...2...3... followed by
-- selected reset option.
--============================================================================
function aRST1()
  ResetF = 1
end

function aRST2()
  if (ResetF == 1) then
    ResetF = 2
  else
    ResetF = 0
  end
end

function aRST3()
  if (ResetF == 2) then
    ResetF = 3
  else
    ResetF = 0
  end
end

function aRST_Audio()
  if (ResetF == 3) then
    ResetF = 0
    sendToDevice( "^FS3840$")
    aInitialSetup()
    print( "All audio parameters except paging, reset to factory settings.")
  end
end

function aRST_Paging()
  if (ResetF == 3) then
    ResetF = 0
    sendToDevice( "^FS4096$")
    aInitialSetup()
    print( "All paging parameters reset to factory settings.")
  end
end

function aRST_NoIP()
  if (ResetF == 3) then
    ResetF = 0
    sendToDevice( "^FS32735$")
    aInitialSetup()
    print( "All parameters except TCP/IP and EDIDs reset to factory settings.")
  end
end

function aRST_ALL()
  if (ResetF == 3) then
    ResetF = 0
    sendToDevice( "^FS65535$")
    aInitialSetup()
    print( "All parameters reset to factory settings!!!")
    print( "If using TCP/IP you will likely need to power cycle, and possibly use the Network tab, to reconnect your switch!!")
  end
end

function factory()
  ResetF = 3
  aRST_ALL()
end

function aReset( tParams)
  tParams = tParams or {}
  local resetF
  local msg
  local option = tParams["Select Option"]

  if (option == "Reset all audio settings") then
    resetF = 3843
    msg = "All audio parameters except paging, reset to factory settings."
  elseif (option == "Reset paging parameters") then
    resetF = 4096
    msg = "All paging parameters reset to factory settings."
  elseif (option == "Clear EDIDs and HDCP keys from EEPROM") then
    resetF = 32768
    msg = "All EDIDs and HDCP keys cleared from EEPROM\nYou must power cycle the switch to clear EDIDs and HDCP keys from cache."
  elseif (option == "Clear everything except TCP/IP") then
    resetF = 32735
    msg = "All parameters except TCP/IP and EDIDs reset to factory settings."
  elseif (option == "Set all zones to powered-off by default") then
    resetF = 0
    msg = "When the switch is power cycled, all zones will start up as powered off."
    sendToDevice( "^PZ@1:8,0$SS1$")
  end

  if (resetF ~= 0) then
    sendToDevice( "^FS"..resetF.."$")
  end
  print( msg)
end

function cSetTrigger( tParams)
  tParams = tParams or {}
  local set

  local trigger = tParams["Trigger"]
  local state = tParams["State"]

  if (state == "ON") then
    set = 1
  elseif (state == "OFF") then
    set = 0
  else
    set = 2
  end

  sendToDevice( "^STRG@"..trigger..","..set.."$")
end

function cSetPageLevel( tParams)
  tParams = tParams or {}
  local set

  local level = tParams["Page"]

  sendToDevice( "^pSET"..level.."$")
end

--============================================================================
-- Table of "Actions" and "Commands"
--============================================================================
ActionT =
{  ["InitialSetup"] = aInitialSetup,    -- Setup the hardware for the first time
  ["BackupPwrSel"] = aBackupPwrSel,    -- Backup the in/out and power on/off settings
  ["BackupVolume"] = aBackupVolume,    -- Backup the volume settings
  ["BackupAudio"] = aBackupAudio,      -- Backup the audio settings (not volume)
  ["BackupTiming"] = aBackupTiming,    -- Backup the switch timings
  ["BackupPaging"] = aBackupPaging,    -- Backup the paging settings
  ["BackupEDID"] = aBackupEDID,        -- Backup the EDID settings
  ["ClearEDID"] = aClearEDID,        -- Backup the EDID settings
  ["EAS"] = aEAS,                -- Display EDID Audio Support

  ["RST1"] = aRST1,
  ["RST2"] = aRST2,
  ["RST3"] = aRST3,
  ["RST_Audio"] = aRST_Audio,
  ["RST_Paging"] = aRST_Paging,
  ["RST_NoIP"] = aRST_NoIP,
  ["RST_ALL"] = aRST_ALL,

  ["Reset"] = aReset,

  ["TestTriggers"] = cSetTrigger,
  ["TestPaging"] = cSetPageLevel
}

--============================================================================
-- Table of error messages.
-- These messages convert the error codes returned by the switch to
-- full messages.
--============================================================================
ErrMsgT =
{  [1] = "Unknown command",
  [2] = "A parameter is out of range",
  [3] = "Syntax error in command",
  [4] = "Bad checksum",
  [5] = "Wrong number of parameters",
  [6] = "Busy, cannot process command",
  [7] = "Buffer overflow",
  [8] = "Power is off, command ignored",
  [100] = "DSP audio initialized with no error",
  [201] = "Could not initialize the HDMI section",
  [202] = "Could not initialize the HDMI section",
}
-- End of LUA Code --
--]]
      