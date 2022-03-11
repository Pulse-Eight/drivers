require "common.p8declares"

function OnPropertyChanged(sProperty)
	local propertyValue = Properties[sProperty]

	if (LOG ~= nil and type(LOG) == "table") then
		LogTrace("OnPropertyChanged(" .. sProperty .. ") changed to: " .. Properties[sProperty])
	end

	-- Remove any spaces (trim the property)
	local trimmedProperty = string.gsub(sProperty, " ", "")
	local status = true
	local err = ""

	if (ON_PROPERTY_CHANGED[sProperty] ~= nil and type(ON_PROPERTY_CHANGED[sProperty]) == "function") then
		status, err = pcall(ON_PROPERTY_CHANGED[sProperty], propertyValue)
	elseif (ON_PROPERTY_CHANGED[trimmedProperty] ~= nil and type(ON_PROPERTY_CHANGED[trimmedProperty]) == "function") then
		status, err = pcall(ON_PROPERTY_CHANGED[trimmedProperty], propertyValue)
	end

	if (not status) then
		LogError("LUA_ERROR: " .. err)
	end
end

function UpdateProperty(propertyName, propertyValue)
    --LogTrace("UpdateProperty("..propertyName..", "..propertyValue..") current value: "..Properties[propertyName])
	if (Properties[propertyName] ~= nil) then
		C4:UpdateProperty(propertyName, propertyValue)
	end
end