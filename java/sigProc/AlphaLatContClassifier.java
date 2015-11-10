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
import java.io.BufferedReader;


/**
 * Created by Pieter on 23-2-2015.
 * Continuous classifying of data from the buffer and sending events back
 */
public class AlphaLatContClassifier extends ContinuousClassifier {

    private static final String TAG = ContinuousClassifier.class.getSimpleName();

    private String baselineEnd = null;
	 private String baselineEventType = "stimulus.baseLine";
    private String baselineStart = "start";
    private int nBaselineStep = 5000;

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
		ContinuousClassifier cc=new AlphaLatContClassifier(hostname,port,timeout);
		// load classifiers, make connection to buffer
		cc.initialize(clsfrStream);
		// run the classifier
		cc.mainloop();
	 }

	 AlphaLatContClassifier(String host, int port, int timeout){
		  super(host,port,timeout);
	 }

	 @Override
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
                System.out.println( "Waiting for " + (nSamples + trialLength_samp + 1) + " samples");
                status = C.waitForSamples(nSamples + trialLength_samp + 1, this.timeout_ms);
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
            int[] startIdx = Matrix.range(onSamples, status.nSamples - trialLength_samp - 1, step_samp);
            if (startIdx.length > 0) nSamples = startIdx[startIdx.length - 1] + step_samp;

            for (int fromId : startIdx) {
                // Get the data
                int toId = fromId + trialLength_samp - 1;
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
                for (PreprocClassifier c : classifiers) {
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
                if (dv == null || predictionFilter < 0) dv = f;
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
                    if (nBaselineStep > 0 && nBaseline > nBaselineStep) {
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
}
