using System.IO;
using System.Collections.Generic;

namespace FieldTrip.Buffer
{
  public class BufferClient {
	 public const short VERSION = 1;
	 public const short GET_HDR = 0x201;
	 public const short GET_DAT = 0x202;
	 public const short GET_EVT = 0x203;
	 public const short GET_OK  = 0x204;
	 public const short GET_ERR = 0x205;
	
	 public const short PUT_HDR = 0x101;
	 public const short PUT_DAT = 0x102;
	 public const short PUT_EVT = 0x103;
	 public const short PUT_OK  = 0x104;
	 public const short PUT_ERR = 0x105;
	
	 public const short FLUSH_HDR = 0x301;
	 public const short FLUSH_DAT = 0x302;
	 public const short FLUSH_EVT = 0x303;
	 public const short FLUSH_OK  = 0x304;
	 public const short FLUSH_ERR = 0x305;
	
	 public const short WAIT_DAT = 0x402;
	 public const short WAIT_OK  = 0x404;
	 public const short WAIT_ERR = 0x405;
		
	 public const short NO_ERROR = 0x505;
	 public const short BUFFER_READ_ERROR = 0x506;
	 public const short VERSION_ERROR = 0x507;
	 public const short BUFFER_NOT_MATCH_DESCRIPTION_ERROR = 0x508;
	 public const short INVALID_EVENT_DEF_ERROR = 0x509;
	 public const short INVALID_SIZE_DATA_DEF_ERROR = 0x510;
				
	 public SocketChannel sockChan;
	 public bool activeConnection;
	 protected bool autoReconnect;
	 protected string host;
	 protected int port;
	 protected ByteOrder myOrder;
	 internal int errorReturned;
	
	 public BufferClient() {
		myOrder = ByteOrder.nativeOrder();
	 }
		
	 public BufferClient(ByteOrder order) {
		myOrder = order;
	 }
		
	 virtual public bool connect(string hostname, int port) {
		// if ( sockChan == null )
		// 	{
		sockChan = new SocketChannel();  
		// }
		// else if ( sockChan != null && sockChan.isConnected()) {
		//	disconnect(); // disconnect old connection
		//}
		sockChan.connect(hostname, port);
		activeConnection = sockChan.isConnected();
		if ( activeConnection ) { // cache the connection info
		  this.host = hostname;
		  this.port = port;
		}
		return activeConnection;
	 }		
		
	 public bool connect(string address) {
		int colonPos = address.LastIndexOf(':');
		if (colonPos != -1) {
		  string hostname = address.Substring(0,colonPos);
		  int port = int.Parse(address.Substring(colonPos+1));
				
		  return connect(hostname,port);
		}
		throw new IOException("Address format not recognized / supported yet.");
		// other addresses not recognised yet
		return false;
	 }
		
	 public bool reconnect() {
		System.Console.WriteLine("Remote side disconnected detected. Trying to reconnect to : " + host + ":" + port);
		return connect(host,port);
	 }

	 public void disconnect()  {
		if ( sockChan!=null ) sockChan.close();		 
		sockChan = null;
		activeConnection=false;
	 }
		
	 public bool isConnected() {
		if (activeConnection && sockChan != null && sockChan.isConnected()) {
		    try {
			// part1 indicates whether error or connected.
			bool part1 = sockChan.socket().Client.Poll(1000, System.Net.Sockets.SelectMode.SelectRead);

			// part2 indicates whether data is still available.
			bool part2 = sockChan.socket().Client.Available == 0;

			// if both parts are true, socket is dead.
			if (part1 && part2)
				return false;
			else
				return true;
		    }
		    catch (IOException ex)
		    {
		    }
		}

		return false;
	 }
		
	 virtual public Header getHeader() {
		ByteBuffer buf;
	
		buf = ByteBuffer.allocate(8);
		buf.order(myOrder);
		
		buf = buf.putShort(VERSION);
		buf = buf.putShort(GET_HDR);
		buf = buf.putInt(0);
		buf.rewind();
		writeAll(buf);
		
		buf = readResponse(GET_OK);
		Header hdr = new Header(buf);
		return hdr;
	 }
		
	 /** Returns true if channel names were written */
	 public bool putHeader(Header hdr) {
		ByteBuffer buf;
		int bufsize = hdr.getSerialSize();
	
		buf = ByteBuffer.allocate(8 + bufsize);
		buf.order(myOrder);
		
		buf.putShort(VERSION).putShort(PUT_HDR).putInt(bufsize);
		hdr.serialize(buf);
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
		return hdr.channelNameSize > hdr.nChans;
	 }
		
