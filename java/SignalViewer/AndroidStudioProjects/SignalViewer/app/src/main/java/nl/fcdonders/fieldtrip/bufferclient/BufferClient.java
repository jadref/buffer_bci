/*
 * Copyright (C) 2010, Stefan Klanke
 * Donders Institute for Donders Institute for Brain, Cognition and Behaviour,
 * Centre for Cognitive Neuroimaging, Radboud University Nijmegen,
 * Kapittelweg 29, 6525 EN Nijmegen, The Netherlands
 */
package nl.fcdonders.fieldtrip.bufferclient;

import java.nio.channels.*;
import java.nio.*;
import java.net.*;
import java.io.*;

public class BufferClient {
	public static final short VERSION = 1;
	public static final short GET_HDR = 0x201;
	public static final short GET_DAT = 0x202;
	public static final short GET_EVT = 0x203;
	public static final short GET_OK  = 0x204;
	public static final short GET_ERR = 0x205;

	public static final short PUT_HDR = 0x101;
	public static final short PUT_DAT = 0x102;
	public static final short PUT_EVT = 0x103;
	public static final short PUT_OK  = 0x104;
	public static final short PUT_ERR = 0x105;

	public static final short FLUSH_HDR = 0x301;
	public static final short FLUSH_DAT = 0x302;
	public static final short FLUSH_EVT = 0x303;
	public static final short FLUSH_OK  = 0x304;
	public static final short FLUSH_ERR = 0x305;

	public static final short WAIT_DAT = 0x402;
	public static final short WAIT_OK  = 0x404;
	public static final short WAIT_ERR = 0x405;


	public BufferClient() {
		myOrder = ByteOrder.nativeOrder();
		activeConnection=false;
		autoReconnect=false;
		timeout=500;
	}
	
	public BufferClient(ByteOrder order) {
		myOrder = order;
		activeConnection=false;
		autoReconnect=false;
		timeout=500;
	}
	
	public synchronized boolean connect(String hostname, int port) throws IOException {
		 //System.out.println("connect ");
		if ( sockChan != null && sockChan.isConnected()) {
			 disconnect(); // disconnect old connection
		}
		sockChan = SocketChannel.open();		
		//System.out.println("Host " + hostname + " port : " + port);
		sockChan.connect(new InetSocketAddress(hostname, port));
		activeConnection = sockChan.isConnected();
		if ( activeConnection ) { // cache the connection info
			 sockChan.socket().setSoTimeout(timeout);
			 sockChan.socket().setTcpNoDelay(true); //disable Nagle's algorithm...i.e. allow small packets
			 this.host = hostname;
			 this.port = port;
		}
		return activeConnection;
	}
	
	public synchronized boolean connect(String address) throws IOException {
		int colonPos = address.lastIndexOf(':');
		if (colonPos != -1) {
			String hostname = address.substring(0,colonPos);
			Integer port;
		
			try {
				port = new Integer(address.substring(colonPos+1));
			}
			catch (NumberFormatException e) {
				System.out.println(e);
				return false;
			}
			return connect(hostname, port.intValue());
		}
		System.out.println("Address format not recognized / supported yet.");
		// other addresses not recognised yet
		return false;
	}
	
	 public synchronized boolean reconnect() throws IOException {
		  System.out.println("Remote side disconnected detected. Trying to reconnect to : " + host + ":" + port);
		  return connect(host,port);
	 }

	public synchronized void disconnect() throws IOException {
		 if ( sockChan!=null ) sockChan.socket().close();		 
		sockChan = null;
		activeConnection=false;
	}
	
	public synchronized boolean isConnected() {
		 boolean conn=false;
		 if (activeConnection && sockChan != null && sockChan.isConnected() ) {
			  // try to read 1 byte, if this fails then the socket was reset
			  int nread=-1;
			  try {
					ByteBuffer tmp= ByteBuffer.allocate(1);
					sockChan.configureBlocking(false);
					nread=sockChan.read(tmp); // fast non-blocking read
					sockChan.configureBlocking(true);
			  } catch (IOException e) { }
			  //System.out.println("read " + nread + "bytes"); System.out.flush();
			  if ( nread<0 ) {
					activeConnection=false;
			  } else {
					conn = true;
			  }
		 }
		 return conn;
	}

