--[[=============================================================================
    Functions for Testing different aspects of the environment

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]
require "common.p8declares"

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