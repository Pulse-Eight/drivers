--Copyright Pulse-Eight Limited 2016

function P8INT:GET_MATRIX_URL()
    local ip = Properties["Device IP Address"] or ""
    return "http://" .. ip
end

function P8INT:DISCOVER()
    C4:urlGet("http://www.gotomymatrix.com", {}, false,
	   function(ticketId, strData, responseCode, tHeaders, strError)
		  if responseCode == 302 then
			 local httpLocation = tHeaders["Location"]
			 httpLocation = string.gsub(httpLocation, "http://", "")
			 httpLocation = string.gsub(httpLocation, "/", "")
			 UpdateProperty("Device IP Address", httpLocation)
			 LogInfo("Device IP Address has been updated to: " .. httpLocation)
			 FirstRun()
		  else
			 LogWarn("Failed to discover your system, please visit www.gotomymatrix.com in your browser for more information")
		  end
	   end)
end

function P8INT:SET_ONLINE_STATUS(status)
    if (status == "offline") then
	   if (DEVICE_ONLINE == 1) then
		  C4:SetBindingStatus(6000, "offline")
		  DEVICE_ONLINE = 0
	   end
    elseif (status == "online") then
	   if (DEVICE_ONLINE == 0) then
		  C4:SetBindingStatus(6000, "online")
		  DEVICE_ONLINE = 1
	   end
    end
end

function ON_PROPERTY_CHANGED.DeviceIPAddress(propertyValue)
    C4:SetBindingAddress(6000, propertyValue)
    FirstRun()
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function OnNetworkBindingChanged( idBinding, bIsBound) 
	if (idBinding == 6000) then
		if (bIsBound == true) then
			UpdateProperty("Device IP Address", C4:GetBindingAddress (6000))
			FirstRun()
		end
	end
end