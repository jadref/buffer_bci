package nl.dcc.buffer_bci.matrixalgebra.miscellaneous;
public class MeanVarTracker {
        // class to track the mean and variance of an input set of points
        double[] sX=null;
        double[] sX2=null;
        double N=0;
        double [] mu=null;
        double [] sigma=null;
        double alpha=1.0;
        public MeanVarTracker(){};
        public void reset(){ sX=null; sX2=null; mu=null; sigma=null;  N=0; }
        public void addPoint(double [] x){
            if( N==0 ) {
                sX=new double[x.length];
                sX2=new double[x.length];
                mu=new double[x.length];
                sigma=new double[x.length];
            }
            // update the counter
            N = (1-alpha)*N+alpha;
            for ( int i=0; i<sX.length; i++){
                // update the cummulants
                sX[i] = (1-alpha)*sX[i]  + alpha*x[i];
                sX2[i]= (1-alpha)*sX2[i] + alpha*x[i]*x[i];
                // update the summary statistics
                mu[i] = sX[i] / N;
                sigma[i] = (sX2[i] - sX[i]*sX[i]/N)/N;
            }
        }
        public void setalpha(double alpha){ this.alpha=alpha; }
        //public sethalflife(double hl){ this.alpha=Math.log(hl); }
        public double[] getmu(){ return mu; }
        public double[] getsigma(){ return sigma; }
}
