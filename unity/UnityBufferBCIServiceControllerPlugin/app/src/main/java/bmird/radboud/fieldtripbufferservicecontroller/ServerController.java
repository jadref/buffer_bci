package bmird.radboud.fieldtripbufferservicecontroller;

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

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;

import bmird.radboud.fieldtripserverservice.monitor.BufferInfo;
import bmird.radboud.fieldtripserverservice.monitor.ClientInfo;

/**
 * Created by georgedimitriadis on 08/02/15.
 */
public class ServerController {

    private String serverServicePackageName = C.SERVER_SERVICE_PACKAGE_NAME;
    private String serverServiceClassName = C.SERVER_SERVICE_CLASS_NAME;

    Intent intent;
    private Timer timer;

    protected BufferInfo buffer;

    private Context context;

    private SparseArray<ClientInfo> clients = new SparseArray<ClientInfo>();
    private final ArrayList<ClientInfo> clientsArray = new ArrayList<ClientInfo>();
    protected String uptime;
    protected boolean initalUpdateCalled = false;
    private String address;
    private int port = 1972;
    private int nSamples=10000;
    private int nEvents=1000;
    private int dataType;
    private int nChannels;
    private float fSample ;
    private long startTime;
    private SimpleDateFormat minSec = new SimpleDateFormat("mm:ss");


     ServerController(Context context){
        this.context = context;
         intent = new Intent();
         intent.setClassName(serverServicePackageName, serverServiceClassName);
    }



