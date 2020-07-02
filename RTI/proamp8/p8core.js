//Copyright Pulse-Eight Limtied 2020

System.Print("P8Core: Initializing...\r\n");

//
//  Globals
//
var DEBUG = Config.Get("DebugTrace") == "true";

var SYSTEM_URL = 'http://' + Config.Get('IPAddress');

System.Print('P8Core: System URL: ' + SYSTEM_URL + '\r\n');

//
//  Startup Code
//