package nl.dcc.buffer_bci;
import java.io.IOException;
import java.util.Random;
import nl.fcdonders.fieldtrip.bufferclient.BufferClient;
import nl.fcdonders.fieldtrip.bufferclient.Header;

// imports for the trigger channel
import java.nio.channels.DatagramChannel;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.net.SocketException;
import java.net.SocketAddress;


public class SignalProxy implements Runnable {
	static int VERB=1;
    // defaults
	 static final String HOSTNAME="localhost";
	 static final int PORT=1972;
	 static final int NCHANNELS=4;
	 static final double FSAMPLE=250;
	 static final int BLOCKSIZE=25;
    public static final int DEFAULTTRIGGERPORT=8300;


    DatagramChannel triggerchannel;
    ByteBuffer buf;    
	 final String hostname;
	 final int port;
	 final int nChannels;
	 final double fSample;
	 final int blockSize;
	 final BufferClient client;
	 final Random generator;
	 final double sinFreq = 10;
	 boolean run = true;
    long t0;
	 int nSample=0;
	 int nBlk   =0;
    static final String usage=
		    "Usage: SignalProxy buffhost:buffport fsample nchans blockSize triggerPort\n"
		  + "where:\n"
		  + "\t buffersocket\t is a string of the form bufferhost:bufferport ("+HOSTNAME+":"+PORT+")\n"
		  + "\t fsample\t is the frequency data is generated in Hz                 ("+FSAMPLE+")\n"
		  + "\t nchans\t is the number of simulated channels to make                 ("+NCHANNELS+")\n"
		  + "\t blocksize\t is the number of samples to send in one packet           ("+BLOCKSIZE+")\n"
    + "\t triggerPort\t is the port to listen for trigger inputs on.           (" + DEFAULTTRIGGERPORT + ")\n";

