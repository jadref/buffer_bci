import java.io.*;
import java.nio.*;
import nl.fcdonders.fieldtrip.bufferclient.*;

class javaclient {
	 public static void main(String[] args) throws IOException,InterruptedException {
		String hostname = "localhost";
		int port = 1972;
		int timeout = 5000;
	
		if (args.length>=1) {
			hostname = args[0];
			int sep = hostname.indexOf(':');
			if ( sep>0 ) {
				 port=Integer.parseInt(hostname.substring(sep+1,hostname.length()));
				 hostname=hostname.substring(0,sep);
			}			
		}
		if (args.length>=2) {
			try {
				port = Integer.parseInt(args[1]);
			}
			catch (NumberFormatException e) {
				timeout = 5000;
			}
		}
		
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
				  //float[][] data = C.getFloatData(0,hdr.nSamples-1);				
				  System.out.println("#channels....: "+hdr.nChans);
				  System.out.println("#samples.....: "+hdr.nSamples);
				  System.out.println("#events......: "+hdr.nEvents);
				  System.out.println("Sampling Freq: "+hdr.fSample);
				  System.out.println("data type....: "+hdr.dataType);
				  for (int n=0;n<hdr.nChans;n++) {
						if (hdr.labels[n] != null) {
							 System.out.println("Ch. " + n + ": " + hdr.labels[n]);
						}
				  }
						
		// Now do the echo-server
		int nEvents=hdr.nEvents;
		boolean endExpt=false;
		while ( !endExpt ) {
			 SamplesEventsCount sec = C.waitForEvents(nEvents,timeout); // Block until there are new events
			 if ( sec.nEvents > nEvents ){
				  // get the new events
				  BufferEvent[] evs = C.getEvents(nEvents,sec.nEvents-1);
				  nEvents=sec.nEvents;// update record of which events we've seen
				  // filter for ones we want
				  System.out.println("Got " + evs.length + " events");
				  for ( int ei=0; ei<evs.length; ei++){
						BufferEvent evt=evs[ei];
						String evttype = evt.getType().toString(); // N.B. to*S*tring, not upper case!
						// only process if it's an event of a type we care about
						// In our case, don't echo our own echo events....
						if ( !evttype.equals("echo") ){  // N.B. use equals, not == to compare string contents!
							 if ( evttype.equals("exit")) { // check for a finish event
								  endExpt=true;
							 } 
							 // Print the even to the console
							 System.out.println(ei + ") t:" + evt.getType().toString() + " v:" + evt.getValue().toString() + " s:" + evt.sample);
							 // Now create the echo event, with auto-completed sample number
							 // N.B. -1 for sample means auto-compute based on the real-time-clock
							 C.putEvent(new BufferEvent("echo",evt.getValue().toString(),-1)); 
						}
				  }
			 } else { // timed out without new events
				  System.out.println("Timeout waiting for events");
			 }
		}		
		C.disconnect();
	}
}
