package nl.dcc.buffer_bci.bufferclientsservice.threads;

import android.util.Log;

import java.io.InputStream;

import nl.dcc.buffer_bci.signalprocessing.AlphaLatContClassifier;
import nl.dcc.buffer_bci.signalprocessing.ContinuousClassifier;
import nl.dcc.buffer_bci.matrixalgebra.linalg.WelchOutputType;
import nl.dcc.buffer_bci.signalprocessing.PreprocClassifier;

public class ThetaContClassifierThread extends AlphaLatContClassifierThread {

    private static final String TAG = ThetaContClassifierThread.class.getSimpleName();
	protected boolean medFilt=true;
	protected WelchOutputType welchOutputType=WelchOutputType.AMPLITUDE;
	 public ThetaContClassifierThread(){
	     step_ms       =200;
	     trialLength_ms=1000;
		  // override default for computing the lateralization to false, so just return summed power
		 compLat=false;
		 normLat=false;
		 medFilt=true;
		 this.processName=TAG; // reset the process name used in logging
		 this.clsfrFile="clsfr_theta_tpref.txt"; // override the default classifier file name
	 }
	 
    @Override
    public String getName() { return TAG; }

    @Override
    public void mainloop() {// Initialize the classifier and connect to the buffer
        super.initialize();
        InputStream clsfrReader = openClsfrFile(clsfrFile);
        if ( clsfrReader == null ) {
            Log.e(TAG, "Aborting!" + clsfrFile);
            return;
        }
        clsfr = new AlphaLatContClassifier(hostname,port,timeout_ms);
        PreprocClassifier.VERB=3;
        clsfr.initialize(clsfrReader,trialLength_ms,step_ms);
        ((AlphaLatContClassifier)clsfr).setcomputeLateralization(compLat);
        ((AlphaLatContClassifier)clsfr).setnormalizeLateralization(normLat);
        ((AlphaLatContClassifier)clsfr).setMedianFilter(medFilt);
        //((AlphaLatContClassifier)clsfr).welchAveType = welchOutputType;
        clsfr.setprocessName(processName);
        clsfr.mainloop();
        clsfr=null;
    }


}
