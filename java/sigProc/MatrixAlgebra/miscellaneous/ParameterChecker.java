package nl.dcc.buffer_bci.matrixalgebra.miscellaneous;

import java.util.Arrays;

/**
 * Created by Pieter on 23-2-2015.
 * Default parameter checks
 */
public class ParameterChecker {
    public static void checkString(String given, String[] options) {
        if (!(Arrays.asList(options).contains(given))) {
            StringBuilder sb = new StringBuilder();
            sb.append("Type should be in [");
            for (String option : options)
                sb.append(option).append(", ");
            sb.append("] but is ").append(given);
            throw new IllegalArgumentException(sb.toString());
        }
    }

    public static void checkRepeats(int repeats) {
        if (repeats < 1)
            throw new IllegalArgumentException("Times should be bigger than 0 but it is " + repeats);
    }

    public static void checkNonNegative(int i) {
        if (i < 0)
            throw new IllegalArgumentException("This integer number should not be negative but is " + i);
    }

    public static void checkNonNegative(double d) {
        if (d < 0.)
            throw new IllegalArgumentException("This double number should not be negative but is " + d);
    }

    public static void checkNonZero(double d) {
        if (d == 0.0)
            throw  new IllegalArgumentException("Number should not be zero but is " + d);
    }

    public static void checkAxis(int axis) throws IllegalArgumentException {
        checkAxis(axis, false);
    }

    public static void checkAxis(int axis, boolean allowMinOne) throws IllegalArgumentException {
        if (axis < -1 || axis > 1)
            if (!(allowMinOne && axis == -1))
                throw new IllegalArgumentException("Axis should be 0 or 1 but is " + axis);
    }

    public static void checkLowerUpperThreshold(double lowerThreshold, double upperThreshold) throws
            IllegalArgumentException {
        if (lowerThreshold > upperThreshold)
            throw new IllegalArgumentException("Lower threshold (=" + lowerThreshold + ") should be lower than upper " +
                    "threshold (=" + upperThreshold + ")");
    }

    public static void checkEquals(int a, int b) throws  IllegalArgumentException{
        if (a != b)
            throw new IllegalArgumentException("Should be equal but are not: " + a + " and " + b);
    }

    public static void checkPower(int a, int base) throws IllegalArgumentException{
        Double exp = Math.log(a) / Math.log(base);
        //noinspection EqualsBetweenInconvertibleTypes
        if (exp.equals(Math.round(exp)))
            throw new IllegalArgumentException("Should be a power of " + base + " but " + a + " is not");
    }
}
