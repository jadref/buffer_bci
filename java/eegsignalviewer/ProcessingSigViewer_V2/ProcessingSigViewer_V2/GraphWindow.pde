/**
 * Window containing the graphs.
 * @author Quintess Barnhoorn, Loes Erven, Kayla Gericke, Mignon Hagemeijer, Nick van der Linden, Peter van Olmen, Sander van t Westeneinde
 * 2018/2019
 */

public class GraphWindow {    
  private Graph[] graphs;
  private float indent=20, graphWidth, graphHeight;
  private float windowX= 0.22*width, windowY=height/15, windowWidth=0.76*width, windowHeight=height-(height/22);
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
  private void drawLegend(color c1, color c2, color c3) {
    float legendHeight = windowHeight-indent*4;
    float legendWidth = graphWidth / 15;
    float legendY = windowY + indent;
    float legendX = windowX + ((windowWidth/10 * 9) / (float) numColumns - indent)*numColumns + indent*2;
    stroke(0);
    rect(legendX-1, legendY-1, legendWidth+2, legendHeight+1); //outline

    //first half of gradient, from c1 to c2
    for (float i = legendY; i <= legendY+legendHeight/2; i++) {
      float inter = map(i, legendY, legendY+legendHeight/2, 0, 1);
      color c = lerpColor(c1, c2, inter);
      stroke(c);
      line(legendX, i, legendX+legendWidth, i);
    }

    //second half of gradient, from c2 to c3
    for (float i = legendY + legendHeight/2; i <= legendY+legendHeight; i++) {
      float inter = map(i, legendY + legendHeight/2, legendY+legendHeight, 0, 1);
      color c = lerpColor(c2, c3, inter);
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
