using System;
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
			Log($"Switcher Route Data: {response}");
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

			Log($"Routing Data: {response}");
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
			Log("Instructing Crestron that the device is On");
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
						Log($"Updated temperature to: {CurrentTemperature} {CurrentTemperatureUnits}");
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
						Log($"Unhandled response from device: {response}");
						break;
				}
			} catch (Exception ex) {
				if (myLastCommand == StandardCommandsEnum.PowerPoll) {
					PowerIsOn = false;
				}
				Log($"Failed to unpack response: {ex}: original data: '{response}'");
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
			RuntimeLogger.Trace($"PrepareStringThenSend: {commandSet.StandardCommand}, Command = {commandSet.Command}");
			switch (myLastCommand) {
				case StandardCommandsEnum.AudioVideoSwitcherRoute:
					var values = commandSet.Command.Split(',');
					if (values.Length < 2) {
						RuntimeLogger.Error("PrepareStringThenSend: Less than 2 values sent");
					} else {
						var inputStr = values[0];
						var outputStr = values[1];

						var success = int.TryParse(inputStr, out var inputId);
						success &= int.TryParse(outputStr, out var outputId);
						if (!success) {
							// Input ID is not parseable as an integer - it's likely to be a string
							if (values[0] == "NONE") {
								RuntimeLogger.Info($"PrepareStringThenSend: Requested a clear on output {outputId}. No command sent to device");
							} else {
								RuntimeLogger.Warning($"PrepareStringThenSend: Unknown values passed to AudioVideoSwitcherRoute: {inputStr} {outputStr}");
							}
							return true;
						}

						// Strip out the prefix and convert to device IDs
						outputId %= 1000;
						inputId %= 1000;

						myLastData["input"] = inputStr;
						myLastData["output"] = outputStr;

						commandSet.Command = $"port/set/{inputId}/{outputId}";
						RuntimeLogger.Trace($"Sending Routing Command: {commandSet.Command}");
					}

					break;
				case StandardCommandsEnum.AudioVideoSwitcherRoutePoll:
				case StandardCommandsEnum.TemperaturePoll:
				case StandardCommandsEnum.PowerPoll:
					Log($"Sending Command: {commandSet.Command}");
					break;
				default:
					Log($"Unhandled command: {commandSet.StandardCommand}, Command = {commandSet.Command}");
					return true; //Don't send message
			}
			commandSet.Parameters = new object[] { RequestType.Get };
			return base.PrepareStringThenSend(commandSet);
		}
	}
}