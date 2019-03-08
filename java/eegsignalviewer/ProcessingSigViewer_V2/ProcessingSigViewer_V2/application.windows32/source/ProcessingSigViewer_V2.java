import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.core.PApplet; 
import controlP5.*; 
import org.apache.commons.math3.transform.FastFourierTransformer; 
import java.util.Arrays; 
import java.util.ArrayList; 
import ddf.minim.*; 
import ddf.minim.analysis.*; 
import ddf.minim.spi.*; 
import ddf.minim.effects.*; 
import ddf.minim.ugens.*; 
import java.math.BigDecimal; 
import java.util.ArrayList; 
import ketai.ui.*; 
import processing.core.PApplet; 
import java.util.Arrays; 
import controlP5.*; 

import org.apache.commons.math3.ml.neuralnet.*; 
import org.apache.commons.math3.ml.neuralnet.twod.*; 
import org.apache.commons.math3.ml.neuralnet.twod.util.*; 
import org.apache.commons.math3.ml.neuralnet.oned.*; 
import org.apache.commons.math3.ml.neuralnet.sofm.*; 
import org.apache.commons.math3.ml.neuralnet.sofm.util.*; 
import org.apache.commons.math3.ml.clustering.*; 
import org.apache.commons.math3.ml.clustering.evaluation.*; 
import org.apache.commons.math3.ml.distance.*; 
import org.apache.commons.math3.analysis.*; 
import org.apache.commons.math3.analysis.differentiation.*; 
import org.apache.commons.math3.analysis.integration.*; 
import org.apache.commons.math3.analysis.integration.gauss.*; 
import org.apache.commons.math3.analysis.function.*; 
import org.apache.commons.math3.analysis.polynomials.*; 
import org.apache.commons.math3.analysis.solvers.*; 
import org.apache.commons.math3.analysis.interpolation.*; 
import org.apache.commons.math3.stat.interval.*; 
import org.apache.commons.math3.stat.ranking.*; 
import org.apache.commons.math3.stat.clustering.*; 
import org.apache.commons.math3.stat.*; 
import org.apache.commons.math3.stat.inference.*; 
import org.apache.commons.math3.stat.correlation.*; 
import org.apache.commons.math3.stat.descriptive.*; 
import org.apache.commons.math3.stat.descriptive.rank.*; 
import org.apache.commons.math3.stat.descriptive.summary.*; 
import org.apache.commons.math3.stat.descriptive.moment.*; 
import org.apache.commons.math3.stat.regression.*; 
import org.apache.commons.math3.linear.*; 
import org.apache.commons.math3.*; 
import org.apache.commons.math3.distribution.*; 
import org.apache.commons.math3.distribution.fitting.*; 
import org.apache.commons.math3.complex.*; 
import org.apache.commons.math3.ode.*; 
import org.apache.commons.math3.ode.nonstiff.*; 
import org.apache.commons.math3.ode.events.*; 
import org.apache.commons.math3.ode.sampling.*; 
import org.apache.commons.math3.random.*; 
import org.apache.commons.math3.primes.*; 
import org.apache.commons.math3.optim.*; 
import org.apache.commons.math3.optim.linear.*; 
import org.apache.commons.math3.optim.nonlinear.vector.*; 
import org.apache.commons.math3.optim.nonlinear.vector.jacobian.*; 
import org.apache.commons.math3.optim.nonlinear.scalar.*; 
import org.apache.commons.math3.optim.nonlinear.scalar.gradient.*; 
import org.apache.commons.math3.optim.nonlinear.scalar.noderiv.*; 
import org.apache.commons.math3.optim.univariate.*; 
import org.apache.commons.math3.exception.*; 
import org.apache.commons.math3.exception.util.*; 
import org.apache.commons.math3.fitting.leastsquares.*; 
import org.apache.commons.math3.fitting.*; 
import org.apache.commons.math3.dfp.*; 
import org.apache.commons.math3.fraction.*; 
import org.apache.commons.math3.special.*; 
import org.apache.commons.math3.geometry.*; 
import org.apache.commons.math3.geometry.hull.*; 
import org.apache.commons.math3.geometry.enclosing.*; 
import org.apache.commons.math3.geometry.spherical.twod.*; 
import org.apache.commons.math3.geometry.spherical.oned.*; 
import org.apache.commons.math3.geometry.euclidean.threed.*; 
import org.apache.commons.math3.geometry.euclidean.twod.*; 
import org.apache.commons.math3.geometry.euclidean.twod.hull.*; 
import org.apache.commons.math3.geometry.euclidean.oned.*; 
import org.apache.commons.math3.geometry.partitioning.*; 
import org.apache.commons.math3.geometry.partitioning.utilities.*; 
import org.apache.commons.math3.optimization.*; 
import org.apache.commons.math3.optimization.linear.*; 
import org.apache.commons.math3.optimization.direct.*; 
import org.apache.commons.math3.optimization.fitting.*; 
import org.apache.commons.math3.optimization.univariate.*; 
import org.apache.commons.math3.optimization.general.*; 
import org.apache.commons.math3.util.*; 
import org.apache.commons.math3.genetics.*; 
import org.apache.commons.math3.transform.*; 
import org.apache.commons.math3.filter.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class ProcessingSigViewer_V2 extends PApplet {

// @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeinde
// * 2018/2019
//This is the main. 
//please try not to add anything here, since this will be visible in all other coded.
//If you add another file to this project make sure it is a new separate class. If this is not done it will be considered part of the main by processing.
//Note: the methods in this file are public because however 

//import processing.android.PFragment;


private ProcessingSigViewer_Model model;
private ProcessingSigViewer_View view;
private ProcessingSigViewer_Controller controller;
private OtherSketch otherSketch;


public void settings() {
  fullScreen();
  //size(500,500); //when developing you might want to use this instead of fullScreen, such that it is easier to use.
}
// this is the firts thing that is called by processing automatically when you run the program. This is the base setup of your program. Do not run this seperately. 

public void setup() {
  this.model = new ProcessingSigViewer_Model();
  //for the android version:
  //model.popUp(this);
  model.setBufferClientClock(this);
  //model.makeSigViewer(this);

  this.view=new ProcessingSigViewer_View();
  view.makeSetup(new ControlP5(this));
  this.controller=new ProcessingSigViewer_Controller();
  controller.setModelView(model, view);
   
  otherSketch = new OtherSketch(this, model, view, controller);
}

// This function is executed in a loop by processing, starting right after the setup(). At the end of this function, the screen is updated.
public void draw() {
  view.drawView();
}

//For some reason it is necessary to call this here to get the button functionality to work.
//If anyone can figure out a way to move this to the controller entirely please do.
public void controlEvent(ControlEvent theEvent) {
  controller.controlEvent(theEvent);
}
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

    min=(float) max(min(dataMatrix), median-standardDeviation*2.5f);
    max=(float) min(max(dataMatrix), median+standardDeviation*2.5f);
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
      curVal = Math.max(curVal, maxVal);
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
    float result = Math.max(data, 1e-12f);  // limits the value to 0.000000000001
    result = (float) Math.log(result);    // gives the natural log of each element in the array
    result = result*20;                  // multiplies each element by 20
    return result;
  }
} 
/* Emumaration with the possibe Filters
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeinde
 * 2018/2019
 */
