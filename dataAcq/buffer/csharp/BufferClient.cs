using System.IO;
using System.Collections.Generic;

namespace FieldTrip.Buffer
{
	public class BufferClient
	{
		public const short VERSION = 1;
		public const short GET_HDR = 0x201;
		public const short GET_DAT = 0x202;
		public const short GET_EVT = 0x203;
		public const short GET_OK = 0x204;
		public const short GET_ERR = 0x205;
	
		public const short PUT_HDR = 0x101;
		public const short PUT_DAT = 0x102;
		public const short PUT_EVT = 0x103;
		public const short PUT_OK = 0x104;
		public const short PUT_ERR = 0x105;
	
		public const short FLUSH_HDR = 0x301;
		public const short FLUSH_DAT = 0x302;
		public const short FLUSH_EVT = 0x303;
		public const short FLUSH_OK = 0x304;
		public const short FLUSH_ERR = 0x305;
	
		public const short WAIT_DAT = 0x402;
		public const short WAIT_OK = 0x404;
		public const short WAIT_ERR = 0x405;
		
		public const short NO_ERROR = 0x505;
		public const short BUFFER_READ_ERROR = 0x506;
		public const short VERSION_ERROR = 0x507;
		public const short BUFFER_NOT_MATCH_DESCRIPTION_ERROR = 0x508;
		public const short INVALID_EVENT_DEF_ERROR = 0x509;
		public const short INVALID_SIZE_DATA_DEF_ERROR = 0x510;

		public SocketChannel SockChan{ get; set; }

		public bool activeConnection{ get; protected set; }

		protected bool autoReconnect;
		protected string host;
		protected int port;
		protected ByteOrder myOrder;
		internal int errorReturned;

		public BufferClient()
		{
			myOrder = ByteOrder.NativeOrder();
		}

		public BufferClient(ByteOrder order)
		{
			myOrder = order;
		}

		/// <summary>
		/// Connect to the FieldTrip buffer at the specified hostname and port.
		/// </summary>
		/// <param name="hostname">Hostname.</param>
		/// <param name="port">Port.</param>
		virtual public bool Connect(string hostname, int port)
		{
			// if ( sockChan == null )
			// 	{
			SockChan = new SocketChannel();  
			// }
			// else if ( sockChan != null && sockChan.isConnected()) {
			//	disconnect(); // disconnect old connection
			//}
			SockChan.Connect(hostname, port);
			activeConnection = SockChan.IsConnected;
			if (activeConnection) { // cache the connection info
				this.host = hostname;
				this.port = port;
			}
			return activeConnection;
		}

		/// <summary>
		/// Connect to the FieldTrip buffer at the given address.
		/// </summary>
		/// <param name="address">Address of format: 'hostname:port'</param>
		public bool Connect(string address)
		{
			int colonPos = address.LastIndexOf(':');
			if (colonPos != -1) {
				string hostname = address.Substring(0, colonPos);
				int port = int.Parse(address.Substring(colonPos + 1));
				
				return Connect(hostname, port);
			}
			throw new IOException("Address format not recognized / supported yet.");
		}

		/// <summary>
		/// Reconnect this instance to the FieldTrip buffer.
		/// </summary>
		public bool Reconnect()
		{
			System.Console.WriteLine("Remote side disconnected detected. Trying to reconnect to : " + host + ":" + port);
			return Connect(host, port);
		}

		/// <summary>
		/// Disconnect this instance from the FieldTrip buffer.
		/// </summary>
		public void Disconnect()
		{
			if (SockChan != null)
				SockChan.Close();		 
			SockChan = null;
			activeConnection = false;
		}

		/// <summary>
		/// Gets a value indicating whether this instance is connected.
		/// </summary>
		/// <value><c>true</c> if this instance is connected; otherwise, <c>false</c>.</value>
		public bool IsConnected {
			get {
				if (activeConnection && SockChan != null && SockChan.IsConnected) {
					try {
						// part1 indicates whether error or connected.
						bool part1 = SockChan.Socket.Client.Poll(1000, System.Net.Sockets.SelectMode.SelectRead);

						// part2 indicates whether data is still available.
						bool part2 = SockChan.Socket.Client.Available == 0;

						// if both parts are true, socket is dead.
						if (part1 && part2)
							return false;
						else
							return true;
					} catch (IOException) {
					}
				}

				return false;
			}
		}

