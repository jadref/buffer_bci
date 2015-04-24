using System.Collections;

namespace FieldTrip.Buffer
{
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
								Labels[n] = System.Text.Encoding.Default.GetString(bs, index, len);
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

		public Header(int nChans, float fSample, int dataType)
		{
			this.NumChans = nChans;
			this.FSample = fSample;
			this.NumSamples = 0;
			this.NumEvents = 0;
			this.DataType = dataType;
			this.Labels = new string[nChans]; // allocate, but do not fill
		}

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