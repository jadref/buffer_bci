package nl.dcc.buffer_bci.bufferserverservice;

import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.res.Resources;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.net.wifi.WifiManager.WifiLock;
import android.os.Bundle;
import android.os.Environment;
import android.os.IBinder;
import android.os.PowerManager;
import android.os.PowerManager.WakeLock;
import android.support.v4.app.NotificationCompat;
import android.util.Log;
import nl.dcc.buffer_bci.monitor.BufferMonitor;
import nl.fcdonders.fieldtrip.bufferserver.BufferServer;

import java.io.File;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;

public class BufferServerService extends Service {

    public static final String TAG = BufferServerService.class.toString();
    private final IntentFilter intentFilter = new IntentFilter(C.FILTER);
    private BufferServer buffer;
    private BufferMonitor monitor;
    private WakeLock wakeLock;
    private WifiLock wifiLock;


    private final BroadcastReceiver mMessageReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(final Context context, Intent intent) {
            Log.i(TAG, "Dealing with Flush request");
            switch (intent.getIntExtra(C.MESSAGE_TYPE, -1)) {
                case C.REQUEST_PUT_HEADER:
                    if ( buffer!= null ) buffer.putHeader(0, 0, 0);
                    break;
                case C.REQUEST_FLUSH_HEADER:
                    if ( buffer!= null ) buffer.flushHeader();
                    break;
                case C.REQUEST_FLUSH_SAMPLES:
                    if ( buffer!= null ) buffer.flushSamples();
                    break;
                case C.REQUEST_FLUSH_EVENTS:
                    if ( buffer!= null ) buffer.flushEvents();
                    break;
                case C.BUFFER_INFO_BROADCAST:
                    if ( monitor != null ) monitor.sendAllInfo();
                default:
            }
        }
    };

    @Override
    public IBinder onBind(final Intent intent) {
        return null;
    }

    /**
     * Called when the service is stopped. Stops the buffer.
     */
    @Override
    public void onDestroy() {
        Log.i(TAG, "Stopping Buffer Service.");
        this.unregisterReceiver(mMessageReceiver);
        if (buffer != null) {
            buffer.stopBuffer();
        }
        if (monitor != null) {
            monitor.stopMonitoring();
        }
        if (wakeLock != null) {
            wakeLock.release();
        }
        if (wifiLock != null) {
            wifiLock.release();
        }
        buffer=null;
        monitor=null;
    }

    @Override
    public int onStartCommand(final Intent intent, final int flags, final int startId) {
        //android.os.Debug.waitForDebugger();
        // If no buffer is running.
        if (wakeLock==null && wifiLock==null ) { // Get Wakelocks

            final PowerManager powerManager = (PowerManager) getSystemService(POWER_SERVICE);
            wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK,
                    C.WAKELOCKTAG);
            wakeLock.acquire();

            final WifiManager wifiMan = (WifiManager) getSystemService(WIFI_SERVICE);
            wifiLock = wifiMan.createWifiLock(C.WAKELOCKTAGWIFI);
            wifiLock.acquire();

        }
        // Get the currently used ip-address
        final int port = intent.getIntExtra("port", 1972);
        final WifiInfo wifiInf = ((WifiManager) getSystemService(WIFI_SERVICE)).getConnectionInfo();
        final int ipAddress = wifiInf.getIpAddress();
        final String ip = String.format(Locale.ENGLISH, "%d.%d.%d.%d",
                ipAddress & 0xff, ipAddress >> 8 & 0xff,
                ipAddress >> 16 & 0xff, ipAddress >> 24 & 0xff);
        String saveDirName="";

        if ( buffer==null ) {
            final int sampleBuffSize = intent.getIntExtra("nSamples", 100);
            final int eventBuffSize = intent.getIntExtra("nEvents", 100);
            // Create a buffer and start it.

            if (isExternalStorageWritable()) {
                Log.i(TAG, "External storage is writable");
                Date now = new Date();
                String session = (new java.text.SimpleDateFormat("yyMMdd", Locale.US)).format(now);
                String block = (new java.text.SimpleDateFormat("HHmm", Locale.US)).format(now);
                File savedir = new File(getExternalFilesDir(null),
                        "raw_buffer"+ "/" + session + "/" + block);
                savedir.mkdirs();
                if ( !savedir.canWrite()) {
                    Log.e(TAG, "Save session directory not created :" + savedir.getPath());
                } else {
                    saveDirName=savedir.getPath();
                    Log.i(TAG, "Saving to directory: " + saveDirName);
                    buffer = new BufferServer(port, sampleBuffSize, eventBuffSize, savedir);
                }
            }

            if (buffer == null) {
                saveDirName="";
                Log.i(TAG, "External storage is sadly not writable");
                Log.w(TAG, "Storage is not writable. I am not saving the data.");
                buffer = new BufferServer(port, sampleBuffSize, eventBuffSize);
            }
            monitor = new BufferMonitor(this, ip + ":" + port, System.currentTimeMillis());
            buffer.addMonitor(monitor);

            // Start the buffer and Monitor
            buffer.start();
            Log.i(TAG, "Buffer started");
            monitor.start();
            Log.i(TAG, "Buffer monitor started.");
        }


        if (buffer != null) {
            this.registerReceiver(mMessageReceiver, intentFilter);
            Log.i(TAG, "Registered receiver with buffer:" + buffer.getName());
        }

        Log.i(TAG, "Buffer Service Running");

        // Create notification text
        final Resources res = getResources();
        final String notification_text;
        if ( saveDirName == null ) {
            notification_text =
                    String.format(res.getString(R.string.notification_text_host), ip + ":" + port)
                            + "      " + res.getString(R.string.notification_text_nosavedir);
        } else {
            notification_text =
                       String.format(res.getString(R.string.notification_text_host), ip + ":" + port)
                            + "      " + String.format(res.getString(R.string.notification_text_savedir), saveDirName);
        }

        final NotificationCompat.Builder mBuilder = new NotificationCompat.Builder(
                this)
                .setSmallIcon(R.drawable.ic_launcher)
                .setContentTitle(res.getString(R.string.notification_title))
                .setContentText(notification_text);

        // Turn this service into a foreground service
        startForeground(1, mBuilder.build());
        Log.i(TAG, "Buffer Server Service moved to foreground.");

        return START_NOT_STICKY;
    }

    /* Checks if external storage is available for read and write */
    public boolean isExternalStorageWritable() {
        String state = Environment.getExternalStorageState();
        return Environment.MEDIA_MOUNTED.equals(state);
    }
}
