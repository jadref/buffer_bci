/*
 * Copyright (C) 2013, Jason Farquhar
 *
 * Extension of bufferclien to add ability to fill in event sample number if it is negative
 * based on the output of the system clock and tracking the mapping between clock-time and sample-time
 */
package nl.fcdonders.fieldtrip.bufferclient;
import java.nio.*;
import java.io.*;

public class BufferClientClock extends BufferClient {

	 protected ClockSync clockSync=null;
	 public long maxSampError  =10000;  // BODGE: very very very big!
	 public long updateInterval=3000; // at least every 3seconds
	 public long minUpdateInterval=10; // at least 10ms (100Hz) between clock updates
	 protected int numWrong=0; // count of number wrong predictions... if too many then reset the clock

	 public BufferClientClock(){
		  super();
		  clockSync=new ClockSync();
	 }
	 public BufferClientClock(double alpha){
		  super();
		  clockSync=new ClockSync(alpha);
	 }
	 public BufferClientClock(ByteOrder order) {
		  super(order);
		  clockSync=new ClockSync();
	 }	 
	 public BufferClientClock(ByteOrder order,double alpha) {
		  super(order);
		  clockSync=new ClockSync(alpha);
	 }

	 //--------------------------------------------------------------------
	 // methods offering additional useful functionality
	 public String getHost() { return sockChan.socket().getInetAddress().getHostName(); }
	 public int getPort() { return sockChan.socket().getPort(); }

	 //--------------------------------------------------------------------
	 // overridden methods to 
	 // Fill in the estimated sample info
	 public BufferEvent putEvent(BufferEvent e) throws IOException {
		  if ( e.sample < 0 ) { e.sample=(int)getSampOrPoll(); }
		  return super.putEvent(e);
	 }
	 public void putEvents(BufferEvent[] e) throws IOException {
		int samp = -1;
		for( int i=0; i<e.length; i++ )
		  {			 
			 if ( e[i].sample < 0 )
				{
				  if ( samp<0 ) samp=(int)getSampOrPoll();
				  e[i].sample=samp;
				}
		  }
		super.putEvents(e);
	 }
	 // use the returned sample info to update the clock sync
	 public SamplesEventsCount wait(int nSamples, int nEvents, int timeout) throws IOException {
		  SamplesEventsCount secount = super.wait(nSamples,nEvents,timeout);
		  //System.out.println("clock update");
		  double deltaSamples = clockSync.getSamp()-secount.nSamples; // delta between true and estimated
		  //System.out.println("sampErr="+getSampErr() + " d(samp) " + deltaSamples + " sampThresh= " + clockSync.m*1000.0*.5);
		  if( getSampErr()<maxSampError ){
				if ( deltaSamples > clockSync.m*1000.0*.5 ){ // lost samples					 
					 System.out.println(deltaSamples + " Lost samples detected");
					 clockSync.reset();
					 //clockSync.b = clockSync.b - deltaSamples;
				} else if ( deltaSamples < -clockSync.m*1000.0*.5 ){ // extra samples
					 System.out.println(-deltaSamples + " Extra samples detected");
					 clockSync.reset();
				}
		  }
		  clockSync.updateClock(secount.nSamples); // update the rt->sample mapping
		  return secount;
	 }
	 public Header getHeader() throws IOException {
		  Header hdr=super.getHeader();
		  clockSync.updateClock(hdr.nSamples); // update the rt->sample mapping
		  return hdr;
	 }
	 public boolean connect(String address) throws IOException {
		  clockSync.reset(); // reset old clock info (if any)
		  return super.connect(address);
	 }

	 //--------------------------------------------------------------------
	 // New methods to do the clock syncronization
	 public long getSampOrPoll() throws IOException {
		  long sample=-1;
		  boolean dopoll=false;
		  if ( getSampErr()>maxSampError || // error too big
				 getTime()>(long)(clockSync.Tlast)+updateInterval || // simply too long since we updated
				 clockSync.N < 8 ) { // Simply not enough points to believe we've got a good estimate
				dopoll=true;
		  }
		  if ( getSamp()<(long)(clockSync.Slast) ){ // detected prediction before last known sample
				numWrong++; // increment count of number of times this has happened
				dopoll=true;
		  } else {
				numWrong=0;
		  }
		  if ( getTime()<(long)(clockSync.Tlast)+minUpdateInterval ) { // don't update too rapidly
				dopoll=false;
		  }
		  if ( dopoll ) { // poll buffer for current samples
				if ( numWrong > 5 ) { 
					 clockSync.reset(); // reset clock if detected sysmetic error
					 numWrong=0;
				}
				long sampest=getSamp();
				//System.out.print("Updating clock sync: SampErr " + getSampErr() + 
				//					  " getSamp " + sampest + " Slast " + clockSync.Slast);
				sample = poll(0).nSamples; // force update if error is too big
				//System.out.println(" poll " + sample + " delta " + (sample-sampest));
		  } else { // use the estimated time
				sample=(int)getSamp();
		  }
		  return sample;
	 }
	 public long getSamp() { return clockSync.getSamp(); }
	 public long getSamp(double time) { return clockSync.getSamp(time); }
	 public long getSampErr() { return Math.abs(clockSync.getSampErr()); }
	 public double getTime() { return clockSync.getTime(); } // time in milliseconds
	 public SamplesEventsCount syncClocks() throws IOException {
		  return	 syncClocks(new int[] {100,100,100,100,100,100,100,100,100});
	 }
	 public SamplesEventsCount syncClocks(int wait) throws IOException {
		  return	 syncClocks(new int[] {wait});
	 }
	 public SamplesEventsCount syncClocks(int[] wait) throws IOException {
		  clockSync.reset();
		  SamplesEventsCount ssc;
		  ssc=poll(0);
		  for (int i=0;i<wait.length;i++) {			
				try {
					 java.lang.Thread.sleep(wait[i]);
				} catch(InterruptedException e) {
				}
				ssc=poll(0);				
		  }
		  return ssc;
	 }
	 public ClockSync getclockSync(){ return clockSync; }
}