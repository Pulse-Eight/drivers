require "common.p8declares"
require "common.p8properties"

require "lib.c4_log"
require "lib.c4_timer"

gForceLogging = false

function ON_DRIVER_INIT.p8init()
	-- Create Log Timer
	gC4LogTimer = c4_timer:new("Log Timer", 45, "MINUTES", OnLogTimerExpired)
end

function OnLogTimerExpired()
	LogWarn("Turning Log Mode Off (timer expired)")
	gC4LogTimer:KillTimer()
	
	C4:UpdateProperty("Log Mode", "Off")
	OnPropertyChanged("Log Mode")
end

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

function ON_PROPERTY_CHANGED.RoutingMode(propertyValue)
     --LogTrace("Routing Mode Changed" .. propertyValue)
	if(propertyValue == "Sink Mode") then
	   P8INT:SET_SOURCESINKMODE(1)
     else
	   P8INT:SET_SOURCESINKMODE(0)
	end
end

function ON_PROPERTY_CHANGED.CECSupport(propertyValue)
    LogTrace("CECEnabled Mode Changed " .. propertyValue)
	if(propertyValue == "Enabled") then
	   P8INT:SET_CEC_ENABLED(1)
     else
	   P8INT:SET_CEC_ENABLED(0)
	end
end

function ON_PROPERTY_CHANGED.CECSwitchingSupport(propertyValue)
     --LogTrace("CECSwitchingSupport Mode Changed " .. propertyValue)
	if(propertyValue == "Enabled") then
	   P8INT:SET_CEC_SWITCHING_SUPPORT(1)
     else
	   P8INT:SET_CEC_SWITCHING_SUPPORT(0)
	end
end


function ON_PROPERTY_CHANGED.SendCECONduringroutechange(propertyValue)
     --LogTrace("Autopoweron Mode Changed " .. propertyValue)
	if(propertyValue == "Yes") then
	   P8INT:SET_POWERON_ON_ROUTING_CHANGE(1)
     else
	   P8INT:SET_POWERON_ON_ROUTING_CHANGE(0)
	end
end

function ON_PROPERTY_CHANGED.SendCECOFFonzoneoff(propertyValue)
     --LogTrace("Autopoweroff Mode Changed " .. propertyValue)
	if(propertyValue == "Yes") then
	   MODE_POWEROFF_ON_ZONE_OFF = 1
     else
	   MODE_POWEROFF_ON_ZONE_OFF = 0
	end
end

function ON_PROPERTY_CHANGED.IndependentRouting(propertyValue)
     --LogTrace("Manual Mode Changed " .. propertyValue)
	if(propertyValue == "Enabled") then
	   P8INT:SET_MANUALMODE(1)
     else
	   P8INT:SET_MANUALMODE(0)
	end
end


-- Main calls from the Director

function OnDriverInit()
    gInitializingDriver = true
    C4:ErrorLog("INIT_CODE: OnDriverInit()")

	-- Call all ON_DRIVER_EARLY_INIT functions.
	for k,v in pairs(ON_DRIVER_EARLY_INIT) do
		if (ON_DRIVER_EARLY_INIT[k] ~= nil and type(ON_DRIVER_EARLY_INIT[k]) == "function") then
			C4:ErrorLog("INIT_CODE: ON_DRIVER_EARLY_INIT." .. k .. "()")
			print("INIT_CODE: ON_DRIVER_EARLY_INIT." .. k .. "()")
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
			print("INIT_CODE: ON_DRIVER_INIT." .. k .. "()")
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

function OnDriverLateInit()
	C4:ErrorLog("INIT_CODE: OnDriverLateInit()")
	C4:SendToProxy(DEFAULT_PROXY_BINDINGID, 'PROTOCOL_WILL_HANDLE_AV_VALID', {})
	-- Call all ON_DRIVER_LATEINIT functions
	for k,v in pairs(ON_DRIVER_LATEINIT) do
		if (ON_DRIVER_LATEINIT[k] ~= nil and type(ON_DRIVER_LATEINIT[k]) == "function") then
			C4:ErrorLog("INIT_CODE: ON_DRIVER_LATEINIT." .. k .. "()")
			ON_DRIVER_LATEINIT[k]()
		end
	end
	--Register for SDDP Setup
	local deviceId = C4:GetDeviceID()
	C4:RegisterSystemEvent(C4SystemEvents["OnSDDPDeviceStatus"], deviceId)
	C4:RegisterSystemEvent(C4SystemEvents["OnDiscoveredDeviceChanged"], deviceId)
	C4:RegisterSystemEvent(C4SystemEvents["OnNetworkBindingAdded"], deviceId) --This is triggered when the user maps the IP in the Network Connections Tab
	C4:RegisterSystemEvent(C4SystemEvents["OnDeviceIPAddressChanged"], deviceId)
	C4:RegisterSystemEvent(C4SystemEvents["OnDiscoveredDeviceAdded"], deviceId)
	C4:RegisterSystemEvent(C4SystemEvents["OnSDDPDeviceDiscover"], deviceId)
	C4:RegisterSystemEvent(C4SystemEvents["OnDeviceDiscovered"], deviceId)
	C4:urlSetTimeout(15)
end

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