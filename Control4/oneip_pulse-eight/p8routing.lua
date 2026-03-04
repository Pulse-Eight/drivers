--Copyright Pulse-Eight Limited 2021

require "lib.json"

local gP8ProxyId

local audioLocked = {
    AUDIOOUTPUT0 = 0,
    AUDIOOUTPUT1 = 0,
    AUDIOOUTPUT2 = 0,
    AUDIOOUTPUT3 = 0,
    AUDIOOUTPUT4 = 0,
    AUDIOOUTPUT5 = 0,
    AUDIOOUTPUT6 = 0,
    AUDIOOUTPUT7 = 0,
    AUDIOOUTPUT8 = 0,
    AUDIOOUTPUT9 = 0
}

local routes = {}
local binding_to_key = {}
local key_to_binding = {}

local function make_key(uid, port_name)
    return uid .. ':' .. port_name
end

function table.contains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end

function dump(o, indent)
    indent = indent or 0
    local ind_str = string.rep(' ', indent)
    if type(o) == 'table' then
        local s = '{'
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '\n' .. ind_str .. ' [' .. k .. '] = ' .. dump(v, indent + 1) .. ','
        end
        return s .. '\n' .. ind_str .. '}'
    else
        return tostring(o)
    end
end

local function build_input_mappings(input_bays, ports)
    local binding_to_key = {}
    local key_to_binding = {}

    -- Video inputs
    local video_in_base = 1000
    local video_port_types = {"hdmi-in-0", "hdmi-in-1", "hdmi-in-2"}
    local block_size = 32
    local range_end = 1099
    for idx, port_type in ipairs(video_port_types) do
        local offset = (idx - 1) * block_size
        for _, bay in ipairs(input_bays) do
            local key = make_key(bay.uid, port_type)
            if ports[key] or table.contains(bay.children, port_type) then
                local binding = video_in_base + offset + bay.bay
                if binding <= range_end then
                    binding_to_key[binding] = key
                    key_to_binding[key] = binding
                end
            end
        end
    end

    -- Audio inputs
    local audio_in_base = 3000
    local audio_port_types = {"rca-in-0", "spdif-in-0"}
    local range_end = 3099
    for idx, port_type in ipairs(audio_port_types) do
        local offset = (idx - 1) * block_size
        for _, bay in ipairs(input_bays) do
            local key = make_key(bay.uid, port_type)
            if ports[key] or table.contains(bay.children, port_type) then
                local binding = audio_in_base + offset + bay.bay
                if binding <= range_end then
                    binding_to_key[binding] = key
                    key_to_binding[key] = binding
                end
            end
        end
    end

    return binding_to_key, key_to_binding
end

local function build_output_mappings(output_bays, ports)
    local binding_to_key = {}
    local key_to_binding = {}

    -- Video outputs
    local video_out_base = 2000
    local video_port_types = {"hdmi-out-0", "hdmi-out-1"}
    local block_size = 64
    local range_end = 2999
    for idx, port_type in ipairs(video_port_types) do
        local offset = (idx - 1) * block_size
        for _, bay in ipairs(output_bays) do
            local key = make_key(bay.uid, port_type)
            if ports[key] or table.contains(bay.children, port_type) then
                local binding = video_out_base + offset + bay.bay
                if binding <= range_end then
                    binding_to_key[binding] = key
                    key_to_binding[key] = binding
                end
            end
        end
    end

    -- Audio outputs
    local audio_out_base = 4000
    local audio_port_types = {"spdif-out-0", "rca-out-0", "spdif-out-1"}
    local range_end = 4999
    for idx, port_type in ipairs(audio_port_types) do
        local offset = (idx - 1) * block_size
        for _, bay in ipairs(output_bays) do
            local key = make_key(bay.uid, port_type)
            if ports[key] or table.contains(bay.children, port_type) then
                local binding = audio_out_base + offset + bay.bay
                if binding <= range_end then
                    binding_to_key[binding] = key
                    key_to_binding[key] = binding
                end
            end
        end
    end

    return binding_to_key, key_to_binding
end

