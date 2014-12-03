package nl.dcc.buffer_bci.imaginedMovement.views;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.geom.Line2D;
import javax.swing.JPanel;

/**
 * Baseline panel.
 * @author Bas Bootsma
 */
public class BaselinePanel extends JPanel
{    
    public static final Color FIXATION_POINT_COLOR = Color.red;
    public static final double FIXATION_POINT_SIZE_FACTOR = 0.1;
    public static final double FIXATION_POINT_WIDTH_FACTOR = 0.005;
    
    /**
     * Constructor.
     */
    public BaselinePanel()
    {
        super();
    }
    
    @Override
    public void paintComponent(Graphics g)
    {
        super.paintComponent(g);
        
        Graphics2D g2d = (Graphics2D)g;
        int size = (this.getWidth() > this.getHeight()) ? this.getHeight() : this.getWidth();
        
        // Draw fixation point.
        double fixationPointPreferredSize = BaselinePanel.FIXATION_POINT_SIZE_FACTOR * size;
        double fixationPointPreferredWidth = BaselinePanel.FIXATION_POINT_WIDTH_FACTOR * size;
        double fixationPointTopLeftX = (this.getWidth() - fixationPointPreferredSize) / 2;
        double fixationPointTopLeftY = (this.getHeight() - fixationPointPreferredSize) / 2;
        
        g2d.setColor(BaselinePanel.FIXATION_POINT_COLOR);
        g2d.setStroke(new BasicStroke((int)fixationPointPreferredWidth));
        
        // Horizontal line.
        g2d.draw(new Line2D.Double(fixationPointTopLeftX,
                                   fixationPointTopLeftY + 0.5 * fixationPointPreferredSize,
                                   fixationPointTopLeftX + fixationPointPreferredSize,
                                   fixationPointTopLeftY + 0.5 * fixationPointPreferredSize));
        
        // Vertical line.
        g2d.draw(new Line2D.Double(fixationPointTopLeftX + 0.5 * fixationPointPreferredSize,
                                   fixationPointTopLeftY,
                                   fixationPointTopLeftX + 0.5 * fixationPointPreferredSize,
                                   fixationPointTopLeftY + fixationPointPreferredSize));
    }
}
