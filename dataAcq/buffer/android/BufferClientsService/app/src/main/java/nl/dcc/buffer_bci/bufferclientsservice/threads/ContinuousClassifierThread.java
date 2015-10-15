package nl.dcc.buffer_bci.bufferclientsservice.threads;

import android.os.Environment;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;

import nl.dcc.buffer_bci.bufferclientsservice.base.Argument;
import nl.dcc.buffer_bci.signalprocessing.ContinuousClassifier;
import nl.dcc.buffer_bci.bufferclientsservice.base.ThreadBase;

/**
 * Created by Pieter on 23-2-2015.
 * Continuous classifying of data from the buffer and sending events back
 */
public class ContinuousClassifierThread extends ThreadBase {

    private static final String TAG = ContinuousClassifier.class.getSimpleName();

    protected String hostname ="localhost";
    protected int port = 1972;
    protected Integer timeout_ms = 1000;
    protected Integer trialLength_ms  =-1;
    protected Integer step_ms  = -1;
    protected String clsfrFile;
    private ContinuousClassifier clsfr=null;

    @Override
    public Argument[] getArguments() {
        final Argument[] arguments = new Argument[18];
        arguments[0] = new Argument("Buffer address", "localhost");
        arguments[1] = new Argument("Buffer port", 1972, true);
        arguments[2] = new Argument("Header", null);
        arguments[3] = new Argument("End type", "stimulus.test");
        arguments[4] = new Argument("End value", "end");
        arguments[5] = new Argument("Prediction event type", "alphaLat");
        arguments[6] = new Argument("Baseline event type", "stimulus.startbaseline");
        arguments[7] = new Argument("Baseline end", null);
        arguments[8] = new Argument("Baseline start", "start");
        arguments[9] = new Argument("N Baseline step", 5000, true);
        arguments[10] = new Argument("Overlap", .5, true);
        arguments[11] = new Argument("Timeout ms", 1000, true);
        arguments[12] = new Argument("Sample step ms", -1, true);
        arguments[13] = new Argument("Prediction filter", -1.0, true);
        arguments[14] = new Argument("Sample trial length", 25, true);
        arguments[15] = new Argument("Sample trial ms", -1, true);
        arguments[16] = new Argument("Normalize latitude", true);
        arguments[17] = new Argument("Clsfr file","clsfr.txt");
        return arguments;
    }

    /**
     * Initializes the attributes of this class
     */
    private void initialize() {
        this.hostname = arguments[0].getString();
        this.port = arguments[1].getInteger();
        this.timeout_ms = arguments[11].getInteger();
        this.step_ms = arguments[12].getInteger();
        this.trialLength_ms = arguments[15].getInteger();
        this.clsfrFile = arguments[17].getString();
    }

    @Override
    public String getName() {
        return "ContinuousClassifier";
    }

    @Override
    public void mainloop() {// Initialize the classifier and connect to the buffer
        initialize();
        clsfr = new ContinuousClassifier(hostname,port,timeout_ms);
        InputStream clsfrReader=null;
        if ( isExternalStorageReadable() ){
            try {
                clsfrReader=androidHandle.openReadFile(clsfrFile);
            } catch ( FileNotFoundException e ) {
                e.printStackTrace();
            } catch ( IOException e ) {
                e.printStackTrace();
            }
        }
        if ( clsfrReader == null ){ // fall back on the resources directory
            clsfrReader=this.getClass().getClassLoader().getResourceAsStream("assets/"+clsfrFile);
        }
        if ( clsfrReader==null) {
            Log.w(TAG, "Huh, couldn't open classifier file: " + clsfrFile);
            Log.w(TAG, "Aborting!" + clsfrFile);
            return;
        }
        clsfr.initialize(clsfrReader,trialLength_ms,step_ms);
        clsfr.mainloop();
        clsfr=null;
    }

    @Override public void stop() { if ( clsfr != null ) clsfr.stop(); }

    /* Checks if external storage is available for read and write */
    public boolean isExternalStorageWritable() {
        String state = Environment.getExternalStorageState();
        return Environment.MEDIA_MOUNTED.equals(state);
    }
    /* Checks if external storage is available to at least read */
    public boolean isExternalStorageReadable() {
        String state = Environment.getExternalStorageState();
        if (Environment.MEDIA_MOUNTED.equals(state) ||
                Environment.MEDIA_MOUNTED_READ_ONLY.equals(state)) {
            return true;
        }
        return false;
    }

    @Override
    public void validateArguments(Argument[] arguments) {
    }
}
