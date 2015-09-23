package nl.dcc.buffer_bci.signalprocessing;

import nl.dcc.buffer_bci.matrixalgebra.linalg.Matrix;
import nl.dcc.buffer_bci.matrixalgebra.linalg.WelchOutputType;
import nl.dcc.buffer_bci.matrixalgebra.miscellaneous.ArrayFunctions;
import nl.dcc.buffer_bci.matrixalgebra.miscellaneous.ParameterChecker;
import nl.dcc.buffer_bci.matrixalgebra.miscellaneous.Windows;
import org.apache.commons.math3.linear.DefaultRealMatrixChangingVisitor;
import org.apache.commons.math3.linear.RealVector;

import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;
import java.io.BufferedReader;
import java.io.IOException;


/**
 * Created by Pieter Marsman on 23-2-2015.
 *  pre-processes a piece of data and applies (a set of) linear classifier(s)
 */
public class PreprocClassifier {

    public static final String TAG = ERSPClassifier.class.toString();

	 protected final String type;
    protected final double samplingFrequency;
    protected final boolean detrend;
    protected final boolean[] isbadCh;
    protected final Matrix spatialFilter;

    protected final double[] spectralFilter;
    //protected final Integer[] outSize;
    protected final int[] windowTimeIdx;

    protected final double[] welchWindow;
    protected final WelchOutputType welchAveType;
    protected final int[] windowFrequencyIdx;

    protected final double badChannelThreshold=-1;
	 protected final double badTrialThreshold=-1;

    protected final String[] subProbDescription;
    protected final List<Matrix> clsfrW;
    protected final double[] clsfrb;

    public PreprocClassifier(String type,
									  double samplingFrequency,
									  boolean detrend,
									  boolean[] isbadCh,
		  Matrix spatialFilter, double[] spectralFilter,/*Integer[] outSize,*/int[] windowTimeIdx,
		  double[] welchWindow,WelchOutputType welchAveType,int[] windowFrequencyIdx,
									  //Double badChannelThreshold,Double badTrialThreshold,
									  String[] subProbDescription, List<Matrix> clsfrW, double[] clsfrb){
        ParameterChecker.checkString(welchAveType.toString(), new String[]{"AMPLITUDE", "power", "db"});

        // TODO: immediately check if the right combination of parameters is given
        this.type = "???";
        this.samplingFrequency = samplingFrequency;
        this.detrend = detrend;
		  this.isbadCh = isbadCh;

        //this.dimension = dimension;

        this.spatialFilter = spatialFilter;
        this.spectralFilter = spectralFilter;
        this.windowTimeIdx = windowTimeIdx;

		  this.welchWindow   = welchWindow;
        this.welchAveType = welchAveType;
        this.windowFrequencyIdx = windowFrequencyIdx;
        //this.outSize = null;
        //this.windowLength = windowLength;
        //this.windowType = windowType;
        //this.windowFn = Windows.getWindow(windowLength, windowType, true);

        //this.badChannelThreshold = badChannelThreshold;
        //this.badTrialThreshold   = badTrialThreshold;

        this.subProbDescription = subProbDescription;
        this.clsfrW = clsfrW;
        this.clsfrb = clsfrb;

        //if (welchStartMs == null) this.welchStartMs = computeSampleStarts(samplingFrequency, new double[]{0});
        //else this.welchStartMs = ArrayFunctions.toPrimitiveArray(welchStartMs);

        System.out.println( "Just created PreprocClassifier with these settings: \n" + this.toString());
    }

	 public Matrix preproc(Matrix data){

        // Bad channel removal
        if ( isbadCh != null ) {
            System.out.println( "Do bad channel removal");
            int[] columns = Matrix.range(0, data.getColumnDimension(), 1);
            int[] rows = new int[isbadCh.length];
            int index = 0;
            for (int i = 0; i < isbadCh.length; i++){
                if (isbadCh[i] == false) { // keep if *not* bad
                    rows[index] = i;
                    index++;
                }
				}
            rows = Arrays.copyOf(rows, index);
            data = new Matrix(data.getSubMatrix(rows, columns));
            System.out.println( "Data shape after bad channel removal: " + data.shapeString());
        }

        // Detrend the data
        if (detrend) {
            System.out.println( "Linearly detrending the data");
            data = data.detrend(1, "linear");
        }

        // Now adaptive bad-channel removal if needed
        List<Integer> badChannels = null;
        if (badChannelThreshold > 0 ) {
            System.out.println( "Adaptive bad-channel detection+removal.");
            Matrix norm = new Matrix(data.multiply(data.transpose()).scalarMultiply(1. / data.getColumnDimension()));
            badChannels = new LinkedList<Integer>();
            // Detecting bad channels
            for (int r = 0; r < data.getRowDimension(); r++)
                if (norm.getEntry(r, 0) > badChannelThreshold) {
                    System.out.println( "Removing channel " + r);
                    badChannels.add(r);
                }

            // Filling bad channels with the mean (car)
            Matrix car = data.mean(0);
            for (int channel : badChannels) {
                data.setRow(channel, car.getColumn(0));
            }
        }

        // Select the time range
        if (windowTimeIdx != null) {
            System.out.println( "Selecting a time range");
            int[] rows = Matrix.range(0, data.getRowDimension(), 1);
            data = new Matrix(data.getSubMatrix(rows, windowTimeIdx));
            System.out.println( "New data shape after time range selection: " + data.shapeString());
        }

        // Spatial filtering
        if (spatialFilter != null) {
            System.out.println( "Spatial filtering the data");
				data.multiply(spatialFilter);
        }
		  return data;
	 }