	 // do we try to auto-reconnect if the connection seems to have been closed?
	 public boolean getAutoReconnect() { return autoReconnect; }
	 public boolean setAutoReconnect(boolean val){ autoReconnect=val; return autoReconnect; }
	 public int getTimeout() { return timeout; }
	 public int setTimeout(int val){ timeout=val; return timeout; }

	
	public synchronized Header getHeader() throws IOException {
		ByteBuffer buf;

		buf = ByteBuffer.allocate(8);
		buf.order(myOrder);
	
		buf.putShort(VERSION).putShort(GET_HDR).putInt(0).rewind();
		writeAll(buf);
	
		buf = readResponse(GET_OK);
		return new Header(buf);
	}
	
	/** Returns true if channel names were written */
	public synchronized boolean putHeader(Header hdr) throws IOException {
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
	
	public synchronized short[][] getShortData(int first, int last) throws IOException {
		DataDescription dd = new DataDescription();
		ByteBuffer buf = getRawData(first, last, dd);
	
		int nSamples = dd.nSamples;
		int nChans = dd.nChans;
		
		short[][] data = new short[nSamples][nChans];
		
		switch (dd.dataType) {
			case DataType.INT8:
				for (int i=0;i<nSamples;i++) {
					for (int j=0;j<nChans;j++) {
						data[i][j] = (short) buf.get();
					}
				}
				break;
			case DataType.INT16:
				ShortBuffer sBuf = buf.asShortBuffer();
				for (int n=0;n<nSamples;n++) sBuf.get(data[n]);
				break;
			default:
				System.out.println("Not supported yet - returning zeros.");
		}
	
		return data;
	}
	
	public synchronized int[][] getIntData(int first, int last) throws IOException {
		DataDescription dd = new DataDescription();
		ByteBuffer buf = getRawData(first, last, dd);
	
		int nSamples = dd.nSamples;
		int nChans = dd.nChans;
		
		int[][] data = new int[nSamples][nChans];
		
		switch (dd.dataType) {
			case DataType.INT8:
				for (int i=0;i<nSamples;i++) {
					for (int j=0;j<nChans;j++) {
						data[i][j] = (int) buf.get();
					}
				}
				break;
			case DataType.INT16:
				for (int i=0;i<nSamples;i++) {
					for (int j=0;j<nChans;j++) {
						data[i][j] = (int) buf.getShort();
					}
				}
				break;
			case DataType.INT32:
				IntBuffer iBuf = buf.asIntBuffer();
				for (int n=0;n<nSamples;n++) iBuf.get(data[n]);
				break;
			default:
				System.out.println("Not supported yet - returning zeros.");
		}
	
		return data;
	}
	
	public synchronized long[][] getLongData(int first, int last) throws IOException {
		DataDescription dd = new DataDescription();
		ByteBuffer buf = getRawData(first, last, dd);
	
		int nSamples = dd.nSamples;
		int nChans = dd.nChans;
		
		long[][] data = new long[nSamples][nChans];
		
		switch (dd.dataType) {
			case DataType.INT8:
				for (int i=0;i<nSamples;i++) {
					for (int j=0;j<nChans;j++) {
						data[i][j] = (int) buf.get();
					}
				}
				break;
			case DataType.INT16:
				for (int i=0;i<nSamples;i++) {
					for (int j=0;j<nChans;j++) {
						data[i][j] = (int) buf.getShort();
					}
				}
				break;
			case DataType.INT32:
				for (int i=0;i<nSamples;i++) {
					for (int j=0;j<nChans;j++) {
						data[i][j] = (int) buf.getInt();
					}
				}
				break;
			case DataType.INT64:
				LongBuffer lBuf = buf.asLongBuffer();
				for (int n=0;n<nSamples;n++) lBuf.get(data[n]);
				break;
			default:
				System.out.println("Not supported yet - returning zeros.");
		}
	
		return data;
	}		
	
	public synchronized float[][] getFloatData(int first, int last) throws IOException {
		DataDescription dd = new DataDescription();
		ByteBuffer buf = getRawData(first, last, dd);
	
		int nSamples = dd.nSamples;
		int nChans = dd.nChans;
		
		float[][] data = new float[nSamples][nChans];
		
		switch (dd.dataType) {
			case DataType.INT8:
				for (int i=0;i<nSamples;i++) {
					for (int j=0;j<nChans;j++) {
						data[i][j] = (float) buf.get();
					}
				}
				break;
			case DataType.INT16:
				for (int i=0;i<nSamples;i++) {
					for (int j=0;j<nChans;j++) {
						data[i][j] = (float) buf.getShort();
					}
				}
				break;
			case DataType.INT32:
				for (int i=0;i<nSamples;i++) {
					for (int j=0;j<nChans;j++) {
						data[i][j] = (float) buf.getInt();
					}
				}
				break;
			case DataType.FLOAT32:
				FloatBuffer fBuf = buf.asFloatBuffer();
				for (int n=0;n<nSamples;n++) fBuf.get(data[n]);
				break;
			case DataType.FLOAT64:
				for (int i=0;i<nSamples;i++) {
					for (int j=0;j<nChans;j++) {
						data[i][j] = (float) buf.getDouble();
					}
				}
				break;
			default:
				System.out.println("Not supported yet - returning zeros.");
		}
	
		return data;
	}
	
	public synchronized double[][] getDoubleData(int first, int last) throws IOException {
		DataDescription dd = new DataDescription();
		ByteBuffer buf = getRawData(first, last, dd);
	
		int nSamples = dd.nSamples;
		int nChans = dd.nChans;
		
		double[][] data = new double[nSamples][nChans];
		
		switch (dd.dataType) {
			case DataType.INT8:
				for (int i=0;i<nSamples;i++) {
					for (int j=0;j<nChans;j++) {
						data[i][j] = (double) buf.get();
					}
				}
				break;
			case DataType.INT16:
				for (int i=0;i<nSamples;i++) {
					for (int j=0;j<nChans;j++) {
						data[i][j] = (double) buf.getShort();
					}
				}
				break;
			case DataType.INT32:
				for (int i=0;i<nSamples;i++) {
					for (int j=0;j<nChans;j++) {
						data[i][j] = (double) buf.getInt();
					}
				}
				break;		
			case DataType.INT64:
				for (int i=0;i<nSamples;i++) {
					for (int j=0;j<nChans;j++) {
						data[i][j] = (double) buf.getLong();
					}
				}
				break;		
			case DataType.FLOAT32:
				for (int i=0;i<nSamples;i++) {
					for (int j=0;j<nChans;j++) {
						data[i][j] = buf.getFloat();
					}
				}
				break;
			case DataType.FLOAT64:
				DoubleBuffer dBuf = buf.asDoubleBuffer();
				for (int n=0;n<nSamples;n++) dBuf.get(data[n]);
				break;
			default:
				System.out.println("Not supported yet - returning zeros.");
		}
	
		return data;
	}
	
	
	public synchronized ByteBuffer getRawData(int first, int last, DataDescription descr) throws IOException {
		ByteBuffer buf;

		buf = ByteBuffer.allocate(16);
		buf.order(myOrder);
	
		buf.putShort(VERSION).putShort(GET_DAT).putInt(8);
		buf.putInt(first).putInt(last).rewind();
		writeAll(buf);
		buf = readResponse(GET_OK);
		
		descr.nChans    = buf.getInt();
		descr.nSamples  = buf.getInt();
		descr.dataType  = buf.getInt();
		descr.sizeBytes = buf.getInt();
	
		int dataSize = descr.nChans * descr.nSamples * DataType.wordSize[descr.dataType];
	
		if (dataSize > descr.sizeBytes || descr.sizeBytes > buf.remaining()) {
			throw new IOException("Invalid size definitions in response from GET DATA request");
		}
	
		return buf;//.slice(); // N.B. slice resets the data order! use with caution
	}	
	
	
	public synchronized BufferEvent[] getEvents() throws IOException {
		ByteBuffer buf;

		buf = ByteBuffer.allocate(8);
		buf.order(myOrder); 
	
		buf.putShort(VERSION).putShort(GET_EVT).putInt(0).rewind();
	
		writeAll(buf);
		buf = readResponse(GET_OK);
	
		int numEvt = BufferEvent.count(buf);
		if (numEvt < 0) throw new IOException("Invalid event definitions in response.");
	
		BufferEvent[] evs = new BufferEvent[numEvt];
		for (int n=0;n<numEvt;n++) {
			evs[n] = new BufferEvent(buf);
		}
		return evs;
	}	
	
	
	public synchronized BufferEvent[] getEvents(int first, int last) throws IOException {
		ByteBuffer buf;

		buf = ByteBuffer.allocate(16);
		buf.order(myOrder); 
	
		buf.putShort(VERSION).putShort(GET_EVT).putInt(8);
		buf.putInt(first).putInt(last).rewind();
	
		writeAll(buf);
		buf = readResponse(GET_OK);
	
		int numEvt = BufferEvent.count(buf);
		if (numEvt != (last-first+1)) throw new IOException("Invalid event definitions in response.");
	
		BufferEvent[] evs = new BufferEvent[numEvt];
		for (int n=0;n<numEvt;n++) {
			evs[n] = new BufferEvent(buf);
		}
		return evs;
	}
	
	public synchronized void putRawData(int nSamples, int nChans, int dataType, byte[] data) throws IOException {
		if (nSamples == 0) return;
		if (nChans == 0) return;
	
		if (data.length != nSamples*nChans*DataType.wordSize[dataType]) {
			throw new IOException("Raw buffer does not match data description");
		}
		
		ByteBuffer buf = preparePutData(nChans, nSamples, dataType);
		buf.put(data);
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
	}	
	
	public synchronized void putData(byte[][] data) throws IOException {
		int nSamples = data.length;
		if (nSamples == 0) return;
		int nChans = data[0].length;
		if (nChans == 0) return;
	
		for (int i=1;i<nSamples;i++) {
			if (nChans != data[i].length) {
				throw new IOException("Cannot write non-rectangular data array");
			}
		}
		
		ByteBuffer buf = preparePutData(nChans, nSamples, DataType.INT8);
		for (int i=0;i<nSamples;i++) {
			buf.put(data[i]);
		}
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
	}
	
	public synchronized void putData(short[][] data) throws IOException {
		int nSamples = data.length;
		if (nSamples == 0) return;
		int nChans = data[0].length;
		if (nChans == 0) return;
	
		for (int i=1;i<nSamples;i++) {
			if (nChans != data[i].length) {
				throw new IOException("Cannot write non-rectangular data array");
			}
		}
		
		ByteBuffer buf = preparePutData(nChans, nSamples, DataType.INT16);
		//System.out.print("[" + nChans + " " + nSamples + "]");
		ShortBuffer sbuf=buf.asShortBuffer();
		for (int i=0;i<nSamples;i++) {
			 sbuf.put(data[i]);
		}
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
	}	
	
	public synchronized void putData(int[][] data) throws IOException {
		int nSamples = data.length;
		if (nSamples == 0) return;
		int nChans = data[0].length;
		if (nChans == 0) return;
	
		for (int i=1;i<nSamples;i++) {
			if (nChans != data[i].length) {
				throw new IOException("Cannot write non-rectangular data array");
			}
		}
		
		ByteBuffer buf = preparePutData(nChans, nSamples, DataType.INT32);
		IntBuffer ibuf=buf.asIntBuffer();
		for (int i=0;i<nSamples;i++) {
			ibuf.put(data[i]);
		}
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
	}
	
	public synchronized void putData(long[][] data) throws IOException {
		int nSamples = data.length;
		if (nSamples == 0) return;
		int nChans = data[0].length;
		if (nChans == 0) return;
	
		for (int i=1;i<nSamples;i++) {
			if (nChans != data[i].length) {
				throw new IOException("Cannot write non-rectangular data array");
			}
		}
		
		ByteBuffer buf = preparePutData(nChans, nSamples, DataType.INT64);
		LongBuffer lbuf=buf.asLongBuffer();
		for (int i=0;i<nSamples;i++) {
			lbuf.put(data[i]);
		}
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
	}	
		
	public synchronized void putData(float[][] data) throws IOException {
		int nSamples = data.length;
		if (nSamples == 0) return;
		int nChans = data[0].length;
		if (nChans == 0) return;
	
		for (int i=1;i<nSamples;i++) {
			if (nChans != data[i].length) {
				throw new IOException("Cannot write non-rectangular data array");
			}
		}
		
		ByteBuffer buf = preparePutData(nChans, nSamples, DataType.FLOAT32);
		FloatBuffer fbuf=buf.asFloatBuffer();
		for (int i=0;i<nSamples;i++) {
			fbuf.put(data[i]);
		}
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
	}	
	
	 // 1-d data version.  Mostly for Octave calls, but useful in other cases
	 public synchronized void putData(double[] data, int[] sz) throws IOException {
		  int nSamples = sz[0]; // N.B. Java convention = ROW-Major, i.e. cols == channels vary fastest
		  int nChans = sz[1];
		  if( data.length != nSamples*nChans ) {
				throw new IOException("Cannot size does not match data size");
		  }		  
		  ByteBuffer buf = preparePutData(nChans, nSamples, DataType.FLOAT64);
		  buf.asDoubleBuffer().put(data);
		  buf.rewind();
		  writeAll(buf);
		  readResponse(PUT_OK);
		  return;
	 }
	 
	 public synchronized void putData(double[][] data) throws IOException {
		int nSamples = data.length;
		if (nSamples == 0) return;
		int nChans = data[0].length;
		if (nChans == 0) return;
	
		for (int i=1;i<nSamples;i++) {
			if (nChans != data[i].length) {
				throw new IOException("Cannot write non-rectangular data array");
			}
		}
		
		ByteBuffer buf = preparePutData(nChans, nSamples, DataType.FLOAT64);
		DoubleBuffer dbuf=buf.asDoubleBuffer();
		for (int i=0;i<nSamples;i++) {
			dbuf.put(data[i]);
		}
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
	}	

	public synchronized BufferEvent putEvent(BufferEvent e) throws IOException {
		ByteBuffer buf;

		buf = ByteBuffer.allocate(8+e.size());
		buf.order(myOrder); 
	
		buf.putShort(VERSION).putShort(PUT_EVT).putInt(e.size());
		e.serialize(buf);
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
		return e;
	}

	 public synchronized void putRawEvent(byte[] e) throws IOException {
		  putRawEvent(e,0,e.length);
	 }
	 public synchronized void putRawEvent(byte[] e,int offset, int len) throws IOException {
		ByteBuffer buf;

		buf = ByteBuffer.allocate(8+len);
		buf.order(myOrder); 
	
		buf.putShort(VERSION).putShort(PUT_EVT).putInt(len);
		buf.put(e,offset,len);
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
	}


	public synchronized void putEvents(BufferEvent[] e) throws IOException {
		ByteBuffer buf;
		int bufsize = 0;
	
		for (int i=0;i<e.length;i++) {
			bufsize += e[i].size();
		}

		buf = ByteBuffer.allocate(8+bufsize);
		buf.order(myOrder); 
	
		buf.putShort(VERSION).putShort(PUT_EVT).putInt(bufsize);
		for (int i=0;i<e.length;i++) {
			e[i].serialize(buf);
		}
		buf.rewind();
		writeAll(buf);
		readResponse(PUT_OK);
	}		
	
	public synchronized void flushHeader() throws IOException {
		ByteBuffer buf = ByteBuffer.allocate(8);
		buf.order(myOrder); 
	
		buf.putShort(VERSION).putShort(FLUSH_HDR).putInt(0).rewind();
		writeAll(buf);
		buf = readResponse(FLUSH_OK);
	}	
	
	public synchronized void flushData() throws IOException {
		ByteBuffer buf = ByteBuffer.allocate(8);
		buf.order(myOrder); 
	
		buf.putShort(VERSION).putShort(FLUSH_DAT).putInt(0).rewind();
		writeAll(buf);
		buf = readResponse(FLUSH_OK);
	}	
	
	public synchronized void flushEvents() throws IOException {
		ByteBuffer buf = ByteBuffer.allocate(8);
		buf.order(myOrder); 
	
		buf.putShort(VERSION).putShort(FLUSH_EVT).putInt(0).rewind();
		writeAll(buf);
		buf = readResponse(FLUSH_OK);
	}	
	
	public synchronized SamplesEventsCount wait(int nSamples, int nEvents, int timeout) throws IOException {
		ByteBuffer buf;

		buf = ByteBuffer.allocate(20);
		buf.order(myOrder); 
	
		buf.putShort(VERSION).putShort(WAIT_DAT).putInt(12);
		buf.putInt(nSamples).putInt(nEvents).putInt(timeout).rewind();
	
		writeAll(buf);
		buf = readResponse(WAIT_OK);
	
		return new SamplesEventsCount(buf.getInt(), buf.getInt());
	}
	
	public synchronized SamplesEventsCount waitForSamples(int nSamples, int timeout) throws IOException {
		return wait(nSamples, -1, timeout);
	}	
	
	public synchronized SamplesEventsCount waitForEvents(int nEvents, int timeout) throws IOException {
		return wait(-1, nEvents, timeout);
	}		
	
	public synchronized SamplesEventsCount poll() throws IOException {
		return wait(0,0,0);
	}
	 public synchronized SamplesEventsCount poll(int timeout) throws IOException {
		  return wait(-1,-1,timeout);
	 }
	
	//*********************************************************************
	//		protected methods and variables from here on
	//*********************************************************************
	
	protected synchronized ByteBuffer readAll(ByteBuffer dst) throws IOException {
		int rem = dst.remaining();
		int now = 0;
		while (rem > 0) {
			 now = sockChan.read(dst);
			 if ( now < 0 ){
				  //System.out.println("Read here ");
				  throw new IOException("Remote side closed connection!");						
			 }
			 rem -= now;
		}
		return dst;
	}
	
	protected synchronized ByteBuffer readResponse(int expected) throws IOException {
		ByteBuffer def = ByteBuffer.allocate(8);
		def.order(myOrder);
		readAll(def);
		def.rewind();
	
		short ver=def.getShort();
		if ( ver != VERSION) throw new IOException("Invalid VERSION returned : " + ver);
		short resp=def.getShort();
		if (resp != expected) 
			 throw new IOException("Error returned from FieldTrip buffer server. Expected " 
										  + Integer.toHexString(expected) + " got " + Integer.toHexString(resp));
		int size = def.getInt();
	
		ByteBuffer buf = ByteBuffer.allocate(size);
		buf.order(myOrder);
		readAll(buf);
		buf.rewind();
		return buf;
	}	
	
	protected synchronized ByteBuffer writeAll(ByteBuffer dst) throws IOException {
		int rem = dst.remaining();
		int now=0;
		while (rem > 0) {
			 now = sockChan.write(dst);
			 if ( now < 0 ){
				  //System.out.println("Write here ");
				  throw new IOException("Remote side closed connection!");
			 }
			 rem -= now;
		}
		return dst;
	}
	
	protected synchronized ByteBuffer preparePutData(int nChans, int nSamples, int type) {
		int bufsize = DataType.wordSize[type]*nSamples*nChans;
		
		ByteBuffer buf = ByteBuffer.allocate(8+16+bufsize);
		buf.order(myOrder);
		buf.putShort(VERSION).putShort(PUT_DAT).putInt(16+bufsize);
		buf.putInt(nChans).putInt(nSamples).putInt(type).putInt(bufsize);
		return buf;
	}
	
	public SocketChannel sockChan;
	public boolean activeConnection;
	protected boolean autoReconnect;
	protected String host;
	protected int port;
	protected int timeout;
	protected ByteOrder myOrder;
}
