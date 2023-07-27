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
--		UpdateProperty("Connected To Network", "Yes")
		UpdateProperty("Version", jsonResponse.Version)
		UpdateProperty("Serial", jsonResponse.Serial)
		if jsonResponse.Model == "FF88S" then
			UpdateProperty("Model", "neo:X")
		elseif jsonResponse.Model == "FF88SA" then
			UpdateProperty("Model", "neo:X+")
		elseif jsonResponse.Model == "FF66SA" then
			UpdateProperty("Model", "neo:XMR")
		elseif jsonResponse.Model == "FF64S" then
			UpdateProperty("Model", "neo:XSR")
		elseif jsonResponse.Model == "FF88" then
			UpdateProperty("Model", "neo:8")
		elseif jsonResponse.Model == "FF88A" then
			UpdateProperty("Model", "neo:8a")
		elseif jsonResponse.Model == "FF66A" then
			UpdateProperty("Model", "neo:6")
		elseif jsonResponse.Model == "FFMS44" then
			UpdateProperty("Model", "neo:4 Professional")
		elseif jsonResponse.Model == "FFMB44" then
			UpdateProperty("Model", "neo:4 Basic")
		elseif jsonResponse.Model == "MM88" then
			UpdateProperty("Model", "neo:8 Modular")
		else
			UpdateProperty("Model", "Unknown Model " .. jsonResponse.Model .. " (You may have loaded the wrong driver)")
		end
		MarkNetworkTransfer(true)
	else
		MarkNetworkTransfer(false, "GET_DETAILS", -1, "Failed to parse response")
	end

end

function P8INT:GET_FEATURES(transfer, responses, errCode, errMsg) 
    --LogTrace("Updating System Features")
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
		
		if jsonResponse.Audio.SupportManualMode == true then
			MODE_MANUALMODE_SUPPORTED = 1
		else
			MODE_MANUALMODE_SUPPORTED = 0
		end
		HideManualModeOption(MODE_MANUALMODE_SUPPORTED)
		MarkNetworkTransfer(true)
	else
		MarkNetworkTransfer(false, "GET_FEATURES", -1, "Failed to parse response")
	end

end

function P8INT:GET_SOURCESINKMODE(transfer, responses, errCode, errMsg)
	--LogTrace("Updating Source/Sink Mode")
	
	if errCode == 0 then 
		local jsonResponse = JSON:decode(responses[#responses].body)
		if jsonResponse.Result then
			if jsonResponse.SinkMode == true then
				MODE_SINK = 1
				UpdateProperty("Routing Mode", "Sink Mode")
			else
				MODE_SINK = 0
				MODE_MANUALMODE = 0
				UpdateProperty("Routing Mode", "Source Mode")
			end
		end
		HideManualModeOption(MODE_SINK)
		MarkNetworkTransfer(true)
	else
		MarkNetworkTransfer(false, "GET_SOURCESINKMODE", -2473, "Failed to get source/sink mode option")
		if MODE_SINK == 1 then
			UpdateProperty("Routing Mode", "Sink Mode")
		else 
			UpdateProperty("Routing Mode", "Source Mode")
		end
	end
end

function P8INT:GET_MANUALMODE(transfer, responses, errCode, errMsg)
	--LogTrace("Updating Manual Mode")
	
	if errCode == 0 then 
		local jsonResponse = JSON:decode(responses[#responses].body)
		if jsonResponse.Result then
			if jsonResponse.manual_mode == true then
				MODE_MANUALMODE = 1
				UpdateProperty("Independent Routing", "Enabled")
			else
				MODE_MANUALMODE = 0
				UpdateProperty("Independent Routing", "Disabled")
			end
		end
		MarkNetworkTransfer(true)
	else
		MarkNetworkTransfer(false, "GET_SOURCESINKMODE", -2476, "Failed to get manual mode option")
		if MODE_MANUALMODE == 1 then
			UpdateProperty("Independent Routing", "Enabled")
		else 
			UpdateProperty("Routing Mode", "Source Mode")
		end
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
		MarkNetworkTransfer(false, "GET_SOURCESINKMODE", -2474, "Failed to get poweron option")
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
    --LogTrace("SET_CEC_SWITCHING_SUPPORT(" .. value .. ")")
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


function P8INT:SET_MANUALMODE(value)
    --LogTrace("SET_MANUALMODE(" .. value .. ")")
	local url = P8INT:GET_MATRIX_URL()
	if value == 1 then
		url = url .. "/Audio/ManualMode/1"
	else
		url = url .. "/Audio/ManualMode/0"
	end
	
	local t = C4:url() -- must create a new ticket every time
		:SetOption("timeout", 15)
		:OnDone(function(transfer, responses, errCode, errMsg)
				if errCode == 0 then 
					MODE_MANUALMODE = value
					MarkNetworkTransfer(true)
				else
					MarkNetworkTransfer(false, "SET_MANUALMODE", -2477, "Failed to change Manual Mode")
					if MODE_MANUALMODE == 1 then
						UpdateProperty("Independent Routing", "Enabled")
					else
						UpdateProperty("Independent Routing", "Disabled")
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

function HideManualModeOption(value) 
	value = 1 - value
	C4:SetPropertyAttribs("Independent Routing", value)
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

-- SETSOURCESINKMODE(value) expects a value of 1 for Sink Mode, 0 for Source Mode
function P8INT:SET_SOURCESINKMODE(value)
	--LogTrace("SET_SOURCESINKMODE(" .. value .. ")")
	local url = P8INT:GET_MATRIX_URL() .. "/Audio/SinkMode/" ..value
	local t = C4:url() -- must create a new ticket every time
		:SetOption("timeout", 15)
		:OnDone(function(transfer, responses, errCode, errMsg)
				if errCode == 0 then 
					MODE_SINK = value
					MarkNetworkTransfer(true)
				else
					MarkNetworkTransfer(false, "SET_SOURCESINKMODE", -2475, "Failed to change poweronroutingchange")
					if MODE_SINK == 1 then
						UpdateProperty("Routing Mode", "Sink Mode")
					else
						UpdateProperty("Routing Mode", "Source Mode")
					end
				end
			end)
		:Get(url)

end


function P8INT:REBOOT()
    LogInfo("Rebooting System")
	C4:url():Get(P8INT:GET_MATRIX_URL() .. "/System/Restart")
end