		/// <summary>
		/// Retrieves the header.
		/// </summary>
		/// <returns>The header or null if the header couldn't be retrieved.</returns>
		virtual public Header GetHeader()
		{
			ByteBuffer buf;
	
			buf = ByteBuffer.Allocate(8);
			buf.Order(myOrder);
		
			buf = buf.PutShort(VERSION);
			buf = buf.PutShort(GET_HDR);
			buf = buf.PutInt(0);
			buf.Rewind();
			WriteAll(buf);
		
			buf = ReadResponse(GET_OK);
			Header hdr = new Header(buf);
			return hdr;
		}

		/// <summary>
		/// Puts the header.
		/// </summary>
		/// <returns><c>true</c>, if channel names were written, <c>false</c> otherwise.</returns>
		/// <param name="hdr">Hdr.</param>
		public bool PutHeader(Header hdr)
		{
			ByteBuffer buf;
			int bufsize = hdr.GetSerialSize();
	
			buf = ByteBuffer.Allocate(8 + bufsize);
			buf.Order(myOrder);
		
			buf.PutShort(VERSION).PutShort(PUT_HDR).PutInt(bufsize);
			hdr.Serialize(buf);
			buf.Rewind();
			WriteAll(buf);
			ReadResponse(PUT_OK);
			return hdr.ChannelNameSize > hdr.NumChans;
		}

		public short[,] GetShortData(int first, int last)
		{
			DataDescription dd = new DataDescription();
			ByteBuffer buf = GetRawData(first, last, dd);
		
			int nSamples = dd.NumSamples;
			int nChans = dd.NumChans;
			
			short[,] data = new short[nSamples, nChans];
			
			switch (dd.DataType) {
				case DataType.INT8:
					for (int i = 0; i < nSamples; i++) {
						for (int j = 0; j < nChans; j++) {
							data[i, j] = (short)buf.Get();
						}
					}
					break;
				case DataType.INT16:
					ShortBuffer sBuf = buf.AsShortBuffer();
					short[] rowData;
					for (int n = 0; n < nSamples; n++) {
						rowData = GetRow<short>(data, n);
						sBuf.Get(rowData);
					}
					break;
				default:
					throw new IOException("Not supported yet - returning zeros.");	
			}
		
			return data;
		}

		public int[,] GetIntData(int first, int last)
		{
			DataDescription dd = new DataDescription();
			ByteBuffer buf = GetRawData(first, last, dd);
		
			int nSamples = dd.NumSamples;
			int nChans = dd.NumChans;
			
			int[,] data = new int[nSamples, nChans];
			
			switch (dd.DataType) {
				case DataType.INT8:
					for (int i = 0; i < nSamples; i++) {
						for (int j = 0; j < nChans; j++) {
							data[i, j] = (int)buf.Get();
						}
					}
					break;
				case DataType.INT16:
					for (int i = 0; i < nSamples; i++) {
						for (int j = 0; j < nChans; j++) {
							data[i, j] = (int)buf.GetShort();
						}
					}
					break;
				case DataType.INT32:
					IntBuffer iBuf = buf.AsIntBuffer();
					int[] rowData;
					for (int n = 0; n < nSamples; n++) {
						rowData = GetRow<int>(data, n);
						iBuf.Get(rowData);
					}
					break;
				default:
					throw new IOException("Not supported yet - returning zeros.");
			}
		
			return data;
		}

		public long[,] GetLongData(int first, int last)
		{
			DataDescription dd = new DataDescription();
			ByteBuffer buf = GetRawData(first, last, dd);
		
			int nSamples = dd.NumSamples;
			int nChans = dd.NumChans;
			
			long[,] data = new long[nSamples, nChans];
			
			switch (dd.DataType) {
				case DataType.INT8:
					for (int i = 0; i < nSamples; i++) {
						for (int j = 0; j < nChans; j++) {
							data[i, j] = (int)buf.Get();
						}
					}
					break;
				case DataType.INT16:
					for (int i = 0; i < nSamples; i++) {
						for (int j = 0; j < nChans; j++) {
							data[i, j] = (int)buf.GetShort();
						}
					}
					break;
				case DataType.INT32:
					for (int i = 0; i < nSamples; i++) {
						for (int j = 0; j < nChans; j++) {
							data[i, j] = (int)buf.GetInt();
						}
					}
					break;
				case DataType.INT64:
					LongBuffer lBuf = buf.AsLongBuffer();
					long[] rowData;
					for (int n = 0; n < nSamples; n++) {
						rowData = GetRow<long>(data, n);
						lBuf.Get(rowData);
					}
					break;
				default:
					throw new IOException("Not supported yet - returning zeros.");
			}
		
			return data;
		}

