require "common.p8declares"
require "common.p8init"
require "common.p8core"
require "common.c4_command"
require "common.c4_notify"
--require "common.c4_diagnostics" --DEBUG
require "p8proxy"
require "p8system"
require "p8routing"
require "p8monitoring"

--Defines

MAX_INPUTS = 8
MAX_OUTPUTS = 8

--Init Functions

local gP8RoutingUpdateTimer
local gP8DetailsTimer
local gP8HealthTimer

function ON_DRIVER_EARLY_INIT.main()
    C4:AddVariable("Temp0", 0, "NUMBER")
end

function ON_DRIVER_INIT.main()
    gP8RoutingUpdateTimer = c4_timer:new("Routing Update", 15, "SECONDS", RoutingUpdateTimer, true)
    gP8RoutingUpdateTimer:StartTimer()
    gP8DetailsTimer = c4_timer:new("Details Update", 10, "SECONDS", DetailsUpdateTimer, true)
    gP8DetailsTimer:StartTimer()
    gP8HealthTimer = c4_timer:new("Health Update", 1, "MINUTES", HealthUpdateTimer, true)
    gP8HealthTimer:StartTimer()
    --Call once to set initial states
    RoutingUpdateTimer()
    DetailsUpdateTimer()
    HealthUpdateTimer()
    P8INT:FETCH_INSTALLER_ID()
end

function RoutingUpdateTimer()
    P8INT:GET_ROUTING(DEFAULT_PROXY_BINDINGID)
end

function DetailsUpdateTimer()
    P8INT:GET_DETAILS(DEFAULT_PROXY_BINDINGID)
end

function HealthUpdateTimer()
    P8INT:GET_HEALTH(DEFAULT_PROXY_BINDINGID)
end