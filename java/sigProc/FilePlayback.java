package nl.dcc.buffer_bci;
import java.io.*;
import java.nio.*;
import javax.swing.JFileChooser;
import nl.fcdonders.fieldtrip.bufferclient.*;

public class FilePlayback {
    protected static final String TAG = FilePlayback.class.getSimpleName();
	 final static int VERB=1;
    private static int BUFFERSIZE = 65500;
    private InputStream dataReader = null;
    private InputStream eventReader = null;
    private InputStream headerReader = null;
	 boolean run=true;
	 final String hostname;
	 final int port;
	 final String dataDir;
	 final double speedup;
	 final int blockSize;
	 final BufferClient client;
	 
	 static final String usage=
		    "Usage: FilePlayback buffhost:buffport dataDir speedup buffsamp\n"
		  + "where:\n"
		  + "\t buffersocket\t is a string of the form bufferhost:bufferport (localhost:1972)\n"
		  + "\t dataDir\t is the directory which contains the saved data\n"
		  + "\t speedup\t is a speedup factor to play back at                       (1)\n"
		  + "\t buffsamp\t is the number of file samples to put in each buffer packet (1)\n";

	 public static void main(String[] args) throws IOException,InterruptedException {
		String hostname = "localhost";
		int port = 1972;
		int timeout = 5000;
		double speedup=1;
		int blockSize=1;
		String dataDir=null;
	
		if (args.length==0 ){
			 System.out.print(usage);
          javax.swing.JFileChooser fc = new javax.swing.JFileChooser();
          int returnVal = fc.showOpenDialog(null);
          if (returnVal == javax.swing.JFileChooser.APPROVE_OPTION) {
              File file = fc.getSelectedFile();
              dataDir=file.getParent();
          }
		}
		if (args.length>=1) {
			hostname = args[0];
			int sep = hostname.indexOf(':');
			if ( sep>0 ) {
				 port=Integer.parseInt(hostname.substring(sep+1,hostname.length()));
				 hostname=hostname.substring(0,sep);
			}			
		}
		System.out.println(TAG+" Host:port="+hostname+port);

		if (args.length>=2) {
			 dataDir=args[1];
		}
		System.out.println(TAG+" dataDir="+dataDir);

		if ( args.length>=3 ) {
			try {
				speedup = Integer.parseInt(args[2]);
			}
			catch (NumberFormatException e) {
				 speedup = 1;
			}			 
		}
		System.out.println(TAG+" speedup="+speedup);

		if ( args.length>=4 ) {
			try {
				blockSize = Integer.parseInt(args[3]);
			}
			catch (NumberFormatException e) {
				 blockSize = 1;
			}			 
		}
		System.out.println(TAG+" blockSize="+blockSize);
		FilePlayback sp=new FilePlayback(hostname,port,dataDir,speedup,blockSize);
		sp.mainloop();
		sp.stop();		
	 }
	 

	 public FilePlayback(String hostname, int port, 
								InputStream dataReader, InputStream eventReader, InputStream headerReader, 
								double speedup, int blockSize){
			 this.hostname = hostname;
			 this.port     = port;
			 this.dataDir  = null;
			 this.dataReader = dataReader;
			 this.eventReader= eventReader;
			 this.headerReader=headerReader;
			 this.speedup  = speedup;
			 this.blockSize= blockSize;
			 client   = new BufferClient();
	 }

	 public FilePlayback(String hostname, int port, String dataDir, double speedup, int blockSize){
			 this.hostname = hostname;
			 this.port     = port;
			 this.dataDir  = dataDir;
			 this.speedup  = speedup;
			 this.blockSize= blockSize;
			 client   = new BufferClient();
			 // Open the header/events/samples files
			 try {
				  initFiles(dataDir);
			 } catch ( FileNotFoundException e ) {
				  e.printStackTrace();
				  System.exit(-1);
			 }
	 }


	 public void mainloop(){
		
		while( !client.isConnected() && run ) {
			 try {
				  System.out.println("Connecting to "+hostname+":"+port);
				  client.connect(hostname, port);
			 } catch (IOException e) {
			 }
			 if ( !client.isConnected() ){
 				  System.out.println("Couldn't connect. waiting");
				  try {
						Thread.sleep(1000);
				  } catch ( InterruptedException e ) {
						run = false;
						System.exit(-1);
				  }
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
            System.out.println(TAG+" Sending header: " + hdr.toString());
        }
        hdr.nSamples = 0; // reset number of samples to 0

        try {
            client.putHeader(hdr);
        } catch (IOException e) {
            e.printStackTrace();
        }

        // Interval between sending samples to the buffer
        int pktSamples = hdr.nChans * blockSize; // number data samples in each buffer packet
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


        while(!eof && run) {//The run switch allows control of stopping the thread and getting out of the loop
            // Read one buffer packets worth of samples
            // increment the cursor position
            if (VERB > 0 && elapsed_ms > print_ms + 500) {
                print_ms = elapsed_ms;
                System.out.println(TAG+ " " + nblk + " " + nsamp + " " + nevent + " " + (elapsed_ms / 1000)
											  + " (blk,samp,event,sec)\r");
            }


            // read and write the samples
            try {
                n = dataReader.read(samples);
            } catch (IOException e) {
					 n = -1;
                e.printStackTrace();
            }
            if (n <= 0) {
                eof = true;
                break;
            } // stop if run out of samples

            try {
                client.putRawData(blockSize, hdr.nChans, hdr.dataType, samples);
            } catch (IOException e) {
                e.printStackTrace();
            }

            // update the sample count
            nsamp += blockSize;
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
                    System.out.println(TAG+ " Read Event: " + evt);
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

		  stop();
	}
	 
	 public void stop() { run=false; }
    public boolean isrunning(){ return run; }

	 void initFiles(String fdir) throws FileNotFoundException {
		  dataReader = new BufferedInputStream(new FileInputStream(fdir + File.separator + "samples"));
		  eventReader = new BufferedInputStream(new FileInputStream(fdir + File.separator + "events"));
		  headerReader = new BufferedInputStream(new FileInputStream(fdir + File.separator + "header"));
    }

	 void cleanup() throws IOException {
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
