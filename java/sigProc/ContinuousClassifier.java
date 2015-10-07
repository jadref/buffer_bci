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
public class ContinuousClassifier {

    protected static final String TAG = ContinuousClassifier.class.getSimpleName();
	 public static final int VERB = 1; // debugging verbosity level

    protected String hostname ="localhost";
    protected int port = 1972;
    protected String endType = "stimulus.test";
    protected String endValue = "end";
    protected String predictionEventType = "classifier.prediction";
    protected String baselineEventType = "stimulus.startbaseline";
    protected String baselineEnd = null;
    protected String baselineStart = "start";
    protected Integer nBaselineStep = 5000;

    protected Double predictionFilter = 1.0;
    protected Integer timeout_ms = 1000;
    protected boolean normalizeLatitude = true;
    protected List<PreprocClassifier> classifiers;
    protected BufferClientClock C = null;
    protected Integer trialLength_ms  =-1;
    protected Integer trialLength_samp=-1;
    protected Double overlap   = .5;
    protected Integer step_ms  = -1;
    protected Integer step_samp= -1;
    protected Float fs=-1.0f;
    protected Header header=null;

	 static final String usage="java ContinuousClassifer buffhost:buffport weightfile trlen_ms step_ms timeout_ms";

	 public static void main(String[] args) throws IOException,InterruptedException {	
		  String hostname=null;
		  int port=-1;
		  int timeout=-1;
		  InputStream clsfrStream=null;
		  if ( args.length<1 ) {System.out.print(usage); System.exit(1);}

		if (args.length>=1) {
			hostname = args[0];
			int sep = hostname.indexOf(':');
			if ( sep>0 ) {
				 port=Integer.parseInt(hostname.substring(sep+1,hostname.length()));
				 hostname=hostname.substring(0,sep);
			}			
		}
		// Open the file from which to read the classifier parameters
		if (args.length>=2) {
			 String clsfrFile = args[1];
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

		int trialLength_ms = -1;
		if (args.length>=3) {
			try {
				 trialLength_ms = Integer.parseInt(args[2]);
			}
			catch (NumberFormatException e) {
				 System.err.println("Couldnt understand your triallength spec.... using 1000ms");
			}			 
		}
		int step_ms = -1;
		if (args.length>=4) {
			try {
				 step_ms = Integer.parseInt(args[3]);
			}
			catch (NumberFormatException e) {
				 System.err.println("Couldnt understand your step spec....");
			}			 
		}
		if (args.length>=4) {
			try {
				timeout = Integer.parseInt(args[3]);
			}
			catch (NumberFormatException e) {
				 System.out.println("Couldnt understand your timeout spec....");
				timeout = 5000;
			}
		}
		
		// make the cont classifier object
		ContinuousClassifier cc=new ContinuousClassifier(hostname,port,timeout);
		// load classifiers, make connection to buffer
		cc.initialize(clsfrStream,trialLength_ms,step_ms);
		// run the classifier
		cc.mainloop();
	 }

	 public ContinuousClassifier(String host, int port, int timeout){
		  if ( host !=null )     this.hostname=host;
		  if ( port >0 )     this.port=port;
		  if ( timeout >=0 ) this.timeout_ms=timeout;
	 }

    /**
     * Creates a set of classifiers using a file stored in the project
     *
     * @param is, input stream to read the weight matrix from 
     * @return List of classifiers (only one)
     */
    protected static List<PreprocClassifier> createClassifiers(BufferedReader is) {
        List<PreprocClassifier> classifiers = new LinkedList<PreprocClassifier>();
		  try { 
				classifiers.add(PreprocClassifier.fromString(is));
		  } catch ( java.io.IOException e ) {
				e.printStackTrace(System.out);
		  }
        return classifiers;
    }

    /**
     * Connects to the buffer
     */
    protected void connect() {
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
    protected void initialize(InputStream is) {
		  initialize(is,-1,-1);
	 }

	 public void initialize(InputStream is, int trialLength_ms, int step_ms) {
		  if ( VERB>0 ) System.out.println("trlen="+trialLength_ms+" step="+step_ms);
		  BufferedReader br = new BufferedReader(new InputStreamReader(is));
        classifiers = createClassifiers(br);
		  // convert the classifier to the right type
		  // TODO: BODGE: THERE REALLY SHOULD BE A BETTER WAY TO DO THIS!!!!!!
		  for ( int i=0 ; i<classifiers.size(); i++){ // Note: need to use list.set to change inplace
				PreprocClassifier c = classifiers.get(i);
				if ( c.getType().equals("ERP") ) {
					 if ( VERB>0 ) System.out.println("Making ERPClassifier");
					 classifiers.set(i,new ERPClassifier(c));
				}else if ( c.getType().equals("ERsP") ) {
					 if ( VERB>0 ) System.out.println("Making ERSPClassifier");
					 classifiers.set(i,new ERSPClassifier(c));
				} else {
					 System.out.println("Huh? Unknown classifer type="+c.getType());
				}
		  }
        C = new BufferClientClock();
        // Initialize the classifier and connect to the buffer
        connect();
		  if ( trialLength_ms>0 ) this.trialLength_ms = trialLength_ms;
		  if ( step_ms>0 )        this.step_ms        = step_ms;
        setNullFields();
        if ( VERB>0 ) System.out.println( this.toString() );
    }

    /**
     * Compute the necessary variable using the variables that were set by the user. Throws an error if to few variables
     * are set.
     */
    protected void setNullFields() {
        // Set trial length
        if (header != null) {
            fs = header.fSample;
        } else {
            throw new RuntimeException("First connect to the buffer");
        }
        if (trialLength_samp <0) {
            trialLength_samp = -1;
            if (trialLength_ms >0) {
                trialLength_samp = Double.valueOf(Math.round(trialLength_ms/1000.0*fs)).intValue();
            } else {
					 for ( PreprocClassifier c : classifiers ) {
						  if ( c.type.equals("ERP") || c.type.equals("erp") ) {
								if ( false ) { //c.outSize != null) {
									 ;//trialLength_samp = Math.max(trialLength_samp,outSz[1]);
								} else {
									 trialLength_samp = Math.max(trialLength_samp,c.clsfrW.get(0).getColumnDimension());
								}
						  } else if ( c.type.equals("ERSP") || c.type.equals("ERsP") ) {
								System.out.println("ERSP size");
								trialLength_samp = Math.max(trialLength_samp,c.welchWindow.length);
						  } else {
								System.err.println("ERROR: Unrecognized classifier type");
						  }
					 }
				}
        }

        // Set wait time
        if( step_ms >0 ) {
            step_samp = Double.valueOf(Math.round(step_ms / 1000.0 * fs)).intValue();
        } else if ( overlap>0 ) {
            step_samp = Long.valueOf(Math.round(trialLength_samp * overlap)).intValue();
        }
    }

    public void mainloop() {
        // Get information of the buffer
        int nEvents = header.nEvents;
        int nSamples = header.nSamples;

        // Initialize initial variables. These are used later on to store the data.
		  int nOut=classifiers.get(0).getOutputSize()-1; nOut=nOut>0?nOut:1;
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
            int[] startIdx= Matrix.range(onSamples, status.nSamples - trialLength_samp - 1, step_samp);
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
                    f      = new Matrix(f.add(result.f));    // accumulate predictions over classifiers
                    fraw   = new Matrix(fraw.add(result.fraw));
                }

                // Smooth the classifiers
                if (dv == null || predictionFilter == null) {
						  dv = f;
                } else {
                    if (predictionFilter >= 0.) { // exponiential smoothing of predictions
                        dv = new Matrix(dv.scalarMultiply(1. - predictionFilter).add(f.scalarMultiply(predictionFilter)));
                    }
                }

                // Send prediction event
                try {
                    BufferEvent event = new BufferEvent(predictionEventType, dv.getColumn(0), fromId);
                    C.putEvent(event);
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }

            // Deal with new events
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
                    System.out.println("got(t:" + type + " v:" + value + " s:" + event.sample +")");
                    if (type.equals(endType) && value.equals(endValue)) {
                        System.out.println( "End expected");
                        endExpected = true;
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

    public String toString() {
        String str = "\nContinuousClassifier with parameters:\n" + 
				"Buffer host:     \t" + hostname + "\n" +
				"Buffer port:     \t" + port + "\n" + 
				"End type:        \t" + endType + "\n" + 
				"End value:       \t" + endValue + "\n" + 
				"predictionEventType:\t" + predictionEventType + "\n" +
				"trialLength_ms:  \t" + trialLength_ms + "\n"+
				"trialLength_samp:\t" + trialLength_samp + "\n" + 
				"Overlap:         \t" +	overlap + "\n" +
				"step_ms:         \t" + step_ms + "\n" + 
				"step_samp:       \t" + step_samp + "\n" + 
				"predictionFilter:\t" + predictionFilter + "\n" + 
				"timeout_ms:      \t" + timeout_ms + "\n" + 
				"Fs:              \t" + fs + "\n";
		  str += "#Classifiers:   \t" + classifiers.size();
		  for ( int i=0; i < classifiers.size(); i++ ) {
				str += "W{" + i + "}=\n" + classifiers.get(i).toString() + "\n\n";
		  }
		  return str;
    }
}
