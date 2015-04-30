using System.Text;

namespace FieldTrip.Buffer
{
    /// <summary>
    /// A datastructure containing information about the number of channels, samples, events, etc. in the FieldTrip buffer.
    /// </summary>
	public class Header
	{
		public const int CHUNK_UNKNOWN = 0;
		public const int CHUNK_CHANNEL_NAMES = 1;
		public const int CHUNK_CHANNEL_FLAGS = 2;
		public const int CHUNK_RESOLUTIONS = 3;
		public const int CHUNK_ASCII_KEYVAL = 4;
		public const int CHUNK_NIFTI1 = 5;
		public const int CHUNK_SIEMENS_AP = 6;
		public const int CHUNK_CTF_RES4 = 7;


        /// <summary>
        /// Initializes a Header from the specified <see cref="FieldTrip.Buffer.ByteBuffer"/>.
        /// </summary>
        /// <param name="buf">The buffer to read the header from.</param>
		public Header(ByteBuffer buf)
		{
			NumChans = buf.GetInt();
			NumSamples = buf.GetInt();
			NumEvents = buf.GetInt();
			FSample = buf.GetFloat();
			DataType = buf.GetInt();
			int size = buf.GetInt();
			Labels = new string[NumChans];
		
			while (size > 0) {
				int chunkType = buf.GetInt();
				int chunkSize = buf.GetInt();
				byte[] bs = new byte[chunkSize];
				buf.Get(ref bs);
				
				if (chunkType == CHUNK_CHANNEL_NAMES) {
					int n = 0, len = 0, index = 0;
					for (int pos = 0; pos < chunkSize; pos++) {
						if (bs[pos] == 0) {
							if (len > 0) {
								Labels[n] = Encoding.Default.GetString(bs, index, len);
								index = pos + 1;
							}
							len = 0;
							if (++n == NumChans)
								break;
						} else {
							len++;
						}
					}
				} else {
					// ignore all other chunks for now
				}
				size -= 8 + chunkSize;
			}
		}

        /// <summary>
        /// Initializes a header from the specified parameters.
        /// </summary>
        /// <param name="nChans">The number of channels.</param>
        /// <param name="fSample"></param>
        /// <param name="dataType">The datatype.</param>
		public Header(int nChans, float fSample, int dataType)
		{
			this.NumChans = nChans;
			this.FSample = fSample;
			this.NumSamples = 0;
			this.NumEvents = 0;
			this.DataType = dataType;
			this.Labels = new string[nChans]; // allocate, but do not fill
		}

        /// <summary>
        /// Determine the size of the serialized representation of this instance.
        /// </summary>
        /// <returns>A size in bytes.</returns>
		public int GetSerialSize()
		{
			int size = 24;
		
			if (Labels.Length == NumChans) {
				ChannelNameSize = 0;
				for (int i = 0; i < NumChans; i++) {
					ChannelNameSize++;
					if (Labels[i] != null)
						ChannelNameSize += Labels[i].ToString().ToCharArray().Length;
				}
				if (ChannelNameSize > NumChans) {
					// we've got more than just empty string
					size += 8 + ChannelNameSize;
				}
			}
			return size;
		}

        /// <summary>
        /// Serializes the Header to the specified buffer.
        /// </summary>
        /// <param name="buf">The buffer to write the serialized header to.</param>
		public void Serialize(ByteBuffer buf)
		{
			buf.PutInt(NumChans);
			buf.PutInt(NumSamples);
			buf.PutInt(NumEvents);
			buf.PutFloat(FSample);
			buf.PutInt(DataType);
			if (ChannelNameSize <= NumChans) {
				// channel names are all empty or array length does not match
				buf.PutInt(0);
			} else {
				buf.PutInt(8 + ChannelNameSize);	// 8 bytes for chunk def
				buf.PutInt(CHUNK_CHANNEL_NAMES);
				buf.PutInt(ChannelNameSize);
				for (int i = 0; i < NumChans; i++) {
					if (Labels[i] != null)
						buf.PutString(Labels[i]);
					buf.PutByte((byte)0);
				}
			} 
		}

		public int ChannelNameSize{ get; set; }

		public int DataType{ get; set; }

		public float FSample{ get; set; }

		/// <summary>
		/// Gets or sets the number channels.
		/// </summary>
		/// <value>The number of channels.</value>
		public int NumChans{ get; set; }

		/// <summary>
		/// Gets or sets the number samples.
		/// </summary>
		/// <value>The number samples.</value>
		public int NumSamples{ get; set; }

		/// <summary>
		/// Gets or sets the number events.
		/// </summary>
		/// <value>The number events.</value>
		public int NumEvents{ get; set; }

		/// <summary>
		/// Gets or sets the labels.
		/// </summary>
		/// <value>The labels.</value>
		public string[] Labels{ get; set; }
	}
}