		public float[,] GetFloatData(int first, int last)
		{
			DataDescription dd = new DataDescription();
			ByteBuffer buf = GetRawData(first, last, dd);

			int nSamples = dd.NumSamples;
			int nChans = dd.NumChans;
			
			float[,] data = new float[nSamples, nChans];
			
			switch (dd.DataType) {
				case DataType.INT8:
					for (int i = 0; i < nSamples; i++) {
						for (int j = 0; j < nChans; j++) {
							data[i, j] = (float)buf.Get();
						}
					}
					break;
				case DataType.INT16:
					for (int i = 0; i < nSamples; i++) {
						for (int j = 0; j < nChans; j++) {
							data[i, j] = (float)buf.GetShort();
						}
					}
					break;
				case DataType.INT32:
					for (int i = 0; i < nSamples; i++) {
						for (int j = 0; j < nChans; j++) {
							data[i, j] = (float)buf.GetInt();
						}
					}
					break;
				case DataType.FLOAT32:
					for (int i = 0; i < nSamples; i++) {
						for (int j = 0; j < nChans; j++) {
							data[i, j] = (float)buf.GetFloat();
						}
					}
					break;
				case DataType.FLOAT64:
					for (int i = 0; i < nSamples; i++) {
						for (int j = 0; j < nChans; j++) {
							data[i, j] = (float)buf.GetDouble();
						}
					}
					break;
				default:
					throw new IOException("Not supported yet - returning zeros.");
			}
		
			return data;
		}

		public double[,] GetDoubleData(int first, int last)
		{
			DataDescription dd = new DataDescription();
			ByteBuffer buf = GetRawData(first, last, dd);
		
			int nSamples = dd.NumSamples;
			int nChans = dd.NumChans;
			
			double[,] data = new double[nSamples, nChans];
			
			switch (dd.DataType) {
				case DataType.INT8:
					for (int i = 0; i < nSamples; i++) {
						//data[i] = new double[nChans];
						for (int j = 0; j < nChans; j++) {
							data[i, j] = (double)buf.Get();
						}
					}
					break;
				case DataType.INT16:
					for (int i = 0; i < nSamples; i++) {
						for (int j = 0; j < nChans; j++) {
							data[i, j] = (double)buf.GetShort();
						}
					}
					break;
				case DataType.INT32:
					for (int i = 0; i < nSamples; i++) {
						for (int j = 0; j < nChans; j++) {
							data[i, j] = (double)buf.GetInt();
						}
					}
					break;	
				case DataType.INT64:
					for (int i = 0; i < nSamples; i++) {
						for (int j = 0; j < nChans; j++) {
							data[i, j] = (double)buf.GetLong();
						}
					}
					break;		
				case DataType.FLOAT32:
					for (int i = 0; i < nSamples; i++) {
						for (int j = 0; j < nChans; j++) {
							data[i, j] = buf.GetFloat();
						}
					}
					break;
				case DataType.FLOAT64:
					DoubleBuffer dBuf = buf.AsDoubleBuffer();
					double[] rowData;
					for (int n = 0; n < nSamples; n++) {
						rowData = GetRow<double>(data, n);
						dBuf.Get(rowData);
					}
					break;
				default:
					throw new IOException("Not supported yet - returning zeros.");
			}
		
			return data;
		}

		
		public ByteBuffer GetRawData(int first, int last, DataDescription descr)
		{
			ByteBuffer buf;
			
			buf = ByteBuffer.Allocate(16);
			buf.Order(myOrder);
			
			buf.PutShort(VERSION).PutShort(GET_DAT).PutInt(8);
			buf.PutInt(first).PutInt(last).Rewind();
			WriteAll(buf);
			buf = ReadResponse(GET_OK);
			
			descr.NumChans = buf.GetInt();
			descr.NumSamples = buf.GetInt();
			descr.DataType = buf.GetInt();
			descr.SizeBytes = buf.GetInt();
			
			int dataSize = descr.NumChans * descr.NumSamples * DataType.wordSize[descr.DataType];
			if (dataSize > descr.SizeBytes || descr.SizeBytes > buf.Remaining) {
				errorReturned = INVALID_SIZE_DATA_DEF_ERROR;
				throw new IOException("Invalid size definitions in response from GET DATA request");
			}
			
			return buf.Slice();
		}

