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
    
    float HzBadness = 0.5; // how strong is our unwanted signal? 1 being as bad as can be, 0 being perfectly fine. still need to hook this to actual data
    colorMode(RGB, 1.0); // sets the color range from 0 to 1.0, instead of the usual 0 to 255
    color c1 = color(2.0f * HzBadness, 2.0f * (1 - HzBadness), 0); //goes from red to green, passing yellow midway. traffic light
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
