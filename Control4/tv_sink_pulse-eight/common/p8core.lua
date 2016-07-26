--Copyright Pulse-Eight Limited 2015

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
			 ON_DRIVER_INIT.main()
		  else
			 LogWarn("Failed to discover your system, please visit www.gotomymatrix.com in your browser for more information")
		  end
	   end)
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end