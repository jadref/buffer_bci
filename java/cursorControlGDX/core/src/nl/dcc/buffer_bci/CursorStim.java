package nl.ru.dcc.buffer_bci;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import java.lang.System;
import java.io.*;
import nl.fcdonders.fieldtrip.bufferclient.*;
import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;

 public class CursorStim extends Game {

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
}
