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
