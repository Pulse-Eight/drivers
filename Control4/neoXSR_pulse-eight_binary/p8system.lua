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
			 P8INT:SET_ONLINE_STATUS("offline")
			 return
		  end
		  local jsonResponse = JSON:decode(strData)
		  if jsonResponse.Result then
			 UpdateProperty("System Status", jsonResponse.StatusMessage)
			 UpdateProperty("Connected To Network", "Yes")
			 UpdateProperty("Version", jsonResponse.Version)
			 UpdateProperty("Serial", jsonResponse.Serial)
			 if jsonResponse.Model == "FF64S" then
				UpdateProperty("Model", "neo:XSR")
			 else
				UpdateProperty("Model", "Unknown Model " .. jsonResponse.Model .. " (You may have loaded the wrong driver)")
			 end
			 P8INT:SET_ONLINE_STATUS("online")
		  else
			 UpdateProperty("Model", "Unknown")
			 UpdateProperty("Version", "Unknown")
			 UpdateProperty("Serial", "Unknown")
			 UpdateProperty("Connected To Network", "No")
			 UpdateProperty("System Status", jsonResponse.ErrorMessage)
			 C4:SetBindingStatus(6000, "unknown")
		  end
	   end)
end

function P8INT:GET_SOURCESINKMODE(idBinding)
     --LogTrace("Updating Source/Sink Mode")
	local uri = P8INT:GET_MATRIX_URL() .. "/Audio/SinkMode"
	C4:urlGet(uri, {}, false,
	   function(ticketId, strData, responseCode, tHeaders, strError)
			if responseCode ~= 200 or strError ~= nil then
				LogWarn("Unable to connect to system")
				LogWarn("Error = " .. strError or "Unknown Error")
				LogWarn("Response Code = " .. responseCode)
				UpdateProperty("System Uptime", "Unknown")
				C4:SetBindingStatus(6000, "offline")
				return
			end
			local jsonResponse = JSON:decode(strData)
			if jsonResponse.Result then
				if jsonResponse.SinkMode == true then
				    MODE_SINK = 1
				    UpdateProperty("Routing Mode", "Sink Mode")
				else
				    MODE_SINK = 0
				    UpdateProperty("Routing Mode", "Source Mode")
				end
			end
		end)
end

function P8INT:GET_POWERON_ON_ROUTING_CHANGE(idBinding)
     --LogTrace("Getting autopoweron")
	local uri = P8INT:GET_MATRIX_URL() .. "/CEC/AutoPowerOn"
	C4:urlGet(uri, {}, false,
	   function(ticketId, strData, responseCode, tHeaders, strError)
			if responseCode ~= 200 or strError ~= nil then
				LogWarn("Unable to connect to system")
				LogWarn("Error = " .. strError or "Unknown Error")
				LogWarn("Response Code = " .. responseCode)
				UpdateProperty("System Uptime", "Unknown")
				C4:SetBindingStatus(6000, "offline")
				return
			end
			local jsonResponse = JSON:decode(strData)
			--LogTrace(jsonResponse)
			if jsonResponse.Result then
				if jsonResponse.Setting == true then
				    MODE_POWERON_ON_ROUTING_CHANGE = 1
				    UpdateProperty("Send CEC ON during route change", "Yes")
				else
				    MODE_POWERON_ON_ROUTING_CHANGE = 0
				    UpdateProperty("Send CEC ON during route change", "No")
				end
			end
		end)
end

function P8INT:SET_POWERON_ON_ROUTING_CHANGE(value)
     --LogTrace("Setting autopoweron")
	local uri = P8INT:GET_MATRIX_URL() .. "/CEC/AutoPowerOn"
	local postData = {}
	if value == 1 then
	   postData["Setting"] = true
     else
	   postData["Setting"] = false
     end
	C4:urlPost(uri, JSON:encode(postData), {}, false,
	   function(ticketId, strData, responseCode, tHeaders, strError)
			if responseCode ~= 200 or strError ~= nil then
				LogWarn("Unable to connect to system")
				LogWarn("Error = " .. strError or "Unknown Error")
				LogWarn("Response Code = " .. responseCode)
				UpdateProperty("System Uptime", "Unknown")
				C4:SetBindingStatus(6000, "offline")
				return
		     else
				MODE_POWERON_ON_ROUTING_CHANGE = value
			end
		end)
end

-- SETSOURCESINKMODE(value) expects a value of 1 for Sink Mode, 0 for Source Mode
function P8INT:SET_SOURCESINKMODE(value)
     --LogTrace("Setting Source/Sink Mode")
	local uri = P8INT:GET_MATRIX_URL() .. "/Audio/SinkMode/"..value
	C4:urlGet(uri, {}, false,
	   function(ticketId, strData, responseCode, tHeaders, strError)
			if responseCode ~= 200 or strError ~= nil then
				LogWarn("Unable to connect to system")
				LogWarn("Error = " .. strError or "Unknown Error")
				LogWarn("Response Code = " .. responseCode)
				UpdateProperty("System Uptime", "Unknown")
				C4:SetBindingStatus(6000, "offline")
				return
			else
				MODE_SINK = value
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
				LogWarn("Error = " .. strError or "Unknown Error")
				LogWarn("Response Code = " .. responseCode)
				UpdateProperty("System Uptime", "Unknown")
				C4:SetBindingStatus(6000, "offline")
				return
			end
			local jsonResponse = JSON:decode(strData)
			if jsonResponse.Result then
				C4:SetVariable("Temp0", jsonResponse.Temperature0)
				local s = jsonResponse.Uptime
				C4:SetBindingStatus(6000, "online")
				UpdateProperty("System Uptime", string.format("%.1d days %.1d hours %.1d minutes %.2d seconds", s/(60*60*24), math.floor(s/(60*60)) - (math.floor(s/(60*60*24))*24), s/60%60, s%60))
			else
				C4:SetBindingStatus(6000, "unknown")
				UpdateProperty("System Uptime", "Unknown")
			end
		end)
end

function P8INT:REBOOT()
    LogInfo("Rebooting System")
    local uri = P8INT:GET_MATRIX_URL() .. "/System/Restart"
    C4:urlGet(uri)
end