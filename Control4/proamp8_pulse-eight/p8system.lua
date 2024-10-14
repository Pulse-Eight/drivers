require "lib.json"

function P8INT:GET_DETAILS(idBinding)
    --LogTrace("Updating System Details")
    local uri = P8INT:GET_MATRIX_URL() .. "/System/Details"
    C4:urlGet(uri, {}, false, 
	   function(ticketId, strData, responseCode, tHeaders, strError)
		  if responseCode ~= 200 or strError ~= nil then
			 LogWarn("Unable to connect to system")
			 LogWarn("Error = " .. strError)
			 LogWarn("Response Code = " .. responseCode)
			 UpdateProperty("Connected To Network", "No")
			 UpdateProperty("System Status", "Unable to connect to system")
			 return
		  end
		  local jsonResponse = JSON:decode(strData)
		  if jsonResponse.Result then
			 UpdateProperty("System Status", jsonResponse.StatusMessage)
			 UpdateProperty("Connected To Network", "Yes")
			 UpdateProperty("Version", jsonResponse.Version)
			 UpdateProperty("Serial", jsonResponse.Serial)
			 if jsonResponse.Model == "PROAMP8" then
				UpdateProperty("Model", "ProAmp 8")
			 else
				UpdateProperty("Model", "Unknown Model " .. jsonResponse.Model .. " (You may have loaded the wrong driver)")
			 end
		  else
			 UpdateProperty("Model", "Unknown")
			 UpdateProperty("Version", "Unknown")
			 UpdateProperty("Serial", "Unknown")
			 UpdateProperty("Connected To Network", "No")
			 UpdateProperty("System Status", jsonResponse.ErrorMessage)
		  end
	   end)
end

function P8INT:GET_HEALTH(idBinding)
    --LogTrace("Updating Health Details")
    local uri = P8INT:GET_MATRIX_URL() .. "/System/Health"
    C4:urlGet(uri, {}, false, 
	   function(ticketId, strData, responseCode, tHeaders, strError)
		  if responseCode ~= 200 or strError ~= nil then
			 LogWarn("Unable to connect to system")
			 LogWarn("Error = " .. strError)
			 LogWarn("Response Code = " .. responseCode)
			 UpdateProperty("System Uptime", "Unknown")
			 return
		  end
		  local jsonResponse = JSON:decode(strData)
		  if jsonResponse.Result then
			 C4:SetVariable("Temp0", jsonResponse.Temperature0)
			 C4:SetVariable("Temp1", jsonResponse.Temperature1)
			 C4:SetVariable("Temp2", jsonResponse.Temperature2)
			 C4:SetVariable("Temp3", jsonResponse.Temperature3)
			 local s = jsonResponse.Uptime
			 UpdateProperty("System Uptime", string.format("%.1d days %.1d hours %.1d minutes %.2d seconds", s/(60*60*24), math.floor(s/(60*60)) - (math.floor(s/(60*60*24))*24), s/60%60, s%60))
		  else
			 UpdateProperty("System Uptime", "Unknown")
		  end
	   end)
end

function P8INT:GET_FEATURES(idBinding)
    LogTrace("Updating Features")
    local uri = P8INT:GET_MATRIX_URL() .. "/System/Features"
    C4:urlGet(uri, {}, false, 
		function(ticketId, strData, responseCode, tHeaders, strError)
			if responseCode ~= 200 or strError ~= nil then
				LogWarn("Unable to connect to system")
				LogWarn("Error = " .. strError)
				LogWarn("Response Code = " .. responseCode)
				UpdateProperty("System Uptime", "Unknown")
				return
			end
			local jsonResponse = JSON:decode(strData)
			if jsonResponse.Audio then
				if jsonResponse.Audio.Routing then 
					UpdateProperty("Routing Supported", "Yes")
					SUPPORTS_ROUTING = 1
				end
			else 
				UpdateProperty("Routing Supported", "No")
				SUPPORTS_ROUTING = 0
			end
		end)
end

function P8INT:GET_DOLBYSETTINGS(idBinding)
    LogTrace("Updating Dolby Settings")
    local uri = P8INT:GET_MATRIX_URL() .. "/amp/dolbysettings"
    C4:urlGet(uri, {}, false, 
	   function(ticketId, strData, responseCode, tHeaders, strError)
		  if responseCode ~= 200 or strError ~= nil then
			 LogWarn("Unable to connect to system")
			 LogWarn("Error = " .. strError)
			 LogWarn("Response Code = " .. responseCode)
			 UpdateProperty("System Uptime", "Unknown")
			 return
		  end
		  local jsonResponse = JSON:decode(strData)
		  if jsonResponse.Result then
		    local dMode = tonumber(jsonResponse["dolbyMode"]) or tonumber(jsonResponse["dolby_mode"])
			if dMode == nil then
			elseif dMode == 0 then 
				UpdateProperty("Dolby Mode", "Off")
				DOLBY_MODE = 0
			elseif dMode == 1 then
				UpdateProperty("Dolby Mode", "On (3 Zones)")
				DOLBY_MODE = 1
			else
				UpdateProperty("Dolby Mode", "On (4 Zones)")
				DOLBY_MODE = 2
			end
		  end
	   end)
end

function P8INT:REBOOT()
    LogInfo("Rebooting System")
    local uri = P8INT:GET_MATRIX_URL() .. "/System/Restart"
    C4:urlGet(uri)
end

function P8INT:SET_ROUTINGENABLED(value)
	ROUTING_ENABLED = value
	if(ROUTING_ENABLED == 1) then
		UpdateProperty("Routing Enabled", "Enabled")
	else 
		UpdateProperty("Routing Enabled", "Disabed")
	end
end