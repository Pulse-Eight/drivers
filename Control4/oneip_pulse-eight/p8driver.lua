require "common.p8declares"
require "common.p8init"
require "common.p8core"
require "common.c4_command"
require "common.c4_notify"
require "common.c4_diagnostics" --DEBUG
require "lib.ringbuffer"
require "p8proxy"
require "p8system"
require "p8routing"
require "p8monitoring"

--Init Functions

local gP8InitTimer
local gP8DetailsTimer
local gP8HealthTimer
local gP8AudioTimer

local gP8NetworkStatusBuffer
local gP8PollTicket
local gP8PollRequests = {}

function ON_DRIVER_EARLY_INIT.main()
    C4:AddVariable("Temp0", 0, "NUMBER")
end

function ON_DRIVER_INIT.main()
    FirstRun()
end

function FirstRun()
    --Init Connected Devices
    LogInfo("=== Driver First Run ===")
    P8INT:FETCH_INSTALLER_ID()
    --Initialise ring buffer for monitoring network timeouts
    gP8NetworkStatusBuffer = gP8NetworkStatusBuffer or P8RingBuffer:new(4)

    gP8InitTimer = gP8InitTimer or c4_timer:new("Post Init", 1, "SECONDS", InitTimer)
    gP8InitTimer:StartTimer() -- Call once to set initial states
	
    gP8HealthTimer     = gP8HealthTimer     or c4_timer:new("Health Check", 60, "SECONDS", HealthUpdateTimer, true)
    gP8DetailsTimer    = gP8DetailsTimer    or c4_timer:new("Details Update", 10, "SECONDS", DetailsUpdateTimer, true)
	gP8AudioTimer      = gP8AudioTimer      or c4_timer:new("Audio Update", 60, "SECONDS", AudioUpdateTimer, true)

    gP8HealthTimer:StartTimer()
    gP8DetailsTimer:StartTimer()
	gP8AudioTimer:StartTimer()
	
    LogInfo("All timers started")
end

function InitTimer()
	LogInfo("InitTimer: initial full update")
	DetailsUpdateTimer()
	HealthUpdateTimer()
	AudioUpdateTimer()
end

function AudioUpdateTimer()
	LogTrace("Updating Audio Details")
	
	local updateRequired = false
	if gP8PollRequests.audio == nil then 
		updateRequired = true
	elseif gP8PollRequests.audio:TicketId() == 0 then
		updateRequired = true
	end
	LogTrace("Audio update required")
	gP8PollRequests.audio = C4:url() -- must create a new ticket every time
	:SetOption("timeout", 15)
	:OnDone(function(transfer, responses, errCode, errMsg) 
		P8INT:UPDATE_AUDIO_STATE(transfer, responses, errCode, errMsg)
		end)
	:Get(P8INT:GET_MATRIX_URL() .. "/Audio")
end

function DetailsUpdateTimer()
	local updateRequired = false
	if gP8PollRequests.details == nil then 
		updateRequired = true
	elseif gP8PollRequests.details:TicketId() == 0 then
		updateRequired = true
	end

	if updateRequired then
		gP8PollRequests.details = C4:url() -- must create a new ticket every time
		:SetOption("timeout", 15)
		:OnDone(function(transfer, responses, errCode, errMsg) 
			P8INT:GET_DETAILS(transfer, responses, errCode, errMsg)
			end)
		:Get(P8INT:GET_MATRIX_URL() .. "/System/Details")
	end
end

function HealthUpdateTimer()
    local updateRequired = false
	if gP8PollRequests.health == nil then 
		updateRequired = true
	elseif gP8PollRequests.health:TicketId() == 0 then
		updateRequired = true
	end

	if updateRequired then
		gP8PollRequests.health = C4:url() -- must create a new ticket every time
		:SetOption("timeout", 15)
		:OnDone(function(transfer, responses, errCode, errMsg) 
			P8INT:GET_HEALTH(transfer, responses, errCode, errMsg)
			end)
		:Get(P8INT:GET_MATRIX_URL() .. "/System/Health")
	end
end

function MarkNetworkTransfer(success, source, code, message)
	source = source or ""
	code = code or 0
	message = message or ""
	if code ~= 0 then
		LogWarn(source .. ": Network failure. Code: ".. code .. " " .. message)
	end
	gP8NetworkStatusBuffer:push(success)
end

function DetermineOnlineStatus() 
	-- Count the number of successes and failures
	local total = #(gP8NetworkStatusBuffer.history)
	local successes = 0
	local failures = 0
	for index, value in pairs(gP8NetworkStatusBuffer.history) do
		if value then
			successes = successes + 1
		else
			failures = failures + 1
		end
	end
	
	if successes == total then
		UpdateProperty("Connected To Network", "Yes")
		C4:SetBindingStatus(6000, "online")
	elseif failures == total then
		UpdateProperty("Connected To Network", "No")
		C4:SetBindingStatus(6000, "offline")
	elseif failures > 0 then
		UpdateProperty("Connected To Network", "Yes (Degraded)")
		C4:SetBindingStatus(6000, "online")
	end
end

function CancelRoutingPoll()
	if gP8PollRequests.routing ~= nil then
		if gP8PollRequests.routing:TicketId() ~= 0 then
			gP8PollRequests.routing:Cancel()
		end
	end
end

function PermitRoutingPoll()
	-- gP8MainUpdateTimerBlocked = false
end
