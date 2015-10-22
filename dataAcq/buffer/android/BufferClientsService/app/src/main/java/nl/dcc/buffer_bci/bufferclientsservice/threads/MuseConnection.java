package nl.dcc.buffer_bci.bufferclientsservice.threads;

import android.util.Log;
import com.interaxon.libmuse.*;
import nl.dcc.buffer_bci.bufferclientsservice.base.Argument;
import nl.dcc.buffer_bci.bufferclientsservice.base.ThreadBase;
import nl.fcdonders.fieldtrip.bufferclient.BufferClient;
import nl.fcdonders.fieldtrip.bufferclient.DataType;
import nl.fcdonders.fieldtrip.bufferclient.Header;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

/**
 * Created by Pieter Marsman on 6-4-2015.
 * Connects to the muse using a bluetooth connection. Sends the EEG data to the fieldtrip buffer.
 */
public class MuseConnection extends ThreadBase {

    public final String TAG = MuseConnection.class.toString();
    private Muse muse = null;
    private ConnectionListener connectionListener = null;
    private DataListener dataListener = null;
    private BufferClient client = null;
    private boolean dataTransmission = true;
    private int nSamples;
    private String address;
    private int port;
    private int nChannels;
    private int samplingFrequency;
    private int dataType;
    private int blockSize;

    @Override
    public Argument[] getArguments() {
        Argument[] arguments = new Argument[] {
            new Argument("Buffer Address", "localhost"),
            new Argument("Buffer port", 1972, true),
            new Argument("Channels", 4, true),
            new Argument("Sampling frequency", 220, true),
            new Argument("Datatype", DataType.FLOAT64, true),
            new Argument("BlockSize", 10, true)
        };
        return arguments;
    }

    private void initialize() {
        address = arguments[0].getString();
        port = arguments[1].getInteger();
        nChannels = arguments[2].getInteger();
        samplingFrequency = arguments[3].getInteger();
        dataType = arguments[4].getInteger();
        blockSize = arguments[5].getInteger();
        androidHandle.updateStatus("Address: " + address + ":" + String.valueOf(port));
        Log.d(TAG, this.toString());
    }

    @Override
    public String getName() {
        return "MuseConnection";
    }

    /**
     * Initializes the connections to the buffer and muse. Processing and sending data is done with callbacks.
     * mainloop stays alive to update the UI.
     */
    @Override
    public void mainloop() {
        initialize();

        // Connect to the muse headband
        connectionListener = new ConnectionListener();
        dataListener = new DataListener(blockSize, nChannels);
        Log.i(TAG, "libmuse version=" + LibMuseVersion.SDK_VERSION);
        getMuse();
        connectToMuseAndRun();

        // connect to the buffer
        client = new BufferClient();
        connectToBuffer();
        uploadHeaderToBuffer(nChannels, samplingFrequency, dataType);

        // For showing purposes
        long startMs = Calendar.getInstance().getTimeInMillis();
        long elapsedMs = 0;
        nSamples = 0;

        // Keep the thread alive while it waits for data and processes it. Once every 5 sec the progress is shown.
        run = true;
        while (run) {
            long now = Calendar.getInstance().getTimeInMillis();
            if (startMs + elapsedMs > now + 5000) {
                androidHandle.updateStatus(nSamples + "(" + elapsedMs / 1000 + ")");
                Log.i(TAG, "Elapsed time: " + elapsedMs + ". nSamples: " + nSamples);
            }
        }
    }

