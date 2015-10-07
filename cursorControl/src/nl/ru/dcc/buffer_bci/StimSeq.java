package nl.ru.dcc.buffer_bci;
/* ToDo:
 [] - eventSeq - include boolean eventSeq which says at which event times we should
                 send a stimulus event
 [X] - StimSeq loader, to load a stimulus sequence from a inputstream
 [X] - StimSeqPSK - phase-shift keying, convert a direct stim-seq to one at
                   double the clock rate where 1->10, 0->01
*/ 

import java.util.ArrayList;
import java.io.BufferedReader;
import java.io.IOException;


class StimSeq {
	 // [ nEvent x nSymb ] stimulus code for each time point for each stimulus
	 public float[][] stimSeq=null; 
	 // time stimulus i should finish, 
	 // i.e. stimulus i is on screen from stimTime_ms[i-1]-stimTime_ms[i] 
	 public int[]     stimTime_ms=null; 
	 public boolean[] eventSeq=null;

	 //-----------------------------------------------------------------------------------
	 // Constructor
	 StimSeq(float [][]istimSeq, int[] istimTime_ms){ stimSeq=istimSeq; stimTime_ms=istimTime_ms; }

	 //-----------------------------------------------------------------------------------
	 // S T R I N G (to/from)
	 public String toString(){
		  return toString(stimSeq,stimTime_ms);
	 }
	 public static String toString(float [][]stimSeq, int[] stimTime_ms){
		  String str=new String();
		  str = str + "# stimTime : ";
		  if ( stimSeq==null ) {
				str += "<null>\n[]\n\n";
		  }else{
				str += "1x" +  stimTime_ms.length + "\n";
				for(int i=0;i<stimTime_ms.length-1;i++) str += stimTime_ms[i]+"\t";
				str += stimTime_ms[stimTime_ms.length-1] + "\n";
				str += "\n\n"; // two new lines mark the end of the array
		  }
		  if ( stimSeq==null ) {
				str += "# stimSeq[]=<null>\n[]\n";
		  } else {
				str += "# stimSeq : " + stimSeq.length + "x" + stimSeq[0].length + "\n";
				str += writeArray(stimSeq,false);
		  }
		  return str;
	 }

	 public static StimSeq fromString(BufferedReader bufferedReader) throws IOException {
		  // Read the stimTimes_ms
		  float [][]tmpStimTime = readArray(bufferedReader);
		  if ( tmpStimTime.length>1 ) {
				System.out.println("more than 1 row of stim Times?\n");
				throw new IOException("Vector stim times expected");
		  }
		  float [][]tmpstimSeq = readArray(bufferedReader);
		  if ( tmpstimSeq.length<1 ){
				System.out.println("No stimSeq found in file!");
				throw new IOException("no stimSeq in file");
		  } else if ( tmpstimSeq[0].length != tmpStimTime[0].length ) {
				System.out.println("Mismatched lengths of stimTime (1x" + tmpStimTime[0].length + ")" +
										 " and stimSeq (" + tmpstimSeq.length +"x"+ tmpstimSeq[0].length + ")");
				throw new IOException("stimTime and stimSeq lengths unequal");
		  }
		  // All is good convert stimTimes to int vector and construct
		  int[] stimTime_ms = new int[tmpStimTime[0].length];
		  for ( int i=0; i<tmpStimTime[0].length; i++) stimTime_ms[i]=(int)tmpStimTime[0][i];
		  // Transpose the stimSeq into [epoch][stimulus], i.e. so faster change over stimulus
		  float[][] stimSeq = new float[tmpstimSeq[0].length][tmpstimSeq.length];
		  for ( int si=0; si<tmpstimSeq.length; si++){
				for ( int ei=0; ei<tmpstimSeq[si].length; ei++){
					 stimSeq[ei][si]=tmpstimSeq[si][ei];
				}
		  }
		  return new StimSeq(stimSeq,stimTime_ms);
	 }

