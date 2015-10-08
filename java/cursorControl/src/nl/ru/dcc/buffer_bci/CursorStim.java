package nl.ru.dcc.buffer_bci;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import java.lang.System;
import java.io.*;
import nl.fcdonders.fieldtrip.bufferclient.*;

 public class CursorStim extends JPanel {

	  // the screen we're currently drawing
	  volatile Screen _screen=null;
	  // Object used to communicate between render/controller threads
	  volatile Object _controller=new Object(); 
	  
	  static public int UPDATE_INTERVAL=1000/60; // Graphics re-draw rate
	  static public int VERB=0;
	  static public int avesleep=0;	  
	  float tgtDuration          =1.5f;
	  float seqDuration          =3.5f;
	  float interStimulusDuration=1.5f;
	  int nSymbs                 =8;
	  int nSeq                   =nSymbs*2;
	  volatile BufferClientClock buff=null;

	  public static void main(String[] args) throws java.io.IOException,InterruptedException {
			if ( args.length==0 ) {
				System.out.println("CursorStim bufferhost:bufferport");
		  }
		  String buffhostname = "localhost";
		  int buffport = 1972;
		  if (args.length>=1) {
				buffhostname = args[0];
				int sep = buffhostname.indexOf(':');
				if ( sep>0 ) {
					 buffport=Integer.parseInt(buffhostname.substring(sep+1,buffhostname.length()));
					 buffhostname=buffhostname.substring(0,sep);
				}
		  }			

		  CursorStim cs=new CursorStim();
			try {
				 cs.connectBuffer(buffhostname,buffport);
			} catch ( java.io.IOException ex ) {
				 System.out.println("Problem connecting to the buffer.  Aborting");
			}
			cs.display();
	  }

	  /** Constructor to setup the GUI components */
	  public CursorStim() { 
			this.setBackground(Color.BLACK);
			this.setPreferredSize(new Dimension(800, 500));		 
			this.setFocusable(true); // so we can catch keyboard events
			// increase the default font size a bit...
			this.setFont(this.getFont().deriveFont(this.getFont().getSize()*1.4f));
			this.setForeground(Color.WHITE);
	  }
	  
	  //--------------------------------------------------------------------------------
	  // Main function to control the experiment at the top level
	  public void runExpt() throws java.io.IOException  {
			int   nSymbs     =this.nSymbs;
			int   nSeq       =this.nSeq;
			float seqDuration=this.seqDuration;
			float isi=1f/10;
			String blockName="Untitled";
			// This method implements the main experiment control flow
			InstructWaitKeyScreen instruct=new InstructWaitKeyScreen(this);
			BlankScreen   blank=new BlankScreen();
			System.out.println("Starting Controller");

			// set the startup screen and wait for it to finish				 
			instruct.setString("Look at the target location.\nGood LUCK.\n\nPress a key to continue.");
			instruct.setDuration_ms(3000);
			runScreen(instruct);
			waitScreen();

			// for each block each target happens twice
			int [] tgtSeq=new int[nSeq]; 
			for( int i=0; i<nSymbs; i++ ) { tgtSeq[i*2]=i; tgtSeq[i*2+1]=i; }

			StimSeq ss=null;
			
			// // Block 1: SSEP -- LF @ 2Phase
			// isi=1f/60;
			// blockName = "SSEP_2phase_"+(int)Math.round(1./isi)+"hz";
			// ss=StimSeq.mkStimSeqSSEP(nSymbs,seqDuration,isi,
			// 								 new float[]{1f/10,1f/12,1f/15,1f/20,  1f/10, 1f/12, 1f/15, 1f/20}, 
			// 								 new float[]{0,    0,    0,    0,     .5f/10,.5f/12,.5f/15,.5f/20},
			// 								 true);
			// //System.out.println(ss.toString()); // debug stuff
			// StimSeq.shuffle(tgtSeq);
			// //runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms,true);

			// // Block 2: p3-radial @ 10hz
			// isi=1f/10;
			// blockName = "radial_"+(int)Math.round(1./isi)+"hz";
			// ss=StimSeq.mkStimSeqScan(nSymbs,seqDuration,isi);
			// StimSeq.shuffle(tgtSeq);
			// System.out.println("New block: " + blockName);System.out.print(ss.toString());
			// runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);

			// Block 3: p3-radial @ 20hz
			isi=1f/20;
			blockName = "radial_"+(int)Math.round(1./isi)+"hz";
			ss=StimSeq.mkStimSeqScan(nSymbs,seqDuration,isi);
			StimSeq.shuffle(tgtSeq);
			runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);

			// // Block 4: p3-radial @ 40hz
			// isi=1f/60;
			// blockName="radial_"+(int)Math.round(1./isi)+"hz";
			// ss=StimSeq.mkStimSeqScan(nSymbs,seqDuration,isi);
			// StimSeq.shuffle(tgtSeq);
			// runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);

			// // Block 5: p3-120 @ 10hz
			// isi=1f/10;
			// blockName="radial_120_"+(int)Math.round(1./isi)+"hz";
			// ss=StimSeq.mkStimSeqScanStep(nSymbs,seqDuration,isi,3);
			// StimSeq.shuffle(tgtSeq);
			// runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);

			// Block 6: p3-120 @ 20hz
			isi=1f/20;
			blockName="radial_120_"+(int)Math.round(1./isi)+"hz";
			ss=StimSeq.mkStimSeqScanStep(nSymbs,seqDuration,isi,3);
			StimSeq.shuffle(tgtSeq);
			runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);

			// // Block 7: p3-120 @ 40hz
			// isi=1f/40;
			// blockName="radial_120_"+(int)Math.round(1./isi)+"hz";
			// ss=StimSeq.mkStimSeqScanStep(nSymbs,seqDuration,isi,3);
			// StimSeq.shuffle(tgtSeq);
			// runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);

			// // Block 8: P3 @10
			// isi=1f/10;
			// blockName="P3_"+(int)Math.round(1./isi)+"hz";
			// ss=StimSeq.mkStimSeqRand(nSymbs,seqDuration,isi);
			// StimSeq.shuffle(tgtSeq);
			// runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);

			// Block 9: P3 @20
			isi=1f/20;
			blockName="P3_"+(int)Math.round(1./isi)+"hz";
			ss=StimSeq.mkStimSeqRand(nSymbs,seqDuration,isi);
			StimSeq.shuffle(tgtSeq);
			runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);

			// // Block 9: P3 @40
			// isi=1f/40;
			// blockName="P3_"+(int)Math.round(1./isi)+"hz";
			// ss=StimSeq.mkStimSeqRand(nSymbs,seqDuration,isi);
			// StimSeq.shuffle(tgtSeq);
			// runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);

			// // Block 10: Noise @10
			// isi=1f/10;
			// blockName="noise_"+(int)Math.round(1./isi)+"hz";
			// ss=StimSeq.mkStimSeqGold(nSymbs,seqDuration,isi);
			// StimSeq.shuffle(tgtSeq);
			// runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);

			// // // Block 10: Noise @10
			// // Load from save file
			// blockName = "gold_10hz";
			// {
			// 	 BufferedReader is = new BufferedReader(new InputStreamReader(new FileInputStream(new File("../stimulus/"+blockName+".txt"))));
			// 	 ss = StimSeq.fromString(is);
			// 	 is.close();
			// 	 System.out.print(ss);
			// }
			// // Play this sequence
			// StimSeq.shuffle(tgtSeq);
			// runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);

			// // Block 11: Noise @20
			// isi=1f/20;
			// blockName="noise_"+(int)Math.round(1./isi)+"hz";
			// ss=StimSeq.mkStimSeqGold(nSymbs,seqDuration,isi);
			// StimSeq.shuffle(tgtSeq);
			// runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);
			// Load from save file
			blockName = "gold_20hz";
			{
				 BufferedReader is = new BufferedReader(new InputStreamReader(new FileInputStream(new File("../stimulus/"+blockName+".txt"))));
				 ss = StimSeq.fromString(is);
				 is.close();
			}
			// Play this sequence
			StimSeq.shuffle(tgtSeq);
			runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);

			// // Block 12: Noise @40
			// isi=1f/40;
			// blockName="noise_"+(int)Math.round(1./isi)+"hz";
			// ss=StimSeq.mkStimSeqGold(nSymbs,seqDuration,isi);
			// StimSeq.shuffle(tgtSeq);
			// runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);

			// Load from save file
			blockName = "gold_40hz";
			{
				 BufferedReader is = new BufferedReader(new InputStreamReader(new FileInputStream(new File("../stimulus/"+blockName+".txt"))));
				 ss = StimSeq.fromString(is);
				 is.close();
			}
			// Play this sequence
			StimSeq.shuffle(tgtSeq);
			runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);

			// // Block 13: Noise+psk @20
			// isi=1f/10;
			// blockName="noise_"+(int)Math.round(1./isi)+"hz";
			// ss=StimSeq.mkStimSeqGold(nSymbs,seqDuration,isi);
			// StimSeq.shuffle(tgtSeq);
			// runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);
			// Load from save file
			blockName = "gold_20hz_psk";
			{
				 BufferedReader is = new BufferedReader(new InputStreamReader(new FileInputStream(new File("../stimulus/gold_10hz.txt"))));
				 ss = StimSeq.fromString(is);
				 is.close();
			}
			ss.phaseShiftKey(true); // map to psk version and double the ISI
			// Play this sequence
			StimSeq.shuffle(tgtSeq);
			runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);

			// Load from save file
			// // Block 14: Noise+PSK @40
			// isi=1f/20;
			// blockName="noise_"+(int)Math.round(1./isi)+"hz";
			// ss=StimSeq.mkStimSeqGold(nSymbs,seqDuration,isi);
			// StimSeq.shuffle(tgtSeq);
			// runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);
			// Load from save file
			blockName = "gold_40hz_psk";
			{
				 BufferedReader is = new BufferedReader(new InputStreamReader(new FileInputStream(new File("../stimulus/gold_20hz.txt"))));
				 ss = StimSeq.fromString(is);
				 is.close();
			}
			ss.phaseShiftKey(true); // map to psk version and double the ISI			
			// Play this sequence
			StimSeq.shuffle(tgtSeq);
			runBlock(blockName,seqDuration,tgtSeq,ss.stimSeq,ss.stimTime_ms);

			// Finally display thanks
			instruct.setString("That ends the experiment.\nThanks for participating");
			instruct.setDuration_ms(5000);
			runScreen(instruct);
			waitScreen();			
	  }
	  	  
	  public void runBlock(String stimType, float seqDuration, int[] tgtSeq, float[][] stimSeq, int[] stimTime_ms, boolean contColor)  throws java.io.IOException  {
			// Run a block of the experiment were we vary the target but not the stimulus sequence
			CursorScreen cursor=new CursorScreen(nSymbs);
			InstructWaitKeyScreen instruct=new InstructWaitKeyScreen(this);
			BlankScreen   blank=new BlankScreen();
			addKeyListener(instruct);			

			// set the startup screen and wait for it to finish				 
			instruct.setDuration_ms(30000);
			instruct.setString("The block " + stimType + " starts in " + instruct.getDuration() + "ms\n\n\nPress any key to continue.");
			System.out.println("\n-----------\nThe next block starts in 5s\n"+stimType+"\n-----------\n");
			runScreen(instruct);
			waitScreen();
						
			buff.putEvent(new BufferEvent("stimulus.stimType",stimType,-1));			
			float[][] tgtStim=new float[1][stimSeq[0].length];
			int[]     tgtTime={0};
			for ( int seqi=0; seqi<tgtSeq.length; seqi++){
				 // show target			
				 for(int ti=0;ti<tgtStim[0].length;ti++) 
					  if ( ti==tgtSeq[seqi] ) tgtStim[0][ti]=2; else tgtStim[0][ti]=0;
				 // N.B. Always set the stimSeq first....
				 cursor.setStimSeq(tgtStim,tgtTime,new boolean[]{false});
				 cursor.setDuration(tgtDuration);
				 buff.putEvent(new BufferEvent("stimulus.target",tgtSeq[seqi],-1));
				 runScreen(cursor);
				 waitScreen();
				 
				 // Play the stimulus
				 // N.B. Always set the stimSeq first....
				 cursor.setStimSeq(stimSeq,stimTime_ms,contColor);
				 cursor.setDuration(seqDuration);
				 cursor.setTarget(tgtSeq[seqi]);
				 buff.putEvent(new BufferEvent("stimulus.trial","start",-1));
				 runScreen(cursor);
				 waitScreen();
				 buff.putEvent(new BufferEvent("stimulus.trial","end",-1));

				 // Blank for inter-sequence
				 blank.setDuration(interStimulusDuration);
				 runScreen(blank);
				 waitScreen();
			}
	  }
	  public void runBlock(String stimType, float seqDuration, int[] tgtSeq, float[][] stimSeq, int[] stimTime_ms)  throws java.io.IOException  {
			runBlock(stimType,seqDuration,tgtSeq,stimSeq,stimTime_ms,false);
	  }

	  public void display(){
        JFrame frame = new JFrame("Cursor Stim");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		  frame.setTitle("Cursor Stim");
        frame.getContentPane().add(this, BorderLayout.CENTER);
		  frame.pack();
        frame.setVisible(true);
		  
		  // Create a new thread to run update at regular interval
		  // i.e. this simulates the once/frame call to render
		  try {  Thread.sleep(1000); } catch (InterruptedException ignore) {}
		  Thread updateThread = new Thread() {
					 @Override
					 public void run() {
						  long tnext=getCurTime()+UPDATE_INTERVAL;
						  long update_interval = UPDATE_INTERVAL;
						  while (true) {
								repaint();
								update_interval = UPDATE_INTERVAL;
								if ( _screen != null ) {
									 if ( _screen.isDone() ) {
										  synchronized ( _controller ) { _controller.notify(); }					 
									 } else {
										  update_interval = _screen.nextFrameTime()-getCurTime();
										  //System.out.println("Ui: " + update_interval);
									 }
								}
								//if ( update_interval > UPDATE_INTERVAL ) System.out.println("Ui: " + update_interval);
								update_interval=Math.max(update_interval,UPDATE_INTERVAL);
								tnext+=update_interval;
								// sleep so exactly UPDATE_INTERVAL milliseconds between repaints
								long sleep_ms=tnext - getCurTime();
								try {
									 if ( sleep_ms>0 ) Thread.sleep(sleep_ms);
								} catch (InterruptedException ignore) {}
						  }
					 }
				};
		  updateThread.start(); // called back run()
		  
		  try {
				runExpt();
		  } catch (java.io.IOException ex){
				System.out.println("IO exception" + ex);
				ex.printStackTrace();
		  }

		  // run the experiment
		  frame.dispose();
		  System.exit(0);
	  }

    /**
     * Called by the runtime system whenever the panel needs painting.
     */
    @Override
    public void paintComponent(Graphics g) {        
        super.paintComponent(g);
		  if ( _screen != null ) { _screen.render(g); }
		  java.awt.Toolkit.getDefaultToolkit().sync(); 	// Force refresh of the actual display
    }    

	  public void connectBuffer(String hostname, int port) throws java.io.IOException {
		  buff = new BufferClientClock();
		  Header hdr=null;
		  while( hdr==null ) {
				try {
					 System.out.println("Connecting to "+hostname+":"+port);
					 buff.connect(hostname, port);
					 if ( buff.isConnected() ) { hdr = buff.getHeader(); }
				} catch (java.io.IOException e) {
					 hdr=null;
				}
				if ( hdr==null ){
					 System.out.println("Invalid Header... waiting");
					 try { Thread.sleep(1000);} catch (InterruptedException e){}
				}
		  }
		  System.out.println(hdr.toString());
		  // Sync buffer clock with amplifier sample clock
		  buff.syncClocks(new int[]{0,100,100,100,100,100,200,200,200,200,200});
	  }

	  long getCurTime(){return java.lang.System.currentTimeMillis();}
	  private void waitScreen(){
			synchronized ( _controller ) {
				 try { _controller.wait(); } catch (InterruptedException ignored) {};
			}			
	  }

	  public synchronized Screen setScreen(Screen sc){ return _screen=sc; }
	  public void runScreen(Screen sc){ _screen=sc; _screen.start(); }
	  public void runScreen(){ if ( _screen!=null ) _screen.start(); }

	  class CursorScreen implements Screen {
			Color[] defaultColors={new Color(.5f,.5f,.5f), // bgColor
										  new Color(1f,1f,1f),    // fgColor
										  new Color(0f,1f,0f)};   // tgtColor
			int   nSymbs=8;

			// model of the whole sequence
			int   _tgt=-1;
			float[][] _stimSeq=null;
			int[]   _stimTime_ms=null;
			boolean[] _eventSeq=null;
			Color[] _colors=null;

			// Model for tracking were we currently are in the stimulus display
			int   framei=-1;
			float[] _ss=null;
			float[] _sprob=null;
			volatile long _nextFrameTime=-1; // *relative* time until the next stimulus change
			volatile long _t0=-1; // absolute time we started running
			volatile long _loopStartTime=-1; // absolute time we started current loop
			int _duration_ms=1000; // time we run for

			CursorScreen(int nSymb) { // Initialize variables
				 nSymbs=nSymb;
			}

			public void setDuration_ms(int duration_ms){ _duration_ms=duration_ms; }
			public void setDuration(float duration){ _duration_ms=(int)(duration*1000); }
			public int getDuration(){ return _duration_ms; }
			public void start(){
				 System.out.println("Cursor Screen : " + _duration_ms);
				 framei=-1; // set to -1 to indicate that no-valid frames have been drawn yet
				 // just record the current time so we know when to quit
				 _t0=getCurTime(); // absolute time we started this stimulus
				 _loopStartTime=_t0; // absolute time we started this stimulus loop
				 // get current sample/event count, everything before this time is ignored..
				 if ( buff!=null ) try { _sec=buff.poll(); } catch (java.io.IOException e) {}
			}
			synchronized public boolean isDone(){
				 // mark as finished
				 boolean _isDone = _t0>0 && getCurTime() > _duration_ms + _t0;
				 if ( _isDone ){
					  if ( VERB>=0 )
							System.out.println("Run-time: " + (getCurTime()-_t0) + " / " + 
													 _duration_ms + " ( " + (UPDATE_INTERVAL - avesleep) + " ) ");
					  _t0=-1; framei=-1; // mark as finished					  
				 }
				 return _isDone;
			}
			synchronized public long nextFrameTime(){ return _t0>=0?_nextFrameTime:0; }

			synchronized public void setStimSeq(float [][]stimSeq, int[] stimTime_ms, boolean [] eventSeq, Color[] colors){
				 _eventSeq=eventSeq;
				 // copy the stimulus sequence info to our local copy (thread safer...)
				 _stimTime_ms = new int[stimTime_ms.length]; // copy locally
				 java.lang.System.arraycopy(stimTime_ms,0,_stimTime_ms,0,stimTime_ms.length);
				 // Validate that this stimTime sequence is correct...
				 if ( _stimTime_ms.length==1 && _stimTime_ms[_stimTime_ms.length-1]==0 &&
						_duration_ms>0 ) 
					  _stimTime_ms[0]=_duration_ms;
				 // Copy the stimulus sequence
				 _stimSeq     = new float[stimSeq.length][];
				 for ( int ti=0; ti<stimSeq.length; ti++){ // time points
					  _stimSeq[ti]=new float[nSymbs];
					  java.lang.System.arraycopy(stimSeq[ti],0,_stimSeq[ti],0,nSymbs);
				 }
				 // Init the state tracking variables
				 _ss   = _stimSeq[0];
				 // make a low-level copy of the current stim-seq
				 //_ss=new float[nSymbs]; for ( int i=0; i<_ss.length; i++) _ss[i]=_stimSeq[0][i];
				 _sprob= new float[nSymbs]; for ( int i=0; i<_sprob.length; i++ ) _sprob[i]=0f;
				 if ( VERB>1 ) System.out.println(StimSeq.toString(_stimSeq,_stimTime_ms));
				 // initialize the color-table for this stimulus sequence
				 _colors=colors;
			}
			public void setStimSeq(float [][]stimSeq, int[] stimTime_ms){
				 setStimSeq(stimSeq,stimTime_ms,null,defaultColors);
			}
			public void setStimSeq(float [][]stimSeq, int[] stimTime_ms, boolean [] eventSeq){
				 setStimSeq(stimSeq,stimTime_ms,eventSeq,defaultColors);
			}
			public void setStimSeq(float [][]stimSeq, int[] stimTime_ms, boolean [] eventSeq, boolean contColor){
				 if( contColor ) 
					  setStimSeq(stimSeq,stimTime_ms,eventSeq,null);
				 else
					  setStimSeq(stimSeq,stimTime_ms,eventSeq,defaultColors);
			}
			public void setStimSeq(float [][]stimSeq, int[] stimTime_ms, boolean contColor){
				 if( contColor ) 
					  setStimSeq(stimSeq,stimTime_ms,null,null);
				 else
					  setStimSeq(stimSeq,stimTime_ms,null,defaultColors);
			}
			public void setTarget(int tgt){ _tgt=tgt;}
			public void setTarget(int[] tgt){ 
				 for( int i=0; i<tgt.length; i++) if (tgt[i]>0) {_tgt=i; break;}
			}
			
			void update() {
				 // get the next stimulus frame to display
				 int oframei=framei;
				 updateFramei();

				 // do we have a new frame, if so do new-frame specific updating
				 if ( oframei!=framei ) { // new frame to draw
					  if ( VERB>0 ){
							System.out.print((getCurTime()-_t0) + " ( " + framei + " ) " + 
												  (_stimTime_ms[framei]+_loopStartTime-_t0) + " ss=[");
							for(int i=0;i<_ss.length;i++)System.out.print(_ss[i]+" ");
							System.out.println("]");
					  }
					  if( oframei>0 && framei-oframei>1 ) {
							System.out.println((getCurTime()-_t0) + ": Warning dropped " + (framei-oframei) + " frames!");
					  }
					  // Send event logging we've moved to the next frame
					  if ( buff!=null ) {
							try {
								 getPredictions();
								 if ( _eventSeq == null || _eventSeq[framei] ) // send events if told to
									  sendEvents();
							} catch (java.io.IOException ex){
								 System.out.println("putEvents and/or getPredictions failed");
								 ex.printStackTrace();
							}
					  }
				 }
			}
			long getCurTime(){return java.lang.System.currentTimeMillis();}

			void updateFramei(){
				 // get the current time since start of this loop
				 long curTime    = getCurTime();
				 // skip to the next stimulus frame we should display
				 if ( _stimTime_ms != null ) {
					  framei=framei<0?0:framei;// ensure is valid frame
					  // Skip to the next frame to draw
					  while ( _stimTime_ms[framei] < curTime-_loopStartTime ){
							framei++;
							if ( framei>=_stimSeq.length ) { // loop and update loop start time
								 _loopStartTime += _stimTime_ms[_stimTime_ms.length-1];
								 framei=0;
							}
				     }
					  _nextFrameTime = Math.min(_stimTime_ms[framei]+_loopStartTime,_duration_ms+_t0);
					  _ss = _stimSeq[framei];
					  //java.lang.System.copyarray(_stimSeq[framei],0,_ss,0,_ss.length);// paranoid?
				 }
			}


			SamplesEventsCount _sec=new SamplesEventsCount(0,0); // Track of the number of events/samples processed so far
			int nskip=0;
			void getPredictions() throws java.io.IOException {				 
				 nskip=nskip<40*10?nskip+1:0;
				 if ( false && nskip%40==0 ) { // test the feedback based re-drawing
					  double[] nprob=new double[_sprob.length];
					  float z=0;
					  for ( int i=0; i<nprob.length; i++) { 
							nprob[i] = 1;
							if ( i==_tgt ) nprob[i]=nskip/20f; // shrink towards 1
							z+=nprob[i];
					  }
					  // normalize to be valid probabilities
					  for ( int i=0; i<nprob.length; i++) nprob[i]=nprob[i]/z;
					  buff.putEvent(new BufferEvent("prediction",nprob,-1));
				 }

				 SamplesEventsCount sec=buff.poll(); // get current sample/event count
				 if ( sec.nEvents>_sec.nEvents ) {// new events to process
					  // get the new events
					  BufferEvent[] evs = buff.getEvents(_sec.nEvents,sec.nEvents-1);
					  // filter for ones we want
					  if ( VERB>1 ) System.out.println("Got " + evs.length + " events");
					  for ( int ei=0; ei<evs.length; ei++){
							BufferEvent evt=evs[ei];
							String evttype = evt.getType().toString(); // N.B. to*S*tring, not upper case!
							// only process if it's an event of a type we care about
							if ( evttype.equals("prediction") ){  
								 if ( VERB>0 ) 
									  System.out.println("Processing prediction event: " + evt.toString());
								 // it's a prediction, update the stored symbol probability information
								 Object obj = evt.getValue().getArray();								 
								 try { 
									  String name=obj.getClass().getName();
									  if ( name == "[D" ) { // double array
											double[] nProb=(double[])obj;
											for ( int i=0; i<_sprob.length && i<nProb.length; i++) 
												 _sprob[i]=(float) nProb[i];
									  } else if ( name == "[F" ) {// single array
											float[] nProb=(float[])obj;
											for ( int i=0; i<_sprob.length && i<nProb.length; i++) 
												 _sprob[i]=(float) nProb[i];
									  } else {
											throw new java.lang.ClassCastException(); // don't know how to handle
									  }
								 } catch (java.lang.ClassCastException ex) {
									  System.out.println("Exception: predictions should be of float type");
								 }
							}
					  }
				 }
				 // update record of the events we've seen
				 _sec=sec;
			}

			void sendEvents() throws java.io.IOException{
				 // N.B. easy alternative is to have the sampled auto-filled-in with
				 // buff.putEvent(new BufferEvent("stimulus.stimState",ss,-1));// -1=auto-fill-samp
				 int samp=(int)buff.getSamp();// current sample count
				 buff.putEvent(new BufferEvent("stimulus.stimState",_ss,samp));
				 // Is this a target flash event
				 if ( _tgt>=0 && (_ss[_tgt]==1 || _ss[_tgt]==0) ) { 
					  buff.putEvent(new BufferEvent("stimulus.tgtState",_ss[_tgt],samp));
				 }				 
			}

			void draw(Graphics gg){
				 // draw the current display state
				 Graphics2D g = (Graphics2D) gg;				 				 
				 double stimRadius = 1.0/(nSymbs/2.0+1.0); // relative coordinates
				 // draw the targets -- centers
				 for ( int i=0; i<_ss.length; i++){
					  double theta= 2.0*Math.PI*i/_ss.length;
					  double x    = Math.cos(theta)*(1.0 - 2*stimRadius)/2.0 + .5; // center in rel-coords
					  double y    = Math.sin(theta)*(1.0 - 2*stimRadius)/2.0 + .5;

					  // get the basic color we should be
					  Color color;
					  if ( _colors==null ) { // intensity
							color = new Color(_ss[i],_ss[i],_ss[i]);
					  } else { // colortable
							color = _colors[(int)_ss[i]];
					  }					  
					  g.setColor(color);
					  g.fillOval((int)(getWidth()*(x-stimRadius/2)),(int)(getHeight()*(y - stimRadius/2)),
									 (int)(getWidth()*stimRadius), (int)(getHeight()*stimRadius)); 

					  // Draw a ring round the center to give feedback about the predictions..
					  if ( _sprob[i]>0 ) { // include the effect of any predictions
							if ( VERB>1 ) System.out.println("sProb[ " + i + "]=" + _sprob[i]);
							// N.B. ensure it's as a float!
							if ( _sprob[i]>1f/_ss.length ) { // Green is fixed, scale down red+blue
								 float cscale=(1f-_sprob[i])/(1f-1f/_ss.length);
								 if ( VERB>1 ) System.out.println("scale : " + cscale);
								 color=new Color(color.getRed()/255f*cscale,
													  color.getGreen()/255f,
													  color.getBlue()/255f*cscale);
							} else { // Red is fixed, scale down green/blue
								 float cscale=_sprob[i]*_ss.length;
								 if ( VERB>1 ) System.out.println("scale : " + cscale);
								 color=new Color(color.getRed()/255f,
													  color.getGreen()/255f*cscale,
													  color.getBlue()/255f*cscale);
							}
							g.setColor(color);
							g.setStroke(new BasicStroke((int)(stimRadius*getWidth()/20)));
							g.drawOval((int)(getWidth()*(x-stimRadius/2)),(int)(getHeight()*(y - stimRadius/2)),
										  (int)(getWidth()*stimRadius), (int)(getHeight()*stimRadius)); 
							
					  }
					  
				 }

				 // draw the fixation point
				 if ( _colors==null ) g.setColor(defaultColors[0]); else g.setColor(_colors[0]);
				 g.fillOval((int)(getWidth()*(1.0/2-stimRadius/4)),(int)(getHeight()*(1.0/2-stimRadius/4)),
								(int)(getWidth()*stimRadius/2), (int)(getHeight()*stimRadius/2));				 
				 
			}

			synchronized public void render(Graphics g) {
				 // update the display state with new info (e.g. time, events)
				 if ( _t0<0 || _ss==null ) return; // Do nothing if not started yet
				 update();
				 draw(g);
			}
	  };
}
