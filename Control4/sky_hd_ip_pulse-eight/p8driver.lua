require "common.p8declares"
require "common.p8init"
require "common.p8core"
require "common.c4_command"
require "common.c4_notify"
--require "common.c4_diagnostics" --DEBUG
require "p8proxy"
require "p8sky"

--Init Functions

function ON_DRIVER_EARLY_INIT.main()
end

function ON_DRIVER_INIT.main()
    --Init Connected Devices
    P8INT:SETUP()
end