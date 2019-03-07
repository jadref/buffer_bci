/**
 * Used to show a graph that is one color, which color it is depending on the data.
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
        //x bottom axis
    line(x, y+graphHeight, x+graphWidth, y+graphHeight);
        //x top axis
    line(x, y, x+graphWidth, y);
        //y left axis
    line(x, y, x, y+graphHeight);
        //y right axis
    line(x+graphWidth, y, x+graphWidth, y+graphHeight);
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
1: average power over (input given) signal (the noise)  <- should return one value per channel/node. 
3: color based on how bad. how much? unsure atm. based on avg decibel (ppdat = 20*log(max(ppdat,1e-12));)

notes:
need to do it over past 2 secs, currently not time limited?
started at 19:00. brain froze at 01:00.
precalc matlab bit above shows averaging. it is simply adding all bands then dividing by number. 4 in matlab example (45 47 53 55) but does not have to be so.
'noisebands',{{[23 24 26 27] [45 47 53 55] [97 98 102 103]}},'noiseBins',[],'noisefracBins',[.5 10],...%[0 1.75],...
*/
