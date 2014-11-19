package nl.dcc.buffer_bci.imaginedMovement.views;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.geom.AffineTransform;
import java.awt.geom.Arc2D;
import java.awt.geom.Ellipse2D;
import java.awt.geom.Rectangle2D;
import java.awt.image.AffineTransformOp;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.text.DecimalFormat;
import javax.imageio.ImageIO;
import nl.dcc.buffer_bci.imaginedMovement.State;
import nl.dcc.buffer_bci.imaginedMovement.StateListener;
import org.apache.commons.configuration.Configuration;

/**
 * Meter panel.
 * @author Bas Bootsma
 */
public abstract class MeterPanel extends BasePanel
{
    public static final double EPSILON = 0.01;
    
    private BufferedImage imageArrow;
    private BufferedImage imageArrowRotatedCounterClockwise;
    private BufferedImage imageArrowRotatedClockwise;
    
    /**
     * Constructor.
     * @param state 
     */
    public MeterPanel(Configuration configuration, State state)
    {
        super(configuration, state);
        
        this.getState().addListener(new StateListener()
        {
            public void onTextChanged(String text) 
            {
            }

            public void onDirectionChanged(double direction)
            {
                repaint();
            }

            public void onPowerChanged(double power)
            {
                repaint();
            }

            public void onRotationChanged(State.Rotation rotation)
            {
                repaint();
            }
        });
        
        try
        {
				//System.out.println("Image file: " + this.getConfiguration().getString("arrow.image"));
            this.imageArrow = ImageIO.read(this.getClass().getResourceAsStream(this.getConfiguration().getString("arrow.image")));
            this.imageArrowRotatedCounterClockwise = ImageIO.read(this.getClass().getResourceAsStream(this.getConfiguration().getString("arrow-rotated.counter-clockwise.image")));
            this.imageArrowRotatedClockwise = ImageIO.read(this.getClass().getResourceAsStream(this.getConfiguration().getString("arrow-rotated.clockwise.image")));
        }
        catch(IOException e)
        {
            System.out.println("Unable to load resources.");
        }
    }
    
    /**
     * Returns the image arrow.
     * @return 
     */
    public BufferedImage getImageArrow()
    {
        return this.imageArrow;
    }
    
    /**
     * Returns the image arrow rotated counter clockwise.
     * @return 
     */
    public BufferedImage getImageArrowRotatedCounterClockwise()
    {
        return this.imageArrowRotatedCounterClockwise;
    }
    
    /**
     * Returns the image arrow rotated clockwise.
     * @param
     */
    public BufferedImage getImageArrowRotatedClockwise()
    {
        return this.imageArrowRotatedClockwise;
    }
    
    @Override
    public void paintComponent(Graphics g)
    {
        super.paintComponent(g);
        
        this.paintFrame(g);
        this.paintArrow(g);
        
        if(this.getState().getRotation() != State.Rotation.NONE)
        {
            this.paintArrowRotated(g);
        }
    }
    
    /**
     * Paint arrow.
     * @param g
     */
    protected abstract void paintArrow(Graphics g);
    
    /**
     * Paints an arrow in a given direction (from 0 to 2*pi).
     * @param g
     * @param direction 
     */
    protected void paintArrow(Graphics g, double direction)
    {        
        Graphics2D g2d = (Graphics2D)g;
        int size = (this.getWidth() > this.getHeight()) ? this.getHeight() : this.getWidth();
        
        // Arrow.
        BufferedImage image = this.getImageArrow();
        int imageWidth = image.getWidth();
        int imageHeight = image.getHeight();
        double imagePreferredSize = this.getConfiguration().getDouble("arrow.size") * size;
        double imageScaleFactor = (imageWidth > imageHeight) ? imagePreferredSize / imageWidth : imagePreferredSize / imageHeight;
           
        double rotationSin = Math.abs(Math.sin(direction));
        double rotationCos = Math.abs(Math.cos(direction));
        int imageNewWidth = (int)Math.floor(imageWidth * rotationCos + imageHeight * rotationSin);
        int imageNewHeight = (int)Math.floor(imageHeight * rotationCos + imageWidth * rotationSin);
        
        AffineTransform transform = new AffineTransform();
        transform.scale(imageScaleFactor, imageScaleFactor);
        transform.translate((imageNewWidth - imageWidth) / 2, (imageNewHeight - imageHeight) / 2);
        transform.rotate(direction, imageWidth / 2, imageHeight / 2);
        
        AffineTransformOp operation = new AffineTransformOp(transform, AffineTransformOp.TYPE_BILINEAR);
        image = operation.filter(image, null);

        g2d.drawImage(image,
                     (int)((this.getWidth() - image.getWidth()) / 2),
                     (int)((this.getHeight() - image.getHeight()) / 2),
                     null);
    }
    
