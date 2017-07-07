//Copyright Pulse-Eight Limtied 2017

System.Print("P8Routing: Initializing...\r\n");

//
//  Startup Code
//
var TIMER_INTERVAL = 1000;
var routingUpdateTimer = new Timer();
var TOTAL_INPUTS = 4;

//
//  Internal Functions
//
function UpdateRouting() {
	try {
		var data = JSON.parse(System.GetURL(MATRIX_URL + '/Port/List'));
		
		for (var key in data.Ports) {
			if (data.Ports[key].Mode == 'Output') {
				for (var i = 0; i < TOTAL_INPUTS; i++) {
					SystemVars.Write('O' + data.Ports[key].Bay + 'I' + i, data.Ports[key].ReceiveFrom == i);
				}
			}
		}
	} catch (err) {
		System.Print(err);
	    routingUpdateTimer.Start(UpdateRouting, TIMER_INTERVAL);
	}
}

routingUpdateTimer.Start(UpdateRouting, TIMER_INTERVAL);


//
//  External Functions
//
function PortSet(input, output) {
    if (DEBUG) {
		System.Print('Routing Change: Input ' + input  + ' -> ' + output + '\r\n');
	}

	input--; //Fix offset
	output--; //Fix offset
	var routingChange = System.GetURL(MATRIX_URL + '/Port/Set/' + input + '/' + output);
	if (DEBUG) {
		System.Print(routingChange);
	}
}