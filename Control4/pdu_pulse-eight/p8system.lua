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
			 if jsonResponse.Model == "FFMB44" then
				UpdateProperty("Model", "neo:4 Basic")
			 elseif jsonResponse.Model == "FFMS44" then
				UpdateProperty("Model", "neo:4 Professional")
			 elseif jsonResponse.Model == "MM88" then
				UpdateProperty("Model", "neo:8 Modular")
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