public enum Filter {CENTER, DETREND, NONE};

public enum SpatialFilter {CAR, SLAP, NONE};
/**
 * Used for drawing a LineGraph in the Frequency domain.
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeneinde
 * 2018/2019
 */
 
public class FrequencyGraph extends LineGraph {

  public FrequencyGraph(String name) {
    super(name);
  }
  
  public FrequencyGraph(String name, float x, float y, float graphWidth, float graphHeight, float[] xLabels, float[] yLabels) {
    super(name, x, y, graphWidth, graphHeight, xLabels, yLabels);
  }
  
  /**
  * Sets the x range of the frequency graph, depends on settings in the model.
  */
  public void setXRange(){
   float[] freqRange = {model.getLowFreq(),model.getHighFreq()};
   xRange=freqRange;
  }

}
/**
 * Abstract class used for making a graph of any kind.
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeneinde
 * 2018/2019
 */
 
public abstract class Graph {

  protected float[] data; //The data displayed in the graph
  protected float x, y, graphWidth, graphHeight; //Defines the upper left corner and the graph's width and height.
  protected String name; //Defines the graph's label.
  protected float[] xLabels, yLabels; //Defines where the value pointers on the x and y axis will be drawn.
  protected float[] yRange; //Range of the y axis;
  protected float[] xRange; //Range of the x axis, has to be defined in the subclass;

  public Graph(String name) {
    this.name=name;
  }
  
  public abstract void setXRange();
   
  public Graph(String name, float x, float y, float graphWidth, float graphHeight, float[] xLabels, float[] yLabels) {
    this.name=name;
    this.x=x;
    this.y=y;
    this.graphWidth=graphWidth;
    this.graphHeight=graphHeight;
    this.xLabels=xLabels;
    this.yLabels=yLabels;
  }
  
  public void updateGraph(float[] input) {
    this.data=input;
  }
  
  public void updateYRange(float[] yRange){
    this.yRange=yRange;
  }
  
  public String getName(){
    return name;
  }
  
  public void setName(String newName) {
    this.name = newName;
    writeName();
  }

 
  public void resizeGraph(float x, float y, float graphWidth, float graphHeight, float[] xLabels, float[] yLabels) {
    this.x=x;
    this.y=y;
    this.graphWidth=graphWidth;
    this.graphHeight=graphHeight;
    this.xLabels=xLabels;
    this.yLabels=yLabels;
  }

  public void resizeGraph(float x, float y, float graphWidth, float graphHeight) {
    this.x=x;
    this.y=y;
    this.graphWidth=graphWidth;
    this.graphHeight=graphHeight;
  }

