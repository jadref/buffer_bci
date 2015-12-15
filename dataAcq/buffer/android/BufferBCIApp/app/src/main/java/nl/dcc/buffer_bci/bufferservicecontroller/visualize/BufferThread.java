package nl.dcc.buffer_bci.bufferservicecontroller.visualize;

import android.util.Log;
import nl.fcdonders.fieldtrip.bufferclient.BufferClientClock;
import nl.fcdonders.fieldtrip.bufferclient.BufferEvent;
import nl.fcdonders.fieldtrip.bufferclient.SamplesEventsCount;

import java.io.IOException;
import java.util.Arrays;

/**
 * Created by pieter on 18-5-15.
 */
public class BufferThread extends Thread {

    private static final String TAG = BufferThread.class.getSimpleName();
    private String host;
    private String feedbackEventType="classifier.prediction";
    private int timeout_ms=1000;
    private int port;
    private BufferClientClock C;
    private boolean run;
    private boolean damage;
    private float[] values;

    public BufferThread(String host, int port) {
        this.host = host;
        this.port = port;
        C = new BufferClientClock();
    }

    public BufferThread(String host, int port, String feedbackEventType) {
        this.host = host;
        this.port = port;
        this.feedbackEventType = feedbackEventType;
        C = new BufferClientClock();
    }

    public float[] getValues() {
        // todo use shared memory
        if (values != null) return values;
        else return new float[]{0.f, 0.f, 0.f, 0.f};
    }

    private boolean connect() {
        if (!C.isConnected()) {
            try {
                C.connect(host, port);
                //C.setAutoReconnect(true);
            } catch (IOException e) { // connection failed, wait before trying again
                try{Thread.sleep(200);}catch(InterruptedException ex){}
            }
        }
        return C.isConnected();
    }

    public boolean isRunning(){ return run; }
    public void setRunning(boolean b) {
        run = b;
    }
    public boolean isDamage() {
        return damage;
    }
    public void setDamage(boolean damage) {
        this.damage = damage;
    }

    public void run() {
        SamplesEventsCount count;
        BufferEvent[] events;
        int eventCount = 0;
        int nSamples=0;
        while (run) {
            if (connect()) {
                events=null;
                count=null;
                try {
                    // wait and block until an update event is received
                    count = C.waitForEvents(eventCount, timeout_ms);
                } catch (IOException e) {
                    // connection failed, wait before trying again
                    try{Thread.sleep(200);}catch(InterruptedException ex){}
                }
                if ( count != null ) {
                    // get any new events
                    if (count.nSamples < nSamples) {
                        Log.i(TAG, "Buffer restart detected!");
                        eventCount = count.nEvents;
                    }
                    // load any new events
                    if (count.nEvents > eventCount) {
                        try {
                            events = C.getEvents(eventCount, count.nEvents - 1);
                        } catch ( IOException ex ){
                            Log.e(TAG, ex.toString());
                        }
                    }
                    // update the cursor to the last data/events we have seen
                    eventCount = count.nEvents;
                    nSamples = count.nSamples;
                }
                // process any new events
                if ( events != null && events.length > 0 ) {
                    // check which of these events we care about
                    for (int i = events.length - 1; i >= 0; i--) {
                        String type = String.valueOf(events[i].getType());
                        if (type.equals(feedbackEventType)) {
                            values = convertToFloatArray(events[i].getValue().getArray());
                            damage=true;
                            Log.d(TAG, feedbackEventType + ": " + Arrays.toString(values));
                        }
                    }
                }
            } else {
                // not connected, wait before trying again
                try{Thread.sleep(200);}catch(InterruptedException ex){}
            }
        }
    }

    private float[] convertToFloatArray(Object o) {
        float[] newValues;
        if (o instanceof float[]) {
            float[] values = (float[]) o;
            newValues = new float[values.length];
            for (int j = 0; j < values.length; j++)
                newValues[j] = (float) values[j];
        } else if (o instanceof double[]) {
            double[] values = (double[]) o;
            newValues = new float[values.length];
            for (int j = 0; j < values.length; j++)
                newValues[j] = (float) values[j];
        } else {
            Log.w(TAG, "Unknown data type: " + o.getClass().toString());
            newValues = new float[]{};
        }
        return newValues;
    }
}