		/// <summary>
		/// Gets all events from the FieldTrip buffer.
		/// </summary>
		/// <returns>The events.</returns>
		public BufferEvent[] GetEvents()
		{
			ByteBuffer buf;
	
			buf = ByteBuffer.Allocate(8);
			buf.Order(myOrder); 
		
			buf.PutShort(VERSION).PutShort(GET_EVT).PutInt(0).Rewind();
		
			WriteAll(buf);
			buf = ReadResponse(GET_OK);
		
			int numEvt = BufferEvent.Count(buf);
			if (numEvt < 0) {
				errorReturned = INVALID_EVENT_DEF_ERROR;
				throw new IOException("Invalid event definitions in response.");
			}
			
			BufferEvent[] evs = new BufferEvent[numEvt];
			for (int n = 0; n < numEvt; n++) {
				evs[n] = new BufferEvent(buf);
			}
			return evs;
		}


		/// <summary>
		/// Gets the events between first and last.
		/// </summary>
		/// <returns>The events.</returns>
		/// <param name="first">The first event number.</param>
		/// <param name="last">The last event number.</param>
		public BufferEvent[] GetEvents(int first, int last)
		{
			ByteBuffer buf;
	
			buf = ByteBuffer.Allocate(16);
			buf.Order(myOrder); 
		
			buf.PutShort(VERSION).PutShort(GET_EVT).PutInt(8);
			buf.PutInt(first).PutInt(last).Rewind();
		
			WriteAll(buf);
			buf = ReadResponse(GET_OK);
		
			int numEvt = BufferEvent.Count(buf);
			if (numEvt != (last - first + 1)) { 
				errorReturned = INVALID_EVENT_DEF_ERROR;
				throw new IOException("Invalid event definitions in response.");
			}
			
			BufferEvent[] evs = new BufferEvent[numEvt];
			for (int n = 0; n < numEvt; n++) {
				evs[n] = new BufferEvent(buf);
			}
			return evs;
		}

		public void PutRawData(int nSamples, int nChans, int dataType, byte[] data)
		{
			if (nSamples == 0)
				return;
			if (nChans == 0)
				return;
		
			if (data.Length != nSamples * nChans * DataType.wordSize[dataType]) {
				errorReturned = BUFFER_NOT_MATCH_DESCRIPTION_ERROR;
				throw new IOException("Raw buffer does not match data description");
			}
			
			ByteBuffer buf = PreparePutData(nChans, nSamples, dataType);
			buf.Put(data);
			buf.Rewind();
			WriteAll(buf);
			ReadResponse(PUT_OK);
		}

		public void PutData(byte[,] data)
		{
			int nSamples = data.GetLength(0);
			if (nSamples == 0)
				return;
			int nChans = data.GetLength(1);
			if (nChans == 0)
				return;
		
			ByteBuffer buf = PreparePutData(nChans, nSamples, DataType.INT8);
			byte[] rowData;
			for (int i = 0; i < nSamples; i++) {
				rowData = GetRow<byte>(data, i);
				buf.Put(rowData);
			}
			buf.Rewind();
			WriteAll(buf);
			ReadResponse(PUT_OK);
		}

		public void PutData(short[,] data)
		{
			int nSamples = data.GetLength(0);
			if (nSamples == 0)
				return;
			int nChans = data.GetLength(1);
			if (nChans == 0)
				return;
		
			ByteBuffer buf = PreparePutData(nChans, nSamples, DataType.INT16);
			short[] rowData;
			for (int i = 0; i < nSamples; i++) {
				rowData = GetRow<short>(data, i);
				buf.AsShortBuffer().Put(rowData);
			}
			buf.Rewind();
			WriteAll(buf);
			ReadResponse(PUT_OK);
		}

