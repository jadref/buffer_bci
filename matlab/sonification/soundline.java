import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.DataLine;
import javax.sound.sampled.SourceDataLine;

public class soundline {
	 AudioFormat audioFormat=null;
	 SourceDataLine soundLine=null;
	 int sr=-1;
	 byte[] audBuf=null;
	 
	 public soundline(int sr,int bufferSize) throws Exception {		  
		  init(sr,bufferSize);
	 }
	 public soundline(double sr,double bufferSize) throws Exception {		  
		  init((int)sr,(int)bufferSize);
	 }

	 void init(int sr, int bufferSize) throws javax.sound.sampled.LineUnavailableException {
		  final AudioFormat audioFormat = new AudioFormat(sr, // sample rate
																		  8,  // sample size in bits
																		  1,  // channels
																		  true,  // signed
																		  false  // bigendian
																		  );	 
		  soundLine = AudioSystem.getSourceDataLine(audioFormat);
		  soundLine.open(audioFormat, bufferSize); // set audio buffer size
		  soundLine.start();
		  audBuf=new byte[bufferSize];
	 }
	 public void stop(){
		  // shut-down the audio
		  soundLine.stop();
	 }
	 public int write(byte[] buf, int off, int len){
		  return soundLine.write(buf,off,len);
	 }
	 public int write(double[] buf, double doff, double dlen){
		  int len=(int)dlen;
		  int i  =0;
		  int j  =0;
		  int n  =0;
		  for ( i=(int)doff,j=0; i<len; i++,j++){
				if ( j==audBuf.length ) { // write when buffer is filled
					 n+=soundLine.write(audBuf,0,audBuf.length);
					 j=0;
				}
				audBuf[j]=(byte)buf[i];
		  }
		  if ( j > 0 ) {
				n+=soundLine.write(audBuf,0,j);
		  }
		  return n;
	 }
	 public int write(double[] buf){
		  return write(buf,0,buf.length);
	 }

	 public void playChirp(){
		  long t0=java.lang.System.currentTimeMillis();
		  long t=t0;
		  int nSamp=0;
		  int period_samp = 2; // start at high frequency
		  int counter=0;
		  byte[] buf = new byte[soundLine.getBufferSize()];
		  byte sign=1;
		  while ( nSamp < 100*44100 ) { // play for 100s
				for (int i = 0; i < buf.length; i++) {
					 if (counter > period_samp) { // generate square-wave with period period_samp
						  sign = (byte) -sign;
						  counter = 0;
					 }
					 buf[i] = (byte) (sign * 30);
					 counter++;
				}

				// the next call is blocking until the entire buffer is 
				// sent to the SourceDataLine
				t=java.lang.System.currentTimeMillis();
				nSamp += soundLine.write(buf,0,buf.length);
				System.out.println(t + ") Dur= " + ((buf.length*1000)/sr) + "ms Write = " + (java.lang.System.currentTimeMillis()-t) + " ms  bytes-to-go="+ soundLine.available() );
				// the next call is blocking until all the sound in the buffer is gone
				//soundLine.drain();
				
				// change the period, increment until 1/2 buffer size
				period_samp += 1; if ( period_samp > buf.length/2 ) period_samp=0;
		  }
		  stop();
	 }
};
