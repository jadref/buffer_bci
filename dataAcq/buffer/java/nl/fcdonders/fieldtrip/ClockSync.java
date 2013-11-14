/*
 * Copyright (C) 2014, Jason Farquhar
 * Donders Institute for Donders Institute for Brain, Cognition and Behaviour,
 * Centre for Cognition, Radboud University Nijmegen,
 */
package nl.fcdonders.fieldtrip;

public class ClockSync {
	 double S0, T0; // starting samples, time
	 public double Tlast=-1000, Slast=-1000; // last time at which the sync was updated, needed to compute accuracy?
	 double N=-1;  // number points
	 double sS=0, sT=0;  // sum samples, time
	 double sS2=0, sST=0, sT2=0; // sum product samples time
	 double m, b; // fit, scale and offset
	 double alpha, hl; // learning rate, halflife
	 

	 public ClockSync() {this(.97);}  //N.B. half-life = log(.5)/log(alpha) .95=13, .97=22, .99=70 steps
	 public ClockSync(double alpha){ 
		  this.alpha=alpha; 
		  this.hl = Math.log(.5)/Math.log(alpha);
		  reset();
	 }
	 public ClockSync(double nSamples, double time, double alpha) {
		  this(alpha);
		  updateClock(nSamples,time);
	 }
	 public void reset(){
		  System.out.println("reset clock");
		  N=0;
		  S0=0; T0=0; sS=0; sT=0; sS2=0; sST=0; sT2=0; Tlast=-10000; Slast=-10000;
	 }
	 public double getTime(){ // current time in milliseconds
		  //return ((double)java.lang.System.nanoTime())/1000.0/1000.0; // N.B. only java >=1.5
		  return ((double)java.lang.System.currentTimeMillis());
	 }
	 public void updateClock(double S){
		  updateClock(S, getTime());
	 }
	 public void updateClock(double S, double T) {
		  if ( S<Slast || T<Tlast ) { reset(); } // Buffer restart detected, so reset
		  if ( N <= 0 ){ // first call with actual data, record the start points
				N=0; S0=S; T0=T;
		  }
		  Tlast=T; Slast=S;
		  // subtract the 0-point
		  S=S-S0;
		  T=T-T0;
		  // update the summary statistics
		  N  =alpha*N   + 1;
		  sS =alpha*sS  + S;
		  sT =alpha*sT  + T;
		  sS2=alpha*sS2 + S*S;
		  sST=alpha*sST + S*T;
		  sT2=alpha*sT2 + T*T;
		  // update the fit parameters
		  if (N > 1){
				m = (sST - sS * sT / N) / (sT2 - sT * sT / N);
				b = sS / N + S0 - m * (sT / N + T0);
		  } else { // default to just use the last seen sample number
				m = 0; b = S0;
		  }
	 }

	 public long getSamp(){ return getSamp(getTime());}
	 public long getSamp(double time){ 
		  return (long)(N>2?(m*time + b):Slast); //If not enough data yet, just return last seen #samp
	 }	 
	 // N.B. the max weight is: \sum alpha.^(i) = 1/(1-alpha)
	 //      and the weight of 1 half-lifes worth of data is : (1-alpha.^(hl))/(1-alpha);
	 public long getSampErr(){
		  double weightLim = (1-Math.pow(alpha,hl))/(1-alpha);
		  return (Tlast>0&&N>weightLim)?((long)((getTime()-Tlast)*m)):100000;//BODGE:time since last update in samples
	 }
}
