namespace FieldTrip.Buffer
{
    /// <summary>
    /// Represents the amount of samples and events available after a Wait*() call from <see cref="FieldTrip.Buffer.BufferClient"/> or <see cref="FieldTrip.Buffer.BufferClientClock"/>.
    /// </summary>
	public class SamplesEventsCount
    {
        /// <summary>
        /// Initialize an instance with the given values.
        /// </summary>
        /// <param name="nSamples">The </param>
        /// <param name="nEvents"></param>
		public SamplesEventsCount(int nSamples, int nEvents)
        {
            this.NumSamples = nSamples;
            this.NumEvents = nEvents;
        }

        /// <summary>
        /// The number of samples available.
        /// </summary>
        public int NumSamples { get; set; }

        /// <summary>
        /// The number of events available.
        /// </summary>
		public int NumEvents { get; set; }
    }
}