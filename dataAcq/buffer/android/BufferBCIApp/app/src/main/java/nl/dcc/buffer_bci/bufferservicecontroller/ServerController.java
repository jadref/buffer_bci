package nl.dcc.buffer_bci.bufferservicecontroller;

import android.app.Activity;
import android.app.ActivityManager;
import android.app.AlertDialog;
import android.content.ComponentName;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.res.Resources;
import android.util.Log;
import android.util.SparseArray;

import nl.dcc.buffer_bci.C;
import nl.dcc.buffer_bci.R;
import nl.dcc.buffer_bci.monitor.BufferConnectionInfo;
import nl.dcc.buffer_bci.monitor.BufferInfo;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;

/**
 * Created by georgedimitriadis on 08/02/15.
 */
public class ServerController {

    public static String TAG = ServerController.class.getSimpleName();
    private final ArrayList<BufferConnectionInfo> bufferConnectionsArray = new ArrayList<BufferConnectionInfo>();
    protected BufferInfo buffer;
    protected String uptime;
    protected boolean initalUpdateCalled = false;
    Intent intent;
    private String serverServicePackageName = C.SERVER_SERVICE_PACKAGE_NAME;
    private String serverServiceClassName = C.SERVER_SERVICE_CLASS_NAME;
    //private Timer timer;
    private Context context;
    private SparseArray<BufferConnectionInfo> bufferConnections = new SparseArray<BufferConnectionInfo>();
    private String address;
    private int port = 1972;
    private int nSamples = 10000;
    private int nEvents = 1000;
    private int dataType;
    private int nChannels;
    private float fSample;
    private long startTime;
    private SimpleDateFormat minSec = new SimpleDateFormat("mm:ss");


    ServerController(Context context) {
        this.context = context;
        intent = new Intent();
        intent.setClassName(serverServicePackageName, serverServiceClassName);
    }


    public String toString() {
        String ret = "ServerController:{address=" + address + ", port=" + port + ", nSamples=" + nSamples + ", " +
                "nEvent=" +
                nEvents + ", datatype=" + dataType + ", nChannels=" + nChannels + ", fSample=" + fSample + "} with \n";
        for (BufferConnectionInfo bufferConnectionInfo : bufferConnectionsArray) {
            if ( bufferConnectionInfo.connected ) { // only connected clients
                ret += "\t" + bufferConnectionInfo + "\n";
            }
        }
        return ret;
    }