local function process_audio_json(jsonResponse)
	LogDebug("process_audio_json: starting with " .. #jsonResponse.devices .. " devices")
    local temp_all_ports = {}
    local temp_inputs = {}
    local temp_outputs = {}
    local temp_tx_ports = {}
    local temp_rx_ports = {}
    local temp_input_bays = {}
    local temp_output_bays = {}
    for _, device in ipairs(jsonResponse.devices) do
        local dev_id = device.id
        local uid = device.uid
        for _, port in ipairs(device.inputs or {}) do
            local name = port.name
            local key = make_key(uid, name)
            temp_all_ports[key] = {
                device_id = dev_id,
                uid = uid,
                path = port.path,
                name = name,
                features = port.features,
                type = 'input',
                id = port.id,  -- Added to store port.id
                output_selected = port.output and port.output.selected or nil,
                output_supported = port.output and port.output.supported or nil,
                address = port.address,
                mediabay = port.mediabay,
                parent = port.parent,
                children = port.children
            }
            table.insert(temp_inputs, key)
            if port.features and table.contains(port.features, 'v2ip rx') then
                table.insert(temp_rx_ports, key)
                if port.mediabay and port.mediabay.mode == "Output" then
                    table.insert(temp_output_bays, {
                        bay = port.mediabay.bay,
                        uid = uid,
                        mediabay_key = key,
                        children = port.children or {}
                    })
                end
            end
        end
        for _, port in ipairs(device.outputs or {}) do
            local name = port.name
            local key = make_key(uid, name)
            temp_all_ports[key] = {
                device_id = dev_id,
                uid = uid,
                path = port.path,
                name = name,
                features = port.features,
                type = 'output',
                id = port.id,  -- Added to store port.id
                input_selected = port.input and port.input.selected or nil,
                input_supported = port.input and port.input.supported or nil,
                address = port.address,
                mediabay = port.mediabay,
                children = port.children,
                mute = port.mute
            }
            table.insert(temp_outputs, key)
            if port.features and table.contains(port.features, 'v2ip tx') then
                table.insert(temp_tx_ports, key)
                if port.mediabay and port.mediabay.mode == "Input" then
                    table.insert(temp_input_bays, {
                        bay = port.mediabay.bay,
                        uid = uid,
                        mediabay_key = key,
                        children = port.children or {}
                    })
                end
            end
        end
    end
    table.sort(temp_input_bays, function(a, b) return a.bay < b.bay end)
    table.sort(temp_output_bays, function(a, b) return a.bay < b.bay end)
	
	LogDebug(string.format("Collected %d input bays and %d output bays", #temp_input_bays, #temp_output_bays))
	
    if #temp_input_bays > 32 then end
    if #temp_output_bays > 64 then end
    local forward_adj = {}
    for key, _ in pairs(temp_all_ports) do
        forward_adj[key] = {}
    end
    for key, port in pairs(temp_all_ports) do
		if port.type == 'output' then
			if string.match(port.name, "^v2ip%-tx") then
				for _, sname in ipairs({"hdmi-in-0", "spdif-in-0", "rca-in-0"}) do
					local source_key = make_key(port.uid, sname)
					if temp_all_ports[source_key] then
						table.insert(forward_adj[source_key], key)
					end
				end
				if port.input_supported then
					for _, supp_name in ipairs(port.input_supported) do
						local source_key = make_key(port.uid, supp_name)
						if temp_all_ports[source_key] then
							table.insert(forward_adj[source_key], key)
						end
					end
				end
			else
				-- Regular sinks (hdmi-out-*, spdif-out-*, rca-out-*): always local v2ip-rx-0 + explicit if present
				local rx_key = make_key(port.uid, "v2ip-rx-0")
				if temp_all_ports[rx_key] then
					table.insert(forward_adj[rx_key], key)
				end
				if port.input_supported then
					for _, supp_name in ipairs(port.input_supported) do
						local source_key = make_key(port.uid, supp_name)
						if temp_all_ports[source_key] then
							table.insert(forward_adj[source_key], key)
						end
					end
				end
			end
		end
	end
    for _, tx_key in ipairs(temp_tx_ports) do
        for _, rx_key in ipairs(temp_rx_ports) do
            table.insert(forward_adj[tx_key], rx_key)
        end
    end
    local reverse_adj = {}
    for key, _ in pairs(temp_all_ports) do
        reverse_adj[key] = {}
    end
    for from_key, targets in pairs(forward_adj) do
        for _, to_key in ipairs(targets) do
            table.insert(reverse_adj[to_key], from_key)
        end
    end
    local temp_routes = {}
    for _, sink_key in ipairs(temp_outputs) do
        local sink_port = temp_all_ports[sink_key]
        if not string.match(sink_port.name, "^v2ip%-tx%-") then
            temp_routes[sink_key] = {}
            local queue = {sink_key}
            local visited = {[sink_key] = true}
            local index = 1
            while index <= #queue do
                local current = queue[index]
                index = index + 1
                for _, prev_key in ipairs(reverse_adj[current] or {}) do
                    if not visited[prev_key] then
                        visited[prev_key] = true
                        table.insert(queue, prev_key)
                    end
                end
            end
            for key, _ in pairs(visited) do
                local src_port = temp_all_ports[key]
                if src_port.type == 'input' and key ~= sink_key and not string.match(src_port.name, "^v2ip%-rx%-") then
                    table.insert(temp_routes[sink_key], key)
                end
            end
            table.sort(temp_routes[sink_key])
        end
    end
    local input_binding_to_key, input_key_to_binding = build_input_mappings(temp_input_bays, temp_all_ports)
    local output_binding_to_key, output_key_to_binding = build_output_mappings(temp_output_bays, temp_all_ports)
    local temp_binding_to_key = {}
    local temp_key_to_binding = {}
    for k, v in pairs(input_binding_to_key) do temp_binding_to_key[k] = v end
    for k, v in pairs(output_binding_to_key) do temp_binding_to_key[k] = v end
    for k, v in pairs(input_key_to_binding) do temp_key_to_binding[k] = v end
    for k, v in pairs(output_key_to_binding) do temp_key_to_binding[k] = v end
	LogDebug("process_audio_json: mappings built successfully")
    return temp_routes, temp_binding_to_key, temp_key_to_binding
end


function GetMyProxyId()
    local proxyIdList = C4:GetBoundConsumerDevices(0, DEFAULT_PROXY_BINDINGID)
    local proxyId
    if (proxyIdList ~= nil) then
        for id, name in pairs(proxyIdList) do
            LogWarn("Proxy Id Discovered: " .. id)
            gP8ProxyId = id --only 1?
        end
    end
end

function P8INT:UPDATE_AUDIO_STATE(transfer, responses, errCode, errMsg) 
	errCode = errCode or 0
    errMsg  = errMsg or ""
	
    if errCode ~= 0 then
        LogError(string.format("UPDATE_AUDIO_STATE failed - transport error (errCode=%s, msg=%s)", 
            tostring(errCode), tostring(errMsg or "")))
        MarkNetworkTransfer(false, "UPDATE_AUDIO_STATE", errCode, errMsg or "Transport error")
        return
    end

    if not responses or #responses == 0 then
        LogWarn("UPDATE_AUDIO_STATE: no responses received")
        MarkNetworkTransfer(false, "UPDATE_AUDIO_STATE", -2501, "No response")
        return
    end
	
	local body = responses[#responses].body
    if not body or body == "" then
        LogWarn("UPDATE_AUDIO_STATE: empty response body")
        return
    end
	
	local success, jsonResponse = pcall(JSON.decode, JSON, body)
    if not success then
        LogError("UPDATE_AUDIO_STATE: JSON decode failed")
        LogDebug("Body snippet: " .. (body:sub(1, 250) or ""))
        return
    end
	
	if not jsonResponse.Result or type(jsonResponse.devices) ~= "table" then
		LogWarn("UPDATE_AUDIO_STATE: invalid API response - missing Result or devices array")
		return
    end
	
    success, new_routes, new_binding_to_key, new_key_to_binding = pcall(process_audio_json, jsonResponse)
    if not success then
        LogError(string.format("UPDATE_AUDIO_STATE: process_audio_json crashed - %s", tostring(new_routes)))
        return
    end
	
    routes = new_routes
    binding_to_key = new_binding_to_key
    key_to_binding = new_key_to_binding
	LogInfo(string.format("UPDATE_AUDIO_STATE: successfully processed %d devices", #jsonResponse.devices))
end

function P8INT:IS_ROUTE_VALID(idBinding, tParams) 
	local provider_class    	= tParams["Provider_sClass"]
	local consumer_idBinding 	= tonumber(tParams["Consumer_idBinding"])
	local provider_idBinding 	= tonumber(tParams["Provider_idBinding"])
	local consumer_class    	= tParams["Consumer_sClass"]
	local roomID			= tonumber(tParams["Params_idRoom"])

	if not consumer_idBinding or not provider_idBinding then
		LogTrace("IS_ROUTE_VALID: missing Consumer or Provider binding")
        return "False"
    end

	local source_key = binding_to_key[consumer_idBinding]
    local sink_key = binding_to_key[provider_idBinding]
	
	if not sink_key or not source_key then
        LogDebug(string.format("IS_ROUTE_VALID: unmapped binding consumer=%d provider=%d", consumer_idBinding, provider_idBinding))
        return "False"
    end
	
	local valid = table.contains(routes[sink_key] or {}, source_key)
    LogTrace(string.format("IS_ROUTE_VALID: %d -> %d = %s", provider_idBinding, consumer_idBinding, valid and "True" or "False"))
    return valid and "True" or "False"
end

function P8INT:PORT_SET(idBinding, tParams)
	LogTrace("PORT_SET entered - idBinding=" .. tostring(idBinding))
    LogTrace("tParams: " .. dump(tParams))
    local input = tonumber(tParams["INPUT"] % 1000)
    local output = tonumber(tParams["OUTPUT"] % 1000)
    local input_id = tonumber(tParams["INPUT"])
    local class = tParams["CLASS"]
    local output_id = tonumber(tParams["OUTPUT"])
    local bSwitchSeparate = tParams["SWITCH_SEPARATE"]
    CancelRoutingPoll()
    local ticket = C4:url():SetOption("timeout", 15)
    if class == "VIDEO_SELECTION" or class == "HDMI" or class == nil then
        LogInfo(string.format("Setting VIDEO route: %d → %d", input_id, output_id))
        ticket:OnDone(
            function(transfer, responses, errCode, errMsg)
				PermitRoutingPoll()
                if errCode == 0 then
                    SendNotify("INPUT_OUTPUT_CHANGED", tParams, idBinding)
                    MarkNetworkTransfer(true)
                else
                    MarkNetworkTransfer(false, "PORT_SET", -2501, "Failed to set port")
                end
            end
        ):Get(P8INT:GET_MATRIX_URL() .. "/Port/Set/" .. input .. "/" .. output)
    else
		-- If the port is locked, force the input to the locked input.
		-- TODO: Check locking
		LogInfo(string.format("Setting AUDIO route: binding %d → %d", input_id, output_id))
        local source_key = binding_to_key[input_id]
        local sink_key = binding_to_key[output_id]
        
		if not source_key or not sink_key then
			LogError(string.format("PORT_SET audio: no mapping for input=%d output=%d", input_id, output_id))
            PermitRoutingPoll()
            MarkNetworkTransfer(false, "PORT_SET", -2501, "Invalid binding mapping")
            return
        end
		
		LogTrace(string.format("Resolved keys - Sink: %s | Source: %s", sink_key, source_key))
		
		local url = P8INT:GET_MATRIX_URL() .. "/audio/select/" .. sink_key .. "/" .. source_key
        LogTrace("Calling: " .. url)
		
		ticket:OnDone(function(transfer, responses, errCode, errMsg)
            PermitRoutingPoll()
            if errCode == 0 then
                LogInfo("Audio route set successfully")
                SendNotify("INPUT_OUTPUT_CHANGED", tParams, idBinding)
                MarkNetworkTransfer(true)
            else
                LogError(string.format("Audio route failed (errCode=%d)", errCode))
                MarkNetworkTransfer(false, "PORT_SET", -2501, "Failed to set audio")
            end
        end):Get(url)
    end
end


function P8INT:PRINT_ROUTES()
	print("=== Current Routes Table ===")
	print(dump(routes))
end

function P8INT:PRINT_BTK()
	print("=== Binding to Key Table ===")
	print(dump(binding_to_key))
end

function P8INT:PRINT_KTB()
	print("=== Binding to Key Table ===")
	print(dump(key_to_binding))
end