  public abstract void drawGraph();

  /**
   * Writes the name of the graph in the upper right corner of the graph and then resets the font to a smaller size.
   */
  public void writeName() {
    textSize(26);
    text(name, (x+graphWidth)-150, y+30);
    textSize(12);
  }

  /**
   * Calculates the x coordinate of the element at position i of the arrayOfFloats.
   * @param i - index of the current datapoint in the array of data
   * @param arrayOfFloats - float array containing the data
   * @return the x coordinate of the queried element. 
   */
  protected float xCoordinate(int i, float[] arrayOfFloats) {
    return x + graphWidth * i / arrayOfFloats.length + graphWidth / arrayOfFloats.length / 2;
  }

  /**
   * Calculates the y coordinate of the element at position i of the arrayOfFloats.
   * @param i - index of the current datapoint in the array of data
   * @param arrayOfFloats - float array containing the data
   * @return the y coordinate of the queried element. 
   */
  protected float yCoordinate(int i, float[] arrayOfFloats) {
    //Gives the data point relative to the minimum and maximum of the range
    float relativeDataPoint = (arrayOfFloats[i]-yRange[0])/(yRange[1]-yRange[0]);

    //Makes sure the showed data point is within the range of the graph
    if (relativeDataPoint>1){
      relativeDataPoint=1;
    }
    else if (relativeDataPoint<0){
      relativeDataPoint=0;
    }

    //Gives the data point relative to the height of the graph
    float yOnScreen =y+graphHeight-relativeDataPoint*graphHeight;
    return yOnScreen;
  }

  /**
   * Draws the x and y axes with labels in a graph depending on the x and y range.
   * The x axis has 10 labels and the y axis has 6 (5 compartments, but 6 labels).
   */
   
  protected void drawAxes() {
    setXRange();
    int partitionsX=10, partitionsY=5;
    float minY=yRange[0], maxY=yRange[1];
    float minX=xRange[0], maxX=xRange[1];

    //Helps to position
    float stepSizeY = graphHeight/partitionsY;
    float stepSizeX =graphWidth/partitionsX;

    //Steps in the data
    float dataStepsX = (maxX-minX)/partitionsX;
    float dataStepsY = (maxY-minY)/partitionsY;

    //x bottom axis
    line(x, y+graphHeight, x+graphWidth, y+graphHeight);
    
    //x top axis
    line(x, y, x+graphWidth, y);
    for (int i=0; i<=partitionsX; i++) {
      float xPos=x+stepSizeX*i;
      line(xPos, y+graphHeight-5, xPos, y+graphHeight);
      text(minX+dataStepsX*i, xPos, y+graphHeight+0.03f*graphHeight);
      line(xPos, y+5, xPos, y);
    }  

    //y left axis
    line(x, y, x, y+graphHeight);
    
    //y right axis
    line(x+graphWidth, y, x+graphWidth, y+graphHeight);
    for (int i=0; i<=partitionsY; i++) {
      float yPos=y+stepSizeY*i;
      line(x+5, yPos, x, yPos);
      text(maxY-dataStepsY*i, x-0.05f*graphWidth, yPos);
      line(x-5+graphWidth, yPos, x+graphWidth, yPos);
    }
  }
}
/**
 * Window containing the graphs.
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeneinde
 * 2018/2019
 */

public class GraphWindow {    
  private Graph[] graphs;
  private float indent=20, graphWidth, graphHeight;
  private float windowX= 0.22f*width, windowY=height/15, windowWidth=0.76f*width, windowHeight=height-(height/22);
  private int  numColumns = 0, numRows = 0;
  private float[] xs, ys;

  private float[] yRange=null;
  private ViewType vt = ViewType.TIME;

  public GraphWindow() {
    model.updateData();
    float[][] data = model.getData();
    this.yRange=BasicStats.dataRange(data);
    generateGraphs(data);
  }

  private void generateGraphs(float[][] data) {
    graphs = new Graph[data.length];
    for (int i = 0; i<graphs.length; i++) {
      graphs[i] = new TimeGraph(Integer.toString(i));
    }
    positionGraphs();
  }

  public void setNames(String [] names) {
    for (int i = 0; i < graphs.length && i < names.length; i++) {
      if (names[i] != null) {
        graphs[i].setName(names[i]);
      }
    }
  }

  /**
   * Draws the actual graphs. Receives the graph data from the model.
   */
  public void drawGraphs() {
    stroke(0);
    //model.updateTestData();  // If you want to run testData
    model.updateData(); // If you want to run real data
    updateViewType(model.getViewType());  

    float[][] data = model.getData();
    if (yRange == null || outOfRange(BasicStats.matrixToArray(data)))
      this.yRange=BasicStats.dataRange(data);
      
    for (int i=0; i<graphs.length; i++) {
      graphs[i].updateGraph(data[i]);
      graphs[i].updateYRange(yRange);
      graphs[i].drawGraph();
    }

    switch(vt) { // we need to know whether the 50Hz view type is active such that if that is the case we need to add the Legend. 
    case HZ:
      drawLegend(color(0, 255, 0), color(255, 255, 0), color(255, 0, 0)); // add Legend to 50Hz view
      break;
    default:
      break;
    }
  }

