package nl.dcc.buffer_bci.android.bufferclientsservice.threads;

import java.io.InputStream;

import nl.dcc.buffer_bci.android.bufferclientsservice.base.Argument;
import nl.dcc.buffer_bci.signalprocessing.ContinuousClassifier;
import nl.dcc.buffer_bci.android.bufferclientsservice.base.AndroidHandle;
import nl.dcc.buffer_bci.android.bufferclientsservice.base.ThreadBase;

/**
 * Created by Pieter on 23-2-2015.
 * Continuous classifying of data from the buffer and sending events back
 */
public class ContinuousClassifierThread extends ThreadBase {

    private static final String TAG = ContinuousClassifier.class.getSimpleName();

    private ContinuousClassifier continuousClassifier;
    protected String hostname ="localhost";
    protected int port = 1972;
    protected Integer timeout_ms = 1000;
    protected Integer trialLength_ms  =-1;
    protected Integer step_ms  = -1;
    protected String clsfrFile;

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
        arguments[12] = new Argument("Sample step ms", 500, true);
        arguments[13] = new Argument("Prediction filter", 1.0, true);
        arguments[14] = new Argument("Sample trial length", 25, true);
        arguments[15] = new Argument("Sample trial ms", null);
        arguments[16] = new Argument("Normalize latitude", true);
        arguments[17] = new Argument("Clsfr file","res/clsfr.txt");
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
    public void mainloop() {
        // Initialize the classifier and connect to the buffer
        initialize();
        ContinuousClassifier clsfr = new ContinuousClassifier(hostname,port,timeout_ms);
        InputStream clsfrReader = this.getClass().getClassLoader().getResourceAsStream(clsfrFile);
        clsfr.initialize(clsfrReader,trialLength_ms,step_ms);
        clsfr.mainloop();
    }

    @Override
    public void validateArguments(Argument[] arguments) {
    }

}
