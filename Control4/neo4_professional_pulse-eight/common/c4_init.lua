--[[=============================================================================
    Initial driver initialization and destruction functions

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]
require "common.c4_driver_declarations"
require "common.c4_property"

-- Set template version for this file
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.c4_init = "2015.03.02"
end

--[[=============================================================================
    OnDriverInit()

    Description
    Invoked by director when a driver is loaded. This API is provided for the
    driver developer to contain all of the driver objects that will require
    initialization.

    Parameters
    None

    Returns
    Nothing
===============================================================================]]
function OnDriverInit()
	gInitializingDriver = true
	C4:ErrorLog("INIT_CODE: OnDriverInit()")

	-- Call all ON_DRIVER_EARLY_INIT functions.
	for k,v in pairs(ON_DRIVER_EARLY_INIT) do
		if (ON_DRIVER_EARLY_INIT[k] ~= nil and type(ON_DRIVER_EARLY_INIT[k]) == "function") then
			C4:ErrorLog("INIT_CODE: ON_DRIVER_EARLY_INIT." .. k .. "()")
			local status, err = pcall(ON_DRIVER_EARLY_INIT[k])
			if (not status) then
				LogError("LUA_ERROR: " .. err)
			end
		end
	end

	-- Call all ON_DRIVER_INIT functions
	for k,v in pairs(ON_DRIVER_INIT) do
		if (ON_DRIVER_INIT[k] ~= nil and type(ON_DRIVER_INIT[k]) == "function") then
			C4:ErrorLog("INIT_CODE: ON_DRIVER_INIT." .. k .. "()")
			local status, err = pcall(ON_DRIVER_INIT[k])
			if (not status) then
				LogError("LUA_ERROR: " .. err)
			end
		end
	end

	-- Fire OnPropertyChanged to set the initial Headers and other Property
	-- global sets, they'll change if Property is changed.
	for k,v in pairs(Properties) do
		C4:ErrorLog("INIT_CODE: Calling OnPropertyChanged - " .. k .. ": " .. v)
		local status, err = pcall(OnPropertyChanged, k)
		if (not status) then
			LogError("LUA_ERROR: " .. err)
		end
	end

	gInitializingDriver = false
end

--[[=============================================================================
    OnDriverLateInit()

    Description
    Invoked by director after all drivers in the project have been loaded. This
    API is provided for the driver developer to contain all of the driver
    objects that will require initialization after all drivers in the project
    have been loaded.

    Parameters
    None

    Returns
    Nothing
===============================================================================]]
function OnDriverLateInit()
	C4:ErrorLog("INIT_CODE: OnDriverLateInit()")
	
	-- Call all ON_DRIVER_LATEINIT functions
	for k,v in pairs(ON_DRIVER_LATEINIT) do
		if (ON_DRIVER_LATEINIT[k] ~= nil and type(ON_DRIVER_LATEINIT[k]) == "function") then
			C4:ErrorLog("INIT_CODE: ON_DRIVER_LATEINIT." .. k .. "()")
			ON_DRIVER_LATEINIT[k]()
		end
	end
end


--[[=============================================================================
    OnDriverDestroyed()
    Function called by Director when a driver is removed. Release things this
    driver has allocated such as timers.

    Parameters
    None

    Returns
    Nothing
===============================================================================]]
function OnDriverDestroyed()
	C4:ErrorLog("INIT_CODE: OnDriverDestroyed()")
	
	-- Call all ON_DRIVER_DESTROYED functions
	for k, v in pairs(ON_DRIVER_DESTROYED) do
		if (ON_DRIVER_DESTROYED[k] ~= nil and type(ON_DRIVER_DESTROYED[k]) == "function") then
			C4:ErrorLog("INIT_CODE: ON_DRIVER_DESTROYED." .. k .. "()")
			ON_DRIVER_DESTROYED[k]()
		end
	end
end