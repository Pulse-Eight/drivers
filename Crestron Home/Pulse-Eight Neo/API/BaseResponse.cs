using Newtonsoft.Json;

namespace PulseEight.Neo.IP.API {
	public class BaseResponse {
		[JsonProperty]
		public bool Result { set; get; }

	}
}