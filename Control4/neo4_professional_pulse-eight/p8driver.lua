require "common.p8declares"
require "common.p8init"
require "common.p8core"
require "common.c4_command"
require "common.c4_notify"
require "common.c4_diagnostics" --DEBUG
require "p8proxy"
require "p8system"
require "p8routing"

--Defines

MAX_INPUTS = 4
MAX_OUTPUTS = 4

--Init Functions

local gP8RoutingUpdateTimer
local gP8HealthTimer

function ON_DRIVER_EARLY_INIT.main()
    
end

function ON_DRIVER_INIT.main()
    gP8RoutingUpdateTimer = c4_timer:new("Routing Update", 15, "SECONDS", RoutingUpdateTimer, true)
    gP8RoutingUpdateTimer:StartTimer()
    gP8DetailsTimer = c4_timer:new("Details Update", 10, "SECONDS", DetailsUpdateTimer, true)
    gP8DetailsTimer:StartTimer()
end

function RoutingUpdateTimer()
    P8INT:GET_ROUTING(DEFAULT_PROXY_BINDINGID)
end

function DetailsUpdateTimer()
    P8INT:GET_DETAILS(DEFAULT_PROXY_BINDINGID)
end