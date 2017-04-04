function P8INT:REBOOT_OUTLET(outletNumber)
    local uri = P8INT:GET_MATRIX_URL() .. "/power/reboot/" .. outletNumber
    C4:urlGet(uri)
end