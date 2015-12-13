--Copyright Pulse-Eight Limited 2015

function P8INT:GET_MATRIX_URL()
    local ip = Properties["Device IP Address"] or ""
    return "http://" .. ip
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end