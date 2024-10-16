require "common.p8declares"
require "common.p8init"
require "common.p8core"
require "common.c4_command"
require "common.c4_notify"
require "common.c4_diagnostics" --DEBUG
require "p8proxy"
require "p8system"
require "p8monitoring"

--Defines

MAX_INPUTS = 8
MAX_OUTPUTS = 8

--Init Functions

local gP8DetailsTimer
local gP8HealthTimer
local gP8VolumeTimer
local gP8PropertiesTimer

function ON_DRIVER_EARLY_INIT.main()
    C4:AddVariable("Temp0", 0, "NUMBER")
    C4:AddVariable("Temp1", 0, "NUMBER")
    C4:AddVariable("Temp2", 0, "NUMBER")
    C4:AddVariable("Temp3", 0, "NUMBER")
end

function ON_DRIVER_INIT.main()
    FirstRun()
end

function FirstRun()
    --Init Connected Devices
    gP8DetailsTimer = c4_timer:new("Details Update", 10, "SECONDS", DetailsUpdateTimer, true)
    gP8DetailsTimer:StartTimer()
    gP8HealthTimer = c4_timer:new("Health Update", 1, "MINUTES", HealthUpdateTimer, true)
    gP8HealthTimer:StartTimer()
    gP8VolumeTimer = c4_timer:new("Volume Update", 10, "SECONDS", VolumeUpdateTimer, true)
    gP8VolumeTimer:StartTimer()
	gP8PropertiesTimer = gP8PropertiesTimer or c4_timer:new("Properties Update", 3, "SECONDS", PropertiesUpdateTimer, true)
	gP8PropertiesTimer:StartTimer()
    --Call once to set initial states
    DetailsUpdateTimer()
    HealthUpdateTimer()
    LoopVolumeUpdate()
	PropertiesUpdateTimer()
    P8INT:FETCH_INSTALLER_ID()
end

function VolumeUpdateTimer()
	--LoopVolumeUpdate()
end

function LoopVolumeUpdate()
    for i = 1,MAX_OUTPUTS do
	   P8INT:UPDATE_AUDIO(DEFAULT_PROXY_BINDINGID, 4000 + i - 1)
    end
end

function DetailsUpdateTimer()
    P8INT:GET_DETAILS(DEFAULT_PROXY_BINDINGID)
end

function HealthUpdateTimer()
    P8INT:GET_HEALTH(DEFAULT_PROXY_BINDINGID)
end


function PropertiesUpdateTimer()
	P8INT:GET_FEATURES(DEFAULT_PROXY_BINDINGID)
	P8INT:GET_DOLBYSETTINGS(DEFAULT_PROXY_BINDINGID)
end