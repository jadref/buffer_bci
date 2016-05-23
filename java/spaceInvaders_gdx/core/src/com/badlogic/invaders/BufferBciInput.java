package com.badlogic.invaders;

import nl.fcdonders.fieldtrip.bufferclient.BufferClientClock;
import nl.fcdonders.fieldtrip.bufferclient.BufferEvent;
import nl.fcdonders.fieldtrip.bufferclient.Header;
import nl.fcdonders.fieldtrip.bufferclient.SamplesEventsCount;

import java.io.IOException;
import java.util.ArrayList;

/**
 * The interface into the buffer_bci buffer.
 *
 * Created by lars on 11/21/15.
 */
public class BufferBciInput {
    /** The client to connected with the buffer. **/
    private BufferClientClock client;

    /** The events fetched since the last time events where fetched, based in timeout. **/
    private ArrayList<BufferEvent> events;

    /** Thread that fetches events. **/
    private Thread bufferThread;

    /** The timeout for getEvents. **/
    private int timeout;

    /** Whether or not the buffer thread should still be running. **/
    private boolean running;

    /** Header **/
    private Header header;

    /** Listeners for arrived events. **/
    private ArrayList<ArrivedEventsListener> listeners;

    /**
     * Initializes the BufferBciInput instance.
     */
    public BufferBciInput() {
        this(10);
    }

    /**
     * Initializes the BufferBciInput instance.
     */
    public BufferBciInput(int timeout) {
        this.timeout = timeout;
        events = new ArrayList<BufferEvent>();
        client = new BufferClientClock();
        listeners = new ArrayList<ArrivedEventsListener>();
    }

    /**
     * Adds the provided listener.
     *
     * Note: Events are provided on the buffer_bci thread, NOT on the main thread.
     *
     * @param listener
     */
    public void addArrivedEventsListener(ArrivedEventsListener listener) {
        listeners.add(listener);
    }

    /**
     * Connects to a buffer.
     * @param host
     * @param port
     * @return
     */
    public boolean connect(String host, int port) {

        try {
            System.out.println("Connecting to " + host + ":" + port);
            client.connect(host, port);

            if (client.isConnected()) {
                header = client.getHeader();
            }
        } catch(IOException ex) {
            header = null;
        }

        if(header == null) {
            return false;
        }

        // Start buffer-bci event fetching thread.
        running = true;
        bufferThread = new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    int nEvents = header.nEvents;

                    // While running, fetch events.
                    while (running) {

                        // Check if there are new events.
                        SamplesEventsCount sec = client.waitForEvents(nEvents, timeout);
                        if(sec.nEvents > nEvents) {

                            // Fetch new events.
                            BufferEvent[] evts = client.getEvents(nEvents, sec.nEvents - 1);
                            nEvents = sec.nEvents;

                            // Inform listeners
                            for(ArrivedEventsListener l : listeners){
                                l.receiveEvents(evts);
                            }

                            // Add events to main event list.
                            synchronized (BufferBciInput.this) {
                                for(int i = 0; i< evts.length; i++) {
                                    events.add(evts[i]);
                                }
                            }
                        }
                    }
                } catch(IOException ex) {
                    System.out.println("Exception occurred when fetching events, quiting buffer event loop.");
                    running = false;
                }
            }
        });
        bufferThread.start();

        return true;
    }

    public void stop() {
        running = false;
    }

    public boolean isRunning() {
        return running;
    }

    public synchronized BufferEvent[] getEvents() {
        BufferEvent[] evts = new BufferEvent[events.size()];
        events.toArray(evts);
        events.clear();
        return evts;
    }

    public interface ArrivedEventsListener
    {
        void receiveEvents(BufferEvent[] events);
    }
}
