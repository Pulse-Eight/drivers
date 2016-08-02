require "common.p8declares"
require "common.p8init"
require "common.p8core"
require "common.c4_command"
require "common.c4_notify"
--require "common.c4_diagnostics" --DEBUG
require "p8proxy"
require "p8system"
require "p8control"
require "p8feedback"

--Init Functions

local gP8DetailsTimer

function ON_DRIVER_EARLY_INIT.main()
end

function ON_DRIVER_INIT.main()
    --Init Connected Devices
    P8INT:SETUP()
    gP8DetailsTimer = c4_timer:new("Details Update", 10, "SECONDS", DetailsUpdateTimer, true)
    gP8DetailsTimer:StartTimer()
    gP8FeedbackTimer = c4_timer:new("Feedback Update", 2, "SECONDS", FeedbackTimer, true)
    gP8FeedbackTimer:StartTimer()
    --Call once to set initial states
    DetailsUpdateTimer()
end

function DetailsUpdateTimer()
    P8INT:GET_DETAILS(DEFAULT_PROXY_BINDINGID)
end

function FeedbackTimer()
    P8INT:UPDATE_VOLUME_LEVEL()
end