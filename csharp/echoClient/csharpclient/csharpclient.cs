// note: build using: mcs /r:../../../../dataAcq/buffer/csharp/FieldTrip.Buffer.dll csharpclient.cs
//       run in debug:  mono -debug csharpclient.exe

using System;
using System.Threading;
using FieldTrip.Buffer;

namespace csharpclient
{
    public class csharpclient
    {
        private static bool endExpt = false;

        public static int Main(string[] args)
        {
            string hostname = "localhost";
            int port = 1972;
            int timeout = 5000;
	
            if (args.Length >= 1)
            {
                hostname = args[0];
            }
            if (args.Length >= 2)
            {
                try
                {
                    port = Convert.ToInt32(args[1]);
                }
                catch
                { //  (NumberFormatException e)
                    port = 0;
                }
                if (port <= 0)
                {
                    Console.WriteLine("Second parameter (" + args[1] + ") is not a valid port number.");
                    return 1;
                }
            }
            if (args.Length >= 3)
            {
                try
                {
                    port = Convert.ToInt32(args[2]);
                }
                catch
                { //  (NumberFormatException e)
                    timeout = 5000;
                }
            }
		
            BufferClientClock C = new BufferClientClock();

            Header hdr = null;
            while (hdr == null)
            {
                try
                {
                    Console.Write("Connecting to " + hostname + ":" + port + "...");
                    C.Connect(hostname, port);
                    Console.WriteLine("done");
                    Console.Write("Getting Header...");
                    if (C.IsConnected)
                    {						
                        hdr = C.GetHeader();
                    }
                    Console.WriteLine("done");
                }
                catch
                { //(IOException e)
                    hdr = null;
                }
                if (hdr == null)
                {
                    Console.WriteLine("Invalid Header... waiting");
                    Thread.Sleep(1000);
                }
            }
            Console.WriteLine("#channels....: " + hdr.NumChans);
            Console.WriteLine("#samples.....: " + hdr.NumSamples);
            Console.WriteLine("#events......: " + hdr.NumEvents);
            Console.WriteLine("Sampling Freq: " + hdr.FSample);
            Console.WriteLine("data type....: " + hdr.DataType);
            for (int n = 0; n < hdr.NumChans; n++)
            {
                if (hdr.Labels[n] != null)
                {
                    Console.WriteLine("Ch. " + n + ": " + hdr.Labels[n]);
                }
            }
						
            // Now do the echo-server
            int nEvents = hdr.NumEvents;
            endExpt = false;
            while (!endExpt)
            {
                SamplesEventsCount sec = C.WaitForEvents(nEvents, timeout); // Block until there are new events
                if (sec.nEvents > nEvents)
                {
                    // get the new events
                    BufferEvent[] evs = C.GetEvents(nEvents, sec.nEvents - 1);
                    //float[][] data = C.getFloatData(0,sec.nSamples-1); // Example of how to get data also
                    nEvents = sec.nEvents;// update record of which events we've seen
                    // filter for ones we want
                    Console.WriteLine("Got " + evs.Length + " events");
                    for (int ei = 0; ei < evs.Length; ei++)
                    {
                        BufferEvent evt = evs[ei];
                        string evttype = evt.Type.ToString();
                        // only process if it's an event of a type we care about
                        // In our case, don't echo our own echo events....
                        if (!evttype.Equals("echo"))
                        {
                            if (evttype =="exit")
                            { // check for a finish event
                                endExpt = true;
                            } 
                            // Print the event to the console
                            Console.WriteLine(ei + ") t:" + evt.Type + " v:" + evt.Value + " s:" + evt.Sample);
                            // Now create the echo event, with auto-completed sample number
                            // N.B. -1 for sample means auto-compute based on the real-time-clock
                            C.PutEvent(new BufferEvent("echo", evt.Value.ToString(), -1)); 
                        }
                    }
                }
                else
                { // timed out without new events
                    Console.WriteLine("Timeout waiting for events");
                }
            }
            Console.WriteLine("Normal Exit");
            C.Disconnect();
            return 0;
        }
    }
}
