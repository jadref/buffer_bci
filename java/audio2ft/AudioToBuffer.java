/*
 * Copyright (C) 2010, Stefan Klanke
 * Donders Institute for Donders Institute for Brain, Cognition and Behaviour,
 * Centre for Cognitive Neuroimaging, Radboud University Nijmegen,
 * Kapittelweg 29, 6525 EN Nijmegen, The Netherlands
 *
 * Simple demo of how to stream audio signals to a Fieldtrip buffer 
 *
 */
package nl.dcc.buffer_bci;
import java.io.*;
import nl.fcdonders.fieldtrip.bufferclient.*;
import javax.sound.sampled.*;

public class AudioToBuffer {
	BufferClient ftClient;
	TargetDataLine lineIn;
	 String host="localhost";
	 int    port=1972;
	float fSample=44100.0f;
	 int blockSize=-1; // neg size means compute default for 50Hz buffer packet rate
	 int nByte  =0;
	 int nSample=0;
	 int nBlk   =0;
	 int audioDevID=-1;
	boolean run=true;

	public AudioToBuffer() {
		ftClient = new BufferClient();
	}
	public AudioToBuffer(float fSample){
		 if ( fSample>0 ) this.fSample=fSample;
		 if ( blockSize<0 ) blockSize=(int)(this.fSample/50.0);
		ftClient = new BufferClient();		  
	}
	 public AudioToBuffer(String hostport,float fSample){		  
		  host=hostport;
		 if ( fSample>0 ) this.fSample=fSample;
		 if ( blockSize<0 ) blockSize=(int)(this.fSample/50.0);
		ftClient = new BufferClient();		  
	}
	 public AudioToBuffer(String hostport,float fSample, int blockSize){
		  host=hostport;
		 if ( fSample>0 ) this.fSample=fSample;
		 if ( blockSize>0 ) this.blockSize=blockSize;
		 if ( this.blockSize<0 ) this.blockSize=(int)(this.fSample/50.0);
		ftClient = new BufferClient();		  
	}
	 public AudioToBuffer(String hostport,float fSample, int blockSize, int audioDevID){
		  host=hostport;
		 if ( fSample>0 ) this.fSample=fSample;
		 if ( blockSize>0 ) this.blockSize=blockSize;
		 if ( this.blockSize<0 ) this.blockSize=(int)(this.fSample/50.0);
		 this.audioDevID=audioDevID;
		ftClient = new BufferClient();		  
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
	
	public void listDevices() {
		Mixer.Info[] mixInfo = AudioSystem.getMixerInfo();
    	System.out.println("AUDIO devices available on this machine:");
    	for (int i = 0; i < mixInfo.length; i++) {
			System.out.print((i+1)+": ");
			System.out.println(mixInfo[i]);
			Mixer mixer = AudioSystem.getMixer(mixInfo[i]);
			Line.Info[] lineInfo = mixer.getTargetLineInfo();
			for (int j=0; j < lineInfo.length; j++) {
				System.out.print("   " + (j+1)+": ");
				System.out.println("   " + lineInfo[j]);
			}	
		}
	}
	
	public boolean start() {
		AudioFormat fmt = new AudioFormat(fSample, 16, 2, true, false);
		try {
			 if ( audioDevID<0 ){ // use the default device
				  System.out.print("Trying to open default AUDIO IN device...");
				  lineIn = AudioSystem.getTargetDataLine(fmt);
			 } else { // use the specified mixer
				  Mixer.Info[] mixInfo = AudioSystem.getMixerInfo();
				  System.out.println("Trying to open mixer: " + mixInfo[audioDevID-1]);
				  Mixer mixer = AudioSystem.getMixer(mixInfo[audioDevID-1]);
				  lineIn = (TargetDataLine)mixer.getLine(new DataLine.Info(TargetDataLine.class,fmt));
			 }
			lineIn.open(fmt);
			lineIn.start();
		}
		catch (LineUnavailableException e) {
			System.out.println("Open Audio failed");
			System.out.println(e);
			return false;
		}
		Header hdr = new Header(2, fSample, DataType.INT16);
		try {
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
		lineIn.stop();
	}

	public static void main(String[] args) {
		String hostport="localhost:1972";
		if (args.length > 0 && "--help".equals(args[0])) {
			System.out.println("Usage:   java AudioToBuffer hostname:port fSample audioDevID blockSize");
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

		int audioDevID=-1;
		if ( args.length>=3 ) {
			try {
				audioDevID = Integer.parseInt(args[2]);
			}
			catch (NumberFormatException e) {
			}			 
		}
		System.out.println("audioDevID ="+audioDevID);

		int blockSize=-1;
		if ( args.length>=4 ) {
			try {
				blockSize = Integer.parseInt(args[3]);
			}
			catch (NumberFormatException e) {
			}			 
		}
		System.out.println("Blocksize ="+blockSize);
		
		AudioToBuffer a2b = new AudioToBuffer(hostport,fSample,blockSize,audioDevID);
		a2b.mainloop();
		a2b.stop();
	}

	 public void mainloop(){
		  System.out.println("fSample="+fSample+" blockSize="+blockSize);
		run = true;
		if (connect(host,port)==false) return;
		listDevices();
		if (!start()) return;
		System.out.println("success..");
		
		System.out.println("Now streaming audio. Press q and <enter> to quit.\n");
		nByte   = 0;
		nSample = 0;
		nBlk    = 0;
		long t0 = System.currentTimeMillis();
		long printTime = 0;
		long t  = t0;
		while (run) {
			 // read in the data from the audio
			 int na = lineIn.available();// number samples available to read
			 if ( na>0 ){
				  byte[] buf = new byte[na*4];
				  lineIn.read(buf, 0, na*4);
				  // Send to the buffer
				  try {
						ftClient.putRawData(na, 2, DataType.INT16, buf);
				  }
				  catch (IOException e) {
						System.out.println(e);
				  }
				  
				  // Track how much we have sent
				  nSample = nSample + na;
				  nBlk    = nBlk+1;
			 } else {
				  // Sleep a block of samples should be ready
				  try { 
						Thread.sleep((long)(blockSize*1000.0/fSample));
				  } catch (InterruptedException e){
						System.out.println(e);
				  }				  
			 }

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
