--[[=============================================================================
    ON_INIT, Timer,s and Property management functions

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]
require "common.c4_driver_declarations"
require "lib.c4_log"
require "lib.c4_timer"

-- Set template version for this file
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.c4_common = "2015.03.02"
end

--[[=============================================================================
    Create and Initialize Logging
===============================================================================]]
function ON_DRIVER_EARLY_INIT.c4_common()
	-- Create a logger
	LOG = c4_log:new("Template_c4z Change Name")
end

function ON_DRIVER_INIT.c4_common()
	-- Create Log Timer
	gC4LogTimer = c4_timer:new("Log Timer", 45, "MINUTES", OnLogTimerExpired)
end

--[[=============================================================================
    Log timer callback function
===============================================================================]]
function OnLogTimerExpired()
	LogWarn("Turning Log Mode Off (timer expired)")
	gC4LogTimer:KillTimer()
	
	C4:UpdateProperty("Log Mode", "Off")
	OnPropertyChanged("Log Mode")
end

gForceLogging = false
function ON_PROPERTY_CHANGED.LogMode(propertyValue)
	gC4LogTimer:KillTimer()
	
	if (gForceLogging) then
		LOG:OutputPrint(true)
		LOG:OutputC4Log(true)
	else
		LOG:OutputPrint(propertyValue:find("Print") ~= nil)
		LOG:OutputC4Log(propertyValue:find("Log") ~= nil)
		if (propertyValue == "Off") then
			return
		end
		
		gC4LogTimer:StartTimer()
	end
end

function ON_PROPERTY_CHANGED.LogLevel(propertyValue)
	if (gForceLogging) then
		LOG:SetLogLevel("5 - Debug")
	else
		LOG:SetLogLevel(propertyValue)
	end
end

--[[=============================================================================
    Print Template Versions
===============================================================================]]
function TemplateVersion()
	print ("\nTemplate Versions")
	print ("-----------------------")
	for k, v in pairs(TEMPLATE_VERSION) do
		print (k .. " = " .. v)
	end
	
	print ("")
end