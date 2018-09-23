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

    public static final int DEFAULTTRIGGERPORT=8300;
    DatagramChannel triggerchannel;
    ByteBuffer buf;
    
	 boolean run = true;
	 final String hostname;
	 final int port;
	 final int nChannels;
	 final double fSample;
	 final int blockSize;
	 final BufferClient client;
	 final Random generator;
	 final double sinFreq = 10;
	 int nSample=0;
	 int nBlk   =0;
	 static final String usage=
		    "Usage: SignalProxy buffhost:buffport fsample nchans blockSize triggerPort\n"
		  + "where:\n"
		  + "\t buffersocket\t is a string of the form bufferhost:bufferport (localhost:1972)\n"
		  + "\t fsample\t is the frequency data is generated in Hz                 (100)\n"
		  + "\t nchans\t is the number of simulated channels to make                 (3)\n"
		  + "\t blocksize\t is the number of samples to send in one packet           (5)\n"
    + "\t triggerPort\t is the port to listen for trigger inputs on.           (" + DEFAULTTRIGGERPORT + ")\n";

	 public static void main(String[] args) throws IOException,InterruptedException {
		   String hostname="localhost";
			int port=1972;
			int nChannels=4;
			double fSample=100;
			int blockSize=5;
		  
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

	 public SignalProxy(){
        this("localhost",1972,4,100,5);
    }

	 public SignalProxy(String hostname, int port, int nChannels, double fSample, int blockSize){
		  this.hostname = hostname;
		  this.port     = port;
		  this.nChannels= nChannels;
		  this.fSample  = fSample;
		  this.blockSize= blockSize;

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
            System.out.println("TriggerPort = " + triggerchannel.socket().getPort());
        }
        this.buf = ByteBuffer.allocate(512);
        
        client   = new BufferClient();
		  generator= new Random();
	 }

    private double[][] genData(double[][] data) { // data=[samples x channels]
		for (int x = 0; x < data.length; x++) {//samples
         // 1st channel is random walk
         if( x==0 ) {// wrap around state for last sample
            data[x][0] = data[data.length-1][0] + generator.nextDouble()/10;
         } else{
            data[x][0] = data[x-1][0] + generator.nextDouble();
         }
         for (int y = 1; y < data[x].length-1; y++) {// pure random channels
				data[x][y] = generator.nextDouble();
			}
			// last channel is always pure sin wave
			data[x][data[x].length-1] = Math.sin( (nSample + x)*sinFreq*2*Math.PI/fSample );
		}

		return data;
	}



    // Add triggers to the running data when recieve messages on a trigger port
    // N.B. to test on linux+bash use: cat > /dev/udp/127.0.0.1/8300
    // key + enter sends the trigger   
    private double[][] addTriggers(double[][] data) { // data=[samples x channels]
        // check for trigger messages & add trigger signal if needed        
        int nSamp = data.length;
        int nCh   = data[0].length;
        SocketAddress sendAdd;
        if( triggerchannel!=null ) {
            buf.clear();
            try {
                sendAdd = triggerchannel.receive(buf);// Non-blocking READ
                buf.flip();
                int nread = buf.remaining();
                if( sendAdd!=null && nread>0 ) {
                    System.out.println("Buf"+buf.toString()+" size"+buf.remaining());
                    float trig=0;
                    if( nread<4 ) { // it's a single byte.
                        System.out.println("Byte");                        
                        trig=(float)buf.get();
                    } else if ( nread>=4 )  {// assume it's a single
                        System.out.println("Float");
                        trig=buf.getFloat();
                    }
                    System.out.println("Got trigger " + sendAdd.toString() + " = " +  trig);
                    data[nSamp-1][nCh-1]=trig;
                }
            } catch ( IOException ex ) {                
            }
        }
        return data;
    }
    
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
         hdr.labels[0]="1/f";
		  for (int i = 1; i < nChannels-1; i++) {
				hdr.labels[i]= "noise" + i;
		  }
        hdr.labels[nChannels-1]="sin"+sinFreq+"Hz";
        client.putHeader(hdr);

        nSample = 0;
			nBlk    = 0;
         double[][] data = new double[blockSize][nChannels];//double[][] data = null;			
			long printTime = 0;
			long t0 = System.currentTimeMillis();
			long t  = t0;
			long nextBlockTime = t0;
			while (run) {
				data = genData(data);
            data = addTriggers(data);
				client.putData(data);
            
				nBlk     = nBlk+1;
				nSample  = nSample + blockSize; // current total samples sent
				t        = System.currentTimeMillis() - t0; // current time since start
				nextBlockTime = (long)((nSample+blockSize)*1000/fSample); // time to send next block
				if (nextBlockTime > t) {
					 Thread.sleep(nextBlockTime-t);
				} else if ( t > nextBlockTime+10*1000  ) {
					 // more than 10 seconds behind (probably due to sleep), reset start time
					 System.out.println("Dropped samples/sleep detected.  Reset start.");
					 t0 = System.currentTimeMillis() - nextBlockTime; // reset start time					 
				}
				if (t > printTime) {
					 System.out.print(nBlk + " " + nSample + " 0 " + (t/1000) + " (blk,samp,event,sec)\r");
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
