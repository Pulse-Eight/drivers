using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace PulseEight.Neo.IP.API.Routing {
	public class RoutingDetails : BaseResponse {
		[JsonProperty]
		public List<SimplePortDetails> Ports { set; get; }
	}
}