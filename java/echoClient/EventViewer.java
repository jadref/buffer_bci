import java.io.*;
import java.nio.*;
import nl.fcdonders.fieldtrip.bufferclient.*;

class EventViewer {
	 protected static final String TAG = EventViewer.class.getSimpleName();


	 public static void main(String[] args) throws IOException,InterruptedException {
		String hostname = "localhost";
		int port = 1972;
		int timeout = 500;
	
		if (args.length>=1) {
			hostname = args[0];
			int sep = hostname.indexOf(':');
			if ( sep>0 ) {
				 port=Integer.parseInt(hostname.substring(sep+1,hostname.length()));
				 hostname=hostname.substring(0,sep);
			}			
		}
		System.out.println("Host: "+hostname+":"+port);		

		if (args.length>=3) {
			try {
				port = Integer.parseInt(args[2]);
			}
			catch (NumberFormatException e) {
				timeout = 500;
			}
		}
		System.out.println(TAG+" timeout_ms: " + timeout);
		
		BufferClientClock C = new BufferClientClock();

		Header hdr=null;
		while( hdr==null ) {
			 try {
				  System.out.println(TAG+" Connecting to "+hostname+":"+port);
				  if ( !C.isConnected() ) {
						C.connect(hostname, port);
				  }
				  //C.setAutoReconnect(true);
				  if ( C.isConnected() ) { hdr = C.getHeader(); }
			 } catch (IOException e) {
				  hdr=null;
			 }
			 if ( hdr==null ){
 				  System.out.println(TAG+" Invalid Header... waiting");
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
		int printCount=0;
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
				  printCount+=timeout;
				  if (printCount>5000){// only print timeout message every 5s
						System.out.println(sec.nSamples + "," + sec.nEvents + " (samp,evt) Press <ENTER> to send event.");
						printCount=0;
				  }
			 }
			 if ( System.in.available()>0 ) { // keys to read
				  java.util.Scanner keyboard = new java.util.Scanner(System.in);
				  keyboard.nextLine();
				  // read the initial enter.
				  System.out.print("Enter event type:");
				  String type = keyboard.nextLine();
				  System.out.print("Enter event value:");
				  String value = keyboard.nextLine();
				  C.putEvent(new BufferEvent(type,value,-1)); 
			 }
		}
		C.disconnect();
	}
}
