require "lib.json"

PORT = 49160

function P8INT:SETUP()
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
   LogInfo("Powering Sky+ HD On")
   P8INT:SEND_KEY(0)
end