package edu.nl.ru.fieldtripclientsservice.threads;

import android.util.Log;
import edu.nl.ru.fieldtripclientsservice.base.AndroidHandle;
import edu.nl.ru.fieldtripclientsservice.base.Argument;
import edu.nl.ru.fieldtripclientsservice.base.ThreadBase;
import edu.nl.ru.fieldtripclientsservice.threads.analysis.Classifier;
import edu.nl.ru.fieldtripclientsservice.threads.analysis.ClassifierResult;
import edu.nl.ru.linalg.Matrix;
import edu.nl.ru.linalg.WelchOutputType;
import edu.nl.ru.miscellaneous.ArrayFunctions;
import edu.nl.ru.miscellaneous.Tuple;
import edu.nl.ru.miscellaneous.Windows;
import nl.fcdonders.fieldtrip.bufferclient.BufferClientClock;
import nl.fcdonders.fieldtrip.bufferclient.BufferEvent;
import nl.fcdonders.fieldtrip.bufferclient.Header;
import nl.fcdonders.fieldtrip.bufferclient.SamplesEventsCount;
import org.apache.commons.math3.linear.RealVector;

import java.io.*;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

/**
 * Created by Pieter on 23-2-2015.
 * Continuous classifying of data from the buffer and sending events back
 */
public class ContinuousClassifier extends ThreadBase {

    private static final String TAG = ContinuousClassifier.class.toString();

    private String bufferHost;
    private String endValue;
    private String predictionEventType;
    private String baselineEventType;
    private String endType;
    private String baselineEnd;
    private String baselineStart;
    private Integer nBaselineStep;
    private int bufferPort;
    private Double overlap;
    private Double predictionFilter;
    private Integer sampleTrialMs;
    private Integer sampleStepMs;
    private Integer timeoutMs;
    private boolean normalizeLatitude;
    private List<Classifier> classifiers;
    private BufferClientClock C;
    private Integer sampleTrialLength;
    private Integer sampleStep;
    private Float fs;
    private Header header;

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

    /**
     * Load the linear classifier data from a file on the android device
     *
     * @param rows    The number of rows it should have
     * @param columns The number of columns is should have
     * @return List of matrices that are used for a linear classifier.
     */
    private static List<Matrix> loadWFromFile(int rows, int columns, AndroidHandle android) {

        InputStream is = null;
        try {
            is = android.openAsset("w.csv");
        } catch (IOException e) {
            Log.e(TAG, Log.getStackTraceString(e));
        }

        List<Matrix> matrices = new LinkedList<Matrix>();
        BufferedReader br = null;
        String line;
        String cvsSplitBy = ",";

        try {
            br = new BufferedReader(new InputStreamReader(is));
            while ((line = br.readLine()) != null) {
                // use comma as separator
                String[] items = line.split(cvsSplitBy);
                Matrix m = new Matrix(ArrayFunctions.fromString(items)).reshape(rows, columns);
                matrices.add(m);
            }
        } catch (FileNotFoundException e) {
            Log.e(TAG, Log.getStackTraceString(e));
        } catch (IOException e) {
            Log.e(TAG, Log.getStackTraceString(e));
        } finally {
            if (br != null) {
                try {
                    br.close();
                } catch (IOException e) {
                    Log.e(TAG, Log.getStackTraceString(e));
                }
            }
        }
        return matrices;
    }

    /**
     * Compute the necessary variable using the variables that were set by the user. Throws an error if to few variables
     * are set.
     */
    private void setNullFields() {
        // Set trial length
        if (header != null) {
            fs = header.fSample;
        } else {
            throw new RuntimeException("First connect to the buffer");
        }
        if (sampleTrialLength == null) {
            sampleTrialLength = 0;
            if (sampleTrialMs != null) {
                Float ret = sampleTrialMs / 1000 * fs;
                sampleTrialLength = ret.intValue();
            } else {
                throw new IllegalArgumentException("sampleTrialLength and sampleTrialMs should not both be zero");
            }
        }

        // Set windows
        for (Classifier c : classifiers) {
            sampleTrialLength = c.getSampleTrialLength(sampleTrialLength);
        }

        // Set wait time
        if (sampleStepMs != null) {
            sampleStep = Double.valueOf(Math.round(sampleStepMs / 1000.0 * fs)).intValue();
        } else {
            sampleStep = Long.valueOf(Math.round(sampleTrialLength * overlap)).intValue();
        }
    }

