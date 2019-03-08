package nl.dcc.buffer_bci.signalprocessing;

import nl.dcc.buffer_bci.matrixalgebra.linalg.Matrix;
import nl.dcc.buffer_bci.matrixalgebra.linalg.WelchOutputType;
import nl.dcc.buffer_bci.matrixalgebra.miscellaneous.ArrayFunctions;
import nl.dcc.buffer_bci.matrixalgebra.miscellaneous.Tuple;
import nl.dcc.buffer_bci.matrixalgebra.miscellaneous.Windows;
import nl.dcc.buffer_bci.matrixalgebra.miscellaneous.MedianFilter;
import nl.dcc.buffer_bci.matrixalgebra.miscellaneous.MeanVarTracker;
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

    protected static final String TAG = AlphaLatContClassifier.class.getSimpleName();

	 private String baselineEventType = "stimulus.baseline";
    private String baselineEnd = "end";
    private String baselineStart = "start";
    /**
     * configure the baseline used for z-transformation of the outputs, if
   * nBaselineStep>0 = after baseline start event use this many time-points
     * to compute the baseline, if nBaselineStep<0, use this half-life in a
     * moving-baseline computation, if nBaselineStep==0, don't z-transform.
     */
    private int nBaselineStep = 0;
	 private boolean computeLateralization=true; // lateralization or total power
	 private boolean normalizeLateralization=true; // normalize the lateralization score
    private boolean medianFilter=true;   // median filter the lateralization score
    private MedianFilter medFilt=null;
    private boolean baselinePhase=false; // currently in baseline phase?
    private MeanVarTracker baselineTracker=null;
    
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
		System.out.println("Host: "+hostname+":"+port);
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
		System.out.println("trialLen_ms: " + trialLength_ms);
		int step_ms = -1;
		if (args.length>=4) {
			try {
				 step_ms = Integer.parseInt(args[3]);
			}
			catch (NumberFormatException e) {
				 System.err.println("Couldnt understand your step spec....");
			}			 
		}
		System.out.println("step_ms: " + step_ms);
		if (args.length>=4) {
			try {
				timeout = Integer.parseInt(args[3]);
			}
			catch (NumberFormatException e) {
				 System.out.println("Couldnt understand your timeout spec....");
				timeout = 5000;
			}
		}
	  boolean compLat=true; // lateralization or total power
		if (args.length>=5) {
			try {
				compLat = Integer.parseInt(args[4])>0;
			}
			catch (NumberFormatException e) {
				 System.out.println("Couldnt understand your timeout spec....");
			}
		}
      System.out.println("compLat="+compLat);
	  boolean normLat=true; // normalize the lateralization score
		if (args.length>=6) {
			try {
				normLat = Integer.parseInt(args[5])>0;
			}
			catch (NumberFormatException e) {
				 System.out.println("Couldnt understand your timeout spec....");
			}
		}
      System.out.println("normLat="+normLat);
      boolean medFilt=true;   // median filter the output score
		if (args.length>=7) {
			try {
				medFilt = Integer.parseInt(args[6])>0;
			}
			catch (NumberFormatException e) {
				 System.out.println("Couldnt understand your timeout spec....");
			}
		}
      System.out.println("medFilt="+medFilt);
      int nbaselineStep=-600;   // z-transform the outputs
		if (args.length>=7) {
			try {
				nbaselineStep = Integer.parseInt(args[7]);
			}
			catch (NumberFormatException e) {
				 System.out.println("Couldnt understand your timeout spec....");
			}
		}
      System.out.println("nbaseLineStep="+nbaselineStep);
          
		// make the cont classifier object
		ContinuousClassifier clsfr=new AlphaLatContClassifier(hostname,port,timeout);
      clsfr.VERB=1; // verbose debugging
    // load classifiers, make connection to buffer
		clsfr.initialize(clsfrStream,trialLength_ms,step_ms);
      ((AlphaLatContClassifier)clsfr).setcomputeLateralization(compLat);
      ((AlphaLatContClassifier)clsfr).setnormalizeLateralization(normLat);
      ((AlphaLatContClassifier)clsfr).setMedianFilter(medFilt);
      ((AlphaLatContClassifier)clsfr).setPredictionFilter(-1);
      ((AlphaLatContClassifier)clsfr).setnBaselineStep(nbaselineStep);
      
		// run the classifier
		clsfr.mainloop();
	 }

	 public AlphaLatContClassifier(String host, int port, int timeout){
		  super(host,port,timeout);
		  processName=TAG;
	 }

	 public void setcomputeLateralization(boolean complat){computeLateralization=complat;}
	 public void setnormalizeLateralization(boolean normlat){normalizeLateralization=normlat;}
    public void setMedianFilter(boolean medFilt){medianFilter=medFilt;}
    public void setBaselinePhase(boolean baselinePhase){ this.baselinePhase=baselinePhase;}
    public void setnBaselineStep(int nbaselinestep){ this.nBaselineStep=nbaselinestep;}
    public void setBaselineEventType(String baselineEventType){ this.baselineEventType=baselineEventType; }
    
	 @Override
    public void mainloop() {
        // Get information of the buffer
        int nEvents = header.nEvents;
        int nSamples = header.nSamples;

        // Initialize initial variables. These are used later on to store the data.
		  int nOut=classifiers.get(0).getOutputSize(); nOut=nOut>0?nOut:1;
        if( computeLateralization ) nOut = Math.max(nOut-1,1);
        Matrix baselineMean = null;
        Matrix baselineVar = null;
        int nBaseline = 0;
        Matrix dvBaseline = null;
        Matrix dv2Baseline = null;
        Matrix dv = null;
        boolean endEvent = false;
        long t0 = System.currentTimeMillis();
		  long t=t0;
		  long pnext=t+printInterval_ms;
        medFilt = new MedianFilter();
        baselineTracker = new MeanVarTracker();
        if( nBaselineStep < 0 ) { // continous baseline
            baselineTracker.sethalflife(-nBaselineStep);
            baselinePhase=true;
        }
        
		  try {
				C.putEvent(new BufferEvent("process."+processName,"start",-1));  // Log that we are starting
		  } catch ( IOException e ) { e.printStackTrace(); } 

        // Run the code
        while (!endEvent && run) {
            // Getting data from buffer
            SamplesEventsCount status = null;
            // Block until there are new events
            try {
					 if ( VERB>1 )
						  System.out.println( TAG+" Waiting for " + (nSamples + trialLength_samp + 1) + " samples");
                status = C.waitForSamples(nSamples + trialLength_samp + 1, this.timeout_ms);
            } catch (IOException e) {
                e.printStackTrace();
            }
            if (status.nSamples < nSamples) {
                System.out.println(TAG+ "Buffer restart detected");
                nSamples = status.nSamples;
                dv = null;
                continue;
            }

            // Logging stuff when nothing is happening
				t = System.currentTimeMillis();
            if ( t > pnext ) {
					 System.out.println(String.format("%d %d %5.3f (samp,event,sec)\r",
																 status.nSamples,status.nEvents,(t-t0)/1000.0));
                pnext = t+printInterval_ms;
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
                    continue;
                }
					 if ( VERB>1 ) {
						  System.out.println(TAG+ String.format("Got data @ %d->%d samples", fromId, toId));
					 }
                // Apply all classifiers and add results
                Matrix f = new Matrix(classifiers.get(0).getOutputSize(), 1);
                Matrix fraw = new Matrix(classifiers.get(0).getOutputSize(), 1);
                ClassifierResult result = null;
                for (PreprocClassifier c : classifiers) {
                    result = c.apply(data);
                    f = new Matrix(f.add(result.f));
                    fraw = new Matrix(fraw.add(result.fraw));
                }
					 if ( VERB>1 ) System.out.println(TAG+ " pred="+f);					 

                // Send raw-prediction event
                if( rawpredictionEventType != null ) {
                try {
                    BufferEvent event = new BufferEvent(rawpredictionEventType, f.getColumn(0), fromId);
                    C.putEvent(event);
                } catch (IOException e) {
                    e.printStackTrace();
                }
                }

                // Smooth the classifiers
                if (dv == null || predictionFilter<=0.0 || predictionFilter>=1.0 ) {
						  dv = f;
                } else {
                    if ( medianFilter ) { // median filtering of predictions
                        dv = f;
                        dv.setEntry(0,0, medFilt.apply(dv.getEntry(0,0)));
                    } else if (predictionFilter >= 0.) {// exponiential smoothing of predictions
                        // dv = (1-alpha)*dv + alpha*f
                        dv = new Matrix(dv.scalarMultiply(1. - predictionFilter)
													 .add(f.scalarMultiply(predictionFilter)));
                    }
                }

                // convert from channel powers to lateralization score
                if ( computeLateralization ) { // compute difference in feature values
                    if ( dv.getRowDimension() > 1 ) {
                        double[] dvColumn = dv.getColumn(0);
                        // return 1 less column
                        dv = new Matrix(dvColumn.length - 1, 1);
                        dv.setColumn(0, Arrays.copyOfRange(dvColumn, 1, dvColumn.length));
								if (normalizeLateralization) { // normalized difference score
									 dv.setEntry(0, 0, (dvColumn[1] - dvColumn[0]) / (dvColumn[0] + dvColumn[1]));
								} else {
									 dv.setEntry(0, 0, dvColumn[1] - dvColumn[0]);
								}
						  }
					 }

                // Update baseline
                if (baselinePhase) {
                    if( VERB>2 ) System.out.println("update baseline");
                    nBaseline++;
                    baselineTracker.addPoint(dv.getColumn(0));
                    if( VERB>2 )
                        System.out.println("Baseline Stats:"+ baselineTracker);
                    baselineMean = new Matrix(baselineTracker.getmu());
                    baselineVar  = new Matrix(baselineTracker.getsigma());
                    if (nBaselineStep > 0 && nBaseline > nBaselineStep) {
                        if(VERB>0) System.out.println( "Baseline timeout\n");
                        baselinePhase = false;
								if ( VERB>=0 ) logbaseline(baselineMean,baselineVar);
                    }
                }

                // Normalize to z-score w.r.t. the base-line values
                if( baselineMean !=null ) {
                    dv = new Matrix(dv.subtract(baselineMean)).divideElements(baselineVar);
                }

                // Send prediction event
                try {
                    BufferEvent event = new BufferEvent(predictionEventType, dv.getColumn(0), fromId);
                    C.putEvent(event);
						  if ( VERB>1 ) System.out.println(TAG+ " sent " + event);
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
                    if(VERB>1) System.out.println(TAG+ "got(" + event + ")");
                    if (type.equals(endType) && value.equals(endValue)) {
                        if(VERB>1) System.out.println(TAG+ "End Event. Exiting!");
                        endEvent = true;
                    } else if ( type.equals(baselineEventType) ){
								if ( value.equals(baselineStart) ) {
									 if(VERB>0)System.out.println(TAG+ "Baseline start event received");
									 baselinePhase = true;
									 nBaseline = 0;
								} else if ( value.equals(baselineEnd)) {
									 if(VERB>0) System.out.println(TAG+ "Baseline end event received");
									 if ( baselinePhase ){
										  baselinePhase = false;
										  if ( VERB>=0 ) logbaseline(baselineMean,baselineVar);
									 }
								}
						  }

                }
                nEvents = status.nEvents;
            }
        }
        try {
				C.putEvent(new BufferEvent("process."+processName,"end",-1));		  // Log that we are done
            C.disconnect();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

	 void logbaseline(Matrix baselineMean, Matrix baselineVar){
		  try { 
				C.putEvent(new BufferEvent("classifier.baseline.mean",baselineMean.getColumn(0),-1));
				C.putEvent(new BufferEvent("classifier.baseline.var",baselineVar.getColumn(0),-1));
		  } catch ( IOException e ) {
            e.printStackTrace();
		  }
		  System.out.println(TAG+" baseMean=" + baselineMean.toString());
		  System.out.println(TAG+" baselineVar=" + baselineVar.toString());
	 }
}
