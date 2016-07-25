//Copyright Pulse-Eight Limtied 2016

System.Print("P8Control: Initializing...\r\n");

//
//  Startup Code
//

var connection = null;
var lastInput = '0x00';

//
//  Internal Functions
//
function sendKeyPress() {
	var data = 'POST /cec/key/Input/' + INPUT_PORT + '/ HTTP/1.0\r\n' +
		'Content-Length: 15\r\n' +
		'Content-Type: application/json\r\n' +
		'\r\n' +
		'{"Code":"' + lastInput + '"}';
	if (DEBUG) {
		System.Print('Sending: ' + data);
	}
	var state = connection.Write(data);
	if (state && DEBUG) {
		System.Print('Response: ' + connection.Read(2000) + '\r\n');
	}
	connection.Close();
}

//
//  External Functions
//
function SendCommand(Input) {
	if (DEBUG) {
		System.Print('Input received: ' + INPUT_PORT + ', Command: ' + Input + '\r\n');
		System.Print('Connecting To: ' + Config.Get('IPAddress') + '\r\n');
	}
	lastInput = Input;
	connection = new HTTP(function() {});
	connection.OnConnectFunc = sendKeyPress;
	var openState = connection.Open(Config.Get('IPAddress'), 80);
	if (DEBUG) {
		System.Print('Opened: ' + openState + '\r\n');
		System.Print('OpenState: ' + connection.OpenState);
		System.Print('ConnectState: ' + connection.ConnectState);
	}
}