	 public short[,] getShortData(int first, int last){
		DataDescription dd = new DataDescription();
		ByteBuffer buf = getRawData(first, last, dd);
		
		int nSamples = dd.nSamples;
		int nChans = dd.nChans;
			
		short[,] data = new short[nSamples,nChans];
			
		switch (dd.dataType) {
		case DataType.INT8:
		  for (int i=0;i<nSamples;i++) {
			 for (int j=0;j<nChans;j++) {
				data[i,j] = (short) buf.get();
			 }
		  }
		  break;
		case DataType.INT16:
		  ShortBuffer sBuf = buf.asShortBuffer();
		  short[] rowData;
		  for (int n=0;n<nSamples;n++){
			 rowData = getRow<short>(data, n);
			 sBuf.get(rowData);
		  }
		  break;
		default:
		  throw new IOException("Not supported yet - returning zeros.");
		  break;	
		}
		
		return data;
	 }
		
	 public int[,] getIntData(int first, int last) {
		DataDescription dd = new DataDescription();
		ByteBuffer buf = getRawData(first, last, dd);
		
		int nSamples = dd.nSamples;
		int nChans = dd.nChans;
			
		int[,] data = new int[nSamples,nChans];
			
		switch (dd.dataType) {
		case DataType.INT8:
		  for (int i=0;i<nSamples;i++) {
			 for (int j=0;j<nChans;j++) {
				data[i,j] = (int) buf.get();
			 }
		  }
		  break;
		case DataType.INT16:
		  for (int i=0;i<nSamples;i++) {
			 for (int j=0;j<nChans;j++) {
				data[i,j] = (int) buf.getShort();
			 }
		  }
		  break;
		case DataType.INT32:
		  IntBuffer iBuf = buf.asIntBuffer();
		  int[] rowData;
		  for (int n=0;n<nSamples;n++){
			 rowData = getRow<int>(data, n);
			 iBuf.get(rowData);
		  }
		  break;
		default:
		  throw new IOException("Not supported yet - returning zeros.");
		  break;
		}
		
		return data;
	 }
		
	 public long[,] getLongData(int first, int last) {
		DataDescription dd = new DataDescription();
		ByteBuffer buf = getRawData(first, last, dd);
		
		int nSamples = dd.nSamples;
		int nChans = dd.nChans;
			
		long[,] data = new long[nSamples,nChans];
			
		switch (dd.dataType) {
		case DataType.INT8:
		  for (int i=0;i<nSamples;i++) {
			 for (int j=0;j<nChans;j++) {
				data[i,j] = (int) buf.get();
			 }
		  }
		  break;
		case DataType.INT16:
		  for (int i=0;i<nSamples;i++) {
			 for (int j=0;j<nChans;j++) {
				data[i,j] = (int) buf.getShort();
			 }
		  }
		  break;
		case DataType.INT32:
		  for (int i=0;i<nSamples;i++) {
			 for (int j=0;j<nChans;j++) {
				data[i,j] = (int) buf.getInt();
			 }
		  }
		  break;
		case DataType.INT64:
		  LongBuffer lBuf = buf.asLongBuffer();
		  long[] rowData;
		  for (int n=0;n<nSamples;n++){
			 rowData = getRow<long>(data, n);
			 lBuf.get(rowData);
		  }
		  break;
		default:
		  throw new IOException("Not supported yet - returning zeros.");
		  break;
		}
		
		return data;
	 }		
		
	 public float[,] getFloatData(int first, int last){
		DataDescription dd = new DataDescription();
		ByteBuffer buf = getRawData(first, last, dd);

		int nSamples = dd.nSamples;
		int nChans = dd.nChans;
			
		float[,] data = new float[nSamples,nChans];
			
		switch (dd.dataType) {
		case DataType.INT8:
		  for (int i=0;i<nSamples;i++) {
			 for (int j=0;j<nChans;j++) {
				data[i,j] = (float) buf.get();
			 }
		  }
		  break;
		case DataType.INT16:
		  for (int i=0;i<nSamples;i++) {
			 for (int j=0;j<nChans;j++) {
				data[i,j] = (float) buf.getShort();
			 }
		  }
		  break;
		case DataType.INT32:
		  for (int i=0;i<nSamples;i++) {
			 for (int j=0;j<nChans;j++) {
				data[i,j] = (float) buf.getInt();
			 }
		  }
		  break;
		case DataType.FLOAT32:
		  for (int i=0;i<nSamples;i++) {
			 for (int j=0;j<nChans;j++) {
				data[i,j] = (float) buf.getFloat();
			 }
		  }
		  break;
		case DataType.FLOAT64:
		  for (int i=0;i<nSamples;i++) {
			 for (int j=0;j<nChans;j++) {
				data[i,j] = (float) buf.getDouble();
			 }
		  }
		  break;
		default:
		  throw new IOException("Not supported yet - returning zeros.");
		  break;
		}
		
		return data;
	 }
		
