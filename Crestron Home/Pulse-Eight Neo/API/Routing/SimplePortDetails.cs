using Newtonsoft.Json;

namespace PulseEight.Neo.IP.API.Routing {
	public class SimplePortDetails {
		[JsonProperty]
		public int Bay { set; get; }
		[JsonProperty]
		public string Mode { set; get; }
		[JsonProperty]
		public string Type { set; get; }
		[JsonProperty]
		public int Status { set; get; }
		[JsonProperty]
		public string Name { set; get; }

		[JsonProperty]
		public int ReceiveFrom { set; get; }
	}
}