//Copyright Pulse-Eight Limtied 2016

System.Print("P8Routing: Initializing...\r\n");

//
//  Startup Code
//
//ResetCounter();

//
//  Internal Functions
//

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