package bmird.radboud.fieldtripbufferservicecontroller;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import bmird.radboud.fieldtripserverservice.monitor.BufferInfo;


public class FBServiceControllerBroadcastReceiver extends BroadcastReceiver {


    public FBServiceControllerBroadcastReceiver() {
    }
        @Override
        public void onReceive(final Context context, final Intent intent) {
            if (intent.getIntExtra(C.MESSAGE_TYPE, -1) == C.UPDATE) {
                boolean newBufferInfo = intent.getBooleanExtra(C.IS_BUFFER_INFO, false);
                boolean newClientInfo = intent.getBooleanExtra(C.IS_CLIENT_INFO, false);
                boolean newThreadInfo = intent.getBooleanExtra(C.IS_THREAD_INFO, false);

                Intent intent_for_MainActivity = new Intent(C.FILTER_FROM_SERVER);

                if(newBufferInfo){
                    intent_for_MainActivity.putExtra(C.IS_BUFFER_INFO, newBufferInfo);
                    BufferInfo bf = intent.getParcelableExtra(C.BUFFER_INFO);
                    intent_for_MainActivity.putExtra(C.BUFFER_INFO, intent.getParcelableExtra(C.BUFFER_INFO));
                    //Log.i(C.TAG, "From BroadcastReceiver Sending intent with BufferInfo to MainActivity");
                    context.sendBroadcast(intent_for_MainActivity);
                }

                if(newClientInfo){
                    intent_for_MainActivity.putExtra(C.IS_CLIENT_INFO, newClientInfo);
                    int numOfClients = intent.getIntExtra(C.CLIENT_N_INFOS, 0);
                    intent_for_MainActivity.putExtra(C.CLIENT_N_INFOS, numOfClients);
                    for (int k=0; k<numOfClients; ++k){
                        intent_for_MainActivity.putExtra(C.CLIENT_INFO+k, intent.getParcelableExtra(C.CLIENT_INFO+k));
                    }
                    Log.i(C.TAG, "From BroadcastReceiver Sending client info with "+numOfClients+" clients to MainActivity");
                    context.sendBroadcast(intent_for_MainActivity);
                }

                if(newThreadInfo){
                    intent_for_MainActivity.putExtra(C.IS_THREAD_INFO, newThreadInfo);
                    intent_for_MainActivity.putExtra(C.THREAD_INFO, intent.getParcelableExtra(C.THREAD_INFO));
                    intent_for_MainActivity.putExtra(C.THREAD_INDEX, intent.getIntExtra(C.THREAD_INDEX, 0));
                    intent_for_MainActivity.putExtra(C.THREAD_N_ARGUMENTS, intent.getIntExtra(C.THREAD_N_ARGUMENTS, 0));
                    int nArgs = intent.getIntExtra(C.THREAD_N_ARGUMENTS, 0);
                    for (int k = 0; k < nArgs; k++) {
                        intent_for_MainActivity.putExtra(C.THREAD_ARGUMENTS + k, intent.getSerializableExtra(C.THREAD_ARGUMENTS + k));
                    }
                    //Log.i(C.TAG, "From BroadcastReceiver Sending intent with ThreadInfo to MainActivity");
                    context.sendBroadcast(intent_for_MainActivity);
                }
            }


        }
}
