package nl.dcc.buffer_bci.android.bufferclientsservice.threads;

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

    /**
     * Creates a ContinuousClassifier using a file stored in the project
     *
     * @param android used for getting a file
     * @return List of classifiers (only one)
     */
    private static List<Classifier> createClassifiers(AndroidHandle android) {
        List<Matrix> Ws = loadWFromFile(3, 56, android);
        RealVector b = Matrix.zeros(5, 1).getColumnVector(0);
        Integer[] freqIdx = ArrayFunctions.toObjectArray(Matrix.range(0, 56, 1));
        String[] spectrumDescription = new String[]{"alphaL", "alphaR", "badness", "badChL", "badChR"};
        Integer[] isBad = new Integer[]{0, 0, 0};
        Classifier classifier = new Classifier(Ws, b, true, null, Windows.WindowType.HANNING, WelchOutputType
                .AMPLITUDE, null, freqIdx, 1, null, null, 128, 100., new Integer[]{0}, spectrumDescription, isBad);
        List<Classifier> classifiers = new LinkedList<Classifier>();
        classifiers.add(classifier);
        return classifiers;
    }

    @Override
    public Argument[] getArguments() {
        final Argument[] arguments = new Argument[17];
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
        return arguments;
    }

    /**
     * Initializes the attributes of this class
     */
    private void initialize() {
        this.bufferHost = arguments[0].getString();
        this.bufferPort = arguments[1].getInteger();
        this.header = null; //arguments[2];
        this.endType = arguments[3].getString();
        this.endValue = arguments[4].getString();
        this.predictionEventType = arguments[5].getString();
        this.baselineEventType = arguments[6].getString();
        this.baselineEnd = arguments[7].getString();
        this.baselineStart = arguments[8].getString();
        this.nBaselineStep = arguments[9].getInteger();
        this.overlap = arguments[10].getDouble();
        this.timeoutMs = arguments[11].getInteger();
        this.sampleStepMs = arguments[12].getInteger();
        this.predictionFilter = arguments[13].getDouble();
        this.sampleTrialLength = arguments[14].getInteger();
        this.sampleTrialMs = arguments[15].getInteger();
        this.normalizeLatitude = arguments[16].getBoolean();

        this.classifiers = createClassifiers(android);
        this.C = new BufferClientClock();
    }

    @Override
    public String getName() {
        return "ContinuousClassifier";
    }

    @Override
    public void mainloop() {
        // Initialize the classifier and connect to the buffer
        initialize();
    }
    @Override
    public void validateArguments(Argument[] arguments) {

    }

}
