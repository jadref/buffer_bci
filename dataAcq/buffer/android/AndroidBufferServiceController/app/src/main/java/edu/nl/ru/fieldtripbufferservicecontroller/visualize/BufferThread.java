package edu.nl.ru.fieldtripbufferservicecontroller.visualize;

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
    private int port;
    private BufferClientClock C;
    private boolean run;

    private BufferEvent lastEvent;
    private float[] values;

    public BufferThread(String localhost, int port) {
        this.host = localhost;
        this.port = port;
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
            } catch (IOException e) {
            }
        }
        return C.isConnected();
    }

    public void setRunning(boolean b) {
        run = b;
    }

    public void run() {
        int eventCount = 0;
        while (run) {
            if (connect()) {
                BufferEvent[] events;
                try {
                    SamplesEventsCount count = C.waitForEvents(1, 100000);
                    events = C.getEvents(eventCount, count.nEvents - 1);
                    eventCount = count.nEvents - 1;
                } catch (IOException e) {
                    events = null;
                }
                boolean hasEvents = events != null && events.length > 0;
                if (hasEvents) {
                    for (int i = events.length - 1; i >= 0; i--) {
                        String type = String.valueOf(events[i].getType());
                        if (type.equals("alphaLat")) {
                            lastEvent = events[i];
                            values = convertToFloatArray(lastEvent.getValue().getArray());
                            Log.d(TAG, "Alpha lat: " + Arrays.toString(values));
                            break;
                        }
                    }
                }
            }
        }
    }

    private float[] convertToFloatArray(Object o) {
        float[] newValues;
        if (o instanceof float[])
            newValues = (float[]) lastEvent.getValue().getArray();
        else if (o instanceof double[]) {
            double[] doubleValues = (double[]) o;
            newValues = new float[doubleValues.length];
            for (int j = 0; j < doubleValues.length; j++)
                newValues[j] = (float) doubleValues[j];
        } else {
            Log.w(TAG, "Unknown data type: " + o.getClass().toString());
            newValues = new float[]{};
        }
        return newValues;
    }
}
