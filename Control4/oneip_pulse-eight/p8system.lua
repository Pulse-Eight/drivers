require "lib.json"

function P8INT:GET_HEALTH(transfer, responses, errCode, errMsg)
	--LogTrace("Updating Health Details")
	-- errCode will be 0 on success. -1 if aborted by callback, else error code
	if errCode ~= 0 or errMsg ~= nil then
		if errMsg == nil then
			errMsg = "Unknown Error"
		end
		MarkNetworkTransfer(false, "GET_HEALTH", errCode, errMsg)
		return
	end
	MarkNetworkTransfer(true)

	local jsonResponse = JSON:decode(responses[#responses].body)
	if jsonResponse.Result then
		C4:SetVariable("Temp0", jsonResponse.Temperature0)
		local s = jsonResponse.Uptime
		UpdateProperty("System Uptime", string.format("%.1d days %.1d hours %.1d minutes %.2d seconds", s/(60*60*24), math.floor(s/(60*60)) - (math.floor(s/(60*60*24))*24), s/60%60, s%60))
	else
		UpdateProperty("System Uptime", "Unknown")
	end
end

function P8INT:GET_DETAILS(transfer, responses, errCode, errMsg) 
    --LogTrace("Updating System Details")
	if errCode ~= 0 or errMsg ~= nil then
		if errMsg == nil then
			errMsg = "Unknown Error"
		end
		MarkNetworkTransfer(false, "GET_DETAILS", errCode, errMsg)
		return
	end

	local jsonResponse = JSON:decode(responses[#responses].body)
	if jsonResponse.Result then
		UpdateProperty("System Status", jsonResponse.StatusMessage)
		UpdateProperty("Version", jsonResponse.Version)
		UpdateProperty("Serial", jsonResponse.Serial)
		
		if jsonResponse.Model == "V2IP" then
			UpdateProperty("Model", "OneIP")
		end
		MarkNetworkTransfer(true)
	else
		MarkNetworkTransfer(false, "GET_DETAILS", -1, "Failed to parse response")
	end

end

function P8INT:DISCOVER()
	LogInfo("Detecting Devices")
    C4:url():Get(P8INT:GET_MATRIX_URL() .. "/v2ip/detect")
end


function P8INT:REBOOT()
    LogInfo("Rebooting System")
	C4:url():Get(P8INT:GET_MATRIX_URL() .. "/System/Restart")
end