	 public double[,] getDoubleData(int first, int last) {
		DataDescription dd = new DataDescription();
		ByteBuffer buf = getRawData(first, last, dd);
		
		int nSamples = dd.nSamples;
		int nChans = dd.nChans;
			
		double[,] data = new double[nSamples,nChans];
			
		switch (dd.dataType) {
		case DataType.INT8:
		  for (int i=0;i<nSamples;i++) {
			 //data[i] = new double[nChans];
			 for (int j=0;j<nChans;j++) {
				data[i,j] = (double) buf.get();
			 }
		  }
		  break;
		case DataType.INT16:
		  for (int i=0;i<nSamples;i++) {
			 for (int j=0;j<nChans;j++) {
				data[i,j] = (double) buf.getShort();
			 }
		  }
		  break;
		case DataType.INT32:
		  for (int i=0;i<nSamples;i++) {
			 for (int j=0;j<nChans;j++) {
				data[i,j] = (double) buf.getInt();
			 }
		  }
		  break;	
		case DataType.INT64:
		  for (int i=0;i<nSamples;i++) {
			 for (int j=0;j<nChans;j++) {
				data[i,j] = (double) buf.getLong();
			 }
		  }
		  break;		
		case DataType.FLOAT32:
		  for (int i=0;i<nSamples;i++) {
			 for (int j=0;j<nChans;j++) {
				data[i,j] = buf.getFloat();
			 }
		  }
		  break;
		case DataType.FLOAT64:
		  DoubleBuffer dBuf = buf.asDoubleBuffer();
		  double[] rowData;
		  for (int n=0;n<nSamples;n++){
			 rowData = getRow<double>(data, n);
			 dBuf.get(rowData);
		  }
		  break;
		default:
		  throw new IOException("Not supported yet - returning zeros.");
		  break;
		}
		
		return data;
	 }
		
		
	 public ByteBuffer getRawData(int first, int last, DataDescription descr) {
		ByteBuffer buf;
			
		buf = ByteBuffer.allocate(16);
		buf.order(myOrder);
			
		buf.putShort(VERSION).putShort(GET_DAT).putInt(8);
		buf.putInt(first).putInt(last).rewind();
		writeAll(buf);
		buf = readResponse(GET_OK);
			
		descr.nChans    = buf.getInt();
		descr.nSamples  =buf.getInt();
		descr.dataType  =buf.getInt();
		descr.sizeBytes = buf.getInt();
			
		int dataSize = descr.nChans * descr.nSamples * DataType.wordSize[descr.dataType];
		if (dataSize > descr.sizeBytes || descr.sizeBytes > buf.remaining()) {
		  errorReturned = INVALID_SIZE_DATA_DEF_ERROR;
		  throw new IOException("Invalid size definitions in response from GET DATA request");
		}
			
		return buf.slice();
	 }	
		
		
	 public BufferEvent[] getEvents()  {
		ByteBuffer buf;
	
		buf = ByteBuffer.allocate(8);
		buf.order(myOrder); 
		
		buf.putShort(VERSION).putShort(GET_EVT).putInt(0).rewind();
		
		writeAll(buf);
		buf = readResponse(GET_OK);
		
		int numEvt = BufferEvent.count(buf);
		if (numEvt < 0){
		  errorReturned = INVALID_EVENT_DEF_ERROR;
		  throw new IOException("Invalid event definitions in response.");
		}
			
		BufferEvent[] evs = new BufferEvent[numEvt];
		for (int n=0;n<numEvt;n++) {
		  evs[n] = new BufferEvent(buf);
		}
		return evs;
	 }	
		
		
	 public BufferEvent[] getEvents(int first, int last) {
		ByteBuffer buf;
	
		buf = ByteBuffer.allocate(16);
		buf.order(myOrder); 
		
		buf.putShort(VERSION).putShort(GET_EVT).putInt(8);
		buf.putInt(first).putInt(last).rewind();
		
		writeAll(buf);
		buf = readResponse(GET_OK);
		
		int numEvt = BufferEvent.count(buf);
		if (numEvt != (last-first+1)){ 
		  errorReturned = INVALID_EVENT_DEF_ERROR;
		  throw new IOException("Invalid event definitions in response.");
		}
			
		BufferEvent[] evs = new BufferEvent[numEvt];
		for (int n=0;n<numEvt;n++) {
		  evs[n] = new BufferEvent(buf);
		}
		return evs;
	 }
		
