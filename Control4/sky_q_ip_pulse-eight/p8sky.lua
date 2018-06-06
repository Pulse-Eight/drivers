require "lib.json"

PORT = 49160

function P8INT:SETUP()
	LogInfo("Setup Running")
	local ip = Properties["Device IP Address"] or ""
	local uri = "http://" .. ip .. ":9006/as/system/information"
	C4:urlGet(uri, {}, false,
	   function(ticketId, strData, responseCode, tHeaders, strError)
		  if responseCode == 200 then
			 local jsonResponse = JSON:decode(strData)
			 UpdateProperty("Firmware Version", jsonResponse.modelNumber)
		  else
			UpdateProperty("Firmware Version", "Error")
		  end
	   end)
end

function P8INT:SEND_KEY(code)
    if (code == -1) then
	   return
    end
    local ip = Properties["Device IP Address"] or ""
    local splice = 12
    local skyClient = C4:CreateTCPClient()
	   :OnConnect(function(client)
		 client:ReadAtLeast(1)
	   end)
	   :OnRead(function (client, data)
		  if (string.len(data) < 24) then
			 client:Write(string.sub(data, 0, splice))
			 client:ReadAtLeast(1)
			 splice = 1
		  else
			 client:Write(string.char(4,1,0,0,0,0,math.floor(224 + (code/16)), code % 16))
			 client:Write(string.char(4,0,0,0,0,0,math.floor(224 + (code/16)), code % 16))
		  end
	   end)
	   :Connect(ip, PORT)
end

function P8INT:TURN_ON()
   local ip = Properties["Device IP Address"] or ""
   local uri = "http://" .. ip .. ":9006/as/system/information"
   LogInfo("Checking Sky Q Power State")
   C4:urlGet(uri, {}, false,
	  function(ticketId, strData, responseCode, tHeaders, strError)
		 if responseCode == 200 then
			local jsonResponse = JSON:decode(strData)
			if (jsonResponse.activeStandby) then
				LogInfo("Powering Sky Q On")
				P8INT:SEND_KEY(11)
			else
				LogInfo("Sky Q is already on, ignoring Turn On Request")
			end
	      else
		  LogWarning("Response " .. responseCode .. " when checking power state")
		 end
	  end)
end

function P8INT:TURN_OFF()
   local ip = Properties["Device IP Address"] or ""
   local uri = "http://" .. ip .. ":9006/as/system/information"
   LogInfo("Checking Sky Q Power State")
   C4:urlGet(uri, {}, false,
	  function(ticketId, strData, responseCode, tHeaders, strError)
		 if responseCode == 200 then
			local jsonResponse = JSON:decode(strData)
			if (jsonResponse.activeStandby) then
				LogInfo("Sky Q is already of, ignoring Turn Off Request")
			else
				LogInfo("Powering Sky Q Off")
				P8INT:SEND_KEY(0)
			end
	      else
		  LogWarning("Response " .. responseCode .. " when checking power state")
		 end
	  end)
end