/**
 * Model of the Signal Viewer.
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeneinde
 * 2018/2019
 */
import java.math.BigDecimal;
import java.util.ArrayList;
import ketai.ui.*;
import processing.core.PApplet;
import java.util.Arrays;

public class ProcessingSigViewer_Model {

  PApplet parent;
  private BufferAdapter buffer;
  private int dataSize = 1250; 
  private int binSize = 25;
  private float [][] data = new float[50][dataSize];
  private BufferClientClock bcc;
  private int lowFreq = 0; // lowest frequency to be displayed
  private int highFreq = 50; // highest frequency to be displayed, 124 for no cut
  private Header header;
  private ViewType vt = ViewType.TIME;
  private Filter currentFilter = Filter.NONE;
  private SpatialFilter spatialFilter = SpatialFilter.NONE;
  private int runNum = 1;


  public void ProcessingSigViewer_Model() {
  }

  //public void popUp(PApplet p) {
  //  KetaiAlertDialog.popup(p, "Pop up test", "pop up!" );
  //}

  public BufferClientClock getBufferClientClock() {
    return bcc;
  }

  public Header getHeader() {
    return header;
  }

  public void setBufferClientClock(PApplet parent) {
    bcc = new BufferClientClock(parent);
    this.parent = parent;
  }

  public void makeBuffer() {
    try {
      this.buffer = new BufferAdapter(bcc);
    }
    catch(InterruptedException e) {
      System.out.println(e);
    }
    catch(IOException e) {
      System.out.println(e);
    }
    this.header = buffer.getHeader();
    data = new float[header.nChans][dataSize];
  }

  public String getIp() {
    return bcc.getIp();
  }

  public void setIp(String ip) {
    bcc.setIp(ip);
  }

  public void setBuffer(BufferAdapter buf) {
    this.buffer=buf;
  }

  public float[][] getData() {
    return data;
  }

  public ViewType getViewType() {
    return vt;
  }

  public void setViewType(ViewType vt) {
    this.vt=vt;
  }

  public void setLowFreq(int lowFreq) {
    if (lowFreq < highFreq) {
      this.lowFreq = lowFreq;
    }
  }

  public void setHighFreq(int highFreq) {
    if (highFreq > lowFreq) {
      this.highFreq = highFreq;
    }
  }

  public int getHighFreq() {
    return highFreq;
  }

  public int getLowFreq() {
    return lowFreq;
  }

  /**
   * Changes the current filter; detrend, car, or none.
   */
  public void setFilter(Filter newFilter) {
    currentFilter = newFilter;
  }

  public void setFilter(SpatialFilter newFilter) {
    spatialFilter = newFilter;
  }

  /**
   * Updates the data and processes it according to the current viewtype.
   */
  public void updateData() {
    double [][] newData = buffer.update_data();

    if (currentFilter.equals(Filter.CENTER)) {
      newData = Preprocessor.center(newData);
    } else if (currentFilter.equals(Filter.DETREND)) {
      for (int i = 0; i < newData.length; i++) {
        //       newData[i] = Preprocessor.detrend(newData[i]); // uncomment this when the detrend works.
      }
    }

    if (spatialFilter.equals(SpatialFilter.CAR)) {
      newData = Preprocessor.car(newData);
    }

    switch(vt) {
    case FREQUENCY:
      //Frequencies computed with Processing's FFT class.
      for (int i = 0; i < newData.length; i++) {
        data[i] = Preprocessor.procfft(parent, newData[i], lowFreq, highFreq, header.fSample);
      }
      break;
    case HZ:
      //Frequencies computed with Processing's FFT class for multiple bands. note:no detrending prior as of yet
      // currently gives wrong values (vs matlab). seems related to the avetype option in the welch function for matlab
      for (int i = 0; i < newData.length; i++) {
        data[i] = Preprocessor.procfftNoise(parent, newData[i], 23, 27, 45, 55, 97, 103, header.fSample);
      }

      break;
    default:
      {
        //Spectral filter
        for (int i = 0; i < newData.length; i++) {
          data[i] = Preprocessor.procSpectralFilter(parent, newData[i], lowFreq, highFreq, header.fSample);
        }

      }
    }
  }



  /**
   * Only for providing random data for testing and visual display.
   */
  public void updateTestData() {
    // copy everything one value down
    for (int row = 0; row < data.length; row++) {
      for (int i=0; i<dataSize-1; i++) {
        data[row][i] = data[row][i+1];
      }
    }

    /*
     //Test 1: a static line
     for (int i=0; i<dataSize-1; i++) {
     data1[i] = i;
     data2[i] = (i*2);
     data3[i] = (i*4);
     data4[i] = (i*8);
     }
     //Is displayed how it should be, scales nicely.
     */

    /*
    //Test 2: a moving line
     // new incoming value
     float newVal1=random(1, 1);
     float newVal2=random(2, 2);
     float newVal3=random(-1, -1);
     float newVal4=random(0.5, 0.5);
     //float newValue = noise(frameCount*0.01)*graphWidth;
     //The line first shows as a vertical line. 
     //The reason why becomes apparent after the 3 second mark (which takes longer than 3 seconds to reach! 
     //This is slower than with the actual data for some reason), when it suddenly zooms out to reveal what is happening.
     //I noticed that something similar happens with the actual data. Weird thing is that it doesn't always happen when data is out of range (i.e. the data doesn't always fix itself). 
     
     */
    /*
    //Test 3: random graphs with different data ranges
     float newVal1=random(1, 100);
     float newVal2=random(2, 20);
     float newVal3=random(-1, -10);
     float newVal4=random(0.1, 0.5);
     //At the start only one of the random graphs is visible because the rest is out of range.
     //If I switch to the frequency domain however, 
     //the y ranges are very different and every graph is visible except for the third one 
     //(which shouldn't cause problems because none of the actual data will be negative, but still).
     //If I switch back to the time domain, the y ranges stay the same as in the frequency domain.
     */


    //Test 4: many graphs
    float [] vals = new float[data.length];
    for (int i = 0; i<vals.length; i++) {
      vals[i]=random(-10, 10);
    }



    // set last value to the new value
    for (int i = 0; i<vals.length; i++) {
      data[i][data[i].length-1]=vals[i];
    }

    //data[0][data[0].length-1] = newVal1;
    //data[1][data[1].length-1] = newVal2;
    //data[2][data[2].length-1] = newVal3;
    //data[3][data[3].length-1] = newVal4;
  }

  //close class
}
