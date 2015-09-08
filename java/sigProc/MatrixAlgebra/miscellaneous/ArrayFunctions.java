package nl.dcc.buffer_bci.matrixalgebra.miscellaneous;

import java.util.Arrays;
import java.util.Comparator;

/**
 * Created by Pieter on 28-1-2015.
 * Several functions for double and integer arrays
 */
public class ArrayFunctions {

    public static void reverseDoubleArrayInPlace(double[] arr) {
        for (int i = 0; i < arr.length / 2; i++) {
            double temp = arr[i];
            arr[i] = arr[arr.length - i - 1];
            arr[arr.length - i - 1] = temp;
        }
    }

    public static double max(double[] arr) {
        double max = Double.NEGATIVE_INFINITY;
        for (double val : arr)
            if (val > max)
                max = val;
        return max;
    }

    public static Integer[] getSortIdx(final double[] arr) {
        Integer[] idx = new Integer[arr.length];
        for (int i = 0; i < idx.length; i++)
            idx[i] = i;
        Comparator<Integer> comp = new Comparator<Integer>() {
            @Override
            public int compare(Integer o1, Integer o2) {
                return arr[o1] > arr[o2] ? -1 : (arr[o1] == arr[o2] ? 0 : 1);
            }
        };
        Arrays.sort(idx, comp);
        return idx;
    }

    public static double[] fromString(String[] array) {
        double[] doubleArray = new double[array.length];
        for (int i = 0; i < array.length; i++) {
            doubleArray[i] = Double.valueOf(array[i]);
		  }
        return doubleArray;
    }

    public static double[][] reshape(double[][] A, int m, int n) {
        int origM = A.length;
        int origN = A[0].length;
        if(origM*origN != m*n){
            throw new IllegalArgumentException("New matrix must be of same area as matrix A");
        }
        double[][] B = new double[m][n];
        double[] A1D = new double[A.length * A[0].length];

        int index = 0;
        for (double[] aA : A) {
            for (int j = 0; j < A[0].length; j++) {
                A1D[index++] = aA[j];
            }
        }

        index = 0;
        for(int i = 0;i<n;i++){
            for(int j = 0;j<m;j++){
                B[j][i] = A1D[index++];
            }

        }
        return B;
    }

    public static int[] toPrimitiveArray(Integer[] arr) {
        int[] newArr = new int[arr.length];
        for (int i = 0; i < arr.length; i++)
            if (arr[i] != null)
                newArr[i] = arr[i];
        return newArr;
    }

    public static double[] toPrimitiveArray(Double[] arr) {
        double[] newArr = new double[arr.length];
        for (int i = 0; i < arr.length; i++)
            if (arr[i] != null)
                newArr[i] = arr[i];
        return newArr;
    }

    public static Integer[] toObjectArray(int[] arr) {
        Integer[] newArr = new Integer[arr.length];
        for (int i = 0; i < arr.length; i++)
            newArr[i] = arr[i];
        return newArr;
    }

    public static Double[] toObjectArray(double[] arr) {
        Double[] newArr = new Double[arr.length];
        for (int i = 0; i < arr.length; i++)
            newArr[i] = arr[i];
        return newArr;
    }
}
