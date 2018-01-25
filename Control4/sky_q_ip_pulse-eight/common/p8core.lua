--Copyright Pulse-Eight Limited 2017

function ON_PROPERTY_CHANGED.DeviceIPAddress(propertyValue)
    P8INT:SETUP()
end

function ON_PROPERTY_CHANGED.SkyBoxType(propertyValue)
    P8INT:SETUP()
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end