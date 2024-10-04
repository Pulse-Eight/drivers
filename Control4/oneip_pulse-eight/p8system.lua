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
			MODE_SINK_SUPPORTED = 1
		end
		MarkNetworkTransfer(true)
	else
		MarkNetworkTransfer(false, "GET_DETAILS", -1, "Failed to parse response")
	end

end

function P8INT:GET_FEATURES(transfer, responses, errCode, errMsg) 
    LogTrace("Updating System Features")
	if errCode ~= 0 or errMsg ~= nil then
		if errMsg == nil then
			errMsg = "Unknown Error"
		end
		MarkNetworkTransfer(false, "GET_FEATURES", errCode, errMsg)
		return
	end

	local jsonResponse = JSON:decode(responses[#responses].body)
	if jsonResponse.Result then
		if jsonResponse.CEC == true then
			UpdateProperty("CEC Support", "Enabled")
			MODE_CEC_ENABLED = 1
		else
			UpdateProperty("CEC Support", "Disabled")
			MODE_CEC_ENABLED = 0
		end
		HideCecOptions(MODE_CEC_ENABLED)
		if jsonResponse.CEC_Switching == true then
			UpdateProperty("CEC Switching Support", "Enabled")
			MODE_CEC_SWITCHING = 1
		else
			UpdateProperty("CEC Switching Support", "Disabled")
			MODE_CEC_SWITCHING = 1
		end		
		
		MarkNetworkTransfer(true)
	else
		MarkNetworkTransfer(false, "GET_FEATURES", -1, "Failed to parse response")
	end

end

function P8INT:GET_POWERON_ON_ROUTING_CHANGE(transfer, responses, errCode, errMsg)
	if errCode == 0 then 
		local jsonResponse = JSON:decode(responses[#responses].body)
		if jsonResponse.Result then
			if jsonResponse.Setting == true then
				MODE_POWERON_ON_ROUTING_CHANGE = 1
				UpdateProperty("Send CEC ON during route change", "Yes")
			else
				MODE_POWERON_ON_ROUTING_CHANGE = 0
				UpdateProperty("Send CEC ON during route change", "No")
			end
		end
		MarkNetworkTransfer(true)
	else
		MarkNetworkTransfer(false, "GET_POWERON_ON_ROUTING_CHANGE", -2474, "Failed to get poweron option")
		if MODE_POWERON_ON_ROUTING_CHANGE == 1 then
			UpdateProperty("Send CEC ON during route change", "Yes")
		else 
			UpdateProperty("Send CEC ON during route change", "No")
		end
	end
end


function P8INT:SET_CEC_ENABLED(value)
    --LogTrace("SET_CEC_ENABLED(" .. value .. ")")
	local url = P8INT:GET_MATRIX_URL()
	if value == 1 then
		url = url .. "/CEC/enable"
	else
		url = url .. "/CEC/disable"
	end
	
	local t = C4:url() -- must create a new ticket every time
		:SetOption("timeout", 15)
		:OnDone(function(transfer, responses, errCode, errMsg)
				if errCode == 0 then 
					MODE_CEC_ENABLED = value
					MarkNetworkTransfer(true)
				else
					MarkNetworkTransfer(false, "SET_CEC_ENABLED", -2471, "Failed to change CEC mode")
					if MODE_CEC_ENABLED == 1 then
						UpdateProperty("CEC Support", "Enabled")
					else
						UpdateProperty("CEC Support", "Disabled")
					end
				end
				HideCecOptions(MODE_CEC_ENABLED)
			end)
		:Get(url)
end

function P8INT:SET_CEC_SWITCHING_SUPPORT(value)
    LogTrace("SET_CEC_SWITCHING_SUPPORT(" .. value .. ")")
	local url = P8INT:GET_MATRIX_URL()
	if value == 1 then
		url = url .. "/CEC/switching/on"
	else
		url = url .. "/CEC/switching/off"
	end
	
	local t = C4:url() -- must create a new ticket every time
		:SetOption("timeout", 15)
		:OnDone(function(transfer, responses, errCode, errMsg)
				if errCode == 0 then 
					MODE_CEC_SWITCHING = value
					MarkNetworkTransfer(true)
				else
					MarkNetworkTransfer(false, "SET_CEC_SWITCHING_SUPPORT", -2472, "Failed to change CEC switching support")
					if MODE_CEC_SWITCHING == 1 then
						UpdateProperty("CEC Switching Support", "Enabled")
					else
						UpdateProperty("CEC Switching Support", "Disabled")
					end
				end
			end)
		:Get(url)
end

function HideCecOptions(value) 
	value = 1 - value
	C4:SetPropertyAttribs("CEC Switching Support", value)
	C4:SetPropertyAttribs("Send CEC ON during route change", value)
	C4:SetPropertyAttribs("Send CEC OFF on zone off", value)
end

function P8INT:SET_POWERON_ON_ROUTING_CHANGE(value)
	--LogTrace("SET_POWERON_ON_ROUTING_CHANGE(" .. value .. ")")
	local url = P8INT:GET_MATRIX_URL() .. "/CEC/AutoPowerOn"
	local postData = {}
	postData["Setting"] = (value == 1)
	local t = C4:url() -- must create a new ticket every time
		:SetOption("timeout", 15)
		:OnDone(function(transfer, responses, errCode, errMsg)
				if errCode == 0 then 
					MODE_POWERON_ON_ROUTING_CHANGE = value
					MarkNetworkTransfer(true)
				else
					MarkNetworkTransfer(false, "SET_POWERON_ON_ROUTING_CHANGE", -2475, "Failed to change poweronroutingchange")
					if MODE_POWERON_ON_ROUTING_CHANGE == 1 then
						UpdateProperty("Send CEC ON during route change", "Yes")
					else
						UpdateProperty("Send CEC ON during route change", "No")
					end
				end
			end)
		:Post(url, JSON:encode(postData))
end

function P8INT:DISCOVER()
	LogInfo("Detecting Devices")
    C4:url():Get(P8INT:GET_MATRIX_URL() .. "/v2ip/detect")
end


function P8INT:REBOOT()
    LogInfo("Rebooting System")
	C4:url():Get(P8INT:GET_MATRIX_URL() .. "/System/Restart")
end