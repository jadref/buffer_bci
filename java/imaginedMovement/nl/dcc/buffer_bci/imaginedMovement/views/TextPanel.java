package nl.dcc.buffer_bci.imaginedMovement.views;

import java.awt.Color;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.geom.Rectangle2D;
import nl.dcc.buffer_bci.imaginedMovement.State;
import nl.dcc.buffer_bci.imaginedMovement.StateListener;
import org.apache.commons.configuration.Configuration;

/**
 * Text panel.
 * @author Bas Bootsma.
 */
public class TextPanel extends BasePanel
{
    /**
     * Constructor.
     * @param configuration
     * @param state 
     */
    public TextPanel(Configuration configuration, State state)
    {
        super(configuration, state);
        
        this.getState().addListener(new StateListener()
        {
            public void onTextChanged(String text)
            {
                repaint();
            }

            public void onDirectionChanged(double direction)
            {
            }

            public void onPowerChanged(double power)
            {
            }

            public void onRotationChanged(State.Rotation rotation)
            {
            }
        });
    }
    
    @Override
    public void paintComponent(Graphics g)
    {
        super.paintComponent(g);
        
        Graphics2D g2d = (Graphics2D)g;
        
        // Draw text.
        Font font = new Font(this.getConfiguration().getString("text.font"), Font.PLAIN, this.getConfiguration().getInt("text.size"));
        FontMetrics fontMetrics = this.getFontMetrics(font);
        
        // Split the text into multiple lines.
        String lines[] = this.getState().getText().split("[\r\n]+");
        
        // Compute total height.
        double heightTotal = 0;
        
        for(String line : lines)
        {
            Rectangle2D lineBounds = fontMetrics.getStringBounds(line, g);
            heightTotal += lineBounds.getHeight();
        }

        g2d.setFont(font);
        g2d.setColor(Color.decode(this.getConfiguration().getString("text.color")));
        
        // Draw all lines.
        double heightOffset = 0;
        
        for(String line : lines)
        {
            Rectangle2D lineBounds = fontMetrics.getStringBounds(line, g);
            heightOffset += lineBounds.getHeight();
            
            g2d.drawString(line,
                          (int)((this.getWidth() - lineBounds.getWidth()) / 2),
                          (int)((this.getHeight() - heightTotal) / 2 + heightOffset));
        }
    }
}