    /**
     * Connects to the buffer
     */
    private void connect() {
        while (header == null) {
            try {
                Log.i(TAG, "Connecting to " + bufferHost + ":" + bufferPort);
					 if ( !C.isConnected() ) {
						  C.connect(hostname, port);
					 }
                //C.setAutoReconnect(true);
                if (C.isConnected()) {
                    header = C.getHeader();
                }
            } catch (IOException e) {
                header = null;
            }
            if (header == null) {
                Log.w(TAG, "Invalid Header... waiting");
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    Log.e(TAG, Log.getStackTraceString(e));
                }
            }
        }
    }

    @Override
    public Argument[] getArguments() {
        final Argument[] arguments = new Argument[17];
        arguments[0] = new Argument("Buffer address", "localhost");
        arguments[1] = new Argument("Buffer port", 1972, true);
        arguments[2] = new Argument("Header", null);
        arguments[3] = new Argument("End type", "stimulus.test");
        arguments[4] = new Argument("End value", "end");
        arguments[5] = new Argument("Prediction event type", "classifier.prediction");
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
        this.connect();
        this.setNullFields();
        Log.v(TAG, this.toString());

        // Get information of the buffer
        int nEvents = header.nEvents;
        int nSamples = header.nSamples;

        // Initialize initial variables. These are used later on to store the data.
        Matrix baseLineVal = Matrix.zeros(classifiers.get(0).getOutputSize() - 1, 1);
        Matrix baseLineVar = Matrix.ones(classifiers.get(0).getOutputSize() - 1, 1);
        boolean baselinePhase = false;
        int nBaseline = 0;
        Matrix dvBaseline = null;
        Matrix dv2Baseline = null;
        Matrix dv = null;
        boolean endExpected = false;
        long t0 = 0;

        // Run the code
        run = true;
        while (!endExpected && run) {
            // Getting data from buffer
            SamplesEventsCount status = null;
            // Block until there are new events
            try {
                Log.d(TAG, "Waiting for " + (nSamples + sampleTrialLength + 1) + " samples");
                status = C.waitForSamples(nSamples + sampleTrialLength + 1, this.timeoutMs);
            } catch (IOException e) {
                Log.e(TAG, Log.getStackTraceString(e));
            }
            if (status.nSamples < header.nSamples) {
                Log.i(TAG, "Buffer restart detected");
                nSamples = status.nSamples;
                dv = null;
                continue;
            }

            // Logging stuff when nothing is happening
            if (System.currentTimeMillis() - t0 > 5000) {
                Log.i(TAG, String.format("%5.3f seconds, %d samples, %d events", System.currentTimeMillis() / 1000.,
                        status.nSamples, status.nEvents));
                t0 = System.currentTimeMillis();
            }

            // Process any new data
            int onSamples = nSamples;
            int[] startIdx = Matrix.range(onSamples, status.nSamples - sampleTrialLength - 1, sampleStep);
            if (startIdx.length > 0) nSamples = startIdx[startIdx.length - 1] + sampleStep;

            for (int fromId : startIdx) {
                // Get the data
                int toId = fromId + sampleTrialLength - 1;
                Matrix data = null;
                try {
                    data = new Matrix(new Matrix(C.getDoubleData(fromId, toId)).transpose());
                } catch (IOException e) {
                    Log.e(TAG, Log.getStackTraceString(e));
                }
                Log.d(TAG, String.format("Got data @ %d->%d samples", fromId, toId));

                // Apply all classifiers and add results
                Matrix f = new Matrix(classifiers.get(0).getOutputSize(), 1);
                Matrix fraw = new Matrix(classifiers.get(0).getOutputSize(), 1);
                ClassifierResult result;
                for (Classifier c : classifiers) {
                    result = c.apply(data);
                    f = new Matrix(f.add(result.f));
                    fraw = new Matrix(fraw.add(result.fraw));
                }

                // Postprocessing of alpha lat score
                double[] dvColumn = f.getColumn(0);
                f = new Matrix(dvColumn.length - 1, 1);
                f.setColumn(0, Arrays.copyOfRange(dvColumn, 1, dvColumn.length));
                if (normalizeLatitude) f.setEntry(0, 0, (dvColumn[0] - dvColumn[1]) / (dvColumn[0] + dvColumn[1]));
                else f.setEntry(0, 0, dvColumn[0] - dvColumn[1]);

                // Smooth the classifiers
                if (dv == null || predictionFilter == null) dv = f;
                else {
                    if (predictionFilter > 0.) {
                        dv = new Matrix(dv.scalarMultiply(predictionFilter).add(f.scalarMultiply(1. -
                                predictionFilter)));
                    }
                }
                Log.d(TAG, "Result from classifiers: \n" + Arrays.toString(dv.getColumn(0)));

                // Update baseline
                if (baselinePhase) {
                    nBaseline++;
                    dvBaseline = new Matrix(dvBaseline.add(dv));
                    dv2Baseline = new Matrix(dv2Baseline.add(dv.multiplyElements(dv)));
                    if (nBaselineStep != null && nBaseline > nBaselineStep) {
                        Log.i(TAG, "Baseline timeout\n");
                        baselinePhase = false;
                        Tuple<Matrix, Matrix> ret = baselineValues(dvBaseline, dv2Baseline, nBaseline);
                        baseLineVal = ret.x;
                        baseLineVar = ret.y;
                    }
                }

                // Compare to baseline
                dv = new Matrix(dv.subtract(baseLineVal)).divideElements(baseLineVar);

                // Send prediction event
                Log.d(TAG, "SEND event value: " + Arrays.toString(dv.getColumn(0)));
                try {
                    BufferEvent event = new BufferEvent(predictionEventType, dv.getColumn(0), fromId);
                    C.putEvent(event);
                } catch (IOException e) {
                    Log.e(TAG, Log.getStackTraceString(e));
                }
            }

            // Deal with events
            if (status.nEvents > nEvents) {
                BufferEvent[] events = null;
                try {
                    events = C.getEvents(nEvents, status.nEvents - 1);
                } catch (IOException e) {
                    Log.e(TAG, Log.getStackTraceString(e));
                }

                for (BufferEvent event : events) {
                    String type = event.getType().toString();
                    String value = event.getValue().toString();
                    Log.i(TAG, "GET EVENT (" + event.sample + "): " + type + ", value: " + value);
                    if (type.equals(endType) && value.equals(endValue)) {
                        Log.i(TAG, "End expected");
                        endExpected = true;
                    } else if (type.equals(baselineEventType) && value.equals(baselineEnd)) {
                        Log.i(TAG, "Baseline end event received");
                        baselinePhase = false;
                        Tuple<Matrix, Matrix> ret = baselineValues(dvBaseline, dv2Baseline, nBaseline);
                        baseLineVal = ret.x;
                        baseLineVar = ret.y;
                    } else if (type.equals(baselineEventType) && value.equals(baselineStart)) {
                        Log.i(TAG, "Baseline start event received");
                        baselinePhase = true;
                        nBaseline = 0;
                        dvBaseline = Matrix.zeros(classifiers.get(0).getOutputSize() - 1, 1);
                        dv2Baseline = Matrix.ones(classifiers.get(0).getOutputSize() - 1, 1);
                    }

                }
                nEvents = status.nEvents;
            }
        }
        try {
            C.disconnect();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * Computes the baseline values after the baseline has ended
     *
     * @param dvBaseline  the dv values of the baseline
     * @param dv2Baseline the squared dv values of the baseline
     * @param nBaseline   the number of samples the dv is based on
     * @return The mean and variance of the baseline
     */
    public Tuple<Matrix, Matrix> baselineValues(Matrix dvBaseline, Matrix dv2Baseline, int nBaseline) {
        double scale = 1. / nBaseline;
        Matrix baseLineVal = new Matrix(dvBaseline.scalarMultiply(scale));
        Matrix baseLineVar = new Matrix(new Matrix(dv2Baseline.subtract(dvBaseline.multiplyElements(dvBaseline)
                .scalarMultiply(scale))).abs().scalarMultiply(scale)).sqrt();
        Log.i(TAG, "New baseline value: " + Arrays.toString(baseLineVal.getColumn(0)));
        Log.i(TAG, "New baseline variance: " + Arrays.toString(baseLineVar.getColumn(0)));
        return new Tuple<Matrix, Matrix>(baseLineVal, baseLineVar);
    }

    @Override
    public void validateArguments(Argument[] arguments) {

    }

    public String toString() {
        return "\nContinuousClassifier with parameters:" + "\nBuffer host:  \t" + bufferHost + "\nBuffer port:  \t" +
                bufferPort + "\nHeader:\n     \t" + header + "\nEnd type:     \t" + endType + "\nEnd value:    \t" +
                endValue + "\npredictionEventType:\t" + predictionEventType +
                "\nSample trial ms:\t" + sampleTrialMs + "\nsampleTrialLength:\t" + sampleTrialLength + "\nOverlap:\t" +
                overlap + "\nsampleStepMs:      \t" + sampleStepMs + "\npredictionFilter:\t" + predictionFilter +
                "\nTimeoutMs:\t" + timeoutMs +
                "\nBaselineEnd \t" + baselineEnd +
                "\nBaselineStart\t" + baselineStart +
                "\nBaselineStep\t" + nBaselineStep +
                "\nNormalizeLat\t" + normalizeLatitude +
                "\nFs           \t" + fs;
    }
}
