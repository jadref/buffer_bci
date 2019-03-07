/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import processing.core.*;
import org.apache.commons.math3.*;
import java.util.Arrays;
import java.util.LinkedList;

public class BufferAdapter {
  
  public static int VERB = 0; // debugging verbosity level
  public long printInterval_ms = 5000; // time between debug prints
  protected String hostname = "localhost";
  protected int port = 1972;

  SamplesEventsCount status = null;
  protected boolean run = true;
  protected int timeout_ms = 1000;
  protected BufferClientClock C = null;
  protected int trialLength_ms = 4000; //from opts; how much time is recorded at a time
  protected int trialLengthSamp = 1024; // from opts; how many datapoints are recorded at a time
  protected double fs = -1.0; //Sampling frequency; usually 250
  protected Header header = null;
  protected int nSamples;

  double[][] D;
  int index = 0;
  int n_channels;
  protected int updateSamp;

  public BufferAdapter(BufferClientClock bcc) throws InterruptedException, IOException {
    C = bcc;

    connect();
    fs = header.fSample;
    n_channels = header.nChans;
    updateSamp = (int) header.fSample/4; //4 is formerly from opts

    int bins = trialLengthSamp;//(int) (5 * header.fSample);
    //trialLength_samp = (int) (0.01 * header.fSample);
    D = new double[header.nChans][bins];
    // nEvents = header.nEvents;
    nSamples = header.nSamples;
  }

  public Header getHeader() {
    return header;
  }

  /**
   * Connects to the buffer
   */
  private void connect() {
    while (header == null && run) {
      try {
        System.out.println("Connecting to " + hostname + ":" + port);
        if (!C.isConnected()) {
          C.connect(hostname, port);
        }
        //C.setAutoReconnect(true);
        if (C.isConnected()) {
          header = C.getHeader();
        }
      } 
      catch (IOException e) {
        header = null;
      }
      if (header == null) {
        System.out.println("Invalid Header... waiting");
        try {
          Thread.sleep(1000);
        } 
        catch (InterruptedException e) {
          e.printStackTrace();
        }
      }
    }
  }

  public double [][] update_data() {
    double[][] dv;
    try {
      if (VERB > 1) {
        System.out.println(" Waiting for " + (nSamples + updateSamp + 1) + " samples");
      }
      status = C.waitForSamples(nSamples + updateSamp +1, this.timeout_ms);
    }
    catch (IOException e) {
      e.printStackTrace();
      // connection to buffer failed = quit
      run = false;
      return null;
    }
    if (status.nSamples < nSamples) {
      System.out.println(" Buffer restart detected");
      nSamples = status.nSamples;
      dv = null;
      return null;
    }
    if (status.nSamples > nSamples + fs) {
      //Can't keep up with the data; jump ahead
      nSamples = status.nSamples - updateSamp - 1;
    }

    // Get the data
    int fromId = nSamples;
    int toId = nSamples + updateSamp;
    double[][] data = null;
    try {
      data = C.getDoubleData(fromId, toId);
      data = transposeMatrix(data);
    }
    catch (IOException e) {
      e.printStackTrace();
    }
    double[][] temp = new double[D.length][D[0].length];

    for (int row = 0; row < D.length; row++) {
      System.arraycopy(D[row], updateSamp, temp[row], 0, temp[row].length-updateSamp);
      System.arraycopy(data[row], 0, temp[row], temp[row].length - updateSamp, updateSamp);
    }

    D = temp;

    if (VERB > 1) {
      System.out.println(String.format(" Got data @ %d->%d samples", fromId, toId));
    }
    nSamples = nSamples + updateSamp;
    return D;
  }

  private static double[][] transposeMatrix(double[][] matrix) {
    int m = matrix.length;
    int n = matrix[0].length;

    double[][] transposedMatrix = new double[n][m];

    for (int x = 0; x < n; x++) {
      for (int y = 0; y < m; y++) {
        transposedMatrix[x][y] = matrix[y][x];
      }
    }
    return transposedMatrix;
  }
}
