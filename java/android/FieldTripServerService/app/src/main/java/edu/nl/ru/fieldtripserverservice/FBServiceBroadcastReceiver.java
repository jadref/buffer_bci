package edu.nl.ru.fieldtripserverservice;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class FBServiceBroadcastReceiver extends BroadcastReceiver {

    public static final String TAG = FBServiceBroadcastReceiver.class.toString();

    @Override
    public void onReceive(Context context, Intent intent) {
        Log.i(TAG, "Got Flush request");
        Intent intent_for_bufferService = new Intent(C.FILTER);
        switch (intent.getIntExtra(C.MESSAGE_TYPE, -1)) {
            case C.REQUEST_PUT_HEADER:
                intent_for_bufferService.putExtra(C.MESSAGE_TYPE, C.REQUEST_PUT_HEADER);
                break;
            case C.REQUEST_FLUSH_HEADER:
                intent_for_bufferService.putExtra(C.MESSAGE_TYPE, C.REQUEST_FLUSH_HEADER);
                break;
            case C.REQUEST_FLUSH_SAMPLES:
                intent_for_bufferService.putExtra(C.MESSAGE_TYPE, C.REQUEST_FLUSH_SAMPLES);
                break;
            case C.REQUEST_FLUSH_EVENTS:
                intent_for_bufferService.putExtra(C.MESSAGE_TYPE, C.REQUEST_FLUSH_EVENTS);
                break;
            default:
        }
        context.sendBroadcast(intent_for_bufferService);
    }
}
