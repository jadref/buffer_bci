package nl.dcc.buffer_bci.imaginedMovement.views;

import javax.swing.JPanel;
import nl.dcc.buffer_bci.imaginedMovement.State;
import org.apache.commons.configuration.Configuration;

/**
 * Base panel.
 * @author Bas Bootsma
 */
public abstract class BasePanel extends JPanel
{
    private Configuration configuration;
    private State state;
    
    /**
     * Constructor.
     * @param properties
     * @param state 
     */
    public BasePanel(Configuration configuration, State state)
    {
        super();
        
        this.configuration = configuration;
        this.state = state;
    }
    
    /**
     * Returns the configuration.
     * @return 
     */
    public Configuration getConfiguration()
    {
        return this.configuration;
    }
    
    /**
     * Returns the state.
     * @return 
     */
    public State getState()
    {
        return this.state;
    }
}
