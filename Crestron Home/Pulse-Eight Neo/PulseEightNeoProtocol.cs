﻿using System;
using System.Collections.Generic;
using Crestron.RAD.Common.BasicDriver;
using Crestron.RAD.Common.Enums;
using Crestron.RAD.Common.Transports;
using Crestron.SimplSharp.Net.Http;
using Crestron.RAD.DeviceTypes.AudioVideoSwitcher;
using Newtonsoft.Json;
using PulseEight.Neo.IP.API;
using PulseEight.Neo.IP.API.Health;
using PulseEight.Neo.IP.API.Routing;

namespace PulseEight.Neo.IP {
	public class PulseEightNeoProtocol : AAudioVideoSwitcherProtocol {
		private HttpTransport myTransport;
		private StandardCommandsEnum myLastCommand;
		private readonly Dictionary<string, string> myLastData = new Dictionary<string, string>();
		public PulseEightNeoProtocol(HttpTransport connectionTransport, byte id) : base(connectionTransport, id) {
			myTransport = connectionTransport;
			PollingInterval = 5000; //Milliseconds
			TimeOut = 6000; //Timeout must be higher than PollingInterval, logic is flawed in that the true timeout is PollingInterval - TimeOut. 
			PowerIsOn = true;
			DriverLoaded = true;
			IsConnected = true;
		}

		/// <summary>
		/// Response from device after a successful call of AudioVideoSwitcherRoute, this method is never called! BUG BUG BUG
		/// </summary>
		/// <param name="response">Data from the device</param>
		protected override void DeConstructSwitcherRoute(string response) {
			SendMeData($"Switcher Route Data: {response}");
			base.DeConstructSwitcherRoute(response);
		}

		private void HandleSwitcherRouteResponse(string response) {
			var routingResponse = JsonConvert.DeserializeObject<RoutingResponse>(response);
			if (routingResponse.Result) {
				var input = GetExtenderByApiIdentifier(myLastData["input"]);
				var output = GetExtenderByApiIdentifier(myLastData["output"]);
				if (output != null) {
					output.VideoSourceExtenderId = input.Id;
				}
			}

			SendMeData($"Routing Data: {response}");
		}

		private void UpdateRoutingConfiguration(string response) {
			var routingConfiguration = JsonConvert.DeserializeObject<RoutingDetails>(response);
			if (routingConfiguration.Result) {
				foreach (var port in routingConfiguration.Ports) {
					if (port.Mode == "Output") {
						var output = GetExtenderByApiIdentifier((port.Bay + 2000).ToString());
						if (output != null) {
							var newLocation = (port.ReceiveFrom + 1000).ToString();
							var input = GetExtenderByApiIdentifier(newLocation);
							if (output.VideoSourceExtenderId != input.Id) {
								Log($"Routing changed via external event: Output {output.Id} switched from {output.VideoSourceExtenderId} to {input.Id}");
								output.VideoSourceExtenderId = input.Id;
							}
						}
					}
				}
			}
		}

		/// <summary>
		/// Method is never called BUG BUG BUG
		/// </summary>
		/// <param name="response"></param>
		protected override void DeConstructSwitcherPower(string response) {
			SendMeData("Instructing Crestron that the device is On");
			PowerIsOn = true;
			base.DeConstructSwitcherPower(response);
		}

		/// <summary>
		/// Global response from device after a successful call (all call types)
		/// </summary>
		/// <param name="response">Data from the device</param>
		public override void DataHandler(string response) {
			try {
				response = response.Substring(response.IndexOf("{", StringComparison.InvariantCultureIgnoreCase));
				
				switch (myLastCommand) {
					case StandardCommandsEnum.TemperaturePoll:
						var healthData = JsonConvert.DeserializeObject<HealthResponse>(response);
						CurrentTemperature = Convert.ToInt16(healthData.Temperature0);
						CurrentTemperatureUnits = TemperatureUnit.Celcius;
						SendMeData($"Updated temperature to: {CurrentTemperature} {CurrentTemperatureUnits}");
						break;
					case StandardCommandsEnum.AudioVideoSwitcherRoute:
						HandleSwitcherRouteResponse(response);
						break;
					case StandardCommandsEnum.AudioVideoSwitcherRoutePoll:
						UpdateRoutingConfiguration(response);
						break;
					case StandardCommandsEnum.PowerPoll:
						JsonConvert.DeserializeObject<BaseResponse>(response);
						PowerIsOn = true;
						break;
					default:
						SendMeData($"Unhandled response from device: {response}");
						break;
				}
			} catch (Exception ex) {
				if (myLastCommand == StandardCommandsEnum.PowerPoll) {
					PowerIsOn = false;
				}
				SendMeData($"Failed to unpack response: {ex}: original data: '{response}'");
			}

			base.DataHandler(response);
		}

		/// <summary>
		/// Preprocessor on command to be sent to device. This command handles ALL commands and there is no commandset specific pre-processor to override
		/// </summary>
		/// <param name="commandSet"></param>
		/// <returns></returns>
		protected override bool PrepareStringThenSend(CommandSet commandSet) {
			myLastCommand = commandSet.StandardCommand;
			switch (myLastCommand) {
				case StandardCommandsEnum.AudioVideoSwitcherRoute:
					var values = commandSet.Command.Split(',');
					var inputId = Convert.ToInt32(values[0]) % 1000;
					var outputId = Convert.ToInt32(values[1]) % 1000;

					myLastData["input"] = values[0];
					myLastData["output"] = values[1];

					commandSet.Command = $"port/set/{inputId}/{outputId}";
					SendMeData($"Sending Routing Command: {commandSet.Command}");
					break;
				case StandardCommandsEnum.AudioVideoSwitcherRoutePoll:
				case StandardCommandsEnum.TemperaturePoll:
				case StandardCommandsEnum.PowerPoll:
					SendMeData($"Sending Command: {commandSet.Command}");
					break;
				default:
					SendMeData($"Unhandled command: {commandSet.StandardCommand}, Command = {commandSet.Command}");
					return true; //Don't send message
			}
			//if (commandSet.Parameters == null)
			SendMeData("Setting Parameters to GET.");
			commandSet.Parameters = new Object[] { RequestType.Get };
			//bool foundRequestType = false;
			for(int i = 0; i < commandSet.Parameters.Length; i++)
            {
				SendMeData("Parameter " + i.ToString() + ": " + commandSet.Parameters[i].ToString());
				if(commandSet.Parameters[i].GetType() == typeof(RequestType))
                {
					if ((RequestType)commandSet.Parameters[i] == RequestType.Get)
					{
						SendMeData("Object of type RequestType Found. Already GET");
					} else
					{
						SendMeData("Object of type RequestType Found. Leaving as is");
						//commandSet.Parameters[i] = RequestType.Get;
					}
					//foundRequestType = true;
                }
            }
			/*if(!foundRequestType)
            {
				SendMeData("Object of type RequestType still not found. Adding it");
				Object[] temp = commandSet.Parameters;
				Array.Resize(ref temp, commandSet.Parameters.Length + 1);
				temp[temp.GetUpperBound(0)] = RequestType.Get;
				commandSet.Parameters = temp;
            }*/

			return base.PrepareStringThenSend(commandSet);
		}

		/// <summary>
		/// Wrapper for Log command
		/// </summary>
		/// <param name="data"></param>
		private void SendMeData(string data) {
			Log(data);
		}
	}
}