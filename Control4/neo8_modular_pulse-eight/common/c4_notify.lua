--[[=============================================================================
    Notification Functions

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]
require "common.c4_driver_declarations"

-- Set template version for this file
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.c4_notify = "2015.03.02"
end

--[[=============================================================================
    SendNotify(notifyText, tParams, bindingID)

    Description
    Forwards a notification to the proxy with a list of parameters

    Parameters
    notifyText(string) - The function identifier for the proxy
    tParams(table)     - Table of key value pairs that hold the the parameters
                         and their values used in the proxy function
    bindingID(int)     - The requests binding id

    Returns
    Nothing
===============================================================================]]
function SendNotify(notifyText, tParams, bindingID)
	C4:SendToProxy(bindingID, notifyText, tParams, "NOTIFY")
end

--[[=============================================================================
    SendSimpleNotify(notifyText, ...)

    Description
    Forwards a notification to the proxy with no parameters

    Parameters
    notifyText(string) - The function identifier for the proxy
    bindingID(int)     - Optional parameter containing the requests binding id,
                         if not specified then the DEFAULT_PROXY_ID is given.

    Returns
    Nothing
===============================================================================]]
function SendSimpleNotify(notifyText, ...)
	bindingID = select(1, ...) or DEFAULT_PROXY_BINDINGID
	C4:SendToProxy(bindingID, notifyText, {}, "NOTIFY")
end