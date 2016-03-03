package bmird.radboud.fieldtripbufferservicecontroller;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.util.Log;

import com.unity3d.player.UnityPlayerActivity;

import bmird.radboud.fieldtripclientsservice.ThreadInfo;
import bmird.radboud.fieldtripclientsservice.base.Argument;
import bmird.radboud.fieldtripserverservice.monitor.ClientInfo;



public class MainActivity extends UnityPlayerActivity {
//public class MainActivity extends Activity{

    public ServerController serverController;
    public ClientsController clientsController;

    private BroadcastReceiver mMessageReceiver;

    @Override
    protected void onCreate(final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        serverController = new ServerController(this);
        clientsController = new ClientsController(this);

        if (savedInstanceState == null) {


            IntentFilter intentFilter = new IntentFilter(C.FILTER_FROM_SERVER);
            mMessageReceiver = new BroadcastReceiver() {
                @Override
                public void onReceive(final Context context, Intent intent) {
                    updateServerController(intent);
                }
            };
            this.registerReceiver(mMessageReceiver, intentFilter);
        }
    }


    @Override
    public void onStop(){
        super.onStop();
        this.unregisterReceiver(mMessageReceiver);
    }



    private void updateServerController(Intent intent){
        Log.i(C.TAG, "Got Intent from Broadcast");
        if (intent.getBooleanExtra(C.IS_BUFFER_INFO, false)) {
            //Log.i(C.TAG, "Received Buffer Info.");
            updateServerInfo(intent);
        }
        if (intent.getBooleanExtra(C.IS_CLIENT_INFO, false)) {
            Log.i(C.TAG, "Received Client Info.");
            updateClientInfoFromServer(intent);
        }
        if(intent.getBooleanExtra(C.IS_THREAD_INFO, false)){
            //Log.i(C.TAG, "Received Thread Info");
            updateThreadsInfo(intent);
        }
    }

    private void updateServerInfo(Intent intent) {
        serverController.buffer =  intent.getParcelableExtra(C.BUFFER_INFO);
        if (!serverController.initalUpdateCalled) {
            serverController.initialUpdate();
        }
        serverController.updateBufferInfo();
        //Log.i(C.TAG, "New buffer info");
    }

    private void updateClientInfoFromServer(Intent intent){
        int numOfClients = intent.getIntExtra(C.CLIENT_N_INFOS, 0);
        Log.i(C.TAG, "In UpdateClientInfoFromServer: Number of clientInfos = "+numOfClients);
        ClientInfo[] clientInfo = new ClientInfo[numOfClients];
        for (int k=0; k<numOfClients; ++k){
            clientInfo[k] = intent.getParcelableExtra(C.CLIENT_INFO+k);
            Log.i(C.TAG, "In UpdateClientInfoFromServer: Client update with Client ID = "+clientInfo[k].clientID);
        }
        serverController.updateClients(clientInfo);

    }

    private void updateThreadsInfo(Intent intent){
            ThreadInfo threadInfo = intent.getParcelableExtra(C.THREAD_INFO);
            int nArgs = intent.getIntExtra(C.THREAD_N_ARGUMENTS, 0);
            Argument[] arguments = new Argument[nArgs];
            for (int i = 0; i < nArgs; i++) {
                arguments[i] = (Argument) intent
                        .getSerializableExtra(C.THREAD_ARGUMENTS + i);
            }
            clientsController.updateThreadInfoAndArguments(threadInfo, arguments);
    }

    //Interface
    public String startServer(){
        String serverName = "";
        if (!serverController.isBufferServerServiceRunning()) {
            Log.i(C.TAG, "Starting Buffer Service");
            serverName = serverController.startServerService();
        }
        return serverName;
    }

    public String startClients(){
        String clientsName = "";
        if (!clientsController.isClientsServiceRunning()) {
            Log.i(C.TAG, "Starting Clients Service");
            clientsName = clientsController.startClientsService();
        }
        return clientsName;
    }

    public boolean stopServer(){
        boolean result = false;
        if (serverController.isBufferServerServiceRunning()) {
            Log.i(C.TAG, "Stopping Buffer Service");
            result = serverController.stopServerService();
        }
        return result;
    }

    public boolean stopClients(){
        boolean result = false;
        if (clientsController.isClientsServiceRunning()) {
            Log.i(C.TAG, "Stopping Clients Service");
            result = clientsController.stopClientsService();
        }
        return result;
    }

}










/*
    private void updateServerInfo(Intent intent){
        serverController.buffer = new BufferInfo(intent.getStringExtra(C.BUFFER_INFO_ADDRESS),
                intent.getLongExtra(C.BUFFER_INFO_STARTTIME, 0));
        serverController.buffer.dataType = intent.getIntExtra(C.BUFFER_INFO_DATATYPE, 0);
        serverController.buffer.fSample = intent.getFloatExtra(C.BUFFER_INFO_FSAMPLE, 0);
        serverController.buffer.nChannels = intent.getIntExtra(C.BUFFER_INFO_NCHANNELS, 0);
        serverController.buffer.nEvents = intent.getIntExtra(C.BUFFER_INFO_NEVENTS, 0);
        serverController.buffer.nSamples = intent.getIntExtra(C.BUFFER_INFO_NSAMPLES, 0);
        serverController.updateBufferInfo();
        if (!serverController.initalUpdateCalled) {
            serverController.initialUpdate();
        }
    }


    private void updateClientInfoFromServer(Intent intent){

        int numOfClients = intent.getStringArrayExtra(C.CLIENT_INFO_ADDRESS).length;

        ClientInfo[] clientInfo = new ClientInfo[numOfClients];

        String[] addresses = new String[numOfClients];
        int[] clientIDS = new int[numOfClients];
        int[] samplesGotten = new int[numOfClients];
        int[] samplesPut = new int[numOfClients];
        int[] eventsGotten = new int[numOfClients];
        int[] eventsPut = new int[numOfClients];
        int[] lastActivities = new int[numOfClients];
        int[] waitEvents = new int[numOfClients];
        int[] waitSamples = new int[numOfClients];
        int[] errors = new int[numOfClients];
        long[] timeLastActivities = new long[numOfClients];
        long[] times = new long[numOfClients];
        long[] waitTimeouts = new long[numOfClients];
        boolean[] connected = new boolean[numOfClients];
        boolean[] changed = new boolean[numOfClients];
        int[] diffs = new int[numOfClients];

        for(int i=0; i<numOfClients; ++i){
            ClientInfo client = new ClientInfo(addresses[i], clientIDS[i], times[i]);
            client.changed = changed[i];
            client.connected = connected[i];
            client.diff = diffs[i];
            client.error = errors[i];
            client.eventsGotten = eventsGotten[i];
            client.eventsPut = eventsPut[i];
            client.lastActivity = lastActivities[i];
            client.samplesGotten = samplesGotten[i];
            client.samplesPut = samplesPut[i];
            client.timeLastActivity = timeLastActivities[i];
            client.waitEvents = waitEvents[i];
            client.waitSamples = waitSamples[i];
            client.waitTimeout = waitTimeouts[i];
            clientInfo[i] = client;
        }

        serverController.updateClients(clientInfo);
    }*/



