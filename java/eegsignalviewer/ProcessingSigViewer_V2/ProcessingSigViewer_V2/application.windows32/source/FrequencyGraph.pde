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
