require "lib.json"

function P8INT:GET_DETAILS(idBinding)
    LogTrace("Updating System Details")
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
			 if jsonResponse.Model == "FF88S" then
				UpdateProperty("Model", "neo:X")
			 elseif jsonResponse.Model == "FF88SA" then
				UpdateProperty("Model", "neo:X+")
			 else
				UpdateProperty("Model", "Unknown Model " .. jsonResponse.Model .. " (You may have loaded the wrong driver")
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
    LogTrace("Updating Health Details")
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
			 local s = jsonResponse.Uptime
			 UpdateProperty("System Uptime", string.format("%.1d days %.1d hours %.1d minutes %.2d seconds", s/(60*60*24), math.floor(s/(60*60)) - (math.floor(s/(60*60*24))*24), s/60%60, s%60))
		  else
			 UpdateProperty("System Uptime", "Unknown")
		  end
	   end)
end

function P8INT:REBOOT()
    LogInfo("Rebooting System")
    local uri = P8INT:GET_MATRIX_URL() .. "/System/Restart"
    C4:urlGet(uri)
end