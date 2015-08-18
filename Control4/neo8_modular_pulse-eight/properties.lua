--[[=============================================================================
    Properties Code

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]

-- This macro is utilized to identify the version string of the driver template version used.
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.properties = "2015.03.31"
end

function ON_PROPERTY_CHANGED.NetworkKeepAliveIntervalSeconds(propertyValue)
	gNetworkKeepAliveInterval = tonumber(propertyValue)

end

--[[=============================================================================
    UpdateProperty(propertyName, propertyValue)
  
    Description:
    Sets the value of the given property in the driver
  
    Parameters:
    propertyName(string)  - The name of the property to change
    propertyValue(string) - The value of the property being changed
  
    Returns:
    None
===============================================================================]]
function UpdateProperty(propertyName, propertyValue)

	if (Properties[propertyName] ~= nil) then
		C4:UpdateProperty(propertyName, propertyValue)
	end
end

