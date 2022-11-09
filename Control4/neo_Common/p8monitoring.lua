require "lib.json"

function P8INT:SEND_PULSE()
    LogTrace("Sending Monitoring Pulse")
    local uri = P8INT:GET_MATRIX_URL() .. "/Monitoring/Refresh"
    C4:urlGet(uri)
end

function P8INT:FETCH_INSTALLER_ID()
    local uri = P8INT:GET_MATRIX_URL() .. "/Monitoring/Settings"
    C4:urlGet(uri, {}, false,
	   function(ticketId, strData, responseCode, tHeaders, strError)
		  if responseCode == 200 then
			 local jsonResponse = JSON:decode(strData)
			 if jsonResponse.Result then
				UpdateProperty("Installer Id", jsonResponse.InstallerId)
			 end
		  end
	   end)
end

function ON_PROPERTY_CHANGED.InstallerId(propertyValue)
    LogTrace("Updating Installer Id to: " .. propertyValue)
    local uri = P8INT:GET_MATRIX_URL() .. "/Monitoring/SaveSettings"
    local postData = "{\"monInstallerId\": \"" .. propertyValue .. "\"}"
    C4:urlPost(uri, postData)
    P8INT:SEND_PULSE()
end
