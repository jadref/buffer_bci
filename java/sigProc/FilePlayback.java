package nl.dcc.buffer_bci;
import java.io.*;
import java.nio.*;
import nl.fcdonders.fieldtrip.bufferclient.*;

class FilePlayback {
	 static int VERB=1;
	 static boolean run=true;
    private static int BUFFERSIZE = 65500;
    private static InputStream dataReader = null;
    private static InputStream eventReader = null;
    private static InputStream headerReader = null;

	 public static void main(String[] args) throws IOException,InterruptedException {
		String hostname = "localhost";
		int port = 1972;
		int timeout = 5000;
		double speedup=1;
		int buffsamp=1;
		String datDir=null;
	
		if (args.length==0 ){
			 System.out.println("FilePlayback buffhost:buffport dataDir speedup buffsamp");
			 System.exit(-1);
		}
		if (args.length>=1) {
			hostname = args[0];
			int sep = hostname.indexOf(':');
			if ( sep>0 ) {
				 port=Integer.parseInt(hostname.substring(sep+1,hostname.length()));
				 hostname=hostname.substring(0,sep);
			}			
		}
		if (args.length>=2) {
			 datDir=args[1];
		}

		if ( args.length>=3 ) {
			try {
				speedup = Integer.parseInt(args[2]);
			}
			catch (NumberFormatException e) {
				 speedup = 1;
			}			 
		}

		if ( args.length>=4 ) {
			try {
				buffsamp = Integer.parseInt(args[3]);
			}
			catch (NumberFormatException e) {
				 buffsamp = 1;
			}			 
		}

		// Open the header/events/samples files
		try {
		initFiles(datDir);
		} catch ( FileNotFoundException e ) {
			 e.printStackTrace();
			 System.exit(-1);
		}
		
		BufferClientClock client = new BufferClientClock();
		while( !client.isConnected() ) {
			 try {
				  System.out.println("Connecting to "+hostname+":"+port);
				  client.connect(hostname, port);
			 } catch (IOException e) {
			 }
			 if ( !client.isConnected() ){
 				  System.out.println("Couldn't connect. waiting");
				  Thread.sleep(1000);
			 }
		}

        // Load the header information in one go into a bytebuffer
        byte[] rawbytebuf = new byte[BUFFERSIZE];

        int n = 0;

        try {
            n = headerReader.read(rawbytebuf);
        } catch (IOException e) {
            e.printStackTrace();
        }


        // Byte-buffer used to parse the byte-stream. Force native ordering
        ByteBuffer hdrBuf = ByteBuffer.wrap(rawbytebuf, 0, n);
        hdrBuf.order(ByteOrder.nativeOrder());
        Header hdr = new Header(hdrBuf);
        if (VERB > 0) {
            System.out.println("Sending header: " + hdr.toString());
        }
        hdr.nSamples = 0; // reset number of samples to 0

        try {
            client.putHeader(hdr);
        } catch (IOException e) {
            e.printStackTrace();
        }

        // Interval between sending samples to the buffer
        int pktSamples = hdr.nChans * buffsamp; // number data samples in each buffer packet
        int pktBytes = pktSamples * DataType.wordSize[hdr.dataType];
        int nsamp = 0; // sample counter
        int nblk = 0;
        int nevent = 0;
        byte[] samples = new byte[pktBytes];

        // Size of the event header: type,type_numel,val,val_numel,sample,offset,duration,bufsz
        int evtHdrSz = DataType.wordSize[DataType.INT32] * 8;
        byte[] evtRawBuf = new byte[BUFFERSIZE]; // buffer to hold complete event structure

        // Byte-buffer used to parse the byte-stream. Force native ordering
        ByteBuffer evtBuf = ByteBuffer.wrap(evtRawBuf);
        evtBuf.order(ByteOrder.nativeOrder());
        int payloadSz = 0;
        int evtSample = 0;
        int evtSz = 0;
        long sample_ms = 0;
        long starttime_ms = java.lang.System.currentTimeMillis();
        long elapsed_ms = 0;
        long print_ms = 0;

        // Now do the data forwarding
        boolean eof = false;


        while (!eof && run) { //The run switch allows control of stopping the thread and getting out of the loop
            // Read one buffer packets worth of samples
            // increment the cursor position
            if (VERB > 0 && elapsed_ms > print_ms + 500) {
                print_ms = elapsed_ms;
                System.out.println(nblk + " " + nsamp + " " + nevent + " " + (elapsed_ms / 1000)
											  + " (blk,samp,event,sec)\r");
            }


            // read and write the samples
            try {
                n = dataReader.read(samples);
            } catch (IOException e) {
                e.printStackTrace();
            }
            if (n <= 0) {
                eof = true;
                break;
            } // stop if run out of samples

            try {
                client.putRawData(buffsamp, hdr.nChans, hdr.dataType, samples);
            } catch (IOException e) {
                e.printStackTrace();
            }

            // update the sample count
            nsamp += buffsamp;
            while (evtSample <= nsamp) {
                if (evtSample > 0) { // send the current event
                    try {
                        client.putRawEvent(evtRawBuf, 0, evtSz);
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                    nevent++;
                }

                // read the next event
                try {
                    n = eventReader.read(evtRawBuf, 0, evtHdrSz); // read the fixed size header
                } catch (IOException e) {
                    e.printStackTrace();
                }
                if (n <= 0) {
                    eof = true;
                    break;
                }
                evtSample = ((ByteBuffer) evtBuf.position(4 * 4)).getInt(); // sample index for this event
                payloadSz = ((ByteBuffer) evtBuf.position(4 * 7)).getInt(); // payload size for this event
                evtSz = evtHdrSz + payloadSz;

                // read the variable part
                try {
                    n = eventReader.read(evtRawBuf, evtHdrSz, payloadSz);
                } catch (IOException e) {
                    e.printStackTrace();
                }
                if (n <= 0) {
                    eof = true;
                    break;
                }

                // print the event we just read
                if (VERB > 1) {
                    ByteBuffer tmpev = ByteBuffer.wrap(evtRawBuf, 0, evtSz);
                    tmpev.order(evtBuf.order());
                    BufferEvent evt = new BufferEvent(tmpev);
                    System.out.println("Read Event: " + evt);
                }
            }

            // sleep until the next packet should be send OR EOF
            /*when to send the next sample */
            sample_ms = (long) ((float) (nsamp * 1000) / hdr.fSample / (float) speedup);
            elapsed_ms = java.lang.System.currentTimeMillis() - starttime_ms; // current time
            if (sample_ms > elapsed_ms) try {
                Thread.sleep(sample_ms - elapsed_ms);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            nblk++;
        }

		  client.disconnect();
	}

    static void initFiles(String fdir) throws FileNotFoundException {
		  dataReader = new BufferedInputStream(new FileInputStream(fdir + File.separator + "samples"));
		  eventReader = new BufferedInputStream(new FileInputStream(fdir + File.separator + "events"));
		  headerReader = new BufferedInputStream(new FileInputStream(fdir + File.separator + "header"));
    }

    static void cleanup() throws IOException {
        if (headerReader != null) {
            headerReader.close();
            headerReader = null;
        }
        if (eventReader != null) {
            eventReader.close();
            eventReader = null;
        }
        if (dataReader != null) {
            dataReader.close();
            dataReader = null;
        }
        run = false;
    }
	 
}