	 public ClassifierResult apply(Matrix data){
		  // Do the standard pre-processing
		  data = preproc(data);
		  
		  // Linearly classifying the data
		  System.out.println( "Classifying with linear classifier");
		  Matrix fraw = applyLinearClassifier(data, 0);
		  System.out.println( "Results from the classifier (fraw): " + fraw.toString());
		  Matrix f = new Matrix(fraw.copy());
		  Matrix p = new Matrix(f.copy());
		  p.walkInOptimizedOrder(new DefaultRealMatrixChangingVisitor() {
					 public double visit(int row, int column, double value) {
                return 1. / (1. + Math.exp(-value));
					 }
				});
		  System.out.println( "Results from the classifier (p): " + p.toString());
		  return new ClassifierResult(f, fraw, p, data);		  
	 }

    protected Matrix applyLinearClassifier(Matrix data, int dim) {
        double[] results = new double[clsfrW.size()];
        for (int i = 0; i < clsfrW.size(); i++){
            results[i] = this.clsfrW.get(i).multiplyElements(data).sum().getEntry(0, 0) +
                    clsfrb[i];
		  }
        return new Matrix(results);
    }

    public int computeSampleWidth(double samplingFrequency, double widthMs) {
        return (int) Math.floor(widthMs * (samplingFrequency / 1000.));
    }

    public int[] computeSampleStarts(double samplingFrequency, double[] startMs) {
        int[] sampleStarts = new int[startMs.length];
        for (int i = 0; i < startMs.length; i++)
            sampleStarts[i] = (int) Math.floor(startMs[i] * (samplingFrequency / 1000.));
        return sampleStarts;
    }

    public Integer getSampleTrialLength(Integer sampleTrialLength) {
        if (false) ;// outSize != null) return Math.max(sampleTrialLength, outSize[0]);
        else if (windowTimeIdx != null) return Math.max(sampleTrialLength, windowTimeIdx[1]);
        else if (false) ;//(windowFn != null) return Math.max(sampleTrialLength, windowFn.length);
        throw new RuntimeException("Either outSize, windowTimeIdx or windowFn should be defined");
    }

    public int getOutputSize() {
        return clsfrW.size();
    }

