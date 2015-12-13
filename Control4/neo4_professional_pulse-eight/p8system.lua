require "lib.json"

function P8INT:GET_HEALTH(idBinding)
    LogTrace("Updating System Health")
    local uri = P8INT:GET_MATRIX_URL() .. "/System/Details"
    C4:urlGet(uri, {}, false, 
	   function(ticketId, strData, responseCode, tHeaders, strError)
		  if responseCode ~= 200 or strError ~= nil then
			 LogWarn("Unable to connect to system")
			 LogWarn("Error = " .. strError)
			 LogWarn("Response Code = " .. responseCode)
			 UpdateProperty("System Status", "Unable to connect to system")
			 return
		  end
		  local jsonResponse = JSON:decode(strData)
		  if jsonResponse.Result then
			 UpdateProperty("System Status", jsonResponse.StatusMessage)
			 UpdateProperty("Connected To Network", "Yes")
			 UpdateProperty("Version", jsonResponse.Version)
			 if jsonResponse.Model == "FFMB44" then
				UpdateProperty("Model", "neo:4 Basic")
			 elseif jsonResponse.Model == "FFMS44" then
				UpdateProperty("Model", "neo:4 Professional")
			 else
				UpdateProperty("Model", "Unknown Model " .. jsonResponse.Model .. " (You may have loaded the wrong driver")
			 end
		  else
			 UpdateProperty("Model", "Unknown")
			 UpdateProperty("Version", "Unknown")
			 UpdateProperty("Connected To Network", "No")
			 UpdateProperty("System Status", jsonResponse.ErrorMessage)
		  end
	   end)
end