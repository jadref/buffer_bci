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

    public static String TAG = PreprocClassifier.class.getSimpleName();
	 public static int VERB = 0; // debugging verbosity level

	 public final String type;
    public final double samplingFrequency;
    public final boolean detrend;
    public final boolean[] isbadCh;
    public final Matrix spatialFilter;

    public final double[] spectralFilter;
    //public final Integer[] outSize;
    public final int[] windowTimeIdx;

    public final double[] welchWindow;
    public final WelchOutputType welchAveType;
    public final int[] windowFrequencyIdx;

    public final double badChannelThreshold=-1;
	 public final double badTrialThreshold=-1;

    public final String[] subProbDescription;
    public final List<Matrix> clsfrW;
    public final double[] clsfrb;

    public PreprocClassifier(PreprocClassifier pc){
        this.type = pc.type;
        this.samplingFrequency = pc.samplingFrequency;
        this.detrend = pc.detrend;
		  this.isbadCh = pc.isbadCh;

        //this.dimension = dimension;

        this.spatialFilter  = pc.spatialFilter;
        this.spectralFilter = pc.spectralFilter;
        this.windowTimeIdx  = pc.windowTimeIdx;

		  this.welchWindow   = pc.welchWindow;
        this.welchAveType = pc.welchAveType;
        this.windowFrequencyIdx = pc.windowFrequencyIdx;
        //this.outSize = pc.outSize;

        //this.badChannelThreshold = pc.badChannelThreshold;
        //this.badTrialThreshold   = pc.badTrialThreshold;

        this.subProbDescription = pc.subProbDescription;
        this.clsfrW = pc.clsfrW;
        this.clsfrb = pc.clsfrb;		  
	 }
    public PreprocClassifier(String type,
									  double samplingFrequency,
									  boolean detrend,
									  boolean[] isbadCh,
		  Matrix spatialFilter, double[] spectralFilter,/*Integer[] outSize,*/int[] windowTimeIdx,
		  double[] welchWindow,WelchOutputType welchAveType,int[] windowFrequencyIdx,
									  //Double badChannelThreshold,Double badTrialThreshold,
									  String[] subProbDescription, List<Matrix> clsfrW, double[] clsfrb){
        // TODO: immediately check if the right combination of parameters is given
        this.type = type;

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

        //this.badChannelThreshold = badChannelThreshold;
        //this.badTrialThreshold   = badTrialThreshold;

        this.subProbDescription = subProbDescription;
        this.clsfrW = clsfrW;
        this.clsfrb = clsfrb;

        if ( VERB>=0 ) 
				System.out.println(TAG+ "Just created PreprocClassifier with settings: \n" + this.toString());
    }

	 public String getType() { return type; }
	 
	 public Matrix preproc(Matrix data){

        // Bad channel removal
        if ( isbadCh != null ) {
            if ( VERB>1 ) System.out.println(TAG+ "Do bad channel removal");
            int[] columns = Matrix.range(0, data.getColumnDimension(), 1);
            int[] rows = new int[data.getRowDimension()];
				if ( rows.length != isbadCh.length && VERB>0 ) {
					 System.err.println(TAG+ "Huh? isbad and data rows are not equal!");
				}
            int index = 0;
            for (int i = 0; i<rows.length && i < isbadCh.length; i++){
                if (isbadCh[i] == false ) { // keep if *not* bad
                    rows[index] = i;
                    index++;
                }
				}
				// N.B. everthing outside the is-bad set is automatically ***BAD***
				//for ( int i=isbadCh.length; i<rows.length; i++){rows[index]=i;index++;}
				
            rows = Arrays.copyOf(rows, index); // remove all the unused rows...
            data = new Matrix(data.getSubMatrix(rows, columns));
            if ( VERB>1 ) System.out.println(TAG+ "New size: " + data.shapeString());
        }

        // Detrend the data
        if (detrend) {
            if ( VERB>1 ) System.out.println(TAG+  "Linearly detrending the data");
            data = data.detrend(1, "linear");
            if ( VERB>1 ) System.out.println(TAG+  "New size: " + data.shapeString());
        }

        // Now adaptive bad-channel removal if needed
        List<Integer> badChannels = null;
        if (badChannelThreshold > 0 ) {
            if ( VERB>1 ) System.out.println(TAG+  "Adaptive bad-channel detection+removal.");
            Matrix norm = new Matrix(data.multiply(data.transpose()).scalarMultiply(1. / data.getColumnDimension()));
            badChannels = new LinkedList<Integer>();
            // Detecting bad channels
            for (int r = 0; r < data.getRowDimension(); r++)
                if (norm.getEntry(r, 0) > badChannelThreshold) {
                    if ( VERB>0 ) System.out.println(TAG+  "Removing channel " + r);
                    badChannels.add(r);
                }

            // Filling bad channels with the mean (car)
            Matrix car = data.mean(0);
            for (int channel : badChannels) {
                data.setRow(channel, car.getColumn(0));
            }
        }
		  if ( VERB>1 ) System.out.println(TAG+  "New size: " + data.shapeString());

        // Select the time range
        if (windowTimeIdx != null) {
            if ( VERB>1 ) System.out.println(TAG+  "Selecting a time range");
            int[] rows = Matrix.range(0, data.getRowDimension(), 1);
            data = new Matrix(data.getSubMatrix(rows, windowTimeIdx));
            if ( VERB>1 ) System.out.println(TAG+  "New size: " + data.shapeString());
        }

        // Spatial filtering
        if (spatialFilter != null) {
            if ( VERB>1 ) System.out.println(TAG+  "Spatial filtering the data");
				data.preMultiply(spatialFilter);
            if ( VERB>1 ) System.out.println(TAG+  "New size: " + data.shapeString());
        }
		  if ( VERB>1 ) System.out.println(TAG+  "Final size: " + data.shapeString());
		  return data;
	 }

	 public ClassifierResult apply(Matrix data){
		  if ( VERB>1 ) System.out.println(TAG+ " preproc");
		  // Do the standard pre-processing
		  data = preproc(data);
		  
		  // Linearly classifying the data
		  if ( VERB>1 ) System.out.println(TAG+  "Classifying with linear classifier");
		  Matrix fraw = applyLinearClassifier(data, 0);
		  if ( VERB>1 ) System.out.println(TAG+  "Results from the classifier (fraw): " + fraw.toString());
		  Matrix f = new Matrix(fraw.copy());
		  Matrix p = new Matrix(f.copy());
		  // map to probabilities using the logistic operator
		  p.walkInOptimizedOrder(new DefaultRealMatrixChangingVisitor() {
					 public double visit(int row, int column, double value) {
                return 1. / (1. + Math.exp(-value));
					 }
				});
		  if ( VERB>=0 ) System.out.println(TAG+  "Results from the classifier (p): " + p.toString());
		  return new ClassifierResult(f, fraw, p, data);		  
	 }

    public Matrix applyLinearClassifier(Matrix data, int dim) {
        double[] results = new double[clsfrW.size()];
		  if ( VERB>2 ) System.out.print(TAG+ "Data=" + data.toString());
        for (int i = 0; i < clsfrW.size(); i++){
				if ( VERB>2 ) System.out.print(TAG+ "clsfr{"+i+"}"+clsfrW.get(i).toString());
            results[i] = this.clsfrW.get(i).multiplyElements(data).sum() + clsfrb[i];
            //results[i] = this.clsfrW.get(i).multiplyAccumulateElements(data) + clsfrb[i];
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
		  if ( VERB>2 ) System.out.println("Type = " + type);

		  // read fs            [1 x 1 double]
		  double  fs   = Double.valueOf(readNonCommentLine(is));
		  if ( VERB>2 ) System.out.println("fs = " + fs);

		  // read detrend       [1 x 1 boolean]
		  boolean detrend  = Integer.valueOf(readNonCommentLine(is))>0;
		  if ( VERB>2 ) System.out.println(TAG+ "detrend = " + detrend);


		  // read isbadCh       [1 x nCh boolean]
		  boolean isbadCh[]=null;
		  cols = readNonCommentLine(is).split("[ ,	]"); // split on , or white-space;
		  if ( ! (cols[0].equals("null") || cols[0].equals("[]")) ){
				isbadCh= new boolean[cols.length];
				for ( int i=0; i<cols.length; i++ ) isbadCh[i]=Integer.valueOf(cols[i])>0;
		  } 
		  if ( VERB>2 ) System.out.println(TAG+ "isbad = " + Arrays.toString(isbadCh));
		   
		  // read spatialfilt   [d x d2 double]
		  Matrix spatialFilter = Matrix.fromString(is);
		  if ( VERB>2 ) if ( spatialFilter != null ) {
				System.out.println(TAG+ "spatfilt = " + spatialFilter.toString());
		  } else { 
				System.out.println(TAG+ "spatfilt = null"); 
		  }

		  // read spectralfilt  [t/2 x 1 double]  // for the fftfilter method
		  cols = readNonCommentLine(is).split("[ ,	]");
		  double spectralFilter[]=null;
		  if ( ! (cols[0].equals("null") || cols[0].equals("[]")) ){				
				spectralFilter = new double[cols.length];
				for ( int i=0; i<cols.length; i++ ) spectralFilter[i]=Double.valueOf(cols[i]);
		  }
		  if ( VERB>2 ) System.out.println(TAG+ "spectFilt = " + Arrays.toString(spectralFilter));

		  // read outsz         [2 x 1 int]      // for downsampling during filtering
		  cols = readNonCommentLine(is).split("[ ,	]");
		  int[] outSz =null;
		  if ( ! (cols[0].equals("null") || cols[0].equals("[]")) ){				
				outSz=new int[2];
				for ( int i=0; i<cols.length; i++ ) outSz[i]=Integer.valueOf(cols[i]);
		  }
		  if ( VERB>2 ) System.out.println(TAG+ "outsz = " + Arrays.toString(outSz));

		  // read timeIdx       [t2 x 1 int]
		  cols = readNonCommentLine(is).split("[ ,	]");
		  int[] timeIdx =null;
		  if ( ! (cols[0].equals("null") || cols[0].equals("[]")) ){				
				timeIdx = new int[cols.length];
				for ( int i=0; i<cols.length; i++ ) timeIdx[i]=Integer.valueOf(cols[i]);
		  }
		  if ( VERB>2 ) System.out.println(TAG+ "outsz = " + Arrays.toString(timeIdx));

		  // read welchWindowFn [t2 x 1 double]
		  cols = readNonCommentLine(is).split("[ ,	]");
		  double[] welchWindow =null;
		  if ( ! (cols[0].equals("null") || cols[0].equals("[]")) ){				
				welchWindow = new double[cols.length];
				for ( int i=0; i<cols.length; i++ ) welchWindow[i]=Double.valueOf(cols[i]);
		  }
		  if ( VERB>2 ) System.out.println(TAG+ "welchWindow = " + Arrays.toString(welchWindow));

		  // read welchAveType  [enum]
		  line = readNonCommentLine(is);
		  WelchOutputType welchAveType=WelchOutputType.AMPLITUDE;
		  if ( VERB>2 ) System.out.println(TAG+ "welchAveType = " + welchAveType);
		  
		  // read freqIdx       [f2 x 1 int]
		  cols = readNonCommentLine(is).split("[ ,	]");
		  int[] freqIdx = null;
		  if ( ! (cols[0].equals("null") || cols[0].equals("[]")) ){				
				freqIdx = new int[cols.length];
				for ( int i=0; i<cols.length; i++ ) freqIdx[i]=Integer.valueOf(cols[i]);
		  }
		  if ( VERB>2 ) System.out.println(TAG+ "freqIdx = " + Arrays.toString(freqIdx));

		  // read subProbDesc,  [nSp Strings]
		  cols = readNonCommentLine(is).split("[ ,	]");
		  String[] subProbDesc=cols;
		  //      also tells us the number of classifier weight matrices to expect
		  if ( VERB>2 ) System.out.println(TAG+ "subProbDesc = " + Arrays.toString(subProbDesc));

		  // read W             [ d2 x t2 x nSp ]
		  List<Matrix> W=new LinkedList<Matrix>();
		  for ( int spi=0; spi<subProbDesc.length; spi++){
				W.add(Matrix.fromString(is));
				if ( VERB>2 ) if( W.get(spi) != null ) {
					 System.out.println(W.get(spi).toString());
				}
		  }

		  // read b             [ 1 x nSp ]		  
		  cols = readNonCommentLine(is).split("[ ,	]");		  
		  double[]      b=null;
		  if ( ! (cols[0].equals("null") || cols[0].equals("[]")) ){				
				b=new double[subProbDesc.length];
				for ( int i=0; i<subProbDesc.length; i++ ) b[i]=Double.valueOf(cols[i]);		  
		  }
		  if ( VERB>2 ) System.out.println(TAG+ "b = " + Arrays.toString(b));

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
				if ( VERB>2 ) System.out.println("Line: [" + line + "]");
				// skip comment lines
				if ( line == null || line.startsWith("#") || line.length()==0 ){
					 if ( VERB>2 ) System.out.println(" skipped");
					 continue;
				} else { 
					 break;
				}
		  }
		  if ( VERB>2 ) System.out.println(" Returned");
		  return line;
	 }

    public String toString() {
        String str = 
				"\nType               \t" + type + 
				"\nSampling frequency \t" + samplingFrequency + 
				"\nDetrend            \t" + detrend + 
				"\nIs bad channel     \t" + Arrays.toString(isbadCh) + 
				"\nSpatial filter     \t" + (spatialFilter != null ? spatialFilter.toString() : "null") +
				"\nspectralFilter     \t" + Arrays.toString(spectralFilter) + 
				"\nTime idx           \t" + Arrays.toString(windowTimeIdx) + 
				"\nwelchTaper         \t" + Arrays.toString(welchWindow) + 
				"\nWelch ave type     \t" + welchAveType +
				"\nFrequency idx      \t" + Arrays.toString(windowFrequencyIdx) + 
				"\nsubProb desc       \t" + Arrays.toString((subProbDescription)) + 
				"\nclsfr Weights      \t" + (clsfrW != null ? clsfrW.get(0).toString() : "null") + 
				"\nclsfr bias         \t" + Arrays.toString(clsfrb) + 
				//"\nDimension          \t" + dimension + 
				"";
		  
		  return str;
    }


	 public static void main(String[] args) throws IOException,InterruptedException {
		  // test cases
			 try { 
				  java.io.FileInputStream is = new java.io.FileInputStream(new java.io.File(args[0]));
				  if ( is==null ) System.out.println("Huh, couldnt open file stream.");
				  PreprocClassifier.fromString(new java.io.BufferedReader(new java.io.InputStreamReader(is)));
			 }  catch ( java.io.FileNotFoundException e ) {
				  e.printStackTrace();
			 } catch ( IOException e ) {
				  e.printStackTrace();
			 }
	 }
}
