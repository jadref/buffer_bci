/*
 * Copyright (C) 2013, Jason Farquhar
 *
 * Extension of bufferclien to add ability to fill in event sample number if it is negative
 * based on the output of the system clock and tracking the mapping between clock-time and sample-time
 */
package nl.fcdonders.fieldtrip;
import java.nio.*;
import java.io.*;

public class BufferClientClock extends BufferClient {

	 protected ClockSync clockSync=null;
	 public long maxSampError  =5120;  // BODGE: very very very big!
	 public long updateInterval=10000; // at least every 10seconds

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
		  maxSampError=512; // BODGE: very very very big!
	 }

	 //--------------------------------------------------------------------
	 // methods offering additional useful functionality
	 public String getHost() { return sockChan.socket().getInetAddress().getHostName(); }
	 public int getPort() { return sockChan.socket().getPort(); }

	 //--------------------------------------------------------------------
	 // overridden methods to 
	 // Fill in the estimated sample info
	 public BufferEvent putEvent(BufferEvent e) throws IOException {
		  if ( e.sample < 0 ) { 
				if ( getSampErr()>maxSampError || // error too big
					  getSamp()<(long)(clockSync.Slast) || // detected prediction before last known sample
					  getTime()>(long)(clockSync.Tlast)+updateInterval || // simply too long since we updated
					  clockSync.N < 10 ) { // Simply not enough points to believe we've got a good estimate
					 System.out.print("Updating clock sync: SampErr " + getSampErr() + " getSamp " + getSamp() + " Slast " + clockSync.Slast);
					 e.sample = poll(0).nSamples; // force update if error is too big
					 System.out.println(" poll " + e.sample);
				} else { // use the estimated time
					 e.sample=(int)getSamp();
				}
		  }
		  return super.putEvent(e);
	 }
	 // use the returned sample info to update the clock sync
	 public SamplesEventsCount wait(int nSamples, int nEvents, int timeout) throws IOException {
		  SamplesEventsCount secount = super.wait(nSamples,nEvents,timeout);
		  //System.out.println("clock update");
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
	 public long getSamp() { return clockSync.getSamp(); }
	 public long getSamp(double time) { return clockSync.getSamp(time); }
	 public long getSampErr() { return Math.abs(clockSync.getSampErr()); }
	 public double getTime() { return clockSync.getTime(); }
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