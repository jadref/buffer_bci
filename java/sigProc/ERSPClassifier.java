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
public class ERSPClassifier {

    public static final String TAG = ERSPClassifier.class.toString();

    private final double[] windowFn;
    private final Double[] spatialFilter;
    private final List<Matrix> classifierSlope;
    private final Matrix spectrumMx;
    private final RealVector classifierIntercept;
    private final String[] spectrumDescription;
    private final String type;
    private final WelchOutputType welchAveType;
    private final Boolean detrend;
    private final Double badChannelThreshold;
    private final Integer[] windowTimeIdx;
    private final Integer[] windowFrequencyIdx;
    private final Integer[] thresholdIsBad;
    private final Integer[] outSize;
    private final Integer dimension;
    private final Integer windowLength;
    private final Double samplingFrequency;
    private final Windows.WindowType windowType;
    private int[] welchStartMs;

    public ERSPClassifier(List<Matrix> classifierSlope, RealVector classifierIntercept, Boolean detrend, Double
            badChannelThreshold, Windows.WindowType windowType, WelchOutputType welchAveType, Integer[]
            windowTimeIdx, Integer[] windowFrequencyIdx, Integer dimension, Double[] spatialFilter, Matrix
            spectrumMx, Integer windowLength, Double samplingFrequency, Integer[] welchStartMs, String[]
            spectrumDescription, Integer[] thresholdIsBad) {
        ParameterChecker.checkString(welchAveType.toString(), new String[]{"AMPLITUDE", "power", "db"});

        // todo immediately check if the right combination of parameters is given

        this.type = "ERSP";
        this.detrend = detrend;
        this.dimension = dimension;
        this.spectrumMx = spectrumMx;
        this.spectrumDescription = spectrumDescription;
        this.thresholdIsBad = thresholdIsBad;
        this.classifierSlope = classifierSlope;
        this.classifierIntercept = classifierIntercept;
        this.badChannelThreshold = badChannelThreshold;
        this.samplingFrequency = samplingFrequency;
        this.spatialFilter = spatialFilter;
        this.welchAveType = welchAveType;
        if (welchStartMs == null) this.welchStartMs = computeSampleStarts(samplingFrequency, new double[]{0});
        else this.welchStartMs = ArrayFunctions.toPrimitiveArray(welchStartMs);
        this.windowLength = windowLength;
        this.windowTimeIdx = windowTimeIdx;
        this.windowFrequencyIdx = windowFrequencyIdx;
        this.windowType = windowType;
        this.windowFn = Windows.getWindow(windowLength, windowType, true);
        this.outSize = null;

        System.out.println( "Just created ERSPClassifier with these settings: \n" + this.toString());
    }

    public ClassifierResult apply(Matrix data) {

        // Bad channel removal
        if (thresholdIsBad != null) {
            System.out.println( "Do bad channel removal");
            int[] columns = Matrix.range(0, data.getColumnDimension(), 1);
            int[] rows = new int[thresholdIsBad.length];
            int index = 0;
            for (int i = 0; i < thresholdIsBad.length; i++)
                if (thresholdIsBad[i] == 0) {
                    rows[index] = i;
                    index++;
                }
            rows = Arrays.copyOf(rows, index);
            data = new Matrix(data.getSubMatrix(rows, columns));
            System.out.println( "Data shape after bad channel removal: " + data.shapeString());
        }

        // Detrend the data
        if (detrend != null && detrend) {
            System.out.println( "Linearly detrending the data");
            data = data.detrend(1, "linear");
        }

        // Again, bad channel removal
        List<Integer> badChannels = null;
        if (badChannelThreshold != null) {
            System.out.println( "Second bad channel removal");
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
            data = new Matrix(data.getSubMatrix(rows, ArrayFunctions.toPrimitiveArray(windowTimeIdx)));
            System.out.println( "New data shape after time range selection: " + data.shapeString());
        }

        // Spatial filtering
        if (spatialFilter != null) {
            System.out.println( "Spatial filtering the data");
            for (int r = 0; r < data.getRowDimension(); r++)
                data.setRowVector(r, data.getRowVector(r).mapMultiply(spatialFilter[r]));
        }

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

        // Linearly classifying the data
        System.out.println( "Classifying with linear classifier");
        Matrix fraw = linearClassifier(data, 0);
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

    private Matrix linearClassifier(Matrix data, int dim) {
        double[] results = new double[classifierSlope.size()];
        for (int i = 0; i < classifierSlope.size(); i++)
            results[i] = this.classifierSlope.get(i).multiplyElements(data).sum().getEntry(0, 0) +
                    classifierIntercept.getEntry(i);
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
        if (outSize != null) return Math.max(sampleTrialLength, outSize[0]);
        else if (windowTimeIdx != null) return Math.max(sampleTrialLength, windowTimeIdx[1]);
        else if (windowFn != null) return Math.max(sampleTrialLength, windowFn.length);
        throw new RuntimeException("Either outSize, windowTimeIdx or windowFn should be defined");
    }

    public int getOutputSize() {
        return classifierSlope.size();
    }

    public String toString() {
        return "ERSPClassifier with parameters:" + "\nWindow Fn length:  \t" + windowFn.length + "\nwelchStartMs         " +
                "   " +
                "\t" + Arrays.toString(welchStartMs) + "\nSpatial filter     \t" + Arrays.toString(spatialFilter) +
                "\nclassifierSlope " +
                "shape            " +
                "\t" + (classifierSlope != null ? classifierSlope.get(0).shapeString() : "null") + "\nSpectrum mx " +
                "shape  \t" + (spectrumMx != null ? spectrumMx.shapeString() : "null") + "\nclassifierIntercept      " +
                "            \t" + classifierIntercept + "\nSpectrum desc      \t" + Arrays.toString
                (spectrumDescription) + "\nType               \t" + type + "\nWelch ave type     \t" + welchAveType +
                "\nDetrend            \t" + detrend + "\nBad channel thres  \t" +
                badChannelThreshold + "\nTime idx           \t" + Arrays.toString(windowTimeIdx) + "\nFrequency idx  " +
                "    " +
                "\t" + Arrays.toString(windowFrequencyIdx) + "\nIs bad channel    \t" + Arrays.toString
                (thresholdIsBad) + "\nDimension   " +
                "       \t" +
                dimension + "\nWindow length      \t" + windowLength + "\nSampling frequency \t" + samplingFrequency
                + "\nWindow type        \t" + windowType;
    }
}
