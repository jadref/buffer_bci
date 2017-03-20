/*
 * Wrapper for the TMSI eeg device to send data to the ft buffer
 * 
 *
 * TODO: Channel names
 *       Noise in the LSBs for float data?
 */
package nl.dcc.buffer_bci;
import java.io.*;
import nl.fcdonders.fieldtrip.bufferclient.*;

public class Mobita2ft {
	 BufferClient ftClient;
	 String host="localhost";
	 int    port=1972;
	 float fSample=256.0f;
	 int blockSize=-1; // neg size means compute default for 50Hz buffer packet rate
	 int nByte  =0;
	 int nSample=0;
	 int nBlk   =0;
	 int BUFFERSUBSAMPLESIZE=1; // sub-sample raw data before sending
	 int MAXMISSEDSAMPLES=5;
	 int MAXSAMPLE=0; // max samples to send, never-stop if <=0
	 boolean run=true;
	 String tmsidev=DefineConstants.TMSIDEFAULT;
	 int srd=0;
    protected tmsi tms;

	 public Mobita2ft() {
		  ftClient = new BufferClient();
	 }
	 public Mobita2ft(float fSample){
		  if ( fSample>0 ) this.fSample=fSample;
		  if ( blockSize<0 ) blockSize=(int)(this.fSample/50.0);
		  ftClient = new BufferClient();		  
		  tms=new tmsi();
	 }
	 public Mobita2ft(String hostport,float fSample){		  
		  host=hostport;
		  if ( fSample>0 ) this.fSample=fSample;
		  if ( blockSize<0 ) blockSize=(int)(this.fSample/50.0);
		  ftClient = new BufferClient();		  
		  tms=new tmsi();
	 }
	 public Mobita2ft(String hostport,float fSample, int blockSize){
		  host=hostport;
		  if ( fSample>0 ) this.fSample=fSample;
		  if ( blockSize>0 ) this.blockSize=blockSize;
		  if ( this.blockSize<0 ) this.blockSize=(int)(this.fSample/50.0);
		  ftClient = new BufferClient();		  
		  tms=new tmsi();
	 }
	 public Mobita2ft(String hostport,float fSample, int blockSize, String tmsidev){
		  host=hostport;
		  if ( fSample>0 ) this.fSample=fSample;
		  if ( blockSize>0 ) this.blockSize=blockSize;
		  if ( this.blockSize<0 ) this.blockSize=(int)(this.fSample/50.0);
		  this.tmsidev=tmsidev;
		  ftClient = new BufferClient();		  
		  tms=new tmsi();
	 }
	 
	 void initHostport(String hostport){
		  host = hostport;
		  int sep = host.indexOf(':');
		  if ( sep>0 ) {
				port=Integer.parseInt(host.substring(sep+1,host.length()));
				host=host.substring(0,sep);
		  }					  
	 }
	 
	 public void disconnect() {
		  try {
				ftClient.disconnect();
		  }
		  catch (IOException e) {}
	 }
	
	 public boolean connect(String host, int port) {
		  int sep = host.indexOf(':');
		  if ( sep>0 ) { // override port with part of the host string
				port=Integer.parseInt(host.substring(sep+1,host.length()));
				host=host.substring(0,sep);
		  }					  
		  try {
				ftClient.connect(host,port);
		  }
		  catch (IOException e) {
				System.out.println("Cannot connect to FieldTrip buffer @ " + host + ":" + port);
				return false;
		  }
		  return true;
	 }
		
	 public boolean start() {
		  //-------------------------------------------------------------------------------
		  // open the mobita device
		  int status = tms.tms_init(tmsidev, srd);
		  if (status != 0) {
            System.err.format("Mobita2ft: CANNOT CONNECT: %d\n", status);
				return false;
		  }
		  System.err.println("Mobita2ft: tms initialized, making header");
		  int nchans = tms.tms_get_number_of_channels();
		  fSample = (float) (tmsi.tms_get_sample_freq() / (double) BUFFERSUBSAMPLESIZE);

		  // Define the header information
		  Header hdr = new Header(nchans, fSample, DataType.FLOAT32);
		  //-------------------------------------------------------------------------------
		  // Copy the channel names in
		  for (int i = 0; i < nchans; i++) {
				hdr.labels[i]=tms.tms_get_in_dev().Channel[i].ChannelDescription;
		  }
		  // send the header information to the buffer
		  try {
				System.out.println("Sending header: " + hdr.toString());
				ftClient.putHeader(hdr);
		  } catch (IOException e) {
				System.out.println("PutHeader failed");
				System.out.println(e);
				return false;
		  }
		  return true;
	 }
		
	 public void stop() {
		  System.out.println("Closing...");
		  run=false;
	 }
    public boolean isrunning(){ return run; }


