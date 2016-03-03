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

/**
 * Created by Pieter Marsman on 23-2-2015.
 * Classifies a piece of the data using a linear classifier on the welch spectrum.
 */
public class ERSPClassifier extends PreprocClassifier {
    public static String TAG = ERSPClassifier.class.toString();

	 public ERSPClassifier( PreprocClassifier pc ){
		  super(pc);
	 }

	 public ERSPClassifier(double samplingFrequency,
								  boolean detrend,
								  boolean[] isbadCh,
		  Matrix spatialFilter, double[] spectralFilter,/*Integer[] outSize,*/int[] windowTimeIdx,
		  double[] welchWindow,WelchOutputType welchAveType,int[] windowFrequencyIdx,
								  //Double badChannelThreshold,Double badTrialThreshold,
								  String[] subProbDescription, List<Matrix> clsfrW, double[] clsfrb){
		  super("ERSP",samplingFrequency,detrend,isbadCh,spatialFilter,spectralFilter,windowTimeIdx,welchWindow,welchAveType,windowFrequencyIdx,subProbDescription,clsfrW,clsfrb);
	 }

	 @Override
	 public Matrix preproc(Matrix data){
		  // Common pre-processing
		  data = super.preproc(data);

		  // Welch frequency estimation
		  if ( VERB>1 ) System.out.println(TAG+ "Data shape after preproc: " + data.shapeString());
		  if ( VERB>1 ) System.out.println( "Spectral transformation with welch method");
		  // TODO: Make welch more intelligent....
		  data = data.welch(1, welchWindow, welchAveType, null, 0);
		  if ( VERB>1 ) System.out.println(TAG+  "New size: " + data.shapeString());

		  // Selecting frequencies
		  if (windowFrequencyIdx != null) {
				if ( VERB>1 ) System.out.println(TAG+"Frequency selection");
				int[] allRows = Matrix.range(0, data.getRowDimension(), 1);
				data = new Matrix(data.getSubMatrix(allRows, windowFrequencyIdx));
            if ( VERB>1 ) System.out.println(TAG+  "New size: " + data.shapeString());
		  }
		  return data;
	 }

	 @Override
    public ClassifierResult apply(Matrix data) {	
		  if ( VERB>0 ) System.out.println("ERSP apply");
		  // Do the standard pre-processing
		  data = preproc(data);
		  
		  // Linearly classifying the data
		  if( VERB>1 ) System.out.println(TAG+ "Classifying with linear classifier");
		  Matrix fraw = applyLinearClassifier(data, 0);
		  if( VERB>1 ) System.out.println(TAG+ "Results from the classifier (fraw): " + fraw.toString());
		  Matrix f = new Matrix(fraw.copy());
		  Matrix p = new Matrix(f.copy());
		  p.walkInOptimizedOrder(new DefaultRealMatrixChangingVisitor() {
					 public double visit(int row, int column, double value) {
                return 1. / (1. + Math.exp(-value));
					 }
				});
		  if ( VERB>1 ) System.out.println(TAG+ "Results from the classifier (p): " + p.toString());
		  return new ClassifierResult(f, fraw, p, data);
	 }
}
