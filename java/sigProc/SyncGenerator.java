package nl.dcc.buffer_bci;
import java.io.*;
import java.nio.*;
import nl.fcdonders.fieldtrip.bufferclient.*;

// TODO: Convert to a thread-based version so is compatiable with BufferBCIApp thread model

public class SyncGenerator {
	 static boolean run=true;
	 public static void main(String[] args) throws IOException,InterruptedException {	
		  int syncInterval_s=60;
		  
		  // first argument is sync interval.. if it's an integer
		  int argi=0;
		  if ( args.length>0 ){
				try {
					 syncInterval_s = Integer.parseInt(args[argi]);
					 argi++;
				}
				catch (NumberFormatException e) {
					 argi=0;
				}
		  }
		  
		  if ( args.length < argi+1 ){
				System.out.println("Error must specify at least 1 buffer to send sync pulses to!");
				usage();
				System.exit(1);
		  }
		  
		  java.util.List<BufferClientClock> clients = new java.util.ArrayList<BufferClientClock>();
		  for ( ;argi<args.length; argi++ ){			 
				String hostname = args[argi];
				int port=1972;
				int sep = hostname.indexOf(':');
				if ( sep>0 ) {
					 port=Integer.parseInt(hostname.substring(sep+1,hostname.length()));
					 hostname=hostname.substring(0,sep);
				}
				
				// Try connecting to this buffer, wait until connection established
				BufferClientClock C = new BufferClientClock();
				Header hdr=null;
				while( hdr==null ) {
					 try {
						  System.out.println("Connecting to "+hostname+":"+port);
						  if ( !C.isConnected() ) {
								C.connect(hostname, port);
						  }
						  //C.setAutoReconnect(true);
						  if ( C.isConnected() ) { hdr = C.getHeader(); }
					 } catch (IOException e) {
						  hdr=null;
					 }
					 if ( hdr==null ){
						  System.out.println("Invalid Header... waiting");
						  Thread.sleep(1000);
					 }
				}
				System.out.print("Connected to : "+hostname+":"+port);
				System.out.println("("+hdr.nChans+"ch,"+hdr.fSample+"Hz,"+hdr.nSamples+"samp,"+hdr.nEvents+"evt)");
				// add to the list of connected clients
				clients.add(C);
				
		  }		
		  System.out.println("Sending sync event with type: buffer.sync every " + syncInterval_s + " seconds.");
		  
		  // make the sync event to send to all buffers
		  BufferEvent syncEvt=new BufferEvent("buffer.sync",0,-1);
						
		  // Now do the sync-server
		  long t0=java.lang.System.currentTimeMillis();
		  int  t =0;
		  try {
				while ( run ) {
					 t = (int)(java.lang.System.currentTimeMillis() - t0);
					 syncEvt.setValue(t);
					 for (BufferClientClock C : clients ) {
						  syncEvt.sample=-1;
						  C.putEvent(syncEvt);
					 }
					 System.out.print(".");
					 // sleep until the next sync pulse
					 Thread.sleep(syncInterval_s*1000);
				}
		  } catch (InterruptedException e) {
				System.out.println();
				// disconnect cleanly all clients
				for ( BufferClientClock C : clients ) { C.disconnect();  }
		  }
	 }

	 public void stop() { run=false; }	 
	 
	 static void usage(){
		  System.out.println("syncGenerator interval buffer1 buffer2 .... ");
		  System.out.println("");
		  System.out.println("Send a sync event every interval seconds to the set of buffers buffer1,buffer2,...");
		  System.out.println("   interval -- number in seconds between sync events");
		  System.out.println("   buffer1  -- hostname:port for the first buffer to send to");
		  System.out.println("   buffer2  -- hostname:port for the second buffer to send to");
	 }
}