  /**
   * Draws a legend to the right of the graphs.
   * Is a gradient rectangle from colors c1 to c2 to c3 from top to bottom
   */
  private void drawLegend(int c1, int c2, int c3) {
    float legendHeight = windowHeight-indent*4;
    float legendWidth = graphWidth / 15;
    float legendY = windowY + indent;
    float legendX = windowX + ((windowWidth/10 * 9) / (float) numColumns - indent)*numColumns + indent*2;
    stroke(0);
    rect(legendX-1, legendY-1, legendWidth+2, legendHeight+1); //outline

    //first half of gradient, from c1 to c2
    for (float i = legendY; i <= legendY+legendHeight/2; i++) {
      float inter = map(i, legendY, legendY+legendHeight/2, 0, 1);
      int c = lerpColor(c1, c2, inter);
      stroke(c);
      line(legendX, i, legendX+legendWidth, i);
    }

    //second half of gradient, from c2 to c3
    for (float i = legendY + legendHeight/2; i <= legendY+legendHeight; i++) {
      float inter = map(i, legendY + legendHeight/2, legendY+legendHeight, 0, 1);
      int c = lerpColor(c2, c3, inter);
      stroke(c);
      line(legendX, i, legendX+legendWidth, i);
    }
    stroke(0);
    textSize(17);
    text("badness", legendX, legendY - indent / 2);

    text("0", legendX + legendWidth + indent/2, legendY + indent/2);
    line(legendX + legendWidth - indent/5, legendY - 1, legendX + legendWidth + indent/5, legendY - 1);

    text("0.5", legendX + legendWidth + indent/2, legendY + legendHeight/2 + indent/5);
    line(legendX + legendWidth - indent/5, legendY + legendHeight/2, legendX + legendWidth + indent/5, legendY + legendHeight/2);

    text("1", legendX + legendWidth + indent/2, legendY + legendHeight + indent/5);
    line(legendX + legendWidth - indent/5, legendY + legendHeight, legendX + legendWidth + indent/5, legendY + legendHeight);
  }

  /**
   * Returns whether or not the data is currently out of the set range. 
   * If all data is in range, it is likely that the range is far too large
   * thus it would also need to be recalculated.
   * @param data - the current set of data
   * @return true if more than half of the current data set is out of the current y range 
   * or everything is in range, false if it isn't. 
   */
  private boolean outOfRange(float[] data) {
    int count=0;
    for (float x : data) {
      if (x<yRange[0] || x>yRange[1]){
        count++;
      }
      if (count>data.length/2){
        return true;
      }
    }
    if (count==0){
      return true;
    }
    return false;
  }

  /**
   * Switches between the different graph view types, depending on which button is clicked.
   * @param newVT - the view that the (old) view needs to be switched to.
   */
  private void updateViewType(ViewType newVT) {
    if (!newVT.equals(vt)) {
      vt=newVT;
      for (int i=0; i<graphs.length; i++) {
        switch(vt) {
        case TIME:
            graphs[i]=new TimeGraph(graphs[i].getName());
          break;
        case FREQUENCY:
            graphs[i]=new FrequencyGraph(graphs[i].getName());
          break;
        case HZ:
            graphs[i]=new HzGraph(graphs[i].getName());
          break;
        default:  
          break;
        }
      }
      this.yRange=BasicStats.dataRange(model.getData());
    }
    positionGraphs();
  }

  /**
   * Computes appropriate widths and x and y coordinates based on the size of the window and the number of graphs.
   */
  private void positionGraphs() {
    // update float [] xs and float [] ys according the the amount of graphs in a particular view. 
    xs = new float[graphs.length];
    ys = new float[graphs.length];

    // switch based on the viewtype (time, frequency, 50Hz, power etc.) Might need to be updated when new viewtypes are updated.
    switch(vt) {
    case HZ: // if in 50Hz
      graphWidth = (windowWidth/10 * 9) / (float) numColumns - indent;
      break;
    default: 
      graphWidth = graphWidth();
      break;
    }
    graphHeight = graphHeight();

    for (int i = 0; i < numRows; i++) {
      for (int j = 0; j < numColumns; j++) {
        if (i+j*numRows<graphs.length) {
          xs[i+j*numRows]=windowX+i*graphWidth+i*indent;
          ys[i+j*numRows]=windowY+j*graphHeight+j*indent;
        }
      }
    }
    
    for (int i =0; i<graphs.length; i++) { // resiz all individual graphs in the view type
      graphs[i].resizeGraph(xs[i], ys[i], graphWidth, graphHeight);
    }  
    graphWidth = graphWidth();
  }

