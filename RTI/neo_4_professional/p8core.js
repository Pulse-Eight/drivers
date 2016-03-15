// TCP Sample Driver
// Copyright 2010 Remote Technologies Inc.
//

System.Print("P8Core: Initializing...\r\n");

//
//  Globals
//
var DEBUG = Config.Get("DebugTrace") == "true";

var MATRIX_URL = 'http://' + Config.Get('IPAddress');

System.Print('P8Core: Matrix URL: ' + MATRIX_URL + '\r\n');

//
//  Startup Code
//