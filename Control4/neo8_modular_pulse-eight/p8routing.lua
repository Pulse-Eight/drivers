--Copyright Pulse-Eight Limited 2015

require "lib.json"

function P8INT:PORT_SET(idBinding, tParams)
    local input = tonumber(tParams["INPUT"] % 1000)
    local output = tonumber(tParams["OUTPUT"] % 1000)
    local uri = P8INT:GET_MATRIX_URL() .. "/Port/Set/" .. input .. "/" .. output
    LogTrace("Changing Routing. Input: " .. input .. " -> Output: " .. output)
    C4:urlGet(uri, {}, false, function(ticketId, strData, responseCode, tHeaders, strError)
		  local jsonResponse = JSON:decode(strData)
		  if jsonResponse.Result then
			 self:GET_ROUTING(idBinding)
		  end
	   end)
end

function P8INT:GET_ROUTING(idBinding)
    LogTrace("Updating Current Routing")
    local uri = P8INT:GET_MATRIX_URL() .. "/Port/List/Concise"
    C4:urlGet(uri, {}, false, 
	   function(ticketId, strData, responseCode, tHeaders, strError)
   		  if responseCode ~= 200 or strError ~= nil then
			 LogWarn("Unable to refresh routing")
			 LogWarn("Error = " .. strError)
			 LogWarn("Response Code = " .. responseCode)
			 return
		  end
	   
		  local jsonResponse = JSON:decode(strData)
		  if jsonResponse.Result then
			 for i = 1,MAX_OUTPUTS do
				local tParams = {INPUT = jsonResponse["Output" .. i][1] + 3000, OUTPUT = 4000 + i}
				SendNotify("INPUT_OUTPUT_CHANGED", tParams, idBinding)
				tParams = {INPUT = jsonResponse["Output" .. i][1] + 1000, OUTPUT = 2000 + i}
				SendNotify("INPUT_OUTPUT_CHANGED", tParams, idBinding)	
			 end
		  end
	   end)
end