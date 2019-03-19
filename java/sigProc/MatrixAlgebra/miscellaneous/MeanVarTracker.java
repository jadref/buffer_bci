package nl.dcc.buffer_bci.matrixalgebra.miscellaneous;
public class MeanVarTracker {
    // class to track the mean and variance of an input set of points
    double[] sX=null;
    double[] sX2=null;
    double N=0;
    double [] mu=null;
    double [] sigma=null;
    /**
     * decay constant for the mean+variance tracker.  
     */
    double alpha=.99; // alpha=.99 -> hl=log(.5)/log(alpha)= 69
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
        N = alpha*N+1.0;
        for ( int i=0; i<sX.length; i++){
            // update the cummulants
            sX[i] = alpha*sX[i]  + x[i];
            sX2[i]= alpha*sX2[i] + x[i]*x[i];
            // update the summary statistics
            mu[i] = sX[i] / N;
            if( N>1 ) {
                sigma[i] = Math.sqrt((sX2[i] - (sX[i]*sX[i])/N)/N);
            } else { // default sigma when no data...
                sigma[i] = Math.sqrt(Math.abs(sX[i]));
            }
        }
    }
    public void setalpha(double alpha){ this.alpha=alpha; }
    public void sethalflife(double hl){ this.alpha=Math.exp(Math.log(.5)/hl);}
    public double gethalflife(){ return Math.log(.5)/Math.log(alpha); }
    public double[] getmu(){ return mu; }
    public double[] getsigma(){ return sigma; }
    public String toString(){
        String str = "N="+N;
        str += "sX: [";
        for ( double x : sX ) str += x + ",";
        str += "] sX2:[";
        for ( double x : sX2 ) str += x + ",";
        str += "]";
        str += "mu: [";
        for ( double x : mu ) str += x + ",";
        str += "] sigma:[";
        for ( double x : sigma ) str += x + ",";
        str += "]";
        return str;
    }
}
