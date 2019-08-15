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

MAX_INPUTS = 8
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
    P8INT:SETUP()
    gP8RoutingUpdateTimer = c4_timer:new("Routing Update", 2, "SECONDS", RoutingUpdateTimer, true)
    gP8RoutingUpdateTimer:StartTimer()
    gP8DetailsTimer = c4_timer:new("Details Update", 10, "SECONDS", DetailsUpdateTimer, true)
    gP8DetailsTimer:StartTimer()
    gP8HealthTimer = c4_timer:new("Health Update", 1, "MINUTES", HealthUpdateTimer, true)
    gP8HealthTimer:StartTimer()
    gP8VolumeTimer = c4_timer:new("Volume Update", 10, "SECONDS", VolumeUpdateTimer, true)
    gP8VolumeTimer:StartTimer()
    --Call once to set initial states
    RoutingUpdateTimer()
    DetailsUpdateTimer()
    HealthUpdateTimer()
    VolumeUpdateTimer()
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