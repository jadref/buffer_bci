package nl.ru.dcc.buffer_bci.screens;
import java.awt.Component;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Color;

public class InstructScreen extends StimulusScreen {
    private String instruction;
    public InstructScreen() { this(""); }
    public InstructScreen(String instruction) { setInstruction(instruction); }
    public void setInstruction(String instruction) { this.instruction = instruction; }

    @Override
    public void draw(Component c, Graphics g) {
        int width=c.getWidth();
        int height=c.getHeight();        
        float x = (width* .1f);
        float y = (height * .3f); 

        g.setColor(WINDOWBACKGROUNDCOLOR);
        g.fillRect(0,0,width,height);

        g.setColor(Color.WHITE);
		  Graphics2D gg = (Graphics2D) g;
		  for ( String line : instruction.split("\n") ) {
				gg.drawString(line,x,y);
				y+=gg.getFontMetrics().getHeight();
		  }

		  // Write the run-time to the screen
		  g.drawString("Run-time: " + getTimeSpent_ms() + " / " + getDuration_ms(),
							width/10, (height*9)/10);
        
    }

    @Override
    public void update(float delta) {}
}