    protected void flush(final int flush) {
        final AlertDialog.Builder alert = new AlertDialog.Builder(this.context);

        final Resources res = context.getResources();

        alert.setTitle(res.getString(R.string.confirmation));

        switch (flush) {
            case C.REQUEST_FLUSH_HEADER:
                alert.setMessage(res.getString(R.string.confirmationflushheader));
                break;
            case C.REQUEST_FLUSH_SAMPLES:
                alert.setMessage(res.getString(R.string.confirmationflushsamples));
                break;
            case C.REQUEST_FLUSH_EVENTS:
                alert.setMessage(res.getString(R.string.confirmationflushevents));
                break;
            default:
        }

        alert.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(final DialogInterface dialog, final int whichButton) {
                final Intent intent = new Intent();
                intent.setAction(C.SEND_FLUSHBUFFER_REQUEST_TO_SERVICE);
                intent.putExtra(C.MESSAGE_TYPE, flush);
                context.sendOrderedBroadcast(intent, null);
            }
        });

        alert.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(final DialogInterface dialog, final int whichButton) {
            }
        });

        alert.show();
    }

    protected void initialUpdate() {
        //Log.i(TAG, "Initially Updated Buffer Info.");
        address = buffer.address;
        //timer = new Timer();
        //timer.start();
        startTime = buffer.startTime;
        initalUpdateCalled = true;
    }

    protected void updateBufferInfo() {
        if (buffer.fSample != -1 && buffer.nChannels != -1) {
            dataType = buffer.dataType;
            nChannels = buffer.nChannels;
            fSample = buffer.fSample;
            nEvents = buffer.nEvents;
            nSamples = buffer.nSamples;

        } else {
            dataType = 0;
            nChannels = 0;
            fSample = 0f;
            nEvents = 0;
            nSamples = 0;
        }
    }

    protected void updateBufferConnections(final BufferConnectionInfo[] connectionInfos) {
        for (final BufferConnectionInfo bufferconnection : connectionInfos) {
            if (bufferConnections.get(bufferconnection.getConnectionID()) == null) {
                bufferConnections.put(bufferconnection.getConnectionID(), bufferconnection);
                bufferConnectionsArray.add(bufferconnection);
            } else {
                bufferConnections.get(bufferconnection.getConnectionID()).update(bufferconnection);
                ArrayList<BufferConnectionInfo> tempInfo = new ArrayList<BufferConnectionInfo>(bufferConnectionsArray);
                for (BufferConnectionInfo oldConnection : tempInfo) {
                    if (oldConnection.getConnectionID() == bufferconnection.getConnectionID()) { //Removing duplicates of BufferConnectionInfo with same connectionID
                        int index = tempInfo.indexOf(oldConnection);
                        bufferConnectionsArray.remove(index);
                        bufferConnectionsArray.add(bufferconnection);
                    }
                }
            }
        }
    }

    protected boolean isBufferServerServiceRunning() {
        final ActivityManager manager = (ActivityManager) context.getSystemService(context.ACTIVITY_SERVICE);
        for (final ActivityManager.RunningServiceInfo service : manager.getRunningServices(Integer.MAX_VALUE)) {
            if (service.service.getClassName().equals(serverServiceClassName)) {
                return true;
            }
        }
        return false;
    }

    //Get and Set Buffer Information
    public BufferInfo getBuffer() {
        return buffer;
    }


    // Interface

    public void setBuffer(BufferInfo buffer) {
        this.buffer = buffer;
    }

    public int getBufferPort() {
        return port;
    }

    public void setBufferPort(int port) {
        this.port = port;
    }

    public int getBuffernSamples() {
        return nSamples;
    }

    public void setnBufferSamples(int nSamples) {
        this.nSamples = nSamples;
    }

    public int getBuffernEvents() {
        return nEvents;
    }

    public void setBuffernEvents(int nEvents) {
        this.nEvents = nEvents;
    }

    public int getBuffernChannels() {
        return nChannels;
    }

    public void setBuffernChannels(int nEvents) {
        this.nChannels = nChannels;
    }

    public String getBufferAddress() {
        return address;
    }

    public int getBuffernDataType() {
        return dataType;
    }

    public float getBufferfSample() {
        return fSample;
    }

    public long getBufferStartTime() {
        return startTime;
    }

    public String getBufferUptime() {
        return uptime;
    }

    //Get Connection Information
    public BufferConnectionInfo[] getConnectionInfoArray() {
        return (BufferConnectionInfo[]) bufferConnectionsArray.toArray();
    }

    public int getNumberOfConnections() {
        return bufferConnectionsArray.size();
    }

    public int[] getConnectionIDs() {
        int length = bufferConnections.size();
        int[] ids = new int[length];
        for (int i = 0; i < length; ++i) {
            ids[i] = bufferConnections.valueAt(i).getConnectionID();
        }
        return ids;
    }

    public String getConnectionAddress(int connectionID) {
        synchronized (bufferConnectionsArray) {
            for (BufferConnectionInfo Connection : bufferConnectionsArray) {
                if (Connection.getConnectionID() == connectionID) {
                    return Connection.getAddress();
                }
            }
        }
        return "No Address for Connection with ID: " + connectionID;
    }

    public int getConnectionSamplesGotten(int connectionID) {
        synchronized (bufferConnectionsArray) {
            for (BufferConnectionInfo Connection : bufferConnectionsArray) {
                if (Connection.getConnectionID() == connectionID) {
                    return Connection.samplesGotten;
                }
            }
        }
        return 0;
    }

    public int getConnectionSamplesPut(int connectionID) {
        synchronized (bufferConnectionsArray) {
            for (BufferConnectionInfo Connection : bufferConnectionsArray) {
                if (Connection.getConnectionID() == connectionID) {
                    return Connection.samplesPut;
                }
            }
        }
        return 0;
    }

    public int getConnectionEventsGotten(int connectionID) {
        synchronized (bufferConnectionsArray) {
            for (BufferConnectionInfo Connection : bufferConnectionsArray) {
                if (Connection.getConnectionID() == connectionID) {
                    return Connection.eventsGotten;
                }
            }
        }
        return 0;
    }

    public int getConnectionEventsPut(int connectionID) {
        synchronized (bufferConnectionsArray) {
            for (BufferConnectionInfo Connection : bufferConnectionsArray) {
                if (Connection.getConnectionID() == connectionID) {
                    return Connection.eventsPut;
                }
            }
        }
        return 0;
    }

    public int getConnectionLastActivity(int connectionID) {
        synchronized (bufferConnectionsArray) {
            for (BufferConnectionInfo Connection : bufferConnectionsArray) {
                if (Connection.getConnectionID() == connectionID) {
                    return Connection.lastActivity;
                }
            }
        }
        return 0;
    }

    public int getConnectionWaitEvents(int connectionID) {
        synchronized (bufferConnectionsArray) {
            for (BufferConnectionInfo Connection : bufferConnectionsArray) {
                if (Connection.getConnectionID() == connectionID) {
                    return Connection.waitEvents;
                }
            }
        }
        return 0;
    }

    public int getConnectionWaitSamples(int connectionID) {
        synchronized (bufferConnectionsArray) {
            for (BufferConnectionInfo Connection : bufferConnectionsArray) {
                if (Connection.getConnectionID() == connectionID) {
                    return Connection.waitSamples;
                }
            }
        }
        return 0;
    }

    public int getConnectionError(int connectionID) {
        synchronized (bufferConnectionsArray) {
            for (BufferConnectionInfo Connection : bufferConnectionsArray) {
                if (Connection.getConnectionID() == connectionID) {
                    return Connection.error;
                }
            }
        }
        return 0;
    }

    public long getConnectionTimeLastActivity(int connectionID) {
        synchronized (bufferConnectionsArray) {
            for (BufferConnectionInfo Connection : bufferConnectionsArray) {
                if (Connection.getConnectionID() == connectionID) {
                    return Connection.timeLastActivity;
                }
            }
        }
        return 0L;
    }

    public long getConnectionTime(int connectionID) {
        synchronized (bufferConnectionsArray) {
            for (BufferConnectionInfo Connection : bufferConnectionsArray) {
                if (Connection.getConnectionID() == connectionID) {
                    return Connection.time;
                }
            }
        }
        return 0L;
    }

    public long getConnectionWaitTimeout(int connectionID) {
        synchronized (bufferConnectionsArray) {
            for (BufferConnectionInfo Connection : bufferConnectionsArray) {
                if (Connection.getConnectionID() == connectionID) {
                    return Connection.waitTimeout;
                }
            }
        }
        return 0L;
    }

    public boolean getConnectionConnected(int connectionID) {
        synchronized (bufferConnectionsArray) {
            for (BufferConnectionInfo Connection : bufferConnectionsArray) {
                if (Connection.getConnectionID() == connectionID) {
                    return Connection.connected;
                }
            }
        }
        return false;
    }

    public boolean getConnectionChanged(int connectionID) {
        synchronized (bufferConnectionsArray) {
            for (BufferConnectionInfo Connection : bufferConnectionsArray) {
                if (Connection.getConnectionID() == connectionID) {
                    return Connection.changed;
                }
            }
        }
        return false;
    }

    public int getConnectionDiff(int connectionID) {
        synchronized (bufferConnectionsArray) {
            for (BufferConnectionInfo Connection : bufferConnectionsArray) {
                if (Connection.getConnectionID() == connectionID) {
                    return Connection.diff;
                }
            }
        }
        return 0;
    }

    //Buffer service controls
    public String startServerService() {
        try {
            intent.putExtra("port", port);
        } catch (final NumberFormatException e) {
            intent.putExtra("port", 1972);
        }

        try {
            intent.putExtra("nSamples", nSamples);
        } catch (final NumberFormatException e) {
            intent.putExtra("nSamples", 10000);
        }

        try {
            intent.putExtra("nEvents", nEvents);
        } catch (final NumberFormatException e) {
            intent.putExtra("nEvents", 1000);
        }

        ComponentName serviceName = context.startService(intent);
        String result = "Buffer Service was not found";
        if (serviceName != null) result = serviceName.toString();
        return result;
    }

    public void PutHeader() {
        final Intent intent = new Intent();
        intent.setAction(C.SEND_FLUSHBUFFER_REQUEST_TO_SERVICE);
        intent.putExtra(C.MESSAGE_TYPE, C.REQUEST_PUT_HEADER);
        context.sendOrderedBroadcast(intent, null);
    }

    public void FlushHeader() {
        PutHeader(); //If the header is empty flushing it break. So put something in first.
        flush(C.REQUEST_FLUSH_HEADER);
    }

    public void FlushSamples() {
        flush(C.REQUEST_FLUSH_SAMPLES);
    }

    public void FlushEvents() {
        flush(C.REQUEST_FLUSH_EVENTS);
    }

    public boolean stopServerService() {
        bufferConnections.clear();
        bufferConnectionsArray.clear();
        boolean stopped = context.stopService(intent);
        if (stopped) {
            //if (timer != null) timer.running = false;
            initalUpdateCalled = false;
        }
        return stopped;
    }

    public void reloadConnections() {
        Intent intent = new Intent(C.FILTER_FR0M_SERVER);
        intent.putExtra(C.MESSAGE_TYPE, C.BUFFER_INFO_BROADCAST);
        Log.i(TAG, "Refreshing all server bufferConnections info.");
        context.sendOrderedBroadcast(intent, null);
    }

//    protected class Timer extends Thread {
//        public boolean running = true;
//
//        @Override
//        public void run() {
//            while (running) {
//                ((Activity) context).runOnUiThread(new Runnable() {
//                    @Override
//                    public void run() {
//                        try {
//                            uptime = minSec.format(new Date(System.currentTimeMillis() - buffer.startTime));
//                        } catch (final Exception e) {
//                        }
//                    }
//                });
//                try {
//                    Thread.sleep(1000);
//                } catch (final InterruptedException e) {
//                    // TODO Auto-generated catch block
//                    e.printStackTrace();
//                }
//            }
//        }
//
//    }


}
