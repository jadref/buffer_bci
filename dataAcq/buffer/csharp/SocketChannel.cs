using System.Collections;
using System;
using System.IO;
using System.Net.Sockets;

namespace FieldTrip.Buffer
{
	public class SocketChannel
	{
	
		internal Boolean socketReady = false;
	 
		private TcpClient mySocket;
		private NetworkStream theStream;
		public String Host;
		public int Port;
		public int timeout = 10000;
	    
		public String readerResponse = "";

		
		public SocketChannel()
		{
		}

		~SocketChannel() // distructor, correctly close the socket first
		{
			try { // don't throw within distructor
				mySocket.Close();
			} catch {
			}
		}
	
		// void OnApplicationQuit(){
		//     this.close();
		// }
		
		public bool Connect(string hostname, int port)
		{
			try {
				Host = hostname;
				Port = port;
				mySocket = new TcpClient(Host, Port);
				mySocket.NoDelay = true;
				mySocket.ReceiveTimeout = 0; // allow infinite read time
				theStream = mySocket.GetStream();
				socketReady = true;
				// allow infinite read time, Necessary for long wait_dat calls....
				theStream.ReadTimeout = 1000000;//System.Threading.Infinite; 
			} catch (Exception e) {
				throw new IOException("Socket error: " + e);
				socketReady = false;
			}
			return socketReady;
		}

		public TcpClient socket()
		{
			return mySocket;
		}

		
		public int write(ByteBuffer src)
		{
			int toWrite = (int)src.Remaining();
			byte[] message = new byte[toWrite];
	        
			src.Get(ref message);
	        
			theStream.Write(message, 0, toWrite);
	        
			return toWrite;
		}

	     
		public int Read(ByteBuffer dst)
		{
			int toRead = dst.Capacity();
			byte[] message = new byte[toRead];
	 		
			int readBytes = 0;
			//while(readBytes<toRead){ // this loop is uncessary -- we return number bytes read anyway...
			readBytes += theStream.Read(message, readBytes, toRead - readBytes);
			//}
			dst.Put(message);
			return readBytes;
		}

	 
		public void Close()
		{
			if (!socketReady)
				return;
			mySocket.Close();
			socketReady = false;
		}

	    
		public bool IsConnected()
		{
			if (mySocket != null)
				return mySocket.Connected;
			else
				return false;
		}
	}
}
