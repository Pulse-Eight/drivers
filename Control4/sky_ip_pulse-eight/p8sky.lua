require "lib.json"

PORT = 5900

function P8INT:SETUP()
    LogInfo("Setup Running")
    local boxType = Properties["Sky Box Type"] or ""
    if (boxType == "Sky Q") then
	local ip = Properties["Device IP Address"] or ""
	local uri = "http://" .. ip .. ":9006/as/system/information"
	C4:urlGet(uri, {}, false,
	   function(ticketId, strData, responseCode, tHeaders, strError)
		  if responseCode == 200 then
			 local jsonResponse = JSON:decode(strData)
			 UpdateProperty("Firmware Version", jsonResponse.modelNumber)
			 local rev = string.match(jsonResponse.modelNumber, "([^.]+)")
			 local version = tonumber(string.sub(rev, 2))
			 if (version > 50) then
				LogInfo("Sky Q Version > 50, setting to new port 49160")
				PORT = 49160
			 else
				LogInfo("Sky Q Version <= 50, setting to old port 5900")
				PORT = 5900
			 end
		  end
	   end)
    else
	   LogInfo("Setting port to 49160 as not Sky Q box")
	   PORT = 49160
    end
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
    local boxType = Properties["Sky Box Type"] or ""
    if (boxType == "Sky+ HD") then
	   P8INT:SEND_KEY(0)
    end
    
    local ip = Properties["Device IP Address"] or ""
    local uri = "http://" .. ip .. ":9006/as/system/information"
    C4:urlGet(uri, {}, false,
	   function(ticketId, strData, responseCode, tHeaders, strError)
		  if responseCode == 200 then
			 local jsonResponse = JSON:decode(strData)
			 if (jsonResponse.activeStandby) then
				P8INT:SEND_KEY(0)
			 end
		  end
	   end)
end