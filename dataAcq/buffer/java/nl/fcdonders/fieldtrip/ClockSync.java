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
	 double minUpdateTime = 50; // only update if at least 50ms apart, prevent rounding errors	 

	 public ClockSync() {this(.95);}  //N.B. half-life = log(.5)/log(alpha) .95=13, .97=22, .98=34, .99=69 seconds
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
				N=0; S0=S; T0=T; Tlast=T; Slast=S;
		  }
		  // sanity check inputs and ignore if too close in time -> would lead to infinite gradients
		  if ( T<Tlast+minUpdateTime ) { 
				return;
		  }
		  // BODGE: this should really the be integerated weight
		  double wght = Math.pow(alpha,((double)(T-Tlast))/1000.0); // weight based on time since last update
		  Tlast=T; Slast=S;
		  // subtract the 0-point
		  S=S-S0;
		  T=T-T0;
		  // update the summary statistics
		  N  =wght*N   + 1;
		  sS =wght*sS  + S;
		  sT =wght*sT  + T;
		  sS2=wght*sS2 + S*S;
		  sST=wght*sST + S*T;
		  sT2=wght*sT2 + T*T;
		  // update the fit parameters
		  double Tvar = sT2 - sT * sT / N;
		  double STvar = sST - sS * sT / N;
		  if (N > 1.0 && Tvar>STvar*1e-10){ // only if have good enough condition number (>1e-10)
				m = STvar / Tvar; // NaN if origin and 1 point only due to centering
				b = sS / N + S0 - m * (sT / N + T0);
		  } else if ( N>0.0 && T>0.0 ) { // fit straigt line from origin to this cluster
				m = sS/sT;  b= S0 - m * T0;
		  } else { // default to just use the initial point
				m = 0; b = S0;
		  }
		  System.out.println(" wght=" + wght + " N= " + N + " m,b= " + m + ',' + b);
	 }

	 public long getSamp(){ return getSamp(getTime());}
	 public long getSamp(double time){ 
		  return (long)(N>0?(m*time + b):Slast); //If not enough data yet, just return last seen #samp
	 }	 
	 // N.B. the max weight is: \sum alpha.^(i) = 1/(1-alpha)
	 //      and the weight of 1 half-lifes worth of data is : (1-alpha.^(hl))/(1-alpha);
	 public long getSampErr(){
		  double weightLim = (1-Math.pow(alpha,hl/2))/(1-alpha);
		  System.out.println(" N = " + N + " weightLim = " + weightLim);
		  //BODGE:time since last update in samples
		  return (Tlast>0&&N>weightLim)?((long)((getTime()-Tlast)*m)):100000;
	 }
}
