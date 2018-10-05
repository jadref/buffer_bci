package nl.ru.dcc.buffer_bci;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import java.lang.System;
import java.io.*;
import nl.fcdonders.fieldtrip.bufferclient.*;
import nl.ru.dcc.buffer_bci.screens.*;

public class CursorStim extends JPanel {
    public static final Color WINDOWBACKGROUNDCOLOR=new Color(.5f,.5f,.5f,1f);
    public static String DEFAULTHOST="localhost";
    public static int    DEFAULTPORT=1972;
    
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
		  String host = "localhost";
		  int port = 1972;
		  if (args.length>=1) {
				host = args[0];
				int sep = host.indexOf(':');
				if ( sep>0 ) {
					 port=Integer.parseInt(host.substring(sep+1,host.length()));
					 host=host.substring(0,sep);
				}
		  }			
        // override the default connection locations..
        CursorStim.DEFAULTHOST=host;
        CursorStim.DEFAULTPORT=port;        
        
		  CursorStim cs=new CursorStim();
        cs.display();
	  }

	  /** Constructor to setup the GUI components */
	  public CursorStim() { 
			this.setBackground(WINDOWBACKGROUNDCOLOR);
			this.setPreferredSize(new Dimension(800, 500));		 
			this.setFocusable(true); // so we can catch keyboard events
			// increase the default font size a bit...
			this.setFont(this.getFont().deriveFont(this.getFont().getSize()*1.4f));
			this.setForeground(Color.WHITE);
         buff=new BufferClientClock();
	  }
	  

	  public void display(){
        JFrame frame = new JFrame("Cursor Stim");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		  frame.setTitle("Cursor Stim");
        frame.getContentPane().add(this, BorderLayout.CENTER);
		  frame.pack();
        frame.setVisible(true);
        
        // start the experiment controller thread
        startControllerThread();
        
        // run the main-loop rendering loop
        renderloop();
        
		  // run the experiment
		  frame.dispose();
		  System.exit(0);
	  }

     public void renderloop(){
         // Simulate a fixed interval render loop
         long tnext=getCurTime_ms()+UPDATE_INTERVAL;
         long update_interval = UPDATE_INTERVAL;
         while (true) {
             update_interval = UPDATE_INTERVAL;
             // Cause the render process to proceed...
             // N.B. this causes the GUI to call us back to request a re-paint with
             // the current graphics context, which in turn we use to call the _screen.render()
             // function to do the actual re-drawing
             repaint(); 

             // Check if this screen is finished, if it is tell the controller thread to
             // move to the next stage
             if ( _screen != null ) {
                 if ( _screen.isDone() ) {
                     synchronized ( _controller ) { _controller.notify(); }					 
                 } else { // used in non-continuous-rendering mode
                     update_interval = _screen.nextFrameTime()-getCurTime_ms();
                 }
             }

             // sleep to the next re-draw time.
             update_interval=Math.max(update_interval,UPDATE_INTERVAL);
             tnext +=update_interval;
             // sleep so exactly UPDATE_INTERVAL milliseconds between repaints
             long sleep_ms=tnext - getCurTime_ms();
             try {
                 if ( sleep_ms>0 ) Thread.sleep(sleep_ms);
             } catch (InterruptedException ignore) {}
         }
     }

     /**
      * Called by the runtime system whenever the panel needs painting.
      */
    long lastFrameTime = 0;
    @Override
    public void paintComponent(Graphics g) {        
        super.paintComponent(g);
        float delta = getCurTime_ms() - lastFrameTime;
        if ( _screen != null ) { _screen.render(this,g,delta/1000f); }
        java.awt.Toolkit.getDefaultToolkit().sync(); 	// Force refresh of the actual display
        lastFrameTime=getCurTime_ms();
    }    

     //--------------------------------------------------------------------------------
	  // Main function to control the experiment at the top level
     CursorScreen cursor=null;
     InstructScreen instruct=null;
     BlankScreen   blank=null;
     ConnectingScreen connecting=null;
    
	  public void runExpt() throws java.io.IOException  {
			int   nSymbs     =this.nSymbs;
			int   nSeq       =this.nSeq;
			float seqDuration=this.seqDuration;
			float isi=1f/10;
			String blockName="Untitled";
			// This method implements the main experiment control flow
			instruct=new InstructScreen();
			blank   =new BlankScreen();
         cursor  =new CursorScreen(nSymbs, buff);
         connecting = new ConnectingScreen(buff);
         AddressInputScreen address = new AddressInputScreen(DEFAULTHOST,DEFAULTPORT);

         // get the buffer address
         runScreen(address);
         waitScreen();
         
         
         // make the buffer connection
         connecting.setisDoneOnKeyPress(this);
         connecting.host=address.host;
         connecting.port=address.port;
         runScreen(connecting);         
         waitScreen();
         connecting.clearisDoneOnKeyPress(this);
         


         // set the startup screen and wait for it to finish				 
			instruct.setInstruction("Look at the target location.\nGood LUCK.\n\nPress a key to continue.");
			instruct.setDuration_ms(3000);
			instruct.setisDoneOnKeyPress(this);
			runScreen(instruct);
			waitScreen();
			instruct.clearisDoneOnKeyPress(this);

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
			instruct.setInstruction("That ends the experiment.\nThanks for participating");
			instruct.setDuration_ms(5000);
			runScreen(instruct);
			waitScreen();			
	  }
	  	  
	  public void runBlock(String stimType, float seqDuration, int[] tgtSeq, float[][] stimSeq, int[] stimTime_ms, boolean contColor)  throws java.io.IOException  {

			// set the startup screen and wait for it to finish				 
			instruct.setDuration_ms(30000);
			instruct.setInstruction("The block " + stimType + " starts in " + instruct.getDuration_ms() + "ms\n\n\nPress any key to continue.");
			System.out.println("\n-----------\nThe next block starts in 5s\n"+stimType+"\n-----------\n");
         instruct.setisDoneOnKeyPress(this);
			runScreen(instruct);
			waitScreen();
         instruct.clearisDoneOnKeyPress(this);
						
			if( buff!=null && buff.isConnected() ) buff.putEvent(new BufferEvent("stimulus.stimType",stimType,-1));			
			float[][] tgtStim=new float[1][stimSeq[0].length];
			int[]     tgtTime={0};
			for ( int seqi=0; seqi<tgtSeq.length; seqi++){
				 // show target			
				 for(int ti=0;ti<tgtStim[0].length;ti++) 
					  if ( ti==tgtSeq[seqi] ) tgtStim[0][ti]=2; else tgtStim[0][ti]=0;
				 // N.B. Always set the stimSeq first....
				 cursor.setStimSeq(tgtStim,tgtTime,new boolean[]{false});
				 cursor.setDuration(tgtDuration);
				 if( buff!=null && buff.isConnected() ) buff.putEvent(new BufferEvent("stimulus.target",tgtSeq[seqi],-1));
				 runScreen(cursor);
				 waitScreen();
				 
				 // Play the stimulus
				 // N.B. Always set the stimSeq first....
				 cursor.setStimSeq(stimSeq,stimTime_ms,contColor);
				 cursor.setDuration(seqDuration);
				 cursor.setTarget(tgtSeq[seqi]);
				 if( buff!=null && buff.isConnected() ) buff.putEvent(new BufferEvent("stimulus.trial","start",-1));
				 runScreen(cursor);
				 waitScreen();
				 if( buff!=null && buff.isConnected() ) buff.putEvent(new BufferEvent("stimulus.trial","end",-1));

				 // Blank for inter-sequence
				 blank.setDuration(interStimulusDuration);
				 runScreen(blank);
				 waitScreen();
			}
	  }
	  public void runBlock(String stimType, float seqDuration, int[] tgtSeq, float[][] stimSeq, int[] stimTime_ms)  throws java.io.IOException  {
			runBlock(stimType,seqDuration,tgtSeq,stimSeq,stimTime_ms,false);
	  }

	  long getCurTime_ms(){return java.lang.System.currentTimeMillis();}

    public void runScreen(StimulusScreen screen) {
        this._screen = screen;
        if( _screen != null ) {
            synchronized ( _screen ) {
                this._screen.start();
            }
        }
    }
    private void waitScreen(){
			synchronized ( _controller ) {
				 try { _controller.wait(); } catch (InterruptedException ignored) {};
			}			
	  }    
    
     // start a thread for the experiment management
     public void startControllerThread() {
         System.out.println("Starting Controller");
         Thread updateThread = new Thread() {
            @Override
            public void run() {
                try {
                    runExpt();
                } catch (java.io.IOException ex){
                    System.out.println("IO exception" + ex);
                    ex.printStackTrace();
                }
            }
        };
        updateThread.start(); // called back run()
    }

}
