/**
 * Handles things related to processing the data.
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeneinde
 * 2018/2019
 */

import org.apache.commons.math3.transform.FastFourierTransformer;
import java.util.Arrays;
import java.util.ArrayList;
//import processing.sound.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.spi.*;
import ddf.minim.effects.*;
import ddf.minim.ugens.*;

//import javax.sound.sampled.AudioFormat;

public static class Preprocessor {

  public Preprocessor() {
  }


  /**
   * Filters out the frequencies that are below lowFreq or above highFreq, and returns the data in the time domain.
   * Uses the Minim library.
   * @param parent - papplet
   * @param data - the data you want to show
   * @param lowFreq - the lower cutoff frequency 
   * @param highFreq - the upper cutoff frequency
   * @param sampleFreq - used as sample rate
   * @return result - the data between lowFreq and highFreq
   */
  public static float[] procSpectralFilter(PApplet parent, double [] data, int lowFreq, int highFreq, float sampleFreq) {
    Minim minim = new Minim(parent);
    float[] fdata = BasicStats.toFloatArray(data);

    int fftSize = 1024;
    float[] fftSamples = new float[fftSize];
    //ddf.minim.analysis.FFT fft = new ddf.minim.analysis.FFT( fftSize, sample.sampleRate() );
    ddf.minim.analysis.FFT fft = new ddf.minim.analysis.FFT( fftSize, sampleFreq );
    //fft.linAverages(32);

    System.arraycopy( fdata, 0, fftSamples, 0, fdata.length );
    if ( fdata.length < fftSize ) {
      java.util.Arrays.fill( fftSamples, fdata.length, fftSamples.length - 1, 0.0 );
    }

    // now analyze this buffer
    fft.forward( fftSamples );
    float[] result = new float[fftSamples.length];
    for (int i = 0; i < fftSize/2; ++i)
    {
      if (fft.indexToFreq(i) > highFreq || fft.indexToFreq(i) < lowFreq) {
        fft.setBand(i, 0);
      }
    }
    fft.inverse(result);
    return result;
  }

  /**
   * Transforms the data into the frequency domain using the Minim library, and returns only those frequencies between
   * the given lowest and highest frequency.
   * @param parent - papplet
   * @param data - the data you want to show
   * @param lowFreq - the lower cutoff frequency 
   * @param highFreq - the upper cutoff frequency
   * @param sampleFreq - used as sample rate
   * @return result - the data between lowFreq and highFreq in the frequency domain
   */
  public static float[] procfft(PApplet parent, double [] data, int lowFreq, int highFreq, float sampleFreq) {
    Minim minim = new Minim(parent);
    float[] fdata = BasicStats.toFloatArray(data);

    int fftSize = 1024;
    float[] fftSamples = new float[fftSize];
    ddf.minim.analysis.FFT fft = new ddf.minim.analysis.FFT( fftSize, sampleFreq );

    ArrayList<Float>  spectrum = new ArrayList(); //Array to put the results in
    System.arraycopy( fdata, 0, fftSamples, 0, fdata.length);

    // in case the data is not a power of 2      
    if ( fdata.length < fftSize ) {
      java.util.Arrays.fill( fftSamples, fdata.length, fftSamples.length - 1, 0.0 );
    }

    // now analyze this buffer
    fft.forward( fftSamples );
    for (int i = 0; i < fftSize/2; ++i)
    {
      if (fft.indexToFreq(i) <= highFreq && fft.indexToFreq(i) >= lowFreq) {
        spectrum.add(fft.getBand(i));
      }
    }

    float[] result = new float[spectrum.size()];
    for (int i = 0; i < spectrum.size(); i++) {
      result[i] = (float) spectrum.get(i);
    }
    return result;
  }

  /*
   * This is still work in progress. Doesn't work yet.
   * Detrends the given data
   * @param data - the data you want to detrend
   * @return result - the detrended data
   */
  //public static double [] detrend(double [] data) {

  //double[] detrended = new double[data.length];
  //double[] trendLine = new double[data.length];