	 public void putRawData(int nSamples, int nChans, int dataType, byte[] data)  {
		if (nSamples == 0) return;
		if (nChans == 0) return;
		
		if (data.Length != nSamples*nChans*DataType.wordSize[dataType]) {
		  errorReturned = BUFFER_NOT_MATCH_DESCRIPTION_ERROR;
		  throw new IOException("Raw buffer does not match data description");
		}
			
		ByteBuffer buf = preparePutData(nChans, nSamples, dataType);
		buf.put(data);
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
	 }	
		
	 public void putData(byte[,] data) {
		int nSamples = data.GetLength(0);
		if (nSamples == 0) return;
		int nChans = data.GetLength(1);
		if (nChans == 0) return;
		
		ByteBuffer buf = preparePutData(nChans, nSamples, DataType.INT8);
		byte[] rowData;
		for (int i=0;i<nSamples;i++) {
		  rowData = getRow<byte>(data, i);
		  buf.put(rowData);
		}
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
	 }
		
	 public void putData(short[,] data) {
		int nSamples = data.GetLength(0);
		if (nSamples == 0) return;
		int nChans = data.GetLength(1);
		if (nChans == 0) return;
		
		ByteBuffer buf = preparePutData(nChans, nSamples, DataType.INT16);
		short[] rowData;
		for (int i=0;i<nSamples;i++) {
		  rowData = getRow<short>(data, i);
		  buf.asShortBuffer().put(rowData);
		}
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
	 }	
		
	 public void putData(int[,] data) {
		int nSamples = data.GetLength(0);
		if (nSamples == 0) return;
		int nChans = data.GetLength(1);
		if (nChans == 0) return;
		
		ByteBuffer buf = preparePutData(nChans, nSamples, DataType.INT32);
		int[] rowData;
		for (int i=0;i<nSamples;i++) {
		  rowData = getRow<int>(data, i);
		  buf.asIntBuffer().put(rowData);
		}
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
	 }
		
	 public void putData(long[,] data) {
		int nSamples = data.GetLength(0);
		if (nSamples == 0) return;
		int nChans = data.GetLength(1);
		if (nChans == 0) return;
		
		ByteBuffer buf = preparePutData(nChans, nSamples, DataType.INT64);
		long[] rowData;
		for (int i=0;i<nSamples;i++) {
		  rowData = getRow<long>(data, i);
		  buf.asLongBuffer().put(rowData);
		}
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
	 }	
			
	 public void putData(float[,] data) {
		int nSamples = data.GetLength(0);
		if (nSamples == 0) return;
		int nChans = data.GetLength(1);
		if (nChans == 0) return;
		
		ByteBuffer buf = preparePutData(nChans, nSamples, DataType.FLOAT32);
		float[] rowData;
		for (int i=0;i<nSamples;i++) {
		  rowData = getRow<float>(data, i);
		  buf.asFloatBuffer().put(rowData);
		}
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
	 }	
		
	 public void putData(double[,] data) {
		int nSamples = data.GetLength(0);
		if (nSamples == 0) return;
		int nChans = data.GetLength(1);
		if (nChans == 0) return;

		ByteBuffer buf = preparePutData(nChans, nSamples, DataType.FLOAT64);
		double[] rowData;
		for (int i=0;i<nSamples;i++) {
		  rowData = getRow<double>(data, i);
		  buf.asDoubleBuffer().put(rowData);
		}
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
	 }	
	
	 virtual public BufferEvent putEvent(BufferEvent e)  {
		ByteBuffer buf;
		int eventSize = e.size();
		buf = ByteBuffer.allocate(8+eventSize);
		buf.order(myOrder); 
		
		buf.putShort(VERSION).putShort(PUT_EVT).putInt(e.size());
		e.serialize(buf);
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
		return e;
	 }
	
	 virtual public void putEvents(BufferEvent[] e){
		ByteBuffer buf;
		int bufsize = 0;
		
		for (int i=0;i<e.Length;i++) {
		  bufsize += e[i].size();
		}
	
		buf = ByteBuffer.allocate(8+bufsize);
		buf.order(myOrder); 
		
		buf.putShort(VERSION).putShort(PUT_EVT).putInt(bufsize);
		for (int i=0;i<e.Length;i++) {
		  e[i].serialize(buf);
		}
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
	 }		
		
