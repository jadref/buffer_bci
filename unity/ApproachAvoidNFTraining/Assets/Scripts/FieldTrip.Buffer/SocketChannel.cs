using System.Collections;
using System;
using System.IO;
using System.Net.Sockets;

namespace FieldTrip.Buffer
{
	public class SocketChannel  {

	    internal Boolean socketReady = false;

	    private TcpClient mySocket;
	    private NetworkStream theStream;
		private int readTimeout_ms = 2000;
	    public String Host;
	    public int Port;

	    public String readerResponse="";


		public SocketChannel(){
		}


	    void OnApplicationQuit(){
	        close();
	    }


		public bool connect(string hostname, int port){
			try
	        {
	        	Host = hostname;
	        	Port = port;

				lock(this){
				mySocket = new TcpClient();
				var result = mySocket.BeginConnect(Host, Port,null,null); // timeout connect 
				result.AsyncWaitHandle.WaitOne(TimeSpan.FromSeconds(1));
				if (!mySocket.Connected)
				{
					throw new Exception("Failed to connect.");
				}
				mySocket.EndConnect(result); // we have connected

	            theStream = mySocket.GetStream();
	            socketReady = true;
	            theStream.ReadTimeout=500;
				}
	        }
	        catch (Exception e)
	        {
	          	//throw new IOException("Socket error: " + e);
				mySocket=null;
				theStream = null;
	            socketReady = false;
	        }
	        return socketReady;
		}


		public int write(ByteBuffer src){
				int toWrite = (int)src.remaining ();
				byte[] message = new byte[toWrite];

				src.get (ref message);

			lock (this) {
				theStream.Write (message, 0, toWrite);
			}
	        return toWrite;
		}


	 	public int read(ByteBuffer dst){
	 		int toRead = dst.capacity();
	 		byte[] message = new byte[toRead];

	 		int readBytes = 0;
			int waitTime = 0;
			lock (this) {
				while (readBytes < toRead && waitTime < readTimeout_ms) {
					if (theStream.DataAvailable) { // read if something to do
						readBytes += theStream.Read (message, readBytes, toRead - readBytes);
					} else { // prevent live-lock
						waitTime += 2;
						System.Threading.Thread.Sleep (2);
					}
				}
			}
	 		dst.put(message,0,readBytes);
	 		return readBytes;
	 	}


	    public void close()
	    {
	        if (!socketReady)
	            return;
			lock (this) {
				mySocket.Close ();
	        socketReady = false;
			}
	    }


	    public bool isConnected(){
			lock (this) {
				try {
					if (mySocket != null && mySocket.Client != null && mySocket.Client.Connected) {
						/* pear to the documentation on Poll:
                * When passing SelectMode.SelectRead as a parameter to the Poll method it will return 
                * -either- true if Socket.Listen(Int32) has been called and a connection is pending;
                * -or- true if data is available for reading; 
                * -or- true if the connection has been closed, reset, or terminated; 
                * otherwise, returns false
                */

						// Detect if client disconnected
						if (mySocket.Client.Poll (0, SelectMode.SelectRead)) {
							byte[] buff = new byte[1];
							if (mySocket.Available > 0 && mySocket.Client.Receive (buff, SocketFlags.Peek) == 0) {
								// Client disconnected
								return false;
							} else {
								return true;
							}
						}

						return true;
					} else {
						return false;
					}
				} catch {
					return false;
				}

			}
		}
	}
}
