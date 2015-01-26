import java.net.SocketException;
import java.io.*;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import nl.fcdonders.fieldtrip.bufferclient.*;

class filePlayback {
	 static int VERB=1; // global verbosity level
	 static int BUFFERSIZE = 65500;	 
	 
	 static InputStream dataReader=null; 
	 static InputStream eventReader=null;
	 static InputStream headerReader=null;	 

	 public static void main(String[] args) throws IOException,InterruptedException {
		  int n=0;
		  
		  if ( args.length==0 ) {
				System.out.println("filePlayback saveDirectory bufferhost:bufferport buffsamp speedup");
		  }
		  
		  // saveDirectory
		  String saveDir = "./data";
		  if (args.length>=1) {
				saveDir = args[0];
		  }
		  // buffer host:port
		  String buffhostname = "localhost";
		  int buffport = 1972;
		  if (args.length>=2) {
				buffhostname = args[1];
				int sep = buffhostname.indexOf(':');
				if ( sep>0 ) {
					 buffport=Integer.parseInt(buffhostname.substring(sep+1,buffhostname.length()));
					 buffhostname=buffhostname.substring(0,sep);
				}
		  }
		  int buffsamp = 5;
		  if (args.length>=3) { buffsamp = Integer.parseInt(args[2]); }		  
		  int speedup = 1;
		  if (args.length>=4) { speedup = Integer.parseInt(args[3]); }		  
		  
		  // print the current settings
		  System.out.println("saveDirectory: " + saveDir);
		  System.out.println("Buffer server: " + buffhostname + " : " + buffport);
		  System.out.println("speedup      : " + speedup);		  
		  System.out.println("buffSamp     : " + buffsamp);		  
		
		  // Open the header/events/samples files in the save directory
		  try { 
				initFiles(saveDir);
		  } catch ( IOException e ) {
				System.err.println("Error couldn't open directory: " + saveDir);
				System.err.println(e);
				System.exit(1);
		  }
		
		  // open the connection to the buffer server		  
		  BufferClientClock C = new BufferClientClock();
		  while ( !C.isConnected() ) {
				System.out.println("Connecting to "+buffhostname+":"+buffport);
				try { 
				C.connect(buffhostname, buffport);
				} catch (IOException ex){
				}
				if ( !C.isConnected() ) { 
					 System.out.println("Couldn't connect. Waiting");
					 Thread.sleep(1000);
				}
		  }
		
		  // send the header information
		  // Load the header information in one go into a bytebuffer
		  byte[] rawbytebuf = new byte[BUFFERSIZE];
		  n=headerReader.read(rawbytebuf);
		  // Byte-buffer used to parse the byte-stream.  Force native ordering
		  ByteBuffer hdrBuf  = ByteBuffer.wrap(rawbytebuf,0,n); hdrBuf.order(ByteOrder.nativeOrder());
		  Header hdr=new Header(hdrBuf);
		  if ( VERB>0 ){ System.out.println("Sending header: " + hdr.toString()); }
		  hdr.nSamples=0; // reset number of samples to 0
		  C.putHeader(hdr);

		  // Interval between sending samples to the buffer
		  int pktSamples     = hdr.nChans * buffsamp; // number data samples in each buffer packet
		  int pktBytes       = pktSamples * DataType.wordSize[hdr.dataType];
		  int nsamp          = 0; // sample counter		  
		  int nblk           = 0;
		  int nevent         = 0;
		  byte[] samples     = new byte[pktBytes];
		  // Size of the event header: type,type_numel,val,val_numel,sample,offset,duration,bufsz
		  int evtHdrSz       = DataType.wordSize[DataType.INT32]*8; 
		  byte[] evtRawBuf   = new byte[BUFFERSIZE]; // buffer to hold complete event structure
		  // Byte-buffer used to parse the byte-stream.  Force native ordering
		  ByteBuffer evtBuf  = ByteBuffer.wrap(evtRawBuf); evtBuf.order(ByteOrder.nativeOrder());
		  int payloadSz      = 0;
		  int evtSample      = 0;
		  int evtSz          = 0;
		  long sample_ms     = 0;
		  long starttime_ms  = java.lang.System.currentTimeMillis();
		  long elapsed_ms    = 0;
		  long print_ms      = 0;
	  		
		  // Now do the data forwarding
		  boolean eof=false;
		  while ( !eof ) {			 
				// Read one buffer packets worth of samples
				// increment the cursor position
				if ( VERB>0 && elapsed_ms > print_ms+500 ){ 
					 print_ms=elapsed_ms;
					 System.out.print(nblk + " " + nsamp + " " + nevent + " " + elapsed_ms/1000 + " (blk,samp,event,sec)\r");
				}				
				
				// read and write the samples
				n=dataReader.read(samples);
				if ( n<=0 ) { eof=true; break; } // stop if run out of samples
				C.putRawData(buffsamp,hdr.nChans,hdr.dataType,samples);
				// update the sample count
				nsamp += buffsamp;

				while ( evtSample <= nsamp ) {
					 if ( evtSample > 0 ) { // send the current event
						  C.putRawEvent(evtRawBuf,0,evtSz);
						  nevent++;
					 }
					 // read the next event
					 n = eventReader.read(evtRawBuf,0,evtHdrSz); // read the fixed size header
					 if ( n<=0 ) { eof=true; break; }
					 evtSample=((ByteBuffer)evtBuf.position(4*4)).getInt(); // sample index for this event
					 payloadSz=((ByteBuffer)evtBuf.position(4*7)).getInt(); // payload size for this event
					 evtSz    =evtHdrSz+payloadSz;
					 // read the variable part
					 n = eventReader.read(evtRawBuf,evtHdrSz,payloadSz); 
					 if ( n<=0 ) { eof=true; break; }
					 // print the event we just read
					 if ( VERB>1 ){
						  ByteBuffer tmpev=ByteBuffer.wrap(evtRawBuf,0,evtSz);
						  tmpev.order(evtBuf.order());
						  BufferEvent evt=new BufferEvent(tmpev);
						  System.out.println("Read Event: " + evt);
					 }
				}

				// sleep until the next packet should be send OR EOF
				/*when to send the next sample */
				sample_ms = (long)((float)(nsamp*1000)/hdr.fSample/(float)speedup);
				elapsed_ms= java.lang.System.currentTimeMillis() - starttime_ms; // current time
				if ( sample_ms>elapsed_ms ) Thread.sleep(sample_ms - elapsed_ms);
				
				nblk++;

		  }
		  cleanup();
	 }


	 static void initFiles(String path) throws IOException {
		  // add the reset number prefix to the path
		  dataReader= 
				new BufferedInputStream(new FileInputStream(path+File.separator+"samples"));
		  eventReader= 
				new BufferedInputStream(new FileInputStream(path+File.separator+"events"));
		  headerReader = 
				new BufferedInputStream(new FileInputStream(path+File.separator+"header"));
	 }
	 static void cleanup() throws IOException  {
		  headerReader.close();
		  eventReader.close();
		  dataReader.close();
	 }

}
