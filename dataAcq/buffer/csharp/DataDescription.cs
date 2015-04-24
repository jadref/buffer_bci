using System.Collections;

namespace FieldTrip.Buffer
{
	public class DataDescription
	{
		public int NumSamples{ get; set; }

		public int NumChans{ get; set; }

		public int DataType{ get; set; }

		public int SizeBytes{ get; set; }
	}
}