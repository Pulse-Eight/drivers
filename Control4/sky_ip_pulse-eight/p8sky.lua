require "lib.json"

function P8INT:SEND_KEY(code)
    if (code == -1) then
	   return
    end
    local ip = Properties["Device IP Address"] or ""
    local boxType = Properties["Sky Box Type"] or ""
    local port = 5900
    if (boxType == "Sky+ HD") then
	   port = 49160
    end
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
	   :Connect(ip, port)
end

function P8INT:TURN_ON()
    local boxType = Properties["Sky Box Type"] or ""
    if (boxType == "Sky+ HD") then
	   P8INT:SEND_KEY(11)
    end
    
    local ip = Properties["Device IP Address"] or ""
    local uri = "http://" .. ip .. ":9006/as/system/information"
    C4:urlGet(uri, {}, false,
	   function(ticketId, strData, responseCode, tHeaders, strError)
		  if responseCode == 200 then
			 local jsonResponse = JSON:decode(strData)
			 if (jsonResponse.activeStandby) then
				P8INT:SEND_KEY(11)
			 end
		  end
	   end)
end