    protected void flush(final int flush){
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
            public void onClick(final DialogInterface dialog,
                                final int whichButton) {
                final Intent intent = new Intent();
                intent.setAction(C.SEND_FLUSHBUFFER_REQUEST_TO_SERVICE);
                intent.putExtra(C.MESSAGE_TYPE, flush);
                context.sendOrderedBroadcast(intent, null);
            }
        });

        alert.setNegativeButton("Cancel",
                new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(final DialogInterface dialog,
                                        final int whichButton) {
                    }
                });

        alert.show();
    }


    protected class Timer extends Thread {
        public boolean running = true;

        @Override
        public void run() {
            while (running) {
                ((Activity)context).runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                    try {
                        uptime = minSec.format(new Date(System.currentTimeMillis() - buffer.startTime));
                    } catch (final Exception e) {}
                    }
                });
                try {
                    Thread.sleep(1000);
                } catch (final InterruptedException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                }
            }
        }

    }


    protected void initialUpdate() {
        //Log.i(C.TAG, "Initially Updated Buffer Info.");
        address = buffer.address;
        timer = new Timer();
        timer.start();
        startTime = buffer.startTime;
        initalUpdateCalled = true;
    }

    protected void updateBufferInfo() {
        //Log.i(C.TAG, "Updated Buffer Info.");
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


    protected void updateClients(final ClientInfo[] clientinfo) {
        Log.i(C.TAG, "In UpdateClients: Client list size:" + Integer.toString(clientinfo.length));
        for (final ClientInfo client : clientinfo) {
            if (clients.get(client.clientID) == null) {
                clients.put(client.clientID, client);
                clientsArray.add(client);
            } else {
                clients.get(client.clientID).update(client);
                ArrayList<ClientInfo> tempInfo = new ArrayList<ClientInfo>(clientsArray);
                for(ClientInfo oldClient: tempInfo){
                    if(oldClient.clientID == client.clientID){ //Removing duplicates of ClientInfo with same clientID
                        int index = tempInfo.indexOf(oldClient);
                        clientsArray.remove(index);
                        clientsArray.add(client);
                    }
                }
            }
            Log.i(C.TAG, "In UpdateClients: Updating Client list with client with ID = " + client.clientID);
        }
    }


    protected boolean isBufferServerServiceRunning(){
        final ActivityManager manager = (ActivityManager) context.getSystemService(context.ACTIVITY_SERVICE);
        for (final ActivityManager.RunningServiceInfo service : manager
                .getRunningServices(Integer.MAX_VALUE)) {
            if (service.service.getClassName().equals(serverServiceClassName)) {
                return true;
            }
        }
        return false;
    }




    // Interface

    //Get and Set Buffer Information
    public BufferInfo getBuffer(){ return buffer; }
    public void setBuffer(BufferInfo buffer){ this.buffer = buffer; }

    public int getBufferPort(){ return port; }
    public void setBufferPort(int port){ this.port = port; }

    public int getBuffernSamples(){ return nSamples; }
    public void setnBufferSamples(int nSamples){ this.nSamples = nSamples; }

    public int getBuffernEvents(){ return nEvents; }
    public void setBuffernEvents(int nEvents){ this.nEvents = nEvents; }

    public int getBuffernChannels(){ return nChannels; }
    public void setBuffernChannels(int nEvents){ this.nChannels = nChannels; }

    public String getBufferAddress(){ return address; }

    public int getBuffernDataType(){ return dataType; }

    public float getBufferfSample(){ return fSample; }

    public long getBufferStartTime(){ return startTime; }

    public String getBufferUptime(){ return uptime; }


    //Get Client Information
    public ClientInfo[] getClientInfoArray(){ return (ClientInfo[])clientsArray.toArray(); }

    public int getNumberOfClients(){ return clientsArray.size(); }

    public int[] getClientIDs(){
        int length = clients.size();
        int[] ids = new int[length];
        for (int i=0; i<length; ++i) {
            ids[i] = clients.valueAt(i).clientID;
        }
        return ids;
    }

    public String getClientAddress(int clientID){
        synchronized (clientsArray) {
            for (ClientInfo client : clientsArray) {
                if (client.clientID == clientID) {
                    return client.address;
                }
            }
        }
        return "No Address for Client with ID: "+clientID;
    }

    public int getClientSamplesGotten(int clientID){
        synchronized (clientsArray) {
            for (ClientInfo client : clientsArray) {
                if (client.clientID == clientID) {
                    return client.samplesGotten;
                }
            }
        }
        return 0;
    }

    public int getClientSamplesPut(int clientID){
        synchronized (clientsArray) {
            for (ClientInfo client : clientsArray) {
                if (client.clientID == clientID) {
                    return client.samplesPut;
                }
            }
        }
        return 0;
    }

    public int getClientEventsGotten(int clientID){
        synchronized (clientsArray) {
            for (ClientInfo client : clientsArray) {
                if (client.clientID == clientID) {
                    return client.eventsGotten;
                }
            }
        }
        return 0;
    }

    public int getClientEventsPut(int clientID){
        synchronized (clientsArray) {
            for (ClientInfo client : clientsArray) {
                if (client.clientID == clientID) {
                    return client.eventsPut;
                }
            }
        }
        return 0;
    }

    public int getClientLastActivity(int clientID){
        synchronized (clientsArray) {
            for (ClientInfo client : clientsArray) {
                if (client.clientID == clientID) {
                    return client.lastActivity;
                }
            }
        }
        return 0;
    }

    public int getClientWaitEvents(int clientID){
        synchronized (clientsArray) {
            for (ClientInfo client : clientsArray) {
                if (client.clientID == clientID) {
                    return client.waitEvents;
                }
            }
        }
        return 0;
    }

    public int getClientWaitSamples(int clientID){
        synchronized (clientsArray) {
            for (ClientInfo client : clientsArray) {
                if (client.clientID == clientID) {
                    return client.waitSamples;
                }
            }
        }
        return 0;
    }

    public int getClientError(int clientID){
        synchronized (clientsArray) {
            for (ClientInfo client : clientsArray) {
                if (client.clientID == clientID) {
                    return client.error;
                }
            }
        }
        return 0;
    }

    public long getClientTimeLastActivity(int clientID){
        synchronized (clientsArray) {
            for (ClientInfo client : clientsArray) {
                if (client.clientID == clientID) {
                    return client.timeLastActivity;
                }
            }
        }
        return 0L;
    }

    public long getClientTime(int clientID){
        synchronized (clientsArray) {
            for (ClientInfo client : clientsArray) {
                if (client.clientID == clientID) {
                    return client.time;
                }
            }
        }
        return 0L;
    }

    public long getClientWaitTimeout(int clientID){
        synchronized (clientsArray) {
            for (ClientInfo client : clientsArray) {
                if (client.clientID == clientID) {
                    return client.waitTimeout;
                }
            }
        }
        return 0L;
    }

    public boolean getClientConnected(int clientID){
        synchronized (clientsArray) {
            for (ClientInfo client : clientsArray) {
                if (client.clientID == clientID) {
                    return client.connected;
                }
            }
        }
        return false;
    }

    public boolean getClientChanged(int clientID){
        synchronized (clientsArray) {
            for (ClientInfo client : clientsArray) {
                if (client.clientID == clientID) {
                    return client.changed;
                }
            }
        }
        return false;
    }

    public int getClientDiff(int clientID){
        synchronized (clientsArray) {
            for (ClientInfo client : clientsArray) {
                if (client.clientID == clientID) {
                    return client.diff;
                }
            }
        }
        return 0;
    }


    //Buffer service controls
    public String startServerService(){
        try {
            intent.putExtra("port",port);
        } catch (final NumberFormatException e) {
            intent.putExtra("port", 1972);
        }

        try {
            intent.putExtra("nSamples",nSamples);
        } catch (final NumberFormatException e) {
            intent.putExtra("nSamples", 10000);
        }

        try {
            intent.putExtra("nEvents",nEvents);
        } catch (final NumberFormatException e) {
            intent.putExtra("nEvents", 1000);
        }

        Log.i(C.TAG, "Attempting to start Buffer Service");
        ComponentName serviceName = context.startService(intent);
        Log.i(C.TAG, "Managed to start service: "+ serviceName);

        String result = "Buffer Service was not found";
        if(serviceName!=null)
            result = serviceName.toString();
        return result;
    }


    public void PutHeader(){
        final Intent intent = new Intent();
        intent.setAction(C.SEND_FLUSHBUFFER_REQUEST_TO_SERVICE);
        intent.putExtra(C.MESSAGE_TYPE, C.REQUEST_PUT_HEADER);
        context.sendOrderedBroadcast(intent, null);
    }

    public void FlushHeader(){
        PutHeader(); //If the header is empty flushing it break. So put something in first.
        flush(C.REQUEST_FLUSH_HEADER);
    }

    public void FlushSamples(){
        flush(C.REQUEST_FLUSH_SAMPLES);
    }

    public void FlushEvents(){
        flush(C.REQUEST_FLUSH_EVENTS);
    }

    public boolean stopServerService(){
        clients.clear();
        clientsArray.clear();
        boolean stopped = context.stopService(intent);
        if(stopped){
            timer.running = false;
            initalUpdateCalled = false;
        }
        Log.i(C.TAG, "Trying to stop buffer service: "+ stopped);
        return stopped;
    }


}
