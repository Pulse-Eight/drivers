require "lib.c4_object"

P8INT = inheritsFrom(nil)

-- Command Handler Tables
EX_CMD = {}
PRX_CMD = {}
UI_REQ = {}
NOTIFY = {}
DEV_MSG = {}
LUA_ACTION = {}

ON_DRIVER_INIT = {}
ON_DRIVER_EARLY_INIT = {}
ON_DRIVER_LATEINIT = {}
ON_DRIVER_DESTROYED = {}
ON_PROPERTY_CHANGED = {}

-- Constants
DEFAULT_PROXY_BINDINGID = 5001


-- I don't know why this has to be here, if its placed in p8init.lua it fails and the script does not work. If anyone knows why please let me know

function ON_DRIVER_EARLY_INIT.p8init()
	-- Create a logger
	LOG = c4_log:new("neo:X")
end