package nl.dcc.buffer_bci.imaginedMovement.buffer;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import javax.swing.SwingWorker;
import nl.fcdonders.fieldtrip.bufferclient.BufferClient;
import nl.fcdonders.fieldtrip.bufferclient.BufferEvent;
import nl.fcdonders.fieldtrip.bufferclient.SamplesEventsCount;

/**
 *
 * @author bootsman
 */
public class Buffer extends SwingWorker<Void, BufferEvent>
{
    public static long SLEEP_TIME = 200;
    
    private List<BufferEventListener> eventListeners;
    private BufferClient client;
    
    private int eventIndex;
    
    /**
     * Construct a new buffer.
     * @param hostName
     * @param port
     * @throws IOException 
     */
    public Buffer(String hostName, int port) throws IOException
    {
        this.eventListeners = new ArrayList<BufferEventListener>();
        
        this.client = new BufferClient();
        this.client.connect(hostName, port);
        
        this.eventIndex = 0;
    }
    
    /**
     * Send events.
     * @param events
     * @throws IOException 
     */
    public void sendEvents(BufferEvent... events) throws IOException
    {
        this.client.putEvents(events);
    }

    @Override
    protected Void doInBackground() throws Exception
    {
        while(!this.isCancelled())
        {
            // Listen for events.
            SamplesEventsCount samplesCounts = this.client.poll();

            if(samplesCounts.nEvents - this.eventIndex > 0)
            {
                BufferEvent[] events = this.client.getEvents(this.eventIndex, samplesCounts.nEvents - 1);
                
                for(BufferEvent event : events)
                {
                    this.publish(event);
                }
                
                this.eventIndex = samplesCounts.nEvents;
            }
            
            Thread.sleep(Buffer.SLEEP_TIME);
        }
        
        return null;
    }
    
    @Override
    public void process(List<BufferEvent> events)
    {
        for(BufferEvent event : events)
        {
            for(BufferEventListener eventListener : this.eventListeners)
            {
                eventListener.onReceived(event);
            }
        }
    }
    
    @Override
    protected void done()
    {
        try
        {
            this.client.disconnect();
        }
        catch(Exception e)
        {
        }
    }
    
    /**
     * Add event listener.
     * @param listener 
     */
    public void addEventListener(BufferEventListener listener)
    {
        this.eventListeners.add(listener);
    }
    
    /**
     * Remove event listener.
     * @param listener 
     */
    public void removeEventListener(BufferEventListener listener)
    {
        this.eventListeners.remove(listener);
    }
}
