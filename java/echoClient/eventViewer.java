import java.io.*;
import java.nio.*;
import nl.fcdonders.fieldtrip.bufferclient.*;

class eventViewer {
	 public static void main(String[] args) throws IOException,InterruptedException {
		String hostname = "localhost";
		int port = 1972;
		int timeout = 5000;
	
		if (args.length>=1) {
			hostname = args[0];
		}
		if (args.length>=2) {
			try {
				port = Integer.parseInt(args[1]);
			}
			catch (NumberFormatException e) {
				port = 0;
			}
			if (port <= 0) {
				System.out.println("Second parameter ("+args[1]+") is not a valid port number.");
				System.exit(1);
			}
		}
		if (args.length>=3) {
			try {
				port = Integer.parseInt(args[2]);
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
				  C.connect(hostname, port);
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
						
		// Now do the event viewer
		int nEvents=hdr.nEvents;
		int nevt=0;
		boolean endExpt=false;
		while ( !endExpt ) {
			 SamplesEventsCount sec = C.waitForEvents(nEvents,timeout); // Block until there are new events
			 if ( sec.nEvents > nEvents ){
				  // get the new events
				  BufferEvent[] evs = C.getEvents(nEvents,sec.nEvents-1);
				  nEvents=sec.nEvents;// update record of which events we've seen
				  // filter for ones we want
				  for ( int ei=0; ei<evs.length; ei++){
						BufferEvent evt=evs[ei];
						System.out.println(nevt + ") " + evt); // Print the event to the console
						nevt++;
				  }
			 } else { // timed out without new events
				  System.out.println("Timeout waiting for events");
			 }
		}
		C.disconnect();
	}
}
