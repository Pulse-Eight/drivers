--[[=============================================================================
    Driver Declarations used to call startup routines, teardown routines, and 
    other basic functions of the drivers operation

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]

-- Template Version Table
TEMPLATE_VERSION = {}
TEMPLATE_VERSION.c4_driver_declarations = "2015.03.02"

-- Command Handler Tables
EX_CMD = {}
PRX_CMD = {}
UI_REQ = {}
NOTIFY = {}
DEV_MSG = {}
LUA_ACTION = {}

--[[=============================================================================
    Tables of functions
    The following tables are function containers that are called within the
    following functions:

    OnDriverInit()
        First calls all functions contained within ON_DRIVER_EARLY_INIT table
        then calls all functions contained within ON_DRIVER_INIT table

    OnDriverLateInit()
        Calls all functions contained within ON_DRIVER_LATEINIT table

    OnDriverDestroyed()
        Calls all functions contained within ON_DRIVER_DESTROYED table

    OnPropertyChanged()
        Calls all functions contained within ON_PROPERTY_CHANGED table
===============================================================================]]
ON_DRIVER_INIT = {}
ON_DRIVER_EARLY_INIT = {}
ON_DRIVER_LATEINIT = {}
ON_DRIVER_DESTROYED = {}
ON_PROPERTY_CHANGED = {}

-- Constants
DEFAULT_PROXY_BINDINGID = 5001