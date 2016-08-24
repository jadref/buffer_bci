package nl.dcc.buffer_bci;
import java.io.IOException;
import java.util.Random;
import nl.fcdonders.fieldtrip.bufferclient.BufferClient;
import nl.fcdonders.fieldtrip.bufferclient.Header;

public class SignalProxy {
	static int VERB=1;

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
		    "Usage: SignalProxy buffhost:buffport fsample nchans blockSize\n"
		  + "where:\n"
		  + "\t buffersocket\t is a string of the form bufferhost:bufferport (localhost:1972)\n"
		  + "\t fsample\t is the frequency data is generated in Hz                 (100)\n"
		  + "\t nchans\t is the number of simulated channels to make                 (3)\n"
		  + "\t blocksize\t is the number of samples to send in one packet           (5)\n";

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

	 public SignalProxy(String hostname, int port, int nChannels, double fSample, int blockSize){
		  this.hostname = hostname;
		  this.port     = port;
		  this.nChannels= nChannels;
		  this.fSample  = fSample;
		  this.blockSize= blockSize;
		  client   = new BufferClient();
		  generator= new Random();
	 }

	private double[][] genData() {
		double[][] data = new double[blockSize][nChannels];

		for (int x = 0; x < data.length; x++) {
			for (int y = 0; y < data[x].length-1; y++) {
				data[x][y] = generator.nextDouble();
			}
			// last channel is always pure sin wave
			data[x][data[x].length-1] = Math.sin( (nSample + x)*sinFreq*2*Math.PI/fSample );
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

			client.putHeader(new Header(nChannels, fSample, 10));
			nSample = 0;
			nBlk    = 0;
			double[][] data = null;			
			long printTime = 0;
			long t0 = System.currentTimeMillis();
			long t  = t0;
			long nextBlockTime = t0;
			while (run) {
				data = genData();
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

	public void stop() { run=false; }
   public boolean isrunning(){ return run; }
}
