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
public class ERPClassifier extends PreprocClassifier {
    public static String TAG = ERPClassifier.class.toString();

	 public ERPClassifier( PreprocClassifier pc ){
		  super(pc);
	 }
								  
	 public ERPClassifier( double samplingFrequency,
								  boolean detrend,
								  boolean[] isbadCh,
		  Matrix spatialFilter, double[] spectralFilter,/*Integer[] outSize,*/int[] windowTimeIdx,
		  double[] welchWindow,WelchOutputType welchAveType,int[] windowFrequencyIdx,
								  //Double badChannelThreshold,Double badTrialThreshold,
								  String[] subProbDescription, List<Matrix> clsfrW, double[] clsfrb){
		  super("ERP",samplingFrequency,detrend,isbadCh,spatialFilter,spectralFilter,windowTimeIdx,welchWindow,welchAveType,windowFrequencyIdx,subProbDescription,clsfrW,clsfrb);
	 }

	 @Override
	 public Matrix preproc(Matrix data){
		  if ( VERB>0 ) System.out.println("ERP preproc");
		  // Common pre-processing
		  data = super.preproc(data);

		  // TODO: Add the spectral filter
		  
		  System.out.println("Error: Not defined yet");
		  return data;
	 }
}
