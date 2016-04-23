function P8INT:GET_INPUT_PORT()
    local port = Properties["Input Port"] or "-1"
    local trimPort = string.gsub(port, "Input ", "")
    return tonumber(trimPort)-1
end

function P8INT:SEND_KEY(postData)
    local port = P8INT:GET_INPUT_PORT()
    local uri = P8INT:GET_MATRIX_URL() .. "/cec/key/Input/" .. P8INT:GET_INPUT_PORT()
    C4:urlPost(uri, postData)
end