	 public void flushHeader()  {
		ByteBuffer buf = ByteBuffer.allocate(8);
		buf.order(myOrder); 
		
		buf.putShort(VERSION).putShort(FLUSH_HDR).putInt(0).rewind();
		writeAll(buf);
		buf = readResponse(FLUSH_OK);
	 }	
		
	 public void flushData() {
		ByteBuffer buf = ByteBuffer.allocate(8);
		buf.order(myOrder); 
		
		buf.putShort(VERSION).putShort(FLUSH_DAT).putInt(0).rewind();
		writeAll(buf);
		buf = readResponse(FLUSH_OK);
	 }	
		
	 public void flushEvents(){
		ByteBuffer buf = ByteBuffer.allocate(8);
		buf.order(myOrder); 
		
		buf.putShort(VERSION).putShort(FLUSH_EVT).putInt(0).rewind();
		writeAll(buf);
		buf = readResponse(FLUSH_OK);
	 }	
		
	 virtual public SamplesEventsCount wait(int nSamples, int nEvents, int timeout)  {
		ByteBuffer buf;
		SamplesEventsCount secount = null;
	
		buf = ByteBuffer.allocate(20);
		buf.order(myOrder); 
		
		buf.putShort(VERSION).putShort(WAIT_DAT).putInt(12);
		buf.putInt(nSamples).putInt(nEvents).putInt(timeout).rewind();
		
		writeAll(buf);
		buf = readResponse(WAIT_OK);
		secount = new SamplesEventsCount(buf.getInt(), buf.getInt());
		return secount;
	 }
		
	 public SamplesEventsCount waitForSamples(int nSamples, int timeout) {
		return wait(nSamples, -1, timeout);
	 }	
		
	 public SamplesEventsCount waitForEvents(int nEvents, int timeout) {
		return wait(-1, nEvents, timeout);
	 }

	 public SamplesEventsCount poll(){
		return poll(0);
	 }
	 public SamplesEventsCount poll(int timeout) {
		return wait(-1,-1,timeout);
	 }
		
		
	 //*********************************************************************
	 //		protected methods and variables from here on
	 //*********************************************************************
		
	 protected ByteBuffer readAll(ByteBuffer dst) {
		int cap = dst.capacity();
		int now = 0;
		while (cap > 0) {
		  now = sockChan.read(dst);
		  if ( now < 0 ){
			 //System.Console.WriteLine("Read here ");
			 throw new IOException("Remote side closed connection!");						
		  }
		  cap -= now;
		}
		return dst;
	 }
		
		
		
	 protected ByteBuffer readResponse(int expected) {
		ByteBuffer def = ByteBuffer.allocate(8);
		def.order(myOrder);
		readAll(def);
		def.rewind();
		
		short version = def.getShort();
		short _expected = def.getShort();
		if (version != VERSION){
		  errorReturned = VERSION_ERROR;
		  throw new IOException("Invalid VERSION returned.");
		}
		else if (_expected != expected){ 
		  errorReturned = BUFFER_READ_ERROR;
		  throw new IOException("Error returned from FieldTrip buffer server.");
		}
		else {
		  errorReturned = NO_ERROR;
		}
			
		int size = def.getInt();
			
		ByteBuffer buf = ByteBuffer.allocate(size);
		buf.order(myOrder);
		readAll(buf);
		buf.rewind();
		return buf;
	 }	
		
		
		
	 protected ByteBuffer writeAll(ByteBuffer dst) {
		int rem = (int)dst.remaining();
		int now = 0;
		while (rem > 0) {
		  now = sockChan.write(dst);
		  if ( now < 0 ){
			 //System.Console.Writeline("Write here ");
			 throw new IOException("Remote side closed connection!");
		  }
		  rem -= now;
		}
		return dst;
	 }	
		
		
		
	 protected ByteBuffer preparePutData(int nChans, int nSamples, int type) {
		int bufsize = DataType.wordSize[type]*nSamples*nChans;
			
		ByteBuffer buf = ByteBuffer.allocate(8+16+bufsize);
		buf.order(myOrder);
		buf.putShort(VERSION).putShort(PUT_DAT).putInt(16+bufsize);
		buf.putInt(nChans).putInt(nSamples).putInt(type).putInt(bufsize);
		return buf;
	 }
		
		
		
	 protected T[] getRow<T>(T[,] data, int index){
		List<T> list = new List<T>();
		for(int i=0; i<data.GetLength(1); ++i){
		  list.Add(data[index,i]);
		}
		return list.ToArray();
	 }
  }
}


