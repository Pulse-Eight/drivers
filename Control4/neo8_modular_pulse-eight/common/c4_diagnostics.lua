--[[=============================================================================
    Functions for Testing different aspects of the environment

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]
require "common.c4_driver_declarations"

-- Set template version for this file
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.c4_diagnostics = "2015.03.02"
end

function DisplayGlobals()

	print ("Global Variables")
	print ("----------------------------")
	for k,v in pairs(_G) do                             -- globals
		if not (type(v) == "function") then
			if (string.find(k, "^g%L")  == 1) then
				print(k .. ":  " .. tostring(v))
				if (type(v) == "table") then
					C4PrintTable(v, "   ")
				end
			end
		end
	end

	print ("")
end

function C4PrintTable(tValue, sIndent)

	sIndent = sIndent or "   "
	for k,v in pairs(tValue) do

		print(sIndent .. tostring(k) .. ":  " .. tostring(v))
		if (type(v) == "table") then
			C4PrintTable(v, sIndent .. "   ")
		end
	end
end