	 //-----------------------------------------------------------------------------------
	 // S C A N
	 public static StimSeq mkStimSeqScan(int nSymb, float seqDuration, float isi){
		  int nEvent = (int)(seqDuration/isi)+1;
		  int[] stimTime_ms=new int[nEvent];
		  float[][] stimSeq=new float[nEvent][nSymb];
		  for ( int ei=0; ei<nEvent; ei++){
				stimTime_ms[ei]=(int)((ei+1)*1000.0*isi); // nearest ms
				stimSeq[ei][ei%nSymb]=1f;
		  }
		  return new StimSeq(stimSeq,stimTime_ms);
	 }

	 public static StimSeq mkStimSeqScanStep(int nSymb, float seqDuration, float isi, int step){
		  int nEvent = (int)(seqDuration/isi)+1;
		  int[] stimTime_ms=new int[nEvent];
		  float[][] stimSeq=new float[nEvent][nSymb];
		  // compute the order we will flash in
		  int[] symborder=new int[nSymb];
		  for ( int si=0,ci=0; si<nSymb; si++ ) {
				symborder[si]=ci;
				ci+=step;
				if ( ci>nSymb ) { 
					 ci=ci%nSymb; // wrap-arround
					 // check for re-use of symbols
					 boolean used=false; 
					 for ( int ssi=0; ssi<nSymb; ssi++ ) if( symborder[ssi]==ci ) {used=true; break;}
					 if ( used ) ci++; // extra increment to avoid already used symbol
					 //BODGE: should check for the incremented one also being used already....
				}
		  }

		  for ( int ei=0; ei<nEvent; ei++){
				stimTime_ms[ei]=(int)((ei+1)*1000.0*isi); // nearest ms
				stimSeq[ei][symborder[ei%nSymb]]=1f;
		  }
		  return new StimSeq(stimSeq,stimTime_ms);
	 }

	 //-----------------------------------------------------------------------------------
	 // R A N D
	 public static StimSeq mkStimSeqRand(int nSymb, float seqDuration, float isi){
		  // make a basic sequence for all symbs to use collections shuffle
		  int []perm = new int[nSymb]; for(int i=0; i<nSymb; i++) perm[i]=i;

		  int nEvent = (int)(seqDuration/isi)+1;
		  int[] stimTime_ms = new int[nEvent];
		  float[][] stimSeq = new float[nEvent][nSymb];
		  for ( int ri=0; ri<nEvent; ri+=nSymb){
				StimSeq.shuffle(perm);
				for( int ei=0; ei<nSymb; ei++ ){
					 if ( ri+ei>=nEvent ) break; // stop when all done
					 stimTime_ms[ri+ei]=(int)((ri+ei+1)*1000.0*isi); // nearest ms
					 stimSeq[ri+ei][perm[ei]]=1f;
				}
		  }
		  return new StimSeq(stimSeq,stimTime_ms);
	 }

	 //-----------------------------------------------------------------------------------
	 // S S E P
	 public static StimSeq mkStimSeqSSEP(int nSymb, float seqDuration, float isi, float[] period, float[] phase, boolean smooth){
		  //N.B. period,phase as times in the same units as isi
		  if ( phase==null ) phase=new float[nSymb];

		  int nEvent = (int)(seqDuration/isi)+1;
		  int[] stimTime_ms = new int[nEvent];
		  float[][] stimSeq=new float[nEvent][nSymb];
		  for ( int ei=0; ei<nEvent; ei++){
				stimTime_ms[ei]=(int)((ei+1)*1000.0*isi); // nearest ms
				for ( int si=0; si<nSymb; si++) {
					 // N.B. include slight phase offset to prevent value being exactly==0
					 stimSeq[ei][si] = (float)(Math.cos((stimTime_ms[ei]/1000f+.0001+phase[si])
																	                     /period[si]*2*Math.PI)); 
					 if ( smooth ) {
						  stimSeq[ei][si]=((stimSeq[ei][si]+1)/2)*.99f+.005f; //BODGE: scale to never =0/1
					 } else {
						  stimSeq[ei][si]=stimSeq[ei][si]>0?1f:0f;
					 }
				}
		  }
		  return new StimSeq(stimSeq,stimTime_ms);
	 }

