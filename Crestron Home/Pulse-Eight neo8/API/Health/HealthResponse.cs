using Newtonsoft.Json;

namespace PulseEight.Neo8.IP.API.Health {
	public class HealthResponse : BaseResponse {
		[JsonProperty]
		public int Temperature0 { set; get; }
		[JsonProperty]
		public int Temperature1 { set; get; }
		[JsonProperty]
		public int Temperature2 { set; get; }
		[JsonProperty]
		public int Temperature3 { set; get; }
		[JsonProperty]
		public int Temperature4 { set; get; }
	}
}