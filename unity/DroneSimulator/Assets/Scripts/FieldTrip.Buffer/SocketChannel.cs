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
	            mySocket = new TcpClient(Host, Port);
	            theStream = mySocket.GetStream();
	            socketReady = true;
	            theStream.ReadTimeout=500;
	        }
	        catch (Exception e)
	        {
	          	//throw new IOException("Socket error: " + e);
	            socketReady = false;
	        }
	        return socketReady;
		}
		
		
		public int write(ByteBuffer src){
	        int toWrite = (int)src.remaining();
	        byte[] message = new byte[toWrite];
	        
	        src.get(ref message);
	        
	        theStream.Write(message,0,toWrite);
	        
	        return toWrite;
		}
	     
	     
	 	public int read(ByteBuffer dst){
	 		int toRead = dst.capacity();
	 		byte[] message = new byte[toRead];
	 		
	 		int readBytes = 0;
	 		while(readBytes<toRead){
	 			readBytes += theStream.Read(message, readBytes, toRead-readBytes);
	 		}
	 		dst.put(message);
	 		return readBytes;
	 	}
	 
	 
	    public void close()
	    {
	        if (!socketReady)
	            return;
	        mySocket.Close();
	        socketReady = false;
	    }
	    
	    
	    public bool isConnected(){
	    	if(mySocket!=null)
	    		return mySocket.Connected;
	    	else 
	    		return false;
	    }
	}
}
