package nl.dcc.buffer_bci.bufferclientsservice.threads;

public class AlphaContClassifierThread extends AlphaLatContClassifierThread {

    private static final String TAG = AlphaContClassifierThread.class.getSimpleName();

	 public AlphaContClassifierThread(){
		  // override default for computing the lateralization to false, so just return summed power
		  compLat=false;
		  this.processName=TAG; // reset the process name used in logging
		  this.clsfrFile="clsfr_nf_tpref.txt"; // override the default classifier file name
	 }
	 
    @Override
    public String getName() {
        return TAG;
    }
}
