package nl.dcc.buffer_bci.signalprocessing;

import nl.dcc.buffer_bci.matrixalgebra.linalg.Matrix;
import nl.dcc.buffer_bci.matrixalgebra.linalg.WelchOutputType;
import nl.dcc.buffer_bci.matrixalgebra.miscellaneous.ArrayFunctions;
import nl.dcc.buffer_bci.matrixalgebra.miscellaneous.Tuple;
import nl.dcc.buffer_bci.matrixalgebra.miscellaneous.Windows;
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
public class ContinuousClassifier {

    private static final String TAG = ContinuousClassifier.class.getSimpleName();

    private String hostname ="localhost";
    private int port = 1972;
    private String endType = "stimulus.test";
    private String endValue = "end";
    private String predictionEventType = "classifier.prediction";
    private String baselineEventType = "stimulus.startbaseline";
    private String baselineEnd = null;
    private String baselineStart = "start";
    private Integer nBaselineStep = 5000;

    private Double overlap = .5;
    private Double predictionFilter = 1.0;
    private Integer sampleTrialMs = null;
    private Integer sampleStepMs = 100; // BUG: changing this shouldn't matter for anything else...
    private Integer timeoutMs = 1000;
    private boolean normalizeLatitude = true;
    private List<ERSPClassifier> classifiers;
    private BufferClientClock C = null;
    private Integer sampleTrialLength=-1;
    private Integer sampleStep=-1;
    private Float fs=-1.0f;
    private Header header=null;

	 static final String usage="java ContinuousClassifer buffhost buffport timeoutms weightfile";

	 public static void main(String[] args) throws IOException,InterruptedException {	
		  String hostname=null;
		  int port=-1;
		  int timeout=-1;
		  InputStream clsfrStream=null;
		  if ( args.length<1 ) {System.out.print(usage); System.exit(1);}

		if (args.length>=1) {
			hostname = args[0];
		}
		if (args.length>=2) {
			try {
				port = Integer.parseInt(args[1]);
			}
			catch (NumberFormatException e) {
				port = 0;
			}
			if (port <= 0) {
				System.out.println("Second parameter ("+args[1]+") is not a valid port number.");
				System.exit(1);
			}
		}
		if (args.length>=3) {
			try {
				timeout = Integer.parseInt(args[2]);
			}
			catch (NumberFormatException e) {
				 System.out.println("Couldnt understand your timeout spec....");
				timeout = 5000;
			}
		}
		// Open the file from which to read the classifier parameters
		if (args.length>=4) {
			 String clsfrFile = args[3];
			 System.out.println("Clsfr file = " + clsfrFile);
			 try { 
				  clsfrStream = new FileInputStream(new File(clsfrFile));
			 }  catch ( FileNotFoundException e ) {
				  e.printStackTrace();
			 } catch ( IOException e ) {
				  e.printStackTrace();
			 }
			 if ( clsfrStream==null ) System.out.println("Huh, couldnt open file stream.");
		} else {
			 System.out.println("Error need at least 4 arguments!");
			 System.out.println(usage);
			 System.exit(-1);
		}
		
		// make the cont classifier object
		ContinuousClassifier cc=new ContinuousClassifier(hostname,port,timeout);
		// load classifiers, make connection to buffer
		cc.initialize(clsfrStream);
		// run the classifier
		cc.mainloop();
	 }

	 ContinuousClassifier(String host, int port, int timeout){
		  if ( host !=null )     this.hostname=host;
		  if ( port >0 )     this.port=port;
		  if ( timeout >=0 ) this.timeoutMs=timeout;
	 }