	 public static void main(String[] args) {
		  String tmsidev=DefineConstants.TMSIDEFAULT;
		  String hostport="localhost:1972";
		  if (args.length > 0 && "--help".equals(args[0])) {
				System.out.println("Usage:   java Mobita2ft hostname:port fSample audioDevID blockSize");
				return;
		  }
		  if ( args.length>0 ) {
				hostport=args[0];
		  }
		  System.out.println("HostPort="+hostport);

		  float fSample=-1;
		  if ( args.length>=2 ) {
				try {
					 fSample = Float.parseFloat(args[1]);
				}
				catch (NumberFormatException e) {
				}			 
		  }
		  System.out.println("fSample ="+fSample);

		  if ( args.length>=3 ) {
				tmsidev = args[2];
		  }
		  System.out.println("tmsidev ="+tmsidev);

		  int blockSize=-1;
		  if ( args.length>=4 ) {
				try {
					 blockSize = Integer.parseInt(args[3]);
				}
				catch (NumberFormatException e) {
				}			 
		  }
		  System.out.println("Blocksize ="+blockSize);
		
		  Mobita2ft m2b = new Mobita2ft(hostport,fSample,blockSize,tmsidev);
		  m2b.mainloop();
		  m2b.stop();
	 }

	 public void mainloop(){
		  System.out.println("fSample="+fSample+" blockSize="+blockSize);
		  run = true;
		  if (connect(host,port)==false) return;
		  if (!start()) return;
		  System.out.println("success..");
		
		  /* these are specific structures for the acquisation device */
		  TMS_CHANNEL_DATA_T[] channel; //*< channel data
		  double starttime = tms.get_time();
		  channel = tms.tms_alloc_channel_data();
		  if (channel == null) {
				System.err.format("Mobita2ft: # main: tms_alloc_channel_data problem!! basesamplerate!\n");
		  }

		  nByte   = 0;
		  nSample = 0;
		  nBlk    = 0;
		  int nchans = tms.tms_get_number_of_channels();
		  int tmssamp = 0 ;
		  int nbad=0;
		  float[][] samples = new float[blockSize][nchans];
		  long t0 = System.currentTimeMillis();
		  long printTime = 0;
		  long t  = t0;
		  while (run) {
            //-------------------------------------------------------------------------------
			   // Read DATA from the TMSI device
				if (BUFFERSUBSAMPLESIZE > 1) {
                for (int i = 0; i < samples.length; i++) {
						  for ( int j=0; j<samples[i].length; j++){
								samples[i][j] = 0.0f;
						  }
                }
            }
            for (int si = 0; si < blockSize * BUFFERSUBSAMPLESIZE; si++) { // get a block's worth of TMSIsamples
                // -- assumes 1 sample per call!
					 /* get the new data */
                tmssamp = 0;
                while (tmssamp <= 0) { // get new data samples
                    tmssamp = tms.tms_get_samples(channel);
                    if (tmssamp != nchans) {
                        nbad++;
                        /* Note: the number of samples returned by the tms_get_samples seems
									to be garbage so ignore it for now */
                        System.err.format("Mobita2ft: tms_get_samples error got %d samples when expected 1.\n", tmssamp);
                        if (nbad < MAXMISSEDSAMPLES) {
									 try { // sleep for 500 micro-seconds = .5ms -- to stop cpu hogging
										  Thread.sleep(1); 
									 } catch ( InterruptedException ex) {
									 }
                            continue;
                        } else {
                            System.err.format("Mobita2ft: tmp_get_samples returned *BAD* samples too many times.\n");
                        }
                    } else {
                        if (nbad > 0) {
                            nbad--;
                        }
                    }
                }

                // copy the samples into the data buffer, in the order we
                if (BUFFERSUBSAMPLESIZE > 1) { // accumulate over BUFFERSUBSAMPLESIZE device samples
                    int buffsi = si / BUFFERSUBSAMPLESIZE; // sample index in the buffer data packet
                    for (int chi = 0; chi < nchans; chi++) {
                        samples[buffsi][chi] += channel[chi].data[channel[chi].rs - 1].sample;
                    }
                } else { // 1 amp sample per buffer sample
                    for (int chi = 0; chi < nchans; chi++) {
                        samples[si][chi] = channel[chi].data[channel[chi].rs - 1].sample;
                    }
                }
                nSample += 1; //nSample;
            }
            if (BUFFERSUBSAMPLESIZE > 1) { // convert multi-samples sums into means
                for (int i = 0; i < samples.length; i++) {						  
						  for (int j = 0; j < samples[i].length; j++) {
								samples[i][j] /= BUFFERSUBSAMPLESIZE; // samp = [time][ch]
						  }
                }
            }
            if (MAXSAMPLE > 0 && nSample > MAXSAMPLE) {
                break;
            }		
				
				// Send to the buffer
            //-------------------------------------------------------------------------------
				/* send the data to the buffer */
				try {
					 ftClient.putData(samples);
				}
				catch (IOException e) {
					 System.out.println("putData error!");
					 System.out.println(e);
				}
				  
				// Track how much we have sent
				nBlk    = nBlk+1;

				t        = System.currentTimeMillis() - t0; // current time since start
				if (t >= printTime) {
					 System.out.print(nBlk + " " + nSample + " 0 " + (t/1000) + " (blk,samp,event,sec)\r");
					 printTime = t + 5000; // 5s between prints
				}				

				// Check for key-presses
				try {
					 if (System.in.available() > 0) {
						  int key = System.in.read();
						  if (key == 'q') break;
					 }
				}
				catch (java.io.IOException e) {}
		  }
	 }
}
