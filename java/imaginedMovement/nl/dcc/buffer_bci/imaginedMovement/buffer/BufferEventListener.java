package nl.dcc.buffer_bci.imaginedMovement.buffer;

import nl.fcdonders.fieldtrip.bufferclient.BufferEvent;

/**
 *
 * @author bootsman
 */
public interface BufferEventListener
{
    public void onReceived(BufferEvent event);
}