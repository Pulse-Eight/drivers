using Newtonsoft.Json;

namespace PulseEight.Neo8.IP.API {
	public class BaseResponse {
		[JsonProperty]
		public bool Result { set; get; }

	}
}