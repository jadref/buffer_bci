package nl.dcc.buffer_bci.imaginedMovement.views;

import java.awt.Graphics;
import nl.dcc.buffer_bci.imaginedMovement.State;
import org.apache.commons.configuration.Configuration;

/**
 * Power meter panel.
 * @author Bas Bootsma
 */
public class PowerMeterPanel extends MeterPanel
{
    /**
     * Constructor.
     * @param configuration
     * @param state 
     */
    public PowerMeterPanel(Configuration configuration, State state)
    {
        super(configuration, state);
    }

    @Override
    protected void paintArrow(Graphics g)
    {
        double angleMin = Math.toRadians(this.getConfiguration().getInt("frame.angle.start"));
        double angleTotal = Math.toRadians(Math.abs(this.getConfiguration().getInt("frame.angle.end") - this.getConfiguration().getInt("frame.angle.start")));
 
        double power = (this.getConfiguration().getInt("marker.value.start") > this.getConfiguration().getInt("marker.value.end")) ? 1.0 - this.getState().getPower() : this.getState().getPower();
        double direction = power * angleTotal - angleMin;
        
        this.paintArrow(g, -direction); // Note the minus.
    }
}
