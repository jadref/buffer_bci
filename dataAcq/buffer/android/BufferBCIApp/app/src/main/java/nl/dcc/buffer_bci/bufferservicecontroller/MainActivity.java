package nl.dcc.buffer_bci.bufferservicecontroller;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.*;

import nl.dcc.buffer_bci.C;
import nl.dcc.buffer_bci.R;
import nl.dcc.buffer_bci.bufferservicecontroller.visualize.BubbleSurfaceView;
import nl.dcc.buffer_bci.bufferclientsservice.ThreadInfo;
import nl.dcc.buffer_bci.bufferclientsservice.base.Argument;
import nl.dcc.buffer_bci.monitor.BufferConnectionInfo;

import java.util.HashMap;


public class MainActivity extends Activity {

    public static String TAG = MainActivity.class.getSimpleName();

    public ServerController serverController=null;
    public ClientsController clientsController=null;

    private BroadcastReceiver mMessageReceiver;

    // Gui
    private TextView textView;
    private LinearLayout table; // table for the toggle switches controlling things
    private HashMap<Integer, Integer> threadToView; // mapping from threadID -> table Idx for the toggle view
    private BubbleSurfaceView surfaceView;
    //private HeartBeatTimer heartBeatTimer;

    @Override
    protected void onCreate(final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        //android.os.Debug.waitForDebugger();
        setContentView(R.layout.main_activity);
        textView = (TextView) findViewById(R.id.textView);
        table = (LinearLayout) findViewById(R.id.switches); // N.B. the switches for server/client defined in the resources...
        threadToView = new HashMap<Integer, Integer>();
        surfaceView = (BubbleSurfaceView) findViewById(R.id.surfaceView);

        serverController = new ServerController(this);
        if (serverController.isBufferServerServiceRunning()) {// check if already running
            serverController.reloadConnections();
        }
        clientsController = new ClientsController(this);
        if (clientsController.isThreadsServiceRunning()) {// check if already running
            clientsController.reloadAllThreads();
        }

        if (savedInstanceState == null) {
            IntentFilter intentFilter = new IntentFilter(C.SEND_UPDATE_INFO_TO_CONTROLLER_ACTION);
            mMessageReceiver = new BroadcastReceiver() {
                @Override
                public void onReceive(final Context context, Intent intent) {
                    updateServerController(intent);
                }
            };
            this.registerReceiver(mMessageReceiver, intentFilter);
        }

        // initialize the GUI for the first time.
        //updateServerGui();
        //updateClientsGui();
        //heartBeatTimer = new HeartBeatTimer();
        //heartBeatTimer.start();
    }

    @Override
    public void onStop() {
        super.onStop();
        this.unregisterReceiver(mMessageReceiver);
        //if (heartBeatTimer != null) heartBeatTimer.stopTimer();
    }

    @Override
    public void onDestroy() {
        stopClients();
        stopServer();
        super.onDestroy();
    }

    private void updateServerController(Intent intent) {
        if (intent.getBooleanExtra(C.IS_BUFFER_INFO, false)) {
            updateServerInfo(intent);
        }
        if (intent.getBooleanExtra(C.IS_BUFFER_CONNECTION_INFO, false)) {
            updateBufferConnectionInfo(intent);
        }
        if (intent.getBooleanExtra(C.IS_THREAD_INFO, false)) {
            updateThreadsInfo(intent);
        }
    }

    private void updateServerInfo(Intent intent) {
        serverController.buffer = intent.getParcelableExtra(C.BUFFER_INFO);
        if (!serverController.initalUpdateCalled) {
            serverController.initialUpdate();
        }
        serverController.updateBufferInfo();
        this.updateServerGui();
    }

    private void updateServerStatus() {
        boolean running=false;
        if (serverController != null) {
            running = serverController.isBufferServerServiceRunning();
        }
        ((Switch) table.getChildAt(0)).setChecked(running);
    }

    private void updateClientsStatus() {
        boolean running=false;
        if (clientsController != null) {
            running = clientsController.isThreadsServiceRunning();
        }
        ((Switch) table.getChildAt(1)).setChecked(running);
    }

    private void updateBufferConnectionInfo(Intent intent) {
        int numOfClients = intent.getIntExtra(C.BUFFER_CONNECTION_N_INFOS, 0);
        BufferConnectionInfo[] bufferConnectionInfo = new BufferConnectionInfo[numOfClients];
        for (int k = 0; k < numOfClients; ++k) {
            bufferConnectionInfo[k] = intent.getParcelableExtra(C.BUFFER_CONNECTION_INFO + k);
        }
        serverController.updateBufferConnections(bufferConnectionInfo);
        this.updateServerGui();
    }