	 public static PreprocClassifier fromString(java.io.BufferedReader is) throws java.io.IOException {
		  String line=null;
		  String[] cols=null;
		  // load a classifier from a file stream:
		  // read type          [string]
		  // read fs            [1 x 1 float]
		  // read detrend       [1 x 1 boolean]
		  // read isbad         [1 x 1 boolean]
		  //
		  // read spatialfilt   [d x d2 float]
		  //
		  // read spectralfilt  [t/2 x 1 double]  // for the fftfilter method
		  // read outsz         [2 x 1 int]      // for downsampling during filtering
		  //
		  // read timeIdx       [t2 x 1 int]
		  //
		  // read welchWindowFn [t2 x 1 double]
		  // read welchAveType  [enum]
		  // read freqIdx       [f2 x 1 int]
		  // 
		  // read subProbDesc,  [nSp Strings]
		  //      also tells us the number of classifier weight matrices to expect
		  // read W             [ d2 x t2 x nSp ]
		  // read b             [ 1 x nSp ]		  

		  // read type          [string]
		  String type = readNonCommentLine(is);

		  // read fs            [1 x 1 double]
		  double  fs   = Double.valueOf(readNonCommentLine(is));

		  // read detrend       [1 x 1 boolean]
		  boolean detrend  = Boolean.valueOf(readNonCommentLine(is));

		  // read isbadCh       [1 x nCh boolean]
		  boolean isbadCh[]=null;
		  cols = readNonCommentLine(is).split("[ ,	]"); // split on , or white-space;
		  if ( ! (cols[0].equals("null") || cols[0].equals("[]")) ){
				isbadCh= new boolean[cols.length];
				for ( int i=0; i<cols.length; i++ ) isbadCh[i]=Boolean.valueOf(cols[i]);
		  } 
		   
		  // read spatialfilt   [d x d2 double]
		  Matrix spatialFilter = Matrix.fromString(is);

		  // read spectralfilt  [t/2 x 1 double]  // for the fftfilter method
		  cols = readNonCommentLine(is).split("[ ,	]");
		  double spectralFilter[]=null;
		  if ( ! (cols[0].equals("null") || cols[0].equals("[]")) ){				
				spectralFilter = new double[cols.length];
				for ( int i=0; i<cols.length; i++ ) spectralFilter[i]=Double.valueOf(cols[i]);
		  }

		  // read outsz         [2 x 1 int]      // for downsampling during filtering
		  cols = readNonCommentLine(is).split("[ ,	]");
		  int[] outSz =null;
		  if ( ! (cols[0].equals("null") || cols[0].equals("[]")) ){				
				outSz=new int[2];
				for ( int i=0; i<cols.length; i++ ) outSz[i]=Integer.valueOf(cols[i]);
		  }

		  // read timeIdx       [t2 x 1 int]
		  cols = readNonCommentLine(is).split("[ ,	]");
		  int[] timeIdx =null;
		  if ( ! (cols[0].equals("null") || cols[0].equals("[]")) ){				
				timeIdx = new int[cols.length];
				for ( int i=0; i<cols.length; i++ ) timeIdx[i]=Integer.valueOf(cols[i]);
		  }

		  // read welchWindowFn [t2 x 1 double]
		  cols = readNonCommentLine(is).split("[ ,	]");
		  double[] welchWindow =null;
		  if ( ! (cols[0].equals("null") || cols[0].equals("[]")) ){				
				welchWindow = new double[cols.length];
				for ( int i=0; i<cols.length; i++ ) welchWindow[i]=Double.valueOf(cols[i]);
		  }

		  // read welchAveType  [enum]
		  line = readNonCommentLine(is);
		  WelchOutputType welchAveType=WelchOutputType.AMPLITUDE;
		  
		  // read freqIdx       [f2 x 1 int]
		  cols = readNonCommentLine(is).split("[ ,	]");
		  int[] freqIdx = null;
		  if ( ! (cols[0].equals("null") || cols[0].equals("[]")) ){				
				freqIdx = new int[cols.length];
				for ( int i=0; i<cols.length; i++ ) freqIdx[i]=Integer.valueOf(cols[i]);
		  }

		  // read subProbDesc,  [nSp Strings]
		  cols = readNonCommentLine(is).split("[ ,	]");
		  String[] subProbDesc=cols;
		  //      also tells us the number of classifier weight matrices to expect

		  // read W             [ d2 x t2 x nSp ]
		  List<Matrix> W=new LinkedList<Matrix>();
		  for ( int spi=0; spi<subProbDesc.length; spi++){
				W.add(Matrix.fromString(is));
		  }

		  // read b             [ 1 x nSp ]		  
		  cols = readNonCommentLine(is).split("[ ,	]");		  
		  double[]      b=null;
		  if ( ! (cols[0].equals("null") || cols[0].equals("[]")) ){				
				b=new double[subProbDesc.length];
				for ( int i=0; i<subProbDesc.length; i++ ) b[i]=Double.valueOf(cols[i]);		  
		  }

		  return new PreprocClassifier(type,
												 fs,
												 detrend,
												 isbadCh,
												 spatialFilter,spectralFilter,/*outSz,*/timeIdx,
												 welchWindow,welchAveType,freqIdx,
												 //Double badChannelThreshold,Double badTrialThreshold,
												 subProbDesc, W, b);
	 }
	 protected static String readNonCommentLine(BufferedReader is) throws java.io.IOException {
		  String line;
		  while ( (line = is.readLine()) != null ) {
				// skip comment lines
				if ( line == null || line.startsWith("#") || line.length()==0 ){
					 continue;
				} // double empty line means end of this array
		  }
		  return line;
	 }



    public String toString() {
        String str = 
				"ERSPClassifier with parameters:" + 
				//"\nWindow Fn length:  \t" + windowFn.length + 
				//"\nwelchStartMs       \t" + Arrays.toString(welchStartMs) + 
				"\nSpatial filter     \t" + (spatialFilter != null ? spatialFilter.shapeString() : "null") +
				"\nclsfr Weights      \t" + (clsfrW != null ? clsfrW.get(0).toString() : "null") + 
				"\nclsfr bias         \t" + clsfrb + 
				"\nspectralFilter     \t" + (spectralFilter != null ? spectralFilter.length : "null") + 
				"\nSpectrum desc      \t" + Arrays.toString((subProbDescription)) + 
				"\nType               \t" + type + 
				"\nWelch ave type     \t" + welchAveType +
				"\nDetrend            \t" + detrend + 
				"\nBad channel thres  \t" + badChannelThreshold + 
				"\nBad trial thres    \t" + badTrialThreshold + 
				"\nTime idx           \t" + Arrays.toString(windowTimeIdx) + 
				"\nFrequency idx      \t" + Arrays.toString(windowFrequencyIdx) + 
				"\nIs bad channel     \t" + isbadCh.length + 
				//"\nDimension          \t" + dimension + 
				//"\nWindow length      \t" + windowLength + 
				"\nSampling frequency \t" + samplingFrequency + 
				// "\nWindow type        \t" + windowType
				"";
		  
		  return str;
    }
}