    /**
     * Paint frame including markers.
     * @param g 
     */
    protected final void paintFrame(Graphics g)
    {
        Graphics2D g2d = (Graphics2D)g;
        int size = (this.getWidth() > this.getHeight()) ? this.getHeight() : this.getWidth();
        
        // Rotation circle.
        double frameSize = this.getConfiguration().getDouble("frame.size") * size;
        double frameRadius = 0.5 * frameSize;
        double frameWidth = this.getConfiguration().getDouble("frame.width") * size;
        
        g2d.setColor(Color.decode(this.getConfiguration().getString("frame.color")));
        g2d.setStroke(new BasicStroke((int)frameWidth));
        g2d.draw(new Arc2D.Double((this.getWidth() - frameSize) / 2,
                                  (this.getHeight() - frameSize) / 2,
                                  frameSize,
                                  frameSize,
                                  this.getConfiguration().getInt("frame.angle.start"),
                                  this.getConfiguration().getInt("frame.angle.end"),
                                  Arc2D.CHORD));

        // Draw markers.
        double markerSize = this.getConfiguration().getDouble("marker.size", 0.0) * size;
        double markerOffset = this.getConfiguration().getDouble("marker.offset", 0.0);
        double frameAngleTotal = Math.toRadians(Math.abs(this.getConfiguration().getInt("frame.angle.start", 0) - this.getConfiguration().getInt("frame.angle.end", 0)));
        
        int markerCount = (Math.abs(frameAngleTotal - 2 * Math.PI) <= MeterPanel.EPSILON) ? this.getConfiguration().getInt("marker.count", 2) : this.getConfiguration().getInt("marker.count", 1) - 1;

        double markerAngleStep = frameAngleTotal / markerCount;

        // Draw markers.
        for(int marker = 0; marker < this.getConfiguration().getInt("marker.count", 0); marker++)
        {
            // Marker.
            double markerAngle = marker * markerAngleStep;
            g2d.fill(new Ellipse2D.Double((this.getWidth() - markerSize) / 2 + frameRadius * Math.cos(markerAngle),
                                          (this.getHeight() - markerSize) / 2 + frameRadius * Math.sin(-markerAngle),
                                          markerSize,
                                          markerSize));
            
            // Marker values.
            if(this.getConfiguration().containsKey("marker.value.start") && 
               this.getConfiguration().containsKey("marker.value.end"))
            {
                DecimalFormat decimalFormat = new DecimalFormat("#.##");
                
                int markerValueStart = this.getConfiguration().getInt("marker.value.start");
                int markerValueEnd = this.getConfiguration().getInt("marker.value.end");
                double markerValueStep = (double)Math.abs(markerValueStart - markerValueEnd) / markerCount;               
                double markerValue = (markerValueStart > markerValueEnd)? markerValueStart - marker * markerValueStep : marker * markerValueStep;

                Font font = new Font(this.getConfiguration().getString("text.font"), Font.PLAIN, this.getConfiguration().getInt("text.size"));
                FontMetrics fontMetrics = this.getFontMetrics(font);

                Rectangle2D markerValueBounds = fontMetrics.getStringBounds(decimalFormat.format(markerValue), g);

                g2d.setFont(font);
                g2d.setColor(Color.decode(this.getConfiguration().getString("text.color")));
                g2d.drawString(decimalFormat.format(markerValue),
                              (int)((this.getWidth() - markerValueBounds.getWidth()) / 2 + frameRadius * Math.cos(markerAngle) * (1 + markerOffset)),
                              (int)((this.getHeight() - markerValueBounds.getHeight()) / 2 + fontMetrics.getAscent() + frameRadius * Math.sin(-markerAngle) * (1 + markerOffset)));
            }
        }
    }

    /**
     * Draw arrow curved.
     * @param g 
     */
    protected final void paintArrowRotated(Graphics g)
    {
        Graphics2D g2d = (Graphics2D)g;
        int size = (this.getWidth() > this.getHeight()) ? this.getHeight() : this.getWidth();
        
        // Arrow rotated.
        BufferedImage image = (this.getState().getRotation() == State.Rotation.COUNTER_CLOCKWISE) ? this.getImageArrowRotatedCounterClockwise() : this.getImageArrowRotatedClockwise();
        int imageWidth = image.getWidth();
        int imageHeight = image.getHeight();
        double imagePreferredSize = this.getConfiguration().getDouble("arrow-rotated.size") * size;
        double imageScaleFactor = (imageWidth > imageHeight) ? imagePreferredSize / imageWidth : imagePreferredSize / imageHeight;
        int imageNewWidth = (int)Math.floor(imageWidth * imageScaleFactor);
        int imageNewHeight = (int)Math.floor(imageHeight * imageScaleFactor);
        
        // Determine offset.
        double offset = this.getConfiguration().getDouble("arrow-rotated.offset");
        double imageOffset = (this.getState().getRotation() == State.Rotation.COUNTER_CLOCKWISE) ? -imageNewWidth - offset * size : offset * size;

        AffineTransform transform = new AffineTransform();
        transform.scale(imageScaleFactor, imageScaleFactor);
        
        AffineTransformOp operation = new AffineTransformOp(transform, AffineTransformOp.TYPE_BILINEAR);
        image = operation.filter(image, null);

        g2d.drawImage(image,
                     (int)(this.getWidth() / 2  + imageOffset),
                     (int)((this.getHeight() - image.getHeight()) / 2),
                     null);
    }
    
    
    /*
        
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
                                   * */
}