  //SimpleRegression regression = new SimpleRegression();

  //for (int i = 0; i < data.length; i++) {
  //  regression.addData(i, data[i]);
  //}

  //double slope = regression.getSlope();
  //double intercept = regression.getIntercept();

  //for(int i = 0; i < data.length; i++){

  //    for(int i = 0; i < trendLine.le    //   trendLine[i] = slope * i + intercept;
  //}


  //for(int i = 0; i < trendLine.length; i++){
  //  double trendValue = trendLine[i];
  //  detrended[i] = data[i] -trendValue;
  //}
  // return trendLine;



  //double[] result = new double[data.length];
  //for (int i = 0; i < data.length; i++) {
  //  result[i] = data[i] - intercept - (i * slope);
  //}
  //return result;

  //  }

  /**
   * Centers the data around 0 for each row.
   * @param data - the data you want to center
   * @return result - the centered data
   */
  public static double [][] center(double [][] data) {
    double[][] result = new double[data.length][data[0].length];
    for (int row = 0; row < data.length; row++) {
      double mean = BasicStats.mean(data[row]);
      for (int i = 0; i < data[row].length; i ++) {
        result[row][i] = data[row][i] - mean;
      }
    }
    return result;
  }

  /**
   * Common average reference; subtract the mean of all data combined
   * datapoints from all individual datapoints.
   *
   * @param data
   * @return processed data
   */
  public static double[][] car(double[][] data) {
    double[][] result = new double[data.length][data[0].length];
    for (int i = 0; i < data[0].length; i++) {
      double total = 0;
      for (int chan = 0; chan < data.length; chan++) {
        total += data[chan][i];
      }
      double mean = total/data.length;
      for (int chan = 0; chan < data.length; chan++) {
        result[chan][i] = data[chan][i] - mean;
      }
    }
    return result;
  }

  /**
   * Returns the average amplitude between the three frequency pairs
   * @param parent - 
   * @param data - the data you want to show
   * @param lowFreq1 - the first lower cutoff frequency 
   * @param highFreq1 - the first upper cutoff frequency
   * @param lowFreq2 - the second lower cutoff frequency 
   * @param highFreq2 - the second upper cutoff frequency
   * @param lowFreq3 - the third lower cutoff frequency 
   * @param highFreq3 - the third upper cutoff frequency
   * @param sampleFreq - 
   * @return result - the average amplitudes for the given pairs
   */
  public static float[] procfftNoise(PApplet parent, double [] data, int lowFreq1, int highFreq1, int lowFreq2, int highFreq2, int lowFreq3, int highFreq3, float sampleFreq) {
    Minim minim = new Minim(parent);
    float[] fdata = BasicStats.toFloatArray(data);
    //AudioFormat format = new AudioFormat( sampleFreq, // sample rate
    //  16, // sample size in bits
    //  1, // channels
    //  true, // signed
    //  true   // bigEndian
    //  );
    //AudioSample sample = minim.createSample(fdata, format);

    // this should be as large as you want your FFT to be. generally speaking, 1024 is probably fine.
    int fftSize = 1024;
    float[] fftSamples = new float[fftSize];
    ddf.minim.analysis.FFT fft = new ddf.minim.analysis.FFT( fftSize, sampleFreq );

    ArrayList<Float>  spectrum = new ArrayList(); //Array to put the results in
    System.arraycopy( fdata, 0, fftSamples, 0, fdata.length);

    // in case the data is not a power of 2      
    if ( fdata.length < fftSize ) {
      java.util.Arrays.fill( fftSamples, fdata.length, fftSamples.length - 1, 0.0 );
    }

    // now analyze this buffer      
    fft.forward( fftSamples );
    float avg1 = fft.calcAvg(lowFreq1, highFreq1);
    float avg2 = fft.calcAvg(lowFreq2, highFreq2);
    float avg3 = fft.calcAvg(lowFreq3, highFreq3);
    // print("avg1=" + avg1 + "\n");

 //   sample.close();
    float[] result = {avg1, avg2, avg3};
    return result;
  }
}
