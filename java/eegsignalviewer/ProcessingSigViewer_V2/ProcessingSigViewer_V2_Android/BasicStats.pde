/**
 * This class handles basic statistical calculation on array and other related operations. 
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeinde
 * 2018/2019
 */

public static class BasicStats {

  public BasicStats() {
  }

  /**
  * Calculates the standard deviation of a float array.
  * @param array - the float array of which the sd needs to be found
  * @return the sd of the array as a float.
  */
  public static float sd(float[] array) {
    int len = array.length;
    float standardDeviation=0;
    float mean = mean(array);
    for (float num : array) {
      standardDeviation += Math.pow(num - mean, 2);
    }
    return (float) Math.sqrt(standardDeviation/len);
  }
  
  /**
  * Calculates the mean of a float array.
  * @param array - the float array of which the mean needs to be found
  * @return the mean of the array as a float.
  */
  public static float mean(float[] array) {
    int len = array.length;
    float sum = 0;

    for (float num : array) {
      sum += num;
    }        
    return (float) sum/len;
  }
  
  /**
  * Calculates the mean of a double array.
  * @param array - the double array of which the mean needs to be found
  * @return the mean of the array as a double.
  */
  public static double mean(double[] array) {
    int len = array.length;
    double sum = 0;

    for (double num : array) {
      sum += num;
    }        
    return (double) sum/len;
  }


  /**
   * Calculates the closest power of two that is equal or greater than the given number.
   * @param number - number to find the closest power of two of
   * @return - the closest power of two that is equal or greater than the given number
   */
  public static int powerOfTwo(int number) {
    int result = 1;
    while (result < number) {
      result = (result << 1);
    }
    return result;
  }
  
  /**
  * Calculates the median of a float array.
  * @param array - the float array of which the median needs to be found
  * @return the median of the array as a float.
  */
  public static float median(float[] array) {
    float[] a = copyArray(array);

    Arrays.sort(a);
    int middle = a.length/2;
    float medianValue = 0; 
    if (a.length%2 == 1) {
      medianValue = a[middle];
    } else {
      medianValue = (a[middle-1] + a[middle]) / 2;
    }

    return medianValue;
  }

  /**
  * Makes a deep copy of a float array
  * @param a - the float array to copy
  * @return the copy of the array
  */
  private static float[] copyArray(float[] a) {
    float[] a2= new float[a.length];
    for (int i=0; i< a2.length; i++) {
      a2[i]=a[i];
    }
    return  a2;
  }

  /**
  * Returns a float array with the data range, dependent on the minumum and the maximum datapoints.
  * @param datas - The float array containing the data
  * @return a float array with two values: the minimum and the maximum data range
  */
  public static float[] dataRange(float[][]datas) {
    float[] dataMatrix = matrixToArray(datas);
    float min, max, standardDeviation=sd(dataMatrix), median=median(dataMatrix);

    min=(float) max(min(dataMatrix), median-standardDeviation*2.5);
    max=(float) min(max(dataMatrix), median+standardDeviation*2.5);
    float[] result= {rounding(min), rounding(max)};
    return result;
  }

  /**
  * Turns a float matrix into a float array.
  * @param matrix - a 2D float array representing a matrix.
  * @return a float array of a flattened version of the matrix.
  */
  public static float[] matrixToArray(float [][] matrix) {
    ArrayList<Float> array = new ArrayList();
    for (int i=0; i < matrix.length; i ++) {
      for (float f : matrix[i]) {
        array.add(f);
      }
    }
    float[] result = new float[array.size()];
    for (int i =0; i < array.size(); i++) {
      result[i] = array.get(i);
    }
    return result;
  }
  
  /**
  * Rounds a float up.
  * @param n - the number that needs to be rounded.
  * @return the rounded float.
  */
  private static float rounding(float n) {
    float order = orderOfMagnitude(n);

    return order*((float) ceil(n/order));
  }

  /**
  * Gets the order of magnitude of a float.
  * @param n - the number of which the order of magnitude is wished to be known.
  * @return a power of ten which is the magnitude of the float.
  */
  public static float orderOfMagnitude(float n) {
    float order = (float) (log(n)/log(10f));
    return (float) pow(10f, floor(order));
  }

  /**
  * Turns a double array into a float array.
  * @param darray - the double array
  * @return farray - the float array
  */
  public static float[] toFloatArray(double[] darray) {
    float [] farray = new float[darray.length];
    for (int i = 0; i < farray.length; i ++) {
      farray[i] = (float) darray[i];
    }
    return farray;
  }

  /**
  * Limits the value of each element in a float array to maxVal
  * @param array - the float array
  * @param maxVal - the maximum value allowed in the array
  * @return an array with all elements being at most maxVal.
  */
  public static float[] maxLimitedArray(float[] array, float maxVal) {
    for (float curVal : array) {
      curVal = Math.max(curVal,maxVal);
    }
    return array;
  }

  /**
  * Calculates the natural log for each value in a float array
  * @param array - the float array
  * @return an array with the natural log all original elements.
  */
  public static float[] natLogArray(float[] array) {
    for (float curVal : array) {
      curVal = (float) Math.log( (double) curVal);
    }
    return array;
  }

    /**
  * Multiplies each element in a float array by multVal
  * @param array - the float array
  * @param multVal - the value to be multiplied by
  * @return an array with all elements multiplied by multVal.
  */
  public static float[] multArray(float[] array, float multVal) {
    for (float curVal : array) {
      curVal = curVal*multVal;
    }
    return array;
  }

   public static float toDecibel(float data) {
     float result = Math.max(data,1e-12); // limits the value to 0.000000000001
     result = (float) Math.log(result);           // gives the natural log of each element in the array
     result = result*20;                  // multiplies each element by 20
    return result;
  } 
  
} 