	 //-----------------------------------------------------------------------------------
	 // N O I S E sequences
	 public static StimSeq mkStimSeqNoise(int nSymb, float seqDuration, float isi, float weight){
		  int nEvent = (int)(seqDuration/isi)+1;
		  int[] stimTime_ms = new int[nEvent];
		  float[][] stimSeq=new float[nEvent][nSymb];
		  for ( int ei=0; ei<nEvent; ei++){
				stimTime_ms[ei]=(int)((ei+1)*1000.0*isi); // nearest ms
				for( int si=0; si<nSymb; si++ ){
					 if ( Math.random() > weight ) // 50% change this is a highlight
						  stimSeq[ei][si]=1f;
				}
		  }
		  return new StimSeq(stimSeq,stimTime_ms);
	 }

	 //-----------------------------------------------------------------------------------
	 // G O L D sequences
	 public static StimSeq mkStimSeqGold(int nSymb, float seqDuration, float isi){
		  int nEvent = (int)(seqDuration/isi)+1;
		  int[] stimTime_ms = new int[nEvent];
		  float[][] stimSeq=new float[nEvent][nSymb];
		  
		  // Make 2 LSFR's with the appropriate number of bits..
		  int nBits = (int)Math.max(8,Math.ceil(Math.log(nEvent+1)/Math.log(2))); // Min seq has 8 bits
		  int mask  = 0; for ( int i=0; i<nBits; i++) mask|=1<<i;
		  int taps1 = 0;
		  int taps2 = 0;
		  if ( nBits==8 ) {
				taps1 = makeTaps(new int[]{7,6,5,4,1,0}); // magic: [8,7,6,5,2,1]
				taps2 = makeTaps(new int[]{7,6,5,0});     // magic: [8,7,6,1]
		  } else {
				try { 
					 taps1 = makeTaps(nBits); 
				} catch ( IllegalArgumentException e ) { // fall-back on random
					 for ( int i=0; i<nBits; i++ ) if ( Math.random()>.5 ) taps1 |= 1<<i;
				}
				for ( int i=0; i<nBits; i++ ) if ( Math.random()>.5 ) taps2 |= 1<<i;//Random set of taps...
		  }
		  
		  // test the noise generators...
		  int s,p;
		  s=lsfrNext(1,taps1,mask); p=0; while ( s!=1 ) { p++; s=lsfrNext(s,taps1,mask); }
		  System.out.println("LSFR 1: Period = " + p);
		  s=lsfrNext(1,taps2,mask); p=0; while ( s!=1 ) { p++; s=lsfrNext(s,taps2,mask); }
		  System.out.println("LSFR 2: Period = " + p);

		  int s1    = 1; // State for noise generator 1
		  int s2    = 1; // State for noise generator 2
		  // Used to store the histroy of the state of the 1st m-sequence to do the cyclic XOR
		  int[] seqState = new int[nSymb];
		  // Fill out th first few values for s1
		  for ( int si=0; si<nSymb; si++) { 
				seqState[si] = s1;
				s1 = lsfrNext(s1,taps1,mask);
		  }

		  // Now loop over time doing the appropriate shift+add of the sequences
		  for ( int ei=0; ei<nEvent; ei++){
				stimTime_ms[ei]=(int)((ei+1)*1000.0*isi); // nearest ms
				
				// update the state of the noise generators
				s2 = lsfrNext(s2,taps2,mask);
				s1 = lsfrNext(s1,taps1,mask);
				for( int si=0; si<nSymb; si++ ){
					 if ( si<nSymb-1 ) {
						  seqState[si]=seqState[si+1]; // shift back the sequence state
					 } else {
						  seqState[si]=s1; // insert the new value
					 }
					 // Generate the code value for this combination of time and shifted combination
					 stimSeq[ei][si]=(seqState[si]&1 + s2&1)&1; // sum mod 2
				}
		  }
		  return new StimSeq(stimSeq,stimTime_ms);
	 }