    /**
     * Get the muse headband that is first paired with the device
     */
    private void getMuse() {
        while (muse == null) {
            Log.i(TAG, "Refreshing paired muses list");
            MuseManager.refreshPairedMuses();
            List<Muse> pairedMuses = MuseManager.getPairedMuses();
            if (pairedMuses.size() > 0) muse = pairedMuses.get(0);
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                e.printStackTrace();
                break;
            }
        }
    }

    /**
     * Connect to the detected muse.
     */
    private void connectToMuseAndRun() {
        ConnectionState state = muse.getConnectionState();
        if (state == ConnectionState.CONNECTED || state == ConnectionState.CONNECTING) {
            Log.w("Muse Headband", "doesn't make sense to connect second time to the same muse");
            return;
        }
        muse.registerConnectionListener(connectionListener);
        muse.registerDataListener(dataListener, MuseDataPacketType.EEG);
        muse.setPreset(MusePreset.PRESET_14);
        muse.enableDataTransmission(dataTransmission);
        /**
         * In most cases libmuse native library takes care about
         * exceptions and recovery mechanism, but native code still
         * may throw in some unexpected situations (like bad bluetooth
         * connection). Print all exceptions here.
         */
        try {
            muse.runAsynchronously();
        } catch (Exception e) {
            Log.e(TAG, Log.getStackTraceString(e));
        }
    }

    /**
     * Disconnect from the connected muse
     */
    private void disconnectMuse() {
        if (muse != null && muse.getConnectionState()==ConnectionState.CONNECTED) {
            /**
             * true flag will force libmuse to unregister all listeners,
             * BUT AFTER disconnecting and sending disconnection event.
             * If you don't want to receive disconnection event (for ex.
             * you call disconnect when application is closed), then
             * unregister listeners first and then call disconnect:
             * muse.unregisterAllListeners();
             * muse.disconnect(false);
             */
            muse.unregisterAllListeners();
            muse.disconnect(true);
        }
        muse=null;
    }

    /**
     * Configure the data receiver and processor.
     */
    private void startSending() {
    }

    /**
     * Connect to the buffer for sending events and receiving data.
     */
    private void connectToBuffer() {
        while (!client.isConnected()) {
            Log.i(TAG, "Connecting to " + address + ":" + port);
            androidHandle.updateStatus("Connecting to " + address + ":" + port);
            try {
                client.connect(address, port);
            } catch (IOException ex) {
                Log.e(TAG, "Could not connect to buffer. Maybe the address or port is wrong?");
            }
            if (!client.isConnected()) {
                androidHandle.updateStatus("Couldn't connect. Waiting");
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    /**
     * Upload the header information to the buffer.
     *
     * @param channels          The number of nChannels
     * @param samplingFrequency The expected sampling frequency
     * @param dataType          The datatype.
     */
    private void uploadHeaderToBuffer(int channels, int samplingFrequency, int dataType) {
        Header hdr = new Header(channels, samplingFrequency, dataType);
        try {
            client.putHeader(hdr);
        } catch (IOException e) {
            e.printStackTrace();
        }
        Log.i(TAG, "Uploaded header to the buffer");
        Log.i(TAG, hdr.toString());
    }

    /**
     * Not implemented yet
     *
     * @param arguments arguments to be validated
     */
    @Override
    public void validateArguments(Argument[] arguments) {

    }

    @Override
    public void stop() {
        run=false;
        disconnectMuse();
        if (client != null) try {
            client.disconnect();
        } catch (IOException e) {
            Log.e(TAG, Log.getStackTraceString(e));
        } finally {
            client = null;
        }
        super.stop();
    }

    public String toString() {
        return "MuseConnection with parameters: \n" +
                "Buffer: " + address + ":" + String.valueOf(port) + "\n" +
                "Channels: " + String.valueOf(nChannels) + "\n" +
                "Sampling frequency: " + String.valueOf(samplingFrequency) + "\n" +
                "Datatype: " + String.valueOf(dataType);
    }

    /**
     * Listens to the muse and when it connects gets information from it.
     */
    class ConnectionListener extends MuseConnectionListener {

        @Override
        public void receiveMuseConnectionPacket(MuseConnectionPacket p) {
            final ConnectionState current = p.getCurrentConnectionState();
            final String status = p.getPreviousConnectionState().toString() +
                    " -> " + current;
            final String full = "Muse " + p.getSource().getMacAddress() + " " + status;
            // Check if we lost the connection
            if ( p.getPreviousConnectionState()==ConnectionState.CONNECTED
                 && p.getCurrentConnectionState()==ConnectionState.DISCONNECTED ){
                stop();
            }
            Log.i(TAG,full);
        }
    }

    /**
     * Data listener will be registered to listen for: Accelerometer,
     * Eeg and Relative Alpha bandpower packets. In all cases we will
     * update UI with new values.
     * We also will log message if Artifact packets contains "blink" flag.
     * DataListener methods will be called from execution thread. If you are
     * implementing "serious" processing algorithms inside those listeners,
     * consider to create another thread.
     */
    class DataListener extends MuseDataListener {
        public final String TAG = DataListener.class.toString();
        double [][] dataMatrix; // buffer to store data before sending to the real buffer
        int curPoint=0; // current position in the local buffer

        public DataListener(int blockSize, int nChannels) {
            dataMatrix = new double[blockSize][];
            for ( int bi=0; bi<dataMatrix.length; bi++){
                dataMatrix[bi] = new double[nChannels];
                // zero initially
                for ( int i=0; i<dataMatrix[bi].length; i++) {
                    dataMatrix[bi][i] = 0.0;
                }
            }
        }

        @Override
        public void receiveMuseDataPacket(MuseDataPacket p) {
            switch (p.getPacketType()) {
                case EEG:
                    updateEEG(p.getValues());
                    break;
                default:
                    break;
            }
        }

        @Override
        public void receiveMuseArtifactPacket(MuseArtifactPacket p) {
            if (p.getHeadbandOn() && p.getBlink()) {
                Log.i(TAG, "blink");
            }
        }

        private void updateEEG(final ArrayList<Double> data) {
            //Log.v(TAG, "EEG: " + data.toString());
            for (int i = 0; i < data.size() && i < dataMatrix[0].length; i++) {
                dataMatrix[curPoint][i] = data.get(i);
            }
            curPoint += 1;
            nSamples += 1;
            // block of data ready, send it all to the buffer-server
            if ( curPoint==dataMatrix.length ) {
                try {
                    if ( client != null ) client.putData(dataMatrix);
                } catch (IOException e) {
                    Log.e(TAG, Log.getStackTraceString(e));
                }
                // TODO: Zero the dataMatrix as well?
                curPoint = 0;
            }
        }
    }
}
