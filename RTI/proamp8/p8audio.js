//Copyright Pulse-Eight Limtied 2020

System.Print("P8Routing: Initializing...\r\n");

//
//  Startup Code
//
var TIMER_INTERVAL = 1000;
var routingUpdateTimer = new Timer();
var TOTAL_ZONES = 8;

//
//  Internal Functions
//
function UpdateState() {
	try {
		var data = JSON.parse(System.GetURL(SYSTEM_URL + '/Port/List'));
		
		for (var key in data.Ports) {
			if (data.Ports[key].Mode == 'Output') {
				for (var i = 0; i < TOTAL_ZONES; i++) {
					if (data.Ports[key].volume || data.Ports[key].volLeft) {
						SystemVars.Write('VolumeZone' + (data.Ports[key].Bay + 1), data.Ports[key].volume || data.Ports[key].volLeft);
						SystemVars.Write('PowerZone' + (data.Ports[key].Bay + 1), data.Ports[key].pwrMode);
						SystemVars.Write('MuteZone' + (data.Ports[key].Bay + 1), data.Ports[key].mute > 0);
					}
				}
			}
		}
	} catch (err) {
		System.Print(err);
	    routingUpdateTimer.Start(UpdateState, TIMER_INTERVAL);
	}
}

routingUpdateTimer.Start(UpdateState, TIMER_INTERVAL);


//
//  External Functions
//
function SetVolume(zone, volume) {
	if (DEBUG) {
		System.Print('Setting Volume: Zone ' + zone + ' to ' + volume + '\r\n');
	}

	zone--; //Fix offset
	var response = System.GetURL(SYSTEM_URL + '/Audio/Volume/' + zone + '/' + volume);
	if (DEBUG) {
		System.Print(response);
	}
}

function SetMute(zone, state) {
	if (DEBUG) {
		System.Print('Setting Mute: Zone ' + zone + ' to ' + state + '\r\n');
	}

	zone--; //Fix offset
	var response = System.GetURL(SYSTEM_URL + '/Audio/Mute/' + zone + '/3/' + state);
	if (DEBUG) {
		System.Print(response);
	}
}

function SetPower(zone, state) {
	if (DEBUG) {
		System.Print('Setting Power: Zone ' + zone + ' to ' + state + '\r\n');
	}

	zone--; //Fix offset
	var response = System.GetURL(SYSTEM_URL + '/amp/Power/' + zone + '/' + state);
	if (DEBUG) {
		System.Print(response);
	}
}

function VolumeUp(zone) {
	if (DEBUG) {
		System.Print('Volume Up: Zone ' + zone + '\r\n');
	}

	zone--; //Fix offset
	var response = System.GetURL(SYSTEM_URL + '/Audio/Volume/' + zone + '/up');
	if (DEBUG) {
		System.Print(response);
	}
}

function VolumeDown(zone) {
	if (DEBUG) {
		System.Print('Volume Down: Zone ' + zone + '\r\n');
	}

	zone--; //Fix offset
	var response = System.GetURL(SYSTEM_URL + '/Audio/Volume/' + zone + '/down');
	if (DEBUG) {
		System.Print(response);
	}
}