	 public static int lsfrNext(int register,int taps, int mask){
		  //Get the next output of a Linear Feedback Shift Register (LSFR) pseudo-random number generator
		  // register & 1 selects the low order bit, and do - to create an int that is all 1's if was 1, or all 0's if was 0; the rest is easy to understand
		  //register = ((register >>> 1) ^ (-(register & 1) & taps)) & mask;     

		  int tmp = register & taps & mask; // limit to the tapped locations
		  int output=0; while (tmp>0) { output+=tmp&1; tmp=tmp>>1; } // sum the taps
		  register = (register << 1 | output&1) & mask ; // shift and insert the sum
		  return register;
	 }
	 public static int makeTaps(int[] taps){
		  int tp=0;
		  for ( int i=0; i<taps.length; i++) tp |= 1<<taps[i];
		  return tp;
	 }
	 // return some standard sets of taps for different n
	 public static int makeTaps(int n) throws IllegalArgumentException {
		  switch (n) {
		  case 4: return  (1 << 3) | (1 << 2);     // i.e. 4 3
		  case 5: return  (1 << 4) | (1 << 2);     // i.e. 5 3
		  case 6: return  (1 << 5) | (1 << 4);     // i.e. 6 5
		  case 7: return  (1 << 6) | (1 << 5);     // i.e. 7 6
		  case 8: return  (1 << 7) | (1 << 5) | (1 << 4) | (1 << 3);     // i.e. 8 6 5 4
		  case 9: return  (1 << 8) | (1 << 4);     // i.e. 9 5
		  case 10: return  (1 << 9) | (1 << 6);     // i.e. 10 7
		  case 11: return  (1 << 10) | (1 << 8);     // i.e. 11 9
		  case 12: return  (1 << 11) | (1 << 10) | (1 << 9) | (1 << 3);     // i.e. 12 11 10 4
		  case 13: return  (1 << 12) | (1 << 11) | (1 << 10) | (1 << 7);     // i.e. 13 12 11 8
		  case 14: return  (1 << 13) | (1 << 12) | (1 << 11) | (1 << 1);     // i.e. 14 13 12 2
		  case 15: return  (1 << 14) | (1 << 13);     // i.e. 15 14
		  case 16: return  (1 << 15) | (1 << 13) | (1 << 12) | (1 << 10);     // i.e. 16 14 13 11
		  case 17: return  (1 << 16) | (1 << 13);     // i.e. 17 14
		  case 18: return  (1 << 17) | (1 << 10);     // i.e. 18 11
		  case 19: return  (1 << 18) | (1 << 17) | (1 << 16) | (1 << 13);     // i.e. 19 18 17 14
		  case 31: return  (1 << 30) | (1 << 27);     // i.e. 31 28
		  case 32: return (1 << 31) | (1 << 30) | (1 << 28) | (1 << 0);     // i.e. 32 31 29 1

		  default: throw new IllegalArgumentException("have not programmed the n = " + n + " case...");
		  }     
	 }

