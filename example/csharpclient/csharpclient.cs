// note: build using: mcs /r:../../dataAcq/buffer/csharp/Buffer.dll csharpclient.cs
//       run in debug:  mono -debug csharpclient.exe

using System;
using System.IO;
using FieldTrip.Buffer;

public class csharpclient {
  private static bool endExpt=false;
  public static int Main(String[] args) {
	 String hostname = "localhost";
	 int port = 1972;
	 int timeout = 5000;
	
	 if (args.Length>=1) {
		hostname = args[0];
	 }
	 if (args.Length>=2) {
		try {
		  port = Convert.ToInt32(args[1]);
		}
		catch { //  (NumberFormatException e)
		  port = 0;
		}
		if (port <= 0) {
		  System.Console.WriteLine("Second parameter ("+args[1]+") is not a valid port number.");
		  return 1;
		}
	 }
	 if (args.Length>=3) {
		try {
		  port = Convert.ToInt32(args[2]);
		}
		catch { //  (NumberFormatException e)
		  timeout = 5000;
		}
	 }
		
	 BufferClientClock C = new BufferClientClock();

	 Header hdr=null;
	 while( hdr==null ) {
		try {
		  System.Console.Write("Connecting to "+hostname+":"+port+"...");
		  C.connect(hostname, port);
		  System.Console.WriteLine("done");
		  System.Console.Write("Getting Header...");
		  if ( C.isConnected() ) {						
			 hdr = C.getHeader();
		  }
		  System.Console.WriteLine("done");
		} catch { //(IOException e)
		  hdr=null;
		}
		if ( hdr==null ) {
		  System.Console.WriteLine("Invalid Header... waiting");
		  System.Threading.Thread.Sleep(1000);
		}
	 }
	 System.Console.WriteLine("#channels....: "+hdr.nChans);
	 System.Console.WriteLine("#samples.....: "+hdr.nSamples);
	 System.Console.WriteLine("#events......: "+hdr.nEvents);
	 System.Console.WriteLine("Sampling Freq: "+hdr.fSample);
	 System.Console.WriteLine("data type....: "+hdr.dataType);
	 for (int n=0;n<hdr.nChans;n++) {
		if (hdr.labels[n] != null) {
		  System.Console.WriteLine("Ch. " + n + ": " + hdr.labels[n]);
		}
	 }
						
	 // Now do the echo-server
	 int nEvents=hdr.nEvents;
	 endExpt=false;
	 while ( !endExpt ) {
		SamplesEventsCount sec = C.waitForEvents(nEvents,timeout); // Block until there are new events
		if ( sec.nEvents > nEvents ){
		  // get the new events
		  BufferEvent[] evs = C.getEvents(nEvents,sec.nEvents-1);
		  //float[][] data = C.getFloatData(0,sec.nSamples-1); // Example of how to get data also
		  nEvents=sec.nEvents;// update record of which events we've seen
		  // filter for ones we want
		  System.Console.WriteLine("Got " + evs.Length + " events");
		  for ( int ei=0; ei<evs.Length; ei++){
			 BufferEvent evt=evs[ei];
			 String evttype = evt.getType().toString(); // N.B. to*S*tring, not upper case!
			 // only process if it's an event of a type we care about
			 // In our case, don't echo our own echo events....
			 if ( !evttype.Equals("echo") ){  // N.B. use equals, not == to compare string contents!
				if ( evttype.Equals("exit")) { // check for a finish event
				  endExpt=true;
				} 
				// Print the event to the console
				System.Console.WriteLine(ei + ") t:" + evt.getType().toString() + " v:" + evt.getValue().toString() + " s:" + evt.sample);
				// Now create the echo event, with auto-completed sample number
				// N.B. -1 for sample means auto-compute based on the real-time-clock
				C.putEvent(new BufferEvent("echo",evt.getValue().toString(),-1)); 
			 }
		  }
		} else { // timed out without new events
		  System.Console.WriteLine("Timeout waiting for events");
		}
	 }
	 System.Console.WriteLine("Normal Exit");
	 C.disconnect();
	 return 0;
  }
}