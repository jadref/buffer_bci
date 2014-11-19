using System.Collections;

namespace FieldTrip.Buffer
{
	public class SamplesEventsCount {
		public SamplesEventsCount(int nSamples, int nEvents) {
			this.nSamples = nSamples;
			this.nEvents  = nEvents;
		}
		
		public int nSamples;
		public int nEvents;
	}
}
