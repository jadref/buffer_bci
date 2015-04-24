namespace FieldTrip.Buffer
{
	public class SamplesEventsCount {
		public SamplesEventsCount(int nSamples, int nEvents) {
			this.NumSamples = nSamples;
			this.NumEvents  = nEvents;
		}
		
		public int NumSamples { get; set; }
		public int NumEvents { get; set; }
	}
}