		public void PutData(int[,] data)
		{
			int nSamples = data.GetLength(0);
			if (nSamples == 0)
				return;
			int nChans = data.GetLength(1);
			if (nChans == 0)
				return;
		
			ByteBuffer buf = PreparePutData(nChans, nSamples, DataType.INT32);
			int[] rowData;
			for (int i = 0; i < nSamples; i++) {
				rowData = GetRow<int>(data, i);
				buf.AsIntBuffer().Put(rowData);
			}
			buf.Rewind();
			WriteAll(buf);
			ReadResponse(PUT_OK);
		}

		public void PutData(long[,] data)
		{
			int nSamples = data.GetLength(0);
			if (nSamples == 0)
				return;
			int nChans = data.GetLength(1);
			if (nChans == 0)
				return;
		
			ByteBuffer buf = PreparePutData(nChans, nSamples, DataType.INT64);
			long[] rowData;
			for (int i = 0; i < nSamples; i++) {
				rowData = GetRow<long>(data, i);
				buf.AsLongBuffer().Put(rowData);
			}
			buf.Rewind();
			WriteAll(buf);
			ReadResponse(PUT_OK);
		}

		public void PutData(float[,] data)
		{
			int nSamples = data.GetLength(0);
			if (nSamples == 0)
				return;
			int nChans = data.GetLength(1);
			if (nChans == 0)
				return;
		
			ByteBuffer buf = PreparePutData(nChans, nSamples, DataType.FLOAT32);
			float[] rowData;
			for (int i = 0; i < nSamples; i++) {
				rowData = GetRow<float>(data, i);
				buf.AsFloatBuffer().Put(rowData);
			}
			buf.Rewind();
			WriteAll(buf);
			ReadResponse(PUT_OK);
		}

		public void PutData(double[,] data)
		{
			int nSamples = data.GetLength(0);
			if (nSamples == 0)
				return;
			int nChans = data.GetLength(1);
			if (nChans == 0)
				return;

			ByteBuffer buf = PreparePutData(nChans, nSamples, DataType.FLOAT64);
			double[] rowData;
			for (int i = 0; i < nSamples; i++) {
				rowData = GetRow<double>(data, i);
				buf.AsDoubleBuffer().Put(rowData);
			}
			buf.Rewind();
			WriteAll(buf);
			ReadResponse(PUT_OK);
		}

		/// <summary>
		/// Sends the given event to the FieldTrip buffer.
		/// </summary>
		/// <returns>The event.</returns>
		/// <param name="e">The event to send.</param>
		virtual public BufferEvent PutEvent(BufferEvent e)
		{
			ByteBuffer buf;
			int eventSize = e.Size();
			buf = ByteBuffer.Allocate(8 + eventSize);
			buf.Order(myOrder); 
		
			buf.PutShort(VERSION).PutShort(PUT_EVT).PutInt(e.Size());
			e.Serialize(buf);
			buf.Rewind();
			WriteAll(buf);
			ReadResponse(PUT_OK);
			return e;
		}

		/// <summary>
		/// Puts the given array of events to the FieldTrip buffer.
		/// </summary>
		/// <param name="e">The events to send.</param>
		virtual public void PutEvents(BufferEvent[] e)
		{
			ByteBuffer buf;
			int bufsize = 0;
		
			for (int i = 0; i < e.Length; i++) {
				bufsize += e[i].Size();
			}
	
			buf = ByteBuffer.Allocate(8 + bufsize);
			buf.Order(myOrder); 
		
			buf.PutShort(VERSION).PutShort(PUT_EVT).PutInt(bufsize);
			for (int i = 0; i < e.Length; i++) {
				e[i].Serialize(buf);
			}
			buf.Rewind();
			WriteAll(buf);
			ReadResponse(PUT_OK);
		}

		public void FlushHeader()
		{
			ByteBuffer buf = ByteBuffer.Allocate(8);
			buf.Order(myOrder); 
		
			buf.PutShort(VERSION).PutShort(FLUSH_HDR).PutInt(0).Rewind();
			WriteAll(buf);
			buf = ReadResponse(FLUSH_OK);
		}