    /**
     * Creates a set of classifiers using a file stored in the project
     *
     * @param is, input stream to read the weight matrix from 
     * @return List of classifiers (only one)
     */
    private static List<ERSPClassifier> createClassifiers(InputStream is) {
        List<Matrix> Ws = loadWFromFile(is);
        RealVector b = Matrix.zeros(Ws.size(), 1).getColumnVector(0);
		  // BUG: These numbers should *not* be hard coded here.....
        Integer[] freqIdx = ArrayFunctions.toObjectArray(Matrix.range(0, 26, 1));
        String[] subProbDescription = new String[]{"alphaL", "alphaR", "badness", "badChL", "badChR"};
        Integer[] isBad = new Integer[]{0, 0, 0};
        ERSPClassifier classifier = 
				new ERSPClassifier(128,true, isBad, 
										 null, null, null,
										 null, WelchOutputType.AMPLITUDE, freqIdx,  
										 subProbDescription, Ws, b);
        List<ERSPClassifier> classifiers = new LinkedList<ERSPClassifier>();
        classifiers.add(classifier);
        return classifiers;
    }

    /**
     * Load the linear classifier data from a file
     *
     * @return List of matrices that are used for a linear classifier.
     */
    private static List<Matrix> loadWFromFile(InputStream is) {
		  BufferedReader br = new BufferedReader(new InputStreamReader(is));
		  if ( is == null ) System.out.println("input stream is null?");

        List<Matrix> matrices = new LinkedList<Matrix>();
        try {
				Matrix m = Matrix.fromString(br);
				int h=m.getRowDimension();
				int w=m.getColumnDimension();
				while ( m != null ){
					 if ( m.getRowDimension() != h || m.getColumnDimension() != w ){
						  throw new IOException("matrix sizes are incompatiable");
					 }
					 matrices.add(m);
					 m = Matrix.fromString(br); // get another
				}
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
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
        for (ERSPClassifier c : classifiers) {
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
                System.out.println( "Connecting to " + hostname + ":" + port);
                C.connect(hostname, port);
                //C.setAutoReconnect(true);
                if (C.isConnected()) {
                    header = C.getHeader();
                }
            } catch (IOException e) {
                header = null;
            }
            if (header == null) {
                System.out.println( "Invalid Header... waiting");
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    /**
     * Initializes the attributes of this class
     */
    private void initialize(InputStream is) {
        classifiers = createClassifiers(is);
        C = new BufferClientClock();
        // Initialize the classifier and connect to the buffer
        connect();
        setNullFields();
        System.out.println( this.toString() );
    }

    public void mainloop() {
        // Get information of the buffer
        int nEvents = header.nEvents;
        int nSamples = header.nSamples;

        // Initialize initial variables. These are used later on to store the data.
		  int nOut=classifiers.get(0).getOutputSize()-1; nOut=nOut>0?nOut:1;
        Matrix baseLineVal = Matrix.zeros(nOut, 1);
        Matrix baseLineVar = Matrix.ones(nOut, 1);
        boolean baselinePhase = false;
        int nBaseline = 0;
        Matrix dvBaseline = null;
        Matrix dv2Baseline = null;
        Matrix dv = null;
        boolean endExpected = false;
        long t0 = 0;

        // Run the code
        boolean run = true;
        while (!endExpected && run) {
            // Getting data from buffer
            SamplesEventsCount status = null;
            // Block until there are new events
            try {
                System.out.println( "Waiting for " + (nSamples + sampleTrialLength + 1) + " samples");
                status = C.waitForSamples(nSamples + sampleTrialLength + 1, this.timeoutMs);
            } catch (IOException e) {
                e.printStackTrace();
            }
            if (status.nSamples < header.nSamples) {
                System.out.println( "Buffer restart detected");
                nSamples = status.nSamples;
                dv = null;
                continue;
            }

            // Logging stuff when nothing is happening
            if (System.currentTimeMillis() - t0 > 5000) {
                System.out.println( String.format("%5.3f seconds, %d samples, %d events", System.currentTimeMillis() / 1000.,
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
                    e.printStackTrace();
                }
                System.out.println( String.format("Got data @ %d->%d samples", fromId, toId));

                // Apply all classifiers and add results
                Matrix f = new Matrix(classifiers.get(0).getOutputSize(), 1);
                Matrix fraw = new Matrix(classifiers.get(0).getOutputSize(), 1);
                ClassifierResult result = null;
                for (ERSPClassifier c : classifiers) {
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
                    if (predictionFilter >= 0.) {
                        dv = new Matrix(dv.scalarMultiply(1. - predictionFilter).add(f.scalarMultiply(predictionFilter)));
                    }
                }

                // Update baseline
                if (baselinePhase) {
                    nBaseline++;
                    dvBaseline = new Matrix(dvBaseline.add(dv));
                    dv2Baseline = new Matrix(dv2Baseline.add(dv.multiplyElements(dv)));
                    if (nBaselineStep != null && nBaseline > nBaselineStep) {
                        System.out.println( "Baseline timeout\n");
                        baselinePhase = false;
                        Tuple<Matrix, Matrix> ret = baselineValues(dvBaseline, dv2Baseline, nBaseline);
                        baseLineVal = ret.x;
                        baseLineVar = ret.y;
                    }
                }

                // Compare to baseline
                dv = new Matrix(dv.subtract(baseLineVal)).divideElements(baseLineVar);

                // Send prediction event
                try {
                    BufferEvent event = new BufferEvent(predictionEventType, dv.getColumn(0), fromId);
                    C.putEvent(event);
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }

            // Deal with events
            if (status.nEvents > nEvents) {
                BufferEvent[] events = null;
                try {
                    events = C.getEvents(nEvents, status.nEvents - 1);
                } catch (IOException e) {
                    e.printStackTrace();
                }

                for (BufferEvent event : events) {
                    String type = event.getType().toString();
                    String value = event.getValue().toString();
                    System.out.println( "GET EVENT (" + event.sample + "): " + type + ", value: " + value);
                    if (type.equals(endType) && value.equals(endValue)) {
                        System.out.println( "End expected");
                        endExpected = true;
                    } else if (type.equals(baselineEventType) && value.equals(baselineEnd)) {
                        System.out.println( "Baseline end event received");
                        baselinePhase = false;
                        Tuple<Matrix, Matrix> ret = baselineValues(dvBaseline, dv2Baseline, nBaseline);
                        baseLineVal = ret.x;
                        baseLineVar = ret.y;
                    } else if (type.equals(baselineEventType) && value.equals(baselineStart)) {
                        System.out.println( "Baseline start event received");
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
        System.out.println("New baseline value: " + Arrays.toString(baseLineVal.getColumn(0)));
        System.out.println("New baseline variance: " + Arrays.toString(baseLineVar.getColumn(0)));
        return new Tuple<Matrix, Matrix>(baseLineVal, baseLineVar);
    }

    public String toString() {
        String str = "\nContinuousClassifier with parameters:\n" + 
				"Buffer host:     \t" + hostname + "\n" +
				"Buffer port:     \t" + port + "\n" + 
				"Header:\n        \t" + header + "\n" + 
				"End type:        \t" + endType + "\n" + 
				"End value:       \t" + endValue + "\n" + 
				"predictionEventType:\t" + predictionEventType + "\n" +
				"Samp Trial ms:   \t" + sampleTrialMs + "\n"+
				"sampleTrialLength:\t" + sampleTrialLength + "\n" + 
				"Overlap:         \t" +	overlap + "\n" +
				"sampleStepMs:    \t" + sampleStepMs + "\n" + 
				"predictionFilter:\t" + predictionFilter + "\n" + 
				"TimeoutMs:       \t" + timeoutMs + "\n" + 
				"BaselineEnd:     \t" + baselineEnd + "\n" + 
				"BaselineStart:   \t" + baselineStart + "\n" + 
				"BaselineStep:    \t" + nBaselineStep + "\n" + 
				"NormalizeLat:    \t" + normalizeLatitude + "\n" + 
				"Fs:              \t" + fs + "\n";
		  str += "#Classifiers:   \t" + classifiers.size();
		  for ( int i=0; i < classifiers.size(); i++ ) {
				str += "W{" + i + "}=\n" + classifiers.get(i).toString() + "\n\n";
		  }
		  return str;
    }
}
