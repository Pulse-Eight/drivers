using Crestron.RAD.Common.Interfaces;
using Crestron.RAD.Common.Transports;
using Crestron.RAD.DeviceTypes.AudioVideoSwitcher;
using Crestron.SimplSharp;

namespace PulseEight.Neo.IP {
	public class PulseEightNeoIP : AAudioVideoSwitcher, ITcp {
		public void Initialize(IPAddress ipAddress, int port) {
			var httpTransport = new HttpTransport {
				EnableLogging = InternalEnableLogging,
				CustomLogger = InternalCustomLogger,
				EnableRxDebug = InternalEnableRxDebug,
				EnableTxDebug = InternalEnableTxDebug,
			};

			httpTransport.Initialize(ipAddress, port);
			ConnectionTransport = httpTransport;

			AudioVideoSwitcherProtocol =
				new PulseEightNeoProtocol((HttpTransport)ConnectionTransport, Id) {
					EnableLogging = InternalEnableLogging,
					CustomLogger = InternalCustomLogger
				};

			AudioVideoSwitcherProtocol.RxOut += SendRxOut;
			AudioVideoSwitcherProtocol.Initialize(AudioVideoSwitcherData);
        }
	}
}