using System.Collections;

namespace FieldTrip.Buffer
{
	public class Header {
		public const int CHUNK_UNKNOWN = 0;
		public const int CHUNK_CHANNEL_NAMES = 1;
		public const int CHUNK_CHANNEL_FLAGS = 2;
		public const int CHUNK_RESOLUTIONS = 3;
		public const int CHUNK_ASCII_KEYVAL = 4;
		public const int CHUNK_NIFTI1 = 5;
		public const int CHUNK_SIEMENS_AP = 6;
		public const int CHUNK_CTF_RES4 = 7;
		
	
		public Header(ByteBuffer buf) {
			nChans   = buf.getInt();
			nSamples = buf.getInt();
			nEvents  = buf.getInt();
			fSample  = buf.getFloat();
			dataType = buf.getInt();
			int size = buf.getInt();
			labels   = new string[nChans];
		
			while (size > 0) {
				int chunkType = buf.getInt();
				int chunkSize = buf.getInt();
				byte[] bs = new byte[chunkSize];
				buf.get(ref bs);
				
				if (chunkType == CHUNK_CHANNEL_NAMES) {
					int n = 0, len = 0, index =0;
					for (int pos = 0;pos<chunkSize;pos++) {
						if (bs[pos]==0) {
							if (len>0) {
								labels[n] =System.Text.Encoding.Default.GetString(bs, index, len);
								index = pos +1;
							}
							len = 0;
							if (++n == nChans) break;
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
		
		public Header(int nChans, float fSample, int dataType) {
			this.nChans   = nChans;
			this.fSample  = fSample;
			this.nSamples = 0;
			this.nEvents  = 0;
			this.dataType = dataType;
			this.labels   = new string[nChans]; // allocate, but do not fill
		}
		
		public int getSerialSize() {
			int size = 24;
		
			if (labels.Length == nChans) {
				channelNameSize = 0;
				for (int i=0;i<nChans;i++) {
					channelNameSize++;
					if (labels[i] != null) 
						channelNameSize += labels[i].ToString().ToCharArray().Length;
				}
				if (channelNameSize > nChans) {
					// we've got more than just empty string
					size += 8 + channelNameSize;
				}
			}
			return size;
		}
		
		public void serialize(ByteBuffer buf) {
			buf.putInt(nChans);
			buf.putInt(nSamples);
			buf.putInt(nEvents);
			buf.putFloat(fSample);
			buf.putInt(dataType);
			if (channelNameSize <= nChans) {
				// channel names are all empty or array length does not match
				buf.putInt(0);
			} else {
				buf.putInt(8 + channelNameSize);	// 8 bytes for chunk def
				buf.putInt(CHUNK_CHANNEL_NAMES);
				buf.putInt(channelNameSize);
				for (int i=0;i<nChans;i++) {
					if (labels[i] != null) 
						buf.putString( labels[i]);
					buf.putByte((byte) 0);
				}
			} 
		}
		
		public int channelNameSize;
	
		public int dataType;
		public float fSample;
		public int nChans;
		public int nSamples;
		public int nEvents;
		public string[] labels;
	}
}