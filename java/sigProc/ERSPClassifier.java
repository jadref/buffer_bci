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

	 public Matrix preproc(Matrix data){
		  // Common pre-processing
		  super.preproc(data);

		  // Welch frequency estimation
		  if (data.getColumnDimension() >= windowFn.length) {
				System.out.println( "Spectral filtering with welch method");
				data = data.welch(1, windowFn, welchStartMs, windowLength, true, true);
				System.out.println( "Data shape after welch frequency estimation: " + data.shapeString());
        }

		  // Selecting frequencies
		  if (windowFrequencyIdx != null) {
				int[] allRows = Matrix.range(0, data.getRowDimension(), 1);
				data = new Matrix(data.getSubMatrix(allRows, ArrayFunctions.toPrimitiveArray(windowFrequencyIdx)));
				System.out.println( "Data shape after frequency selection: " + data.shapeString());
		  }
		  return data;
	 }

    public ClassifierResult apply(Matrix data) {	
		  // Do the standard pre-processing
		  data = preproc(data);
		  
		  // Linearly classifying the data
		  System.out.println( "Classifying with linear classifier");
		  Matrix fraw = applylinearClassifier(data, 0);
		  System.out.println( "Results from the classifier (fraw): " + fraw.toString());
		  Matrix f = new Matrix(fraw.copy());
		  // Removing bad channels from the classification
		  if (badChannels != null) {
				for (int channel : badChannels)
					 f.setRowMatrix(channel, Matrix.zeros(1, f.getColumnDimension()));
		  }
		  Matrix p = new Matrix(f.copy());
		  p.walkInOptimizedOrder(new DefaultRealMatrixChangingVisitor() {
					 public double visit(int row, int column, double value) {
                return 1. / (1. + Math.exp(-value));
					 }
				});
		  System.out.println( "Results from the classifier (p): " + p.toString());
		  return new ClassifierResult(f, fraw, p, data);
	 }
}