	 public StimSeq phaseShiftKey(boolean speedup){
		  float[][] ss = new float[stimSeq.length*2][];
		  int[]     st = new int[stimTime_ms.length*2];
		  for ( int ei=0; ei<stimTime_ms.length; ei++){
				// update the stimTime
				if ( speedup ) {
					 st[ei*2]   = stimTime_ms[ei];
					 if ( ei+1<stimTime_ms.length ) {
						  st[ei*2+1] = stimTime_ms[ei] + (int)(stimTime_ms[ei+1]-stimTime_ms[ei])/2;
					 } else {
						  st[ei*2+1] = stimTime_ms[ei] + (int)(stimTime_ms[ei]-stimTime_ms[ei-1])/2;
					 }
				} else {
					 st[ei]                    = stimTime_ms[ei];
					 st[stimTime_ms.length+ei] = stimTime_ms[ei]+ // +1 isi after end
						  stimTime_ms[stimTime_ms.length-1]+(stimTime_ms[1]-stimTime_ms[0]); 
				}
				// update the stimSeq
				ss[ei*2] = stimSeq[ei];
				ss[ei*2+1] = new float[stimSeq[ei].length];
				for ( int si=0; si<stimSeq[ei].length; si++){
					 if ( stimSeq[ei][si]>=0 ) { // for positive stim-types, invert the code
						  ss[ei*2+1][si] = stimSeq[ei][si]>0 ? 0 : 1;
					 } else { // neg stim-types remain unchanged
						  ss[ei*2+1][si] = stimSeq[ei][si];
					 }
				}
		  }
		  stimTime_ms=st;
		  stimSeq    =ss;
		  return this;
	 }


	 //-------------------------------------------------------------------------------------------
	 // Utility functions
	 public static void shuffle(int [] array){
		  // utility function to shuffle elements in a raw array
		  java.util.Random rgen = new java.util.Random();  // Random number generator 
		  for (int i=0; i<array.length; i++) {
				int randomPosition = rgen.nextInt(array.length);
				int temp = array[i];
				array[i] = array[randomPosition];
				array[randomPosition] = temp;
		  }		
	 }

	 public static String writeArray(float [][]array){ return writeArray(array,true); }
	 public static String writeArray(float [][]array, boolean incSize){
		  String str=new String();
		  if ( incSize ) {
				str += "# size = " + array.length + "x" + array[0].length + "\n";
		  }
		  for ( int ti=0; ti<array.length; ti++){ // time points
				for(int i=0;i<array[ti].length-1;i++) str += array[ti][i] + "\t";
				str += array[ti][array[ti].length-1] + "\n";
		  }
		  str += "\n\n"; // two new-lines mark the end of the array
		  return str;
	 }
 
	 public static float[][] readArray(BufferedReader bufferedReader) throws IOException {
		  if ( bufferedReader == null ) {
				System.out.println("could not allocate reader");
				throw new IOException("Couldnt allocate a reader");
		  }
		  int width=-1;
		  // tempory store for all the values loaded from file
		  ArrayList<float[]> rows=new ArrayList<float[]>(10);
		  String line;
		  int nEmptyLines=0;
		  //System.out.println("Starting new matrix");
		  while ( (line = bufferedReader.readLine()) != null ) {
				// skip comment lines
				if ( line == null || line.startsWith("#") ){
					 continue;
				} if ( line.length()==0 ) { // double empty line means end of this array
					 nEmptyLines++;
					 if ( nEmptyLines >1 && width>0 ) { // end of matrix by 2 empty lines
						  //System.out.println("Got 2 empty lines");
						  break;
					 } else { // skip them
						  continue;
					 }
				}
				//System.out.println("Reading line " + rows.size());
				
				// split the line into entries on the split character
				String[] values = line.split("[ ,	]"); // split on , or white-space
				if ( width>0 && values.length != width ) {
					 throw new IOException("Row widths are not consistent!");
				} else if ( width<0 ) {
					 width = values.length;
				}					 
				// read the row
				float[] cols = new float[width]; // tempory store for the cols data
				for ( int i=0; i<values.length; i++ ) {
					 try { 
						  cols[i] = Float.valueOf(values[i]);
					 } catch ( NumberFormatException e ) {
						  throw new IOException("Not a float number " + values[i]);
					 }
				}
				// add to the tempory store
				rows.add(cols);
		  }
		  //if ( line==null ) System.out.println("line == null");
		  
		  if ( width<0 ) return null; // didn't load anything

		  // Now put the data into an array
		  float[][] array = new float[rows.size()][width];
		  for ( int i=0; i<rows.size(); i++) array[i]=rows.get(i);
		  return array;
    }
};
