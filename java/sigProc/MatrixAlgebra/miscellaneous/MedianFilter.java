package nl.dcc.buffer_bci.matrixalgebra.miscellaneous;

public class MedianFilter {
    // Simple approximate median filter based on Jeff McClintock median filter, and or:
    // Ma, Qiang, S. Muthukrishnan, and Mark Sandler. “Frugal Streaming for Estimating Quantiles.” In Space-Efficient Data Structures, Streams, and Algorithms, 77–96. Springer, 2013. http://link.springer.com/chapter/10.1007/978-3-642-40273-9_7.

    protected int    direction=0; // count of the number in the same direction for adaptive step sizing
    protected double step  =0;
    protected double median;
    protected static final double growRate=1.67;// grow slowly
    protected static final double shrinkRate=.33; // backoff rapidly

    public MedianFilter(){
        reset();
    }
    
    public void reset(){
        direction=0;
        step  =1;
        median=java.lang.Double.NaN;
    }
    
    public double apply(final double x){
        if ( java.lang.Double.isNaN(median) ) {
            // reset
            median=x;
            step  =x/100;
            direction=0;
        } else {
            if ( x > median ) { // move larger
                if ( direction>0 ) {         // same direction
                    step=step*growRate;
                } else if ( direction<0 )  { // switched directions
                    step=step*shrinkRate;
                    direction=0; // reset direction history
                }
                direction++;
                median = median + step;
            } else { // move smaller
                if ( direction < 0 ) {        // same direction
                    step=step*growRate;
                } else if ( direction > 0 ) { // switched directions
                    step=step*shrinkRate;
                    direction=0; // reset direction history
                }
                direction--;
                median = median - step;
            }
        }
        return median;
    }
};
