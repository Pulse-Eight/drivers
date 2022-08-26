using Newtonsoft.Json;

namespace PulseEight.Neo.IP.API.Routing {
	public class RoutingResponse : BaseResponse {
		[JsonProperty]
		public string Message { set; get; }
	}
}