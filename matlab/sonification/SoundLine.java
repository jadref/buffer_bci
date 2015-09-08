package nl.dcc.buffer_bci;
import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.DataLine;
import javax.sound.sampled.SourceDataLine;

public class SoundLine {
	 AudioFormat audioFormat=null;
	 SourceDataLine soundLine=null;
	 int nbytes=2;
	 long sampleRate=2000;
	 byte[] audBuf=null;
	 
	 public SoundLine(int sr,int bufferSize, int nbytes) throws Exception {		  
		  init(sr,bufferSize,nbytes);
	 }
	 public SoundLine(double sr,double bufferSize, double nbytes) throws Exception {		  
		  init((int)sr,(int)bufferSize,(int)nbytes);
	 }

	 void init(int sr, int bufferSize, int inbyte) throws javax.sound.sampled.LineUnavailableException {
		  nbytes=inbyte;
		  if ( nbytes >2 | nbytes<1 ) { // check for a supported bit depth
				throw new javax.sound.sampled.LineUnavailableException();
		  }
		  final AudioFormat audioFormat = new AudioFormat(sr,    // sample rate
																		  nbytes*8, // sample size in bits
																		  1,     // channels
																		  true,  // signed
																		  false  // bigendian
																		  );	 
		  soundLine = AudioSystem.getSourceDataLine(audioFormat);
		  soundLine.open(audioFormat, bufferSize); // set audio buffer size
		  start();
		  audBuf=new byte[bufferSize*nbytes]; // N.B. increase size by number bytes/sample
	 }
	 public void stop(){ // shut-down the audio
		  soundLine.stop();
	 }
	 public void start(){ // start the audio
		  soundLine.start();
	 }
	 public void drain(){ // empty the buffer
		  soundLine.drain();
	 }
	 public int available(){
		  return soundLine.available();
	 }
	 public double available_s(){
		  return ((double)soundLine.available())/((double)nbytes)/((double)getSampleRate());
	 }
	 public int getBufferSize(){
		  return soundLine.getBufferSize();
	 }
	 public float getSampleRate(){
		  return soundLine.getFormat().getSampleRate();
	 }
	 public AudioFormat getFormat(){
		  return soundLine.getFormat();
	 }

	 public int write(byte[] buf, int off, int len){
		  return soundLine.write(buf,off,len);
	 }
	 public int write(double[] buf){
		  return write(buf,0,buf.length);
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
				switch(nbytes){
				case 1: audBuf[j]=(byte)buf[i]; break;
					 // convert to 2 bytes in big-edenian format
				case 2: audBuf[j]=(byte)(buf[i]%256); audBuf[j+1]=(byte)(buf[i]/256); j++; break;
				}
		  }
		  if ( j > 0 ) {
				n+=soundLine.write(audBuf,0,j);
		  }
		  return n;
	 }

	 public void playChirp(){
		  long t0=java.lang.System.currentTimeMillis();
		  long t=t0;
		  long te=t0;
		  int nSamp=0;
		  int period_samp = 2; // start at high frequency
		  int counter=0;
		  int avail=0;
		  int sampleRate=(int)getSampleRate();
		  byte[] buf = new byte[sampleRate/10];
		  byte sign=1;
		  while ( nSamp < 100*sampleRate ) { // play for 100s
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
				avail=soundLine.available();
				nSamp += soundLine.write(buf,0,buf.length);
				te=java.lang.System.currentTimeMillis();
				System.out.println((t-t0) + ")\tDur=" + ((buf.length*1000)/sampleRate) + "ms\tWrite=" + (buf.length*1000/sampleRate) + "ms =>" + (te-t) + "ms\tbytes-to-fill="+avail + " bytes-to-play\t" + (soundLine.getBufferSize() - avail) );
				// the next call is blocking until all the sound in the buffer is gone
				//soundLine.drain();
				
				// change the period, increment until 1/2 buffer size
				period_samp += 1; if ( period_samp > buf.length/2 ) period_samp=0;
		  }
		  stop();
	 }
};
