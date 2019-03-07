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
