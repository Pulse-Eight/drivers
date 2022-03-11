require "common.p8declares"
require "common.p8init"
require "common.p8core"
require "common.c4_command"
require "common.c4_notify"
require "common.c4_diagnostics" --DEBUG
require "p8proxy"
require "p8system"
require "p8routing"
require "p8monitoring"

--Defines

MAX_INPUTS = 12
MAX_OUTPUTS = 10

--Init Functions

local gP8RoutingUpdateTimer
local gP8DetailsTimer
local gP8HealthTimer
local gP8VolumeTimer

function ON_DRIVER_EARLY_INIT.main()
    C4:AddVariable("Temp0", 0, "NUMBER")
end

function ON_DRIVER_INIT.main()
    FirstRun()
end

function FirstRun()
    --Init Connected Devices
    LogInfo("First Run")
    P8INT:SETUP()
    P8INT:FETCH_INSTALLER_ID()
    gP8RoutingUpdateTimer = c4_timer:new("Routing Update", 2, "SECONDS", RoutingUpdateTimer, true)
    gP8RoutingUpdateTimer:StartTimer()
    gP8DetailsTimer = c4_timer:new("Details Update", 10, "SECONDS", DetailsUpdateTimer, true)
    gP8DetailsTimer:StartTimer()
    gP8HealthTimer = c4_timer:new("Health Update", 1, "MINUTES", HealthUpdateTimer, true)
    gP8HealthTimer:StartTimer()
    gP8VolumeTimer = c4_timer:new("Volume Update", 10, "SECONDS", VolumeUpdateTimer, true)
    gP8VolumeTimer:StartTimer()
    gP8PropertiesTimer = c4_timer:new("Properties Update", 10, "SECONDS", PropertiesUpdateTimer, true)
    gP8PropertiesTimer:StartTimer()
    --Call once to set initial states
    RoutingUpdateTimer()
    DetailsUpdateTimer()
    HealthUpdateTimer()
    VolumeUpdateTimer()
    PropertiesUpdateTimer()
    --Register for SDDP Setup
    local deviceId = C4:GetDeviceID()
    C4:RegisterSystemEvent(C4SystemEvents["OnSDDPDeviceStatus"], deviceId)
    C4:RegisterSystemEvent(C4SystemEvents["OnDiscoveredDeviceChanged"], deviceId)
    C4:RegisterSystemEvent(C4SystemEvents["OnNetworkBindingAdded"], deviceId) --This is triggered when the user maps the IP in the Network Connections Tab
    C4:RegisterSystemEvent(C4SystemEvents["OnDeviceIPAddressChanged"], deviceId)
    C4:RegisterSystemEvent(C4SystemEvents["OnDiscoveredDeviceAdded"], deviceId)
    C4:RegisterSystemEvent(C4SystemEvents["OnSDDPDeviceDiscover"], deviceId)
    C4:RegisterSystemEvent(C4SystemEvents["OnDeviceDiscovered"], deviceId)
end

function VolumeUpdateTimer()
    for i = 1,MAX_OUTPUTS do
	   --P8INT:UPDATE_AUDIO(DEFAULT_PROXY_BINDINGID, 4000 + i - 1)
    end
end

function RoutingUpdateTimer()
    if (Properties["Auto Sync Navigators"] == "Yes") then
	   P8INT:GET_ROUTING(DEFAULT_PROXY_BINDINGID)
	   P8INT:GET_POWER_STATE(DEFAULT_PROXY_BINDINGID)
    end
end

function DetailsUpdateTimer()
    P8INT:GET_DETAILS(DEFAULT_PROXY_BINDINGID)
end

function HealthUpdateTimer()
    P8INT:GET_HEALTH(DEFAULT_PROXY_BINDINGID)
end

function PropertiesUpdateTimer()
    P8INT:GET_SOURCESINKMODE(DEFAULT_PROXY_BINDINGID)
    P8INT:GET_POWERON_ON_ROUTING_CHANGE(DEFAULT_PROXY_BINDINGID)
end