  /**
   * Computes the appropriate width of a graph and number of graphs in a row.
   */
  private float graphWidth() {
      numColumns = (int) ceil(sqrt(graphs.length));
    return windowWidth / (float) numColumns - indent;
  }

  /**
   * Computes the appropriate height of a graph and number of graphs in a column.
   */
  private float graphHeight() {
    numRows = (int) ceil( graphs.length/ (sqrt(graphs.length)));
    return windowHeight / (float) numRows - indent;
  }
} 
/**
 * Used to show a graph that is one color, which color it is depending on the data. Note this class is almost functional it only needs to be updated to become dependend on the data. 
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeneinde
 * 2018/2019
 */
 
public class HzGraph extends Graph {

  public HzGraph(String name) {
    super(name);
  }

  public HzGraph(String name, float x, float y, float graphWidth, float graphHeight, float[] xLabels, float[] yLabels) {
    super(name, x, y, graphWidth, graphHeight, xLabels, yLabels);
  }
  
  public void setXRange(){
     float[] timeRange = {-5,0};
     xRange=timeRange;
  }
  
  /**
   * Draws the axes without axis labels, as they are not needed in this type of graph.
   *
   */
  @Override
  protected void drawAxes(){      
    line(x, y+graphHeight, x+graphWidth, y+graphHeight);   //x bottom axis 
    line(x, y, x+graphWidth, y); //x top axis  
    line(x, y, x, y+graphHeight);  //y left axis    
    line(x+graphWidth, y, x+graphWidth, y+graphHeight); //y right axis
  }
  
  /**
   * Draws the coloured box, color depending on the badness in the signal.
   *
   */
  public void drawGraph() {
    stroke(0, 0, 0);
    // we need the activity around 45, 47, 53 and 55 Hz.this total activity should be used to modify HzBadness (between 0 and 1.0) 
    
    float HzBadness = 0.5f; // how strong is our unwanted signal? 1 being as bad as can be, 0 being perfectly fine. still need to hook this to actual data
    colorMode(RGB, 1.0f); // sets the color range from 0 to 1.0, instead of the usual 0 to 255
    int c1 = color(2.0f * HzBadness, 2.0f * (1 - HzBadness), 0); //goes from red to green, passing yellow midway. traffic light
    fill(c1);
    rect(x, y, graphWidth, graphHeight); //makes a rectangle. currently does all 4, not hooked to anything useful as of yet
    colorMode(RGB, 255); //sets color range back
    fill(0);
  
    drawAxes();
    writeName();
  }
  
}

/*
steps: 
0: detrend (is this already functional? if so use it)
1: average power over (input given) signal (the noise)  <- should return one value per channel/node. avg activity in the relevant bands for 2 secs eacch
2: color based on how bad. how much? unsure atm. based on avg decibel (ppdat = 20*log(max(ppdat,1e-12));)

keep the noisebands in mind though!
 'noisebands',{{[23 24 26 27] [45 47 53 55] [97 98 102 103]}},'noiseBins',[],'noisefracBins',[.5 10],...%[0 1.75],...
its not just using the 45/47/53/55 bands
*/
/**
 * Used for drawing a graph with a line connecting datapoints.
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeneinde
 * 2018/2019
 */ 
 
public abstract class LineGraph extends Graph {

  public LineGraph(String name) {
    super(name);    
  }

  public LineGraph(String name, float x, float y, float graphWidth, float graphHeight, float[] xLabels, float[] yLabels) {
    super(name, x, y, graphWidth, graphHeight, xLabels, yLabels);
  }

  /**
   * Draws the lineGraph, the axes and name with functions from the superclass Graph: axes with Graph.drawAxes() and the name with Graph.writeName();
   */
  public void drawGraph() {
    stroke(0, 0, 255);
    for (int i=0; i<data.length-1; i++) {
      line(xCoordinate(i, data), yCoordinate(i, data), xCoordinate(i+1, data), yCoordinate(i+1, data));
    }
    stroke(0);
    drawAxes();
    writeName();
  }
  
  
}
/**
 * The window which pops up at the start to ask for an IP-address.
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeneinde
 * 2018/2019
 */



class OtherSketch extends PApplet {

private Textfield text;
private String Ip;
ControlP5 cp;
private ProcessingSigViewer_V2 parent;
private ProcessingSigViewer_Model model;
private ProcessingSigViewer_View view;
private ProcessingSigViewer_Controller controller;

public OtherSketch(ProcessingSigViewer_V2 parent, ProcessingSigViewer_Model model, ProcessingSigViewer_View view, ProcessingSigViewer_Controller controller)
  {
    //store a reference to the first sketch so we can do things with it
    this.parent = parent;
    this.view = view;
    this.model = model;
    this.controller = controller;
 
    ////This will actually launch the new sketch
    runSketch(new String[] {
      "OtherSketch"  //must match the name of this class
      }
      , this);  //the second argument makes sure this sketch is created instead of a brand new one...
    
  }
  public void settings() {
    size((int)(0.2f*parent.width),(int)(0.2f*parent.height));
  }
  
