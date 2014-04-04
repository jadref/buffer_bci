using System.Collections;
using System.Diagnostics;

namespace FieldTrip.Buffer
{
	public class ClockSync {
	   Stopwatch stopWatch=null;
		double S0, T0; // starting samples, time
		double N=-1;  // number points
		double sS=0, sT=0;  // sum samples, time
		double sS2=0, sST=0, sT2=0; // sum product samples time
		double m, b; // fit, scale and offset
		double alpha; // learning rate

		public ClockSync() : this(.95){}  //N.B. half-life = log(.5)/log(alpha) .95=13 steps
		public ClockSync(double alpha){ 
		  this.alpha=alpha; 
		  stopWatch= Stopwatch.StartNew();
		  reset();
		}
		public ClockSync(double nSamples, double time, double alpha) : this(alpha){
			updateClock(nSamples,time);
		}
		void reset(){
		 N=-1;
		 S0=0; T0=0; sS=0; sT=0; sS2=0; sST=0; sT2=0;
		}
		public void updateClock(double S){
			  updateClock(S, stopWatch.ElapsedTicks);
		}
		public void updateClock(double S, double T) {
		   if ( N < 0 ){
			  reset();
			  N=0; S0=S; T0=T;
			}
			// subtract the 0-point
			S=S-S0;
			T=T-T0;
			// update the summary statistics
			N=alpha*N+1;
			sS=alpha*sS+S;
			sT=alpha*sT+T;
			sS2=alpha*sS2+S*S;
			sST=alpha*sST+S*T;
			sT2=alpha*sT2+T*T;
			// update the fit parameters
            if (N > 1)
            {
                m = (sST - sS * sT / N) / (sT2 - sT * sT / N);
                b = sS / N + S0 - m * (sT / N + T0);
            }
            else
            { // default to just use the last seen sample number
                m = 0; b = S0;
            }
		}

		public int time2samp(){
				 return time2samp(stopWatch.ElapsedTicks);
		}
		public int time2samp(double time){
		   return (int)(m*time + b);
		}

	}
}
