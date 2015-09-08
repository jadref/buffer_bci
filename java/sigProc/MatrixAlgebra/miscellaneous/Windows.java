package nl.dcc.buffer_bci.matrixalgebra.miscellaneous;

import org.apache.commons.math3.analysis.function.Gaussian;

/**
 * Created by Pieter on 11-2-2015.
 * Several window functions
 */
public class Windows {

    public enum WindowType {
        GAUSSIAN, HANNING
    }

    public static double[] getWindow(int size, WindowType type, boolean unitAmplitude) {
        ParameterChecker.checkNonNegative(size);

        double[] window;

        switch (type){
            case GAUSSIAN:
                window = gaussianWindow(size);
                break;
            case HANNING:
                window = hanningWindow(size);
                break;
            default:
                throw new IllegalArgumentException("Window type is not yet supported");
        }

        if (unitAmplitude)
            window = unitAmplitude(window);
        return window;
    }

    public static Tuple<int[], Integer> computeWindowLocation(int length, int windows, double overlap) {
        ParameterChecker.checkNonNegative(length);
        ParameterChecker.checkNonNegative(windows);
        ParameterChecker.checkNonNegative(overlap);

        int[] windowStart = new int[windows];
        int width = (int) Math.floor(length / ((windows - 1 ) * (1 - overlap) + 1));
        for (int i = 0; i < windows; i++) {
            windowStart[i] = (int) Math.round(i * (width * (1. - overlap)));
        }
        return new Tuple<int[], Integer>(windowStart, width);
    }

    private static double[] gaussianWindow(int size) {
        double sigma = ((double) size - 1) / 2;
        double[] gaussian = new double[size];
        Gaussian distribution = new Gaussian(((double) size - 1.) / 2.0, sigma);
        for (int i = 0; i < size; i++) {
            gaussian[i] = distribution.value(i);
        }
        return gaussian;
    }

    private static double[] hanningWindow(int size) {
        double[] hanning = new double[size];
        for (int i = 0; i < size; i++) {
            hanning[i] = .5 * (1. - Math.cos((i+1) * 2 * Math.PI / (size + 1)));
        }
        return hanning;
    }

    private static double[] unitAmplitude(double[] window) {
        double max = ArrayFunctions.max(window);
        for (int i = 0; i < window.length; i++)
            window[i] /= max;
        return window;
    }
}
