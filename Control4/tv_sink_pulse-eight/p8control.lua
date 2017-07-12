function P8INT:GET_OUTPUT_PORT()
    local port = Properties["Output Port"] or "-1"
    local trimPort = string.gsub(port, "Output ", "")
    return tonumber(trimPort)-1
end

function P8INT:SEND_KEY(postData)
    local port = P8INT:GET_OUTPUT_PORT()
    local type = Properties["Port Type"] or "Output"
    local uri = P8INT:GET_MATRIX_URL() .. "/cec/key/" .. type .. "/" .. port
    C4:urlPost(uri, postData)
end

function P8INT:DEVICE_POWER(on)
    local port = P8INT:GET_OUTPUT_PORT()
    local state = "on"
    if not on then
	state = "off"
    end
    local type = Properties["Port Type"] or "Output"
    local uri = P8INT:GET_MATRIX_URL() .. "/cec/" .. state .. "/" .. type .. "/" .. port
    C4:urlGet(uri)
end