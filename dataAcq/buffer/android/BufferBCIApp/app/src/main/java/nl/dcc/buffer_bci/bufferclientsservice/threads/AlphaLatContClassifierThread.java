package nl.dcc.buffer_bci.bufferclientsservice.threads;

import android.os.Environment;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;

import nl.dcc.buffer_bci.bufferclientsservice.base.Argument;
import nl.dcc.buffer_bci.signalprocessing.AlphaLatContClassifier;
import nl.dcc.buffer_bci.signalprocessing.ContinuousClassifier;
import nl.dcc.buffer_bci.bufferclientsservice.base.ThreadBase;

public class AlphaLatContClassifierThread extends ThreadBase {

    private static final String TAG = AlphaLatContClassifierThread.class.getSimpleName();

	 String processName = TAG;
    protected String hostname ="localhost";
    protected int port = 1972;
    protected int timeout_ms = 1000;
    protected int trialLength_ms  =-1;
    protected int step_ms  = 100;
    protected String clsfrFile="clsfr_nf.txt";
    private ContinuousClassifier clsfr=null;
	 protected boolean compLat=true;
	 protected boolean normLat=true;

    @Override
    public Argument[] getArguments() {
        final Argument[] arguments = new Argument[]{
                new Argument("Buffer address", new String(hostname)), //0
                new Argument("Buffer port", port, true),
                new Argument("Timeout ms", timeout_ms, true),
                new Argument("End type", "stimulus.test"), //3
                new Argument("End value", "end"),
                new Argument("Prediction event type", "classifier.prediction"), //5
                new Argument("Baseline event type", "stimulus.startbaseline"),
                new Argument("Sample trial ms", trialLength_ms, true), //7
                new Argument("Sample step ms", step_ms, true), //8
                new Argument("Overlap", .5, true), //9
                new Argument("Prediction filter", -1.0, true), //10
                new Argument("Clsfr file",new String(clsfrFile)), //11
                new Argument("Compute Lateralizsation", compLat?1:0, true),//12
                new Argument("Normalize Lat", normLat?1:0, true)//13
        };
        return arguments;
    }

    /**
     * Initializes the attributes of this class
     */
    private void initialize() {
        this.hostname = arguments[0].getString();
        this.port = arguments[1].getInteger();
        this.timeout_ms = arguments[2].getInteger();
        this.trialLength_ms = arguments[7].getInteger();
        this.step_ms = arguments[8].getInteger();
        this.clsfrFile = arguments[11].getString();
        this.compLat   = arguments[12].getInteger()>0;
        this.normLat   = arguments[13].getInteger()>0;
    }

    @Override
    public String getName() {
        return TAG;
    }

    @Override
    public void mainloop() {// Initialize the classifier and connect to the buffer
        initialize();
		  InputStream clsfrReader = openClsfrFile(clsfrFile);
		  if ( clsfrReader == null ) {
            Log.e(TAG, "Aborting!" + clsfrFile);
				return;
		  }
        clsfr = new AlphaLatContClassifier(hostname,port,timeout_ms);
        clsfr.initialize(clsfrReader,trialLength_ms,step_ms);
        ((AlphaLatContClassifier)clsfr).setcomputeLateralization(compLat);
        ((AlphaLatContClassifier)clsfr).setnormalizeLateralization(normLat);
        clsfr.setprocessName(processName);
        clsfr.mainloop();
        clsfr=null;
    }

	 public InputStream openClsfrFile(String clsfrFile){
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
            Log.e(TAG, "Huh, couldn't open classifier file: " + clsfrFile);
            Log.e(TAG, "Aborting!" + clsfrFile);
        }
         return clsfrReader;
	 }


    @Override public void stop() {
        if ( clsfr != null ) clsfr.stop();
    }
    @Override public boolean isrunning(){ if ( clsfr!=null ) return clsfr.isrunning(); return false; }

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