	 public static void main(String[] args) throws IOException,InterruptedException {
        String hostname=HOSTNAME;
        int port       =PORT;
        int nChannels  =NCHANNELS;
        double fSample =FSAMPLE;
        int blockSize  =BLOCKSIZE;
		  
        if (args.length==0 ){
			 System.out.print(usage);
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
		if ( VERB>0 ) System.out.println("Host: "+hostname+":"+port);		

		if (args.length>=2) {
			try {
				 fSample = Double.parseDouble(args[1]);
			}
			catch (NumberFormatException e) {
				 System.err.println("Error: couldn't understand sample rate. "+fSample+"hz assumed");
			}			 
		}
		if ( VERB>0 ) System.out.println("fSample: "+fSample);

		if ( args.length>=3 ) {
			try {
				nChannels = Integer.parseInt(args[2]);
			}
			catch (NumberFormatException e) {
				System.err.println("Error: couldn't understand number of channels. "+nChannels+" assumed");
			}			 
		}
		if ( VERB>0 ) System.out.println("nChannels: "+nChannels);

		if ( args.length>=4 ) {
			try {
				blockSize = Integer.parseInt(args[3]);
			}
			catch (NumberFormatException e) {
				System.err.println("Error: couldn't understand blockSize. "+blockSize+" assumed");
			}			 
		}		  
		if ( VERB>0 ) System.out.println("blockSize: "+blockSize);

		SignalProxy sp=new SignalProxy(hostname,port,nChannels,fSample,blockSize);
		sp.mainloop();
		sp.stop();
	 }

	 public SignalProxy(){ this(HOSTNAME,PORT,NCHANNELS,FSAMPLE,BLOCKSIZE); }

	 public SignalProxy(String hostname, int port, int nChannels, double fSample, int blockSize){
		  this.hostname = hostname;
		  this.port     = port;
		  this.nChannels= nChannels;
		  this.fSample  = fSample;
		  this.blockSize= blockSize;
        this.t0=-1;

        // setup the trigger port
        try { 
            this.triggerchannel = DatagramChannel.open();
            this.triggerchannel.socket().bind(new InetSocketAddress(DEFAULTTRIGGERPORT));
            this.triggerchannel.configureBlocking(false);
        } catch ( SocketException ex ) {
            System.out.println("Error binding the trigger port!");
            this.triggerchannel=null;
        } catch ( IOException ex ) {
            System.out.println("Error creating the trigger channel!");
            this.triggerchannel = null;
        }
        if( this.triggerchannel != null ) {
            System.out.println("TriggerPort: " + triggerchannel.socket().getLocalPort());
        }
        this.buf = ByteBuffer.allocate(1024);
        
        client   = new BufferClient();
		  generator= new Random();
	 }

    private double[][] genData(double[][] data) { // data=[samples x channels]
		for (int x = 0; x < data.length; x++) {//samples
         // 1st channel is random walk
         if( x==0 ) {// wrap around state for last sample
            data[x][0] = data[data.length-1][0] + generator.nextDouble();
         } else{
            data[x][0] = data[x-1][0] + generator.nextDouble();
         }
         for (int y = 1; y < data[x].length-2; y++) {// pure random channels
				data[x][y] = generator.nextDouble();
			}
			// end-2 channel is always pure sin wave
			data[x][data[x].length-2] = Math.sin( (nSample + x)*sinFreq*2*Math.PI/fSample );
			// end channel is always trigger channel
			data[x][data[x].length-1] = 0;
		}
		return data;
	}



    // Add triggers to the running data when recieve messages on a trigger port
    // N.B. to test on linux+bash use: cat > /dev/udp/127.0.0.1/8300
    // key + enter sends the trigger   
    private double[][] addTriggersAndWait(double[][] data, long pktStartTime, long pktEndTime){ // data=[samples x channels]
        if( triggerchannel==null ) return data; 
        // check for trigger messages & add trigger signal if needed        
        int nSamp = data.length;
        int nCh   = data[0].length;
        float sampDuration= (pktEndTime-pktStartTime) / nSamp; // duration of single sample
        int sleepDuration = (int)Math.max(1f,sampDuration);//minimum time to sleep between checking triggers
        //System.out.println("SampDuration=" + sampDuration + "ms  SleepDuration="+sleepDuration);
        SocketAddress sendAdd;
        try {
            long t=getTime();
            while ( t < pktEndTime ) {
                buf.clear();
                sendAdd = triggerchannel.receive(buf);// Non-blocking READ
                buf.flip();
                int nread = buf.remaining();
                if( sendAdd!=null && nread>0 ) {
                    t=getTime(); // update the clock
                    //System.out.println("Buf"+buf.toString()+" size"+buf.remaining());
                    float trig=0;
                    if( nread<4 ) { // it's a single byte.
                        //System.out.println("Byte");                        
                        trig=(float)buf.get();
                    } else if ( nread>=4 )  {// assume it's a single
                        //System.out.println("Float");
                        trig=buf.getFloat();
                    }
                    // get the sample position to insert this trigger at
                    int sampIdx = (int)((t-pktStartTime)/sampDuration);
                    if( sampIdx>data.length-1 ) sampIdx=data.length-1; // ensure fits..
                    data[sampIdx][nCh-1]=trig;
                    System.out.println((t/1000f) + ") " + "samp=" + sampIdx + " Got trigger " + sendAdd.toString() + " = " +  trig);
                }
                try {
                    Thread.sleep(sleepDuration); // wait 1 sample before checking again
                } catch ( InterruptedException ex ) {
                }
                //System.out.print('.');
                t=getTime(); // update the clock
            }
        } catch ( IOException ex ) {
        }
        return data;
    }

    public long sett0(){ return sett0(0); }
    public long sett0(long t0){ return this.t0=System.currentTimeMillis()-t0; }
    public long getTime(){ return System.currentTimeMillis()-t0; }
    
	public void mainloop() {
		run = true;
		try {
			if (!client.isConnected() && run) {
				client.connect(hostname, port);
			} else {
				System.out.println("Could not connect to buffer.");
				return;
			}
			
			System.out.println("Putting header");
         Header hdr = new Header(nChannels,fSample,10);
         // Copy the channel names in
         hdr.labels[0]="1/f"; // 1st channel is 1/f
         for (int i = 1; i < nChannels-2; i++) { // middle channels are pure noise
				hdr.labels[i]= "noise" + i;
		  }
        hdr.labels[nChannels-2]="sin"+sinFreq+"Hz"; // last-but-one is sin
        hdr.labels[nChannels-1]="TRG"; // final channel is trigger channel
        client.putHeader(hdr);

        nSample = 0;
			nBlk    = 0;
         double[][] data = new double[blockSize][nChannels];//double[][] data = null;			
			long printTime = 0;
         sett0();
			long t  = t0;
         long blockStartTime= -1;
			long blockEndTime  = 0;
			while (run) {
				nBlk     = nBlk+1;
				nSample  = nSample + blockSize; // current total samples sent
            blockStartTime= blockEndTime;
            blockEndTime  = (long)(nSample*1000/fSample); // time to send this block

            // generate the data to be sent
            data = genData(data);

            // wait until time to send to the buffer
            data = addTriggersAndWait(data,blockStartTime,blockEndTime);
            t    = getTime(); // current time since start
				if (blockEndTime > t) {
					 Thread.sleep(blockEndTime-t);
				} else if ( t > blockEndTime+10*1000  ) {
					 // more than 10 seconds behind (probably due to sleep), reset start time
					 System.out.println("Dropped samples/sleep detected.  Reset start.");
					 sett0(blockEndTime); // reset start time					 
				}
            // at the right time, send the data
            client.putData(data);
            // logging
				if (t > printTime) {
					 System.out.print(nBlk + " " + nSample + " 0 " + (t/1000f) + " (blk,samp,event,sec)\r");
					 printTime = printTime + 5000; // 5s between prints
				}				
			}
		} catch (final IOException e) {
			 e.printStackTrace();//android.updateStatus("IOException caught, stopping.");
			return;
		} catch (InterruptedException e) {
			 e.printStackTrace();//android.updateStatus("InterruptedException caught, stopping.");
			return;
		}
	}

	@Override
	public void run() {
       mainloop();
   }

   public void start(){ // run in a background thread
       try {
           Thread thread = new Thread(this,"Java Signal Proxy");
           thread.start();
       } catch ( Exception e ) {
           System.err.println(e);
       }
   }

	public void stop() { run=false; }
   public boolean isrunning(){ return run; }
}
