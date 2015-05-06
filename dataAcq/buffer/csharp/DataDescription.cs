using System.Collections;

namespace FieldTrip.Buffer
{
    /// <summary>
    /// Datastructure describing data read from a FieldTripBuffer.
    /// </summary>
	public class DataDescription
	{
        /// <summary>
        /// Number of samples.
        /// </summary>
		public int NumSamples{ get; set; }

        /// <summary>
        /// Number of channels.
        /// </summary>
		public int NumChans{ get; set; }

        /// <summary>
        /// Datatype of the data.
        /// </summary>
		public int DataType{ get; set; }

        /// <summary>
        /// The size of the data in bytes.
        /// </summary>
		public int SizeBytes{ get; set; }
	}
}