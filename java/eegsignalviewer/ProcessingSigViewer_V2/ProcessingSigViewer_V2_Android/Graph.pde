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
    //println(yRange[0]+" "+yRange[1]);
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
  void writeName() {
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
    if (relativeDataPoint>1)
      relativeDataPoint=1;
    else if (relativeDataPoint<0)
      relativeDataPoint=0;

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
      text(minX+dataStepsX*i, xPos, y+graphHeight+0.03*graphHeight);
      line(xPos, y+5, xPos, y);
    }  

    //y left axis
    line(x, y, x, y+graphHeight);
    //y right axis
    line(x+graphWidth, y, x+graphWidth, y+graphHeight);
    for (int i=0; i<=partitionsY; i++) {
      float yPos=y+stepSizeY*i;
      line(x+5, yPos, x, yPos);
      text(maxY-dataStepsY*i, x-0.05*graphWidth, yPos);
      line(x-5+graphWidth, yPos, x+graphWidth, yPos);
    }
  }
}