  public void setup(){
    cp = new ControlP5(this);
    text = cp.addTextfield("IP-adress").setPosition((int)(0.3f*width), (int)(0.42f*height)).setSize((int)(0.4f*width), 20).setValue("127.0.0.1"); 
  }
  //setStringValue
 
  public void draw() {
    background(125, 125, 125);
  }

  public void exit()
  {
    parent.otherSketch = null;
    dispose();
  }
    public void controlEvent(ControlEvent theEvent) {  
     controller.controlEvent(theEvent);
  }



public void input(String theText) {
  // automatically receives results from controller input
  println("a textfield event for controller 'input' : "+theText);
}

  public String getIP(){
    return Ip;
  }
}
/**
 * Handles things related to processing the data.
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeneinde
 * 2018/2019
 */




//import processing.sound.*;






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
    FFT fft = new FFT( fftSize, sampleFreq );
    //fft.linAverages(32);

    System.arraycopy( fdata, 0, fftSamples, 0, fdata.length );
    if ( fdata.length < fftSize ) {
      java.util.Arrays.fill( fftSamples, fdata.length, fftSamples.length - 1, 0.0f );
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

    // this should be as large as you want your FFT to be. generally speaking, 1024 is probably fine.
    int fftSize = 1024;
    float[] fftSamples = new float[fftSize];
    FFT fft = new FFT( fftSize, sampleFreq );

    ArrayList<Float>  spectrum = new ArrayList(); //Array to put the results in
    System.arraycopy( fdata, 0, fftSamples, 0, fdata.length);

    // in case the data is not a power of 2      
    if ( fdata.length < fftSize ) {
      java.util.Arrays.fill( fftSamples, fdata.length, fftSamples.length - 1, 0.0f );
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

  /**
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

    // this should be as large as you want your FFT to be. generally speaking, 1024 is probably fine.
    int fftSize = 1024;
    float[] fftSamples = new float[fftSize];
    FFT fft = new FFT( fftSize, sampleFreq );

    ArrayList<Float>  spectrum = new ArrayList(); //Array to put the results in
    System.arraycopy( fdata, 0, fftSamples, 0, fdata.length);

    // in case the data is not a power of 2      
    if ( fdata.length < fftSize ) {
      java.util.Arrays.fill( fftSamples, fdata.length, fftSamples.length - 1, 0.0f );
    }

    // now analyze this buffer      
    fft.forward( fftSamples );
    float avg1 = fft.calcAvg(lowFreq1, highFreq1);
    float avg2 = fft.calcAvg(lowFreq2, highFreq2);
    float avg3 = fft.calcAvg(lowFreq3, highFreq3);

    float[] result = {avg1, avg2, avg3};
    return result;
  }
}

/**
 * Controller for the Signal Viewer. Handles all external events.
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeneinde
 * 2018/2019
 */
public class ProcessingSigViewer_Controller {

  private ProcessingSigViewer_Model model;
  private ProcessingSigViewer_View view;

  public void ProcessingSigViewer_Controller() {
  }

  public void setModelView(ProcessingSigViewer_Model model, ProcessingSigViewer_View view) {
    this.model=model;
    this.view=view;
  }


  /**
   * Big control function for all possible events (e.g. buttons, textfields)
   * @param theEvent - the event that is happening (e.g. a button is clicked) 
   */
  public void controlEvent(ControlEvent theEvent) { // Here you state what happens when a certain button is activated
    //Standard Preprocessing
    if (theEvent.isGroup() && theEvent.getName().equals("Standard Preprocessing")) {
      println(theEvent.getArrayValue());
      switch((int)theEvent.getValue()) {
        case(1): // None
        model.setFilter(Filter.NONE);
        break;
        case(2): // Center
        model.setFilter(Filter.CENTER);
        break;
        case(3): // Detrend
        model.setFilter(Filter.DETREND);
        break;
      }
    }
    if (theEvent.isGroup() && theEvent.getName().equals("Spatial Filters")) {
      println(theEvent.getArrayValue());
      switch((int)theEvent.getValue()) {
        case(5): // None
        model.setFilter(SpatialFilter.NONE);
        break;
        case(6): // CAR
        model.setFilter(SpatialFilter.CAR);
        break;
        case(7): // SLAP
        model.setFilter(SpatialFilter.SLAP);
        break;
      }
    }
    //Gets the IP-address from the text field
    if (theEvent.isAssignableFrom(Textfield.class)&& theEvent.getName().equals("IP-adress")) {
      println("controlEvent: accessing a string from controller '"
        +theEvent.getName()+"': "
        +theEvent.getStringValue()
        );
      println(model.getIp());
      model.setIp(theEvent.getStringValue());
      model.makeBuffer();
      view.initializeGraphWindow();
      view.setNames(model.getHeader().labels);
      view.setSigView(true);      
      println(model.getIp());
    }
    //Reads the Low Cut-Off
    if (theEvent.isAssignableFrom(Textfield.class)&& theEvent.getName().equals("Low Cut-Off")) {
      println("controlEvent: accessing a string from controller '"
        +theEvent.getName()+"': "
        +theEvent.getStringValue()
        );
      String input = theEvent.getStringValue().replaceAll("[^\\d]", "");
      if (input.length() > 0) {
        int freq = Integer.parseInt(input);
        model.setLowFreq(freq);
      }
    }
    //Reads the High Cut-Off
    if (theEvent.isAssignableFrom(Textfield.class)&& theEvent.getName().equals("High Cut-Off")) {
      println("controlEvent: accessing a string from controller '"
        +theEvent.getName()+"': "
        +theEvent.getStringValue()
        );
      String input = theEvent.getStringValue().replaceAll("[^\\d]", "");
      if (input.length() > 0) {
        int freq = Integer.parseInt(input);
        model.setHighFreq(freq);
      }
    }
    //For switching between view types
    if (theEvent.getName().equals("default")) {
      model.setViewType(ViewType.TIME);
    }
    if (theEvent.getName().equals("Frequency")) {
      model.setViewType(ViewType.FREQUENCY);
    }
    if (theEvent.getName().equals("50 Hz")) {
      model.setViewType(ViewType.HZ);
    }
    if (theEvent.getName().equals("Noisefrac")) {
      model.setViewType(ViewType.NOISEFRAC);
    }
    if (theEvent.getName().equals("Spect")) {
      model.setViewType(ViewType.SPECT);
    }
    if (theEvent.getName().equals("Power")) {
      model.setViewType(ViewType.POWER);
    }
    if (theEvent.getName().equals("Offset")) {
      model.setViewType(ViewType.OFFSET);
    }
  }
}
/**
 * Model of the Signal Viewer.
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeneinde
 * 2018/2019
 */






public class ProcessingSigViewer_Model {
  private PApplet parent;
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

  public void popUp(PApplet p) {
    KetaiAlertDialog.popup(p, "Pop up test", "pop up!" );
  }

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
        //       newData[i] = Preprocessor.detrend(newData[i]);
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

}
/**
 * View for the Signal Viewer. Handles everything that needs to be shown to the user.
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeneinde
 * 2018/2019
 */



public class ProcessingSigViewer_View {  
  ControlP5 controlP5;
  ProcessingSigViewer_Model model;
  private int col = color(128);
  private RadioButton r1, r2;
  private CheckBox c1, c2;
  private Textfield t1, t2, t3;
  private boolean sigView = false;
  private GraphWindow gw;

  public ProcessingSigViewer_View() {
  }

  public void initializeGraphWindow() {
    gw = new GraphWindow();
  }

  public void makeSetup(ControlP5 cp5) {
    controlP5 = cp5;

    addOptionButtons();
    addTabs();

    //gw.setGraphs(new TimeGraph("0"),new TimeGraph("1"),new TimeGraph("2"),new TimeGraph("3"));
  }

  public void setSigView(boolean t) {
    sigView = t;
  }

  public void setNames(String[] names) {
    gw.setNames(names);
  }

  public void drawView() {
    background(col); //background with variable col, if col gets changed, the background colour changes
    drawBoxes();
    writeText();
    if (sigView) {
      gw.drawGraphs();
    }
  }


  /**
   * Adds the tabs for switching between views.
   */
  private void addTabs() {
    ControlFont theFont = new ControlFont(createFont("Times", (int)(0.0083f*width)), (int)(0.0083f*width));

    controlP5.setFont(theFont);

    int w = width/7;
    int h = height/20;
    int tabColor = color(204, 255, 255);
    int txtColor = color(0);

    println(0.05f*height);
    println(width);
    println(0.03f*width);
    println(height);

    controlP5.getTab("default").setWidth(w).setHeight(h)
      .setLabel("Time")
      .setId(1)
      .setColorBackground(tabColor)
      .setColorLabel(txtColor)
      .activateEvent(true);
    ;

    controlP5.addTab("Frequency").setWidth(w)
      .setColorBackground(tabColor)
      .setColorLabel(txtColor)
      .setId(2)
      .setHeight(h)
      .activateEvent(true);
    ;


    controlP5.addTab("50 Hz").setWidth(w).setHeight(h)
      .setColorBackground(tabColor)
      .setColorLabel(txtColor)
      .setId(3)
      .activateEvent(true);
    ;

    controlP5.addTab("Noisefrac").setWidth(w).setHeight(h)
      .setColorBackground(tabColor)
      .setColorLabel(txtColor)
      .setId(4)
      .activateEvent(true);
    ;

    controlP5.addTab("Spect").setWidth(w).setHeight(h)
      .setColorBackground(tabColor)
      .setColorLabel(txtColor)
      .setId(5)
      .activateEvent(true);
    ;

    controlP5.addTab("Power").setWidth(w).setHeight(h)
      .setColorBackground(tabColor)
      .setColorLabel(txtColor)
      .setId(6)
      ;

    controlP5.addTab("Offset").setWidth(w).setHeight(h)
      .setColorBackground(tabColor)
      .setColorLabel(txtColor)
      .setId(7)
      .activateEvent(true);
    ;
  }

  public void changeColour(int n) {
    col=color(n);
  }

  /**
   * Adds the buttons for pre- and postprocessing at the left of the screen.
   */
  private void addOptionButtons() {
    //preprocessing radiobutton group
    r1 = controlP5.addRadioButton("Standard Preprocessing", (int)(0.03f*width), (int)(0.1f*height)).setSize((int)(0.03f*width), (int)(0.05f*height));
    r1.addItem("None", 1);
    r1.addItem("Center", 2);
    r1.addItem("Detrend", 3);
    r1.moveTo("global");

    //Bad Chan Rm
    c1 = controlP5.addCheckBox("check1", (int)(0.03f*width), (int)(0.3f*height)).setSize((int)(0.03f*width), (int)(0.05f*height));
    c1.addItem("Bad Chan Rm", 4);
    c1.moveTo("global");
    t1 = controlP5.addTextfield("").setPosition((int)(0.03f*width), (int)(0.37f*height)).setSize((int)(0.15f*width), (int)(0.03f*width));
    t1.moveTo("global");

    // Spatial filter radiobutton group
    r2 = controlP5.addRadioButton("Spatial Filters", (int)(0.03f*width), (int)(0.48f*height)).setSize((int)(0.03f*width), (int)(0.05f*height));
    r2.addItem(" None", 5); // if this one is on, the r1 button with the same name dissapears, how to fix this?
    r2.addItem(" CAR", 6); //I don't think two items can have the same name
    r2.addItem(" SLAP", 7);
    r2.moveTo("global");
    r2.setSpacingRow(30);

    //Adapt Filter
    c2 = controlP5.addCheckBox("check2").setPosition((int)(0.13f*width), (int)(0.48f*height)).setSize((int)(0.03f*width), (int)(0.05f*height));
    c2.addItem("whiten", 9);
    c2.addItem("rm ArtCh", 10);
    c2.addItem("rm EMG", 11);
    c2.moveTo("global");
    c2.setSpacingRow(30);

    //Spectral Filter
    t2 = controlP5.addTextfield("Low Cut-Off").setPosition((int)(0.03f*width), (int)(0.82f*height)).setSize((int)(0.15f*width), (int)(0.03f*height));
    t2.moveTo("global"); 
    t3 = controlP5.addTextfield("High Cut-Off").setPosition((int)(0.03f*width), (int)(0.91f*height)).setSize((int)(0.15f*width), (int)(0.03f*height));
    t3.moveTo("global");
  }

  /**
   * Writes text for the options at the left of the screen. 
   */
  private void writeText() {
    textSize(17);
    fill(color(0)); // letter colour
    text("Pre-processing", (0.027f*width), (0.085f*height)); // naming of the groups
    text("Spatial filter", (0.027f*width), (0.47f*height));
    text("Adapt filter", (0.127f*width), (0.47f*height));
    text("Spectral filter", (0.027f*width), (0.8f*height));
    textSize(12);
  }

  private void drawBoxes() {
    fill(color(110)); //fills the figures made after this line
    // rect belonging to pre-processing
    rect((0.025f*width), (0.07f*height), (0.17f*width), (0.2f*height));//blocks around the groups
    // rect belonging to Spatial Filter
    rect((0.025f*width), (0.45f*height), (0.075f*width), (0.3f*height));
    //  rect belonging to adapt filter
    rect((0.125f*width), (0.45f*height), (0.079f*width), (0.3f*height));
    //  rect belonging to Bad chan RM
    rect((0.025f*width), (0.29f*height), (0.17f*width), (0.14f*height));
    //  rect belonging to spectral filter
    rect((0.025f*width), (0.77f*height), (0.17f*width), (0.2f*height));
    // rect beloning to graphs
    fill(color(255));
    rect(((0.20f*width)+20), (height/22)+10, (int)(0.77f*width), (int)(0.99f*height));
  }
}
 /**
  * Used for drawing a LineGraph in the Time domain.
  * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeneinde
  * 2018/2019
  */

public class TimeGraph extends LineGraph {
  public TimeGraph(String name) {
    super(name);
  }

  public TimeGraph(String name, float x, float y, float graphWidth, float graphHeight, float[] xLabels, float[] yLabels) {
    super(name, x, y, graphWidth, graphHeight, xLabels, yLabels);
  }
  
 /**
  * Sets the x range of the frequency graph, depends on settings in the model.
  */
  public void setXRange(){
     float[] timeRange = {-4,0};
     xRange=timeRange;
  }
  
}
  public enum ViewType {
    TIME, FREQUENCY, HZ, NOISEFRAC, SPECT, POWER, OFFSET
  };
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "ProcessingSigViewer_V2" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