		public void FlushData()
		{
			ByteBuffer buf = ByteBuffer.Allocate(8);
			buf.Order(myOrder); 
		
			buf.PutShort(VERSION).PutShort(FLUSH_DAT).PutInt(0).Rewind();
			WriteAll(buf);
			buf = ReadResponse(FLUSH_OK);
		}

		public void FlushEvents()
		{
			ByteBuffer buf = ByteBuffer.Allocate(8);
			buf.Order(myOrder); 
		
			buf.PutShort(VERSION).PutShort(FLUSH_EVT).PutInt(0).Rewind();
			WriteAll(buf);
			buf = ReadResponse(FLUSH_OK);
		}

		virtual public SamplesEventsCount Wait(int nSamples, int nEvents, int timeout)
		{
			ByteBuffer buf;
			SamplesEventsCount secount = null;
	
			buf = ByteBuffer.Allocate(20);
			buf.Order(myOrder); 
		
			buf.PutShort(VERSION).PutShort(WAIT_DAT).PutInt(12);
			buf.PutInt(nSamples).PutInt(nEvents).PutInt(timeout).Rewind();
		
			WriteAll(buf);
			buf = ReadResponse(WAIT_OK);
			secount = new SamplesEventsCount(buf.GetInt(), buf.GetInt());
			return secount;
		}

		public SamplesEventsCount WaitForSamples(int nSamples, int timeout)
		{
			return Wait(nSamples, -1, timeout);
		}

		public SamplesEventsCount WaitForEvents(int nEvents, int timeout)
		{
			return Wait(-1, nEvents, timeout);
		}

		public SamplesEventsCount Poll()
		{
			return Poll(0);
		}

		public SamplesEventsCount Poll(int timeout)
		{
			return Wait(-1, -1, timeout);
		}
		
		
		//*********************************************************************
		//		protected methods and variables from here on
		//*********************************************************************
		
		protected ByteBuffer ReadAll(ByteBuffer dst)
		{
			int cap = dst.Capacity;
			int now = 0;
			while (cap > 0) {
				now = SockChan.Read(dst);
				if (now < 0) {
					//System.Console.WriteLine("Read here ");
					throw new IOException("Remote side closed connection!");						
				}
				cap -= now;
			}
			return dst;
		}

		
		
		protected ByteBuffer ReadResponse(int expected)
		{
			ByteBuffer def = ByteBuffer.Allocate(8);
			def.Order(myOrder);
			ReadAll(def);
			def.Rewind();
		
			short version = def.GetShort();
			short _expected = def.GetShort();
			if (version != VERSION) {
				errorReturned = VERSION_ERROR;
				throw new IOException("Invalid VERSION returned.");
			} else if (_expected != expected) { 
				errorReturned = BUFFER_READ_ERROR;
				throw new IOException("Error returned from FieldTrip buffer server.");
			} else {
				errorReturned = NO_ERROR;
			}
			
			int size = def.GetInt();
			
			ByteBuffer buf = ByteBuffer.Allocate(size);
			buf.Order(myOrder);
			ReadAll(buf);
			buf.Rewind();
			return buf;
		}

		
		
		protected ByteBuffer WriteAll(ByteBuffer dst)
		{
			int rem = (int)dst.Remaining;
			int now = 0;
			while (rem > 0) {
				now = SockChan.Write(dst);
				if (now < 0) {
					//System.Console.Writeline("Write here ");
					throw new IOException("Remote side closed connection!");
				}
				rem -= now;
			}
			return dst;
		}

		
		
		protected ByteBuffer PreparePutData(int nChans, int nSamples, int type)
		{
			int bufsize = DataType.wordSize[type] * nSamples * nChans;
			
			ByteBuffer buf = ByteBuffer.Allocate(8 + 16 + bufsize);
			buf.Order(myOrder);
			buf.PutShort(VERSION).PutShort(PUT_DAT).PutInt(16 + bufsize);
			buf.PutInt(nChans).PutInt(nSamples).PutInt(type).PutInt(bufsize);
			return buf;
		}

		
		
		protected T[] GetRow<T>(T[,] data, int index)
		{
			List<T> list = new List<T>();
			for (int i = 0; i < data.GetLength(1); ++i) {
				list.Add(data[index, i]);
			}
			return list.ToArray();
		}
	}
}