    private void updateThreadsInfo(Intent intent) {
        ThreadInfo threadInfo=null;
        if ( intent.hasExtra(C.THREAD_INFO)) {
            try {
                threadInfo = intent.getParcelableExtra(C.THREAD_INFO);
            } catch ( Exception ex) {
                Log.d(TAG, "Couldn't unparcel the thread info......");
                return;
            }
        }
        int nArgs = intent.getIntExtra(C.THREAD_N_ARGUMENTS, 0);
        Argument[] arguments = new Argument[nArgs];
        for (int i = 0; i < nArgs; i++) {
            arguments[i] = (Argument) intent.getSerializableExtra(C.THREAD_ARGUMENTS + i);
        }
        clientsController.updateThreadInfoAndArguments(threadInfo, arguments);
        this.updateClientsGui();
    }

    // Gui
    private void updateServerGui() {
        if ( serverController != null ) {
            updateServerStatus();
            textView.setText(serverController.toString());
        }
    }

    private void updateClientsGui() {
        if ( clientsController==null ) return;
        updateClientsStatus();
        // TODO: This is all a bit of a mess with info spread over different locations and potentially mis-aligned...
        int[] threadIDs = clientsController.getAllThreadIDs();
        if (threadIDs.length != threadToView.size()) {
            table.removeViews(2, threadToView.size());
            threadToView.clear();
        }
        int newIndex = table.getChildCount();
        for (int threadID : threadIDs) {
            if (!threadToView.containsKey(threadID)) {
                String title = clientsController.getThreadTitle(threadID);
                Switch newSwitch = new Switch(this);
                newSwitch.setText(title);
                newSwitch.setOnClickListener(getThreadStarter(threadID));
                table.addView(newSwitch, newIndex);
                threadToView.put(threadID, newIndex);
                newIndex++;
            } else { // update the switch state based on the thread state
                int threadViewIdx = threadToView.get(threadID);
                boolean running = clientsController.getThreadRunning(threadID);
                Switch threadSwitch = ((Switch) table.getChildAt(threadViewIdx));
                threadSwitch.setChecked(running);
            }
        }
    }

    private View.OnClickListener getThreadStarter(final int threadID) {
        return new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Switch switchView = (Switch) view;
                if (switchView.isChecked())
                    clientsController.startThread(threadID);
                else
                    clientsController.stopThread(threadID);
            }
        };
    }

    //Interface
    public void startServer() {
        String serverName = "";
        if (!serverController.isBufferServerServiceRunning()) {
            serverName = serverController.startServerService();
        } else {
            serverController.reloadConnections();
        }
        updateServerGui();
    }

    public void startClients() {
        String clientsName = "";
        if (!clientsController.isThreadsServiceRunning()) {
            clientsName = clientsController.startThreadsService();
        } else { // query for the threads info
            clientsController.reloadAllThreads();
        }
        updateClientsGui();
    }

    public void stopServer() {
        boolean result = false;
        if (serverController.isBufferServerServiceRunning()) {
            result = serverController.stopServerService();
        }
        updateServerGui();
    }

    public void stopClients() {
        boolean result = false;
        if (clientsController.isThreadsServiceRunning()) {
            result = clientsController.stopThreadsService();
        }
        updateClientsGui();
    }

    public void onToggleServerSwitch(View view) {
        Switch switchView = (Switch) view;
        if (switchView.isChecked())
            startServer();
        else
            stopServer();
    }

    public void onToggleClientsSwitch(View view) {
        Switch switchView = (Switch) view;
        if (switchView.isChecked())
            startClients();
        else
            stopClients();
    }


//    protected class HeartBeatTimer extends Thread {
//        // Thread to monitor the status of the clients/server services
//        public boolean running = true;
//
//        @Override
//        public void run() {
////            while (running) {
////                runOnUiThread(new Runnable() {
////                    @Override
////                    public void run() {
////                        updateServerGui();
////                        updateClientsGui();
////                    }
////                });
////                try {
////                    Thread.sleep(1000);
////                } catch (final InterruptedException e) {
////                    // TODO Auto-generated catch block
////                    e.printStackTrace();
////                }
////            }
//        }
//        public void stopTimer() {
//            running = false;
//        }
//    }
}

