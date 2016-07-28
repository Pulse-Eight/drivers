function P8INT:GET_OUTPUT_PORT()
    local port = Properties["Output Port"] or "-1"
    local trimPort = string.gsub(port, "Output ", "")
    return tonumber(trimPort)-1
end

function P8INT:SEND_KEY(postData)
    local port = P8INT:GET_OUTPUT_PORT()
    local uri = P8INT:GET_MATRIX_URL() .. "/cec/key/Output/" .. port
    C4:urlPost(uri, postData)
end

function P8INT:DEVICE_POWER(on)
    local port = P8INT:GET_OUTPUT_PORT()
    local state = "on"
    if not on then
	   state = "off"
    end
    local uri = P8INT:GET_MATRIX_URL() .. "/cec/" .. state .. "/Output/" .. port
    C4:urlGet(uri)
end


--the code below is still in development and cannot be used yet.
function P8INT:UPDATE_VOLUME_LEVEL()
    local port = P8INT:GET_OUTPUT_PORT()
    
    local c4Level = ConvertVolumeToC4(50, 0, 100)
    local tParams = {LEVEL = c4Level, OUTPUT = 4000}
    
    SendNotify("VOLUME_LEVEL_CHANGED", tParams, 5001)	
end

function ConvertVolumeToC4(volume, minDeviceLevel, maxDeviceLevel)
	--to be used when converting a volume level from a device to a 
	--percentage value that can be used by C4 proxies
	--"volume" is the volume value from the device
	--"minDeviceLevel" & "maxDeviceLevel" are the minimum and maximum volume levels
	--as specified in the device protocol documentation
	return ProcessVolumeLevel(volume, minDeviceLevel, maxDeviceLevel, 0, 100)
end

function ConvertVolumeToDevice(volume, minDeviceLevel, maxDeviceLevel)
	--to be used when converting a volume level from a C4 proxy to a 
	--value that can be used by the device 
	--"volume" is the volume value from the C4 proxy
	--"minDeviceLevel" & "maxDeviceLevel" are the minimum and maximum volume levels
	--as specified in the device protocol documentation
	return ProcessVolumeLevel(volume, 0, 100, minDeviceLevel, maxDeviceLevel)
end

function ProcessVolumeLevel(volLevel, minVolLevel, maxVolLevel, minDeviceLevel, maxDeviceLevel)
	  local level = (volLevel-minVolLevel)/(maxVolLevel-minVolLevel)
	  --LogInfo("level = " .. level)
	  local vl=(level*(maxDeviceLevel-minDeviceLevel))+minDeviceLevel
	  --LogInfo("vl = " .. vl)
	  vl= tonumber(("%.".."0".."f"):format(vl))
	  --LogInfo("vl new = " .. vl)
	  LogInfo("ProcessVolumeLevel(level in=" .. volLevel .. ", level out=" .. vl .. ")")
	  return vl
end