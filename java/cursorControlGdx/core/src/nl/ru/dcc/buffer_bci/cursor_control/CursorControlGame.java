package nl.ru.dcc.buffer_bci.cursor_control;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import nl.fcdonders.fieldtrip.bufferclient.BufferEvent;
import nl.ru.dcc.buffer_bci.BufferBciInput;
import nl.ru.dcc.buffer_bci.cursor_control.screens.BlankScreen;
import nl.ru.dcc.buffer_bci.cursor_control.screens.CursorControlScreen;
import nl.ru.dcc.buffer_bci.cursor_control.screens.CursorScreen;
import nl.ru.dcc.buffer_bci.cursor_control.screens.InstructWaitKeyScreen;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;

public class CursorControlGame extends ApplicationAdapter {
	CursorControlScreen screen;
    BufferBciInput input;

	@Override
	public void create () {
        input = new BufferBciInput(500, false);

        while(!input.connect("localhost", 1972))
            Gdx.app.log("CursorControlGame", "Could not connect to buffer!");

        Gdx.app.log("CursorControlGame", "Connected to buffer!");
	}

	@Override
	public void render () {
        screen.render(Gdx.graphics.getDeltaTime());
	}

    private void setScreen(CursorControlScreen screen) {
        this.screen = screen;
    }

    public void runScreen(CursorControlScreen screen) {
        this.screen = screen;
        this.screen.start();
    }

    public void runScreen() {
        if(this.screen != null)
            this.screen.start();
    }




    // Object used to communicate between render/controller threads
    volatile Object _controller=new Object();

    private void waitScreen(){
        synchronized ( _controller ) {
            try { _controller.wait(); } catch (InterruptedException ignored) {};
        }
    }


    int nSymbs                 =8;
    int nSeq                   =nSymbs*2;
    float seqDuration          =3.5f;
    static public int UPDATE_INTERVAL=1000/60; // Graphics re-draw rate

    //--------------------------------------------------------------------------------
    // Main function to control the experiment at the top level
    public void runExpt() throws java.io.IOException  {
        int   nSymbs     =this.nSymbs;
        int   nSeq       =this.nSeq;
        float seqDuration=this.seqDuration;
        float isi=1f/10;
        String blockName="Untitled";
        // This method implements the main experiment control flow
        InstructWaitKeyScreen instruct=new InstructWaitKeyScreen();
        BlankScreen blank=new BlankScreen();
        System.out.println("Starting Controller");

        // set the startup screen and wait for it to finish
        instruct.setInstruction("Look at the target location.\nGood LUCK.\n\nPress a key to continue.");
        instruct.setDuration(3000);
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
        instruct.setInstruction("That ends the experiment.\nThanks for participating");
        instruct.setDuration(5000);
        runScreen(instruct);
        waitScreen();
    }


    float tgtDuration          =1.5f;
    float interStimulusDuration=1.5f;

    public void runBlock(String stimType, float seqDuration, int[] tgtSeq, float[][] stimSeq, int[] stimTime_ms, boolean contColor)  throws java.io.IOException  {
        // Run a block of the experiment were we vary the target but not the stimulus sequence
        CursorScreen cursor=new CursorScreen(nSymbs, input);
        InstructWaitKeyScreen instruct=new InstructWaitKeyScreen();
        BlankScreen   blank=new BlankScreen();

        // set the startup screen and wait for it to finish
        instruct.setDuration(30000);
        instruct.setInstruction("The block " + stimType + " starts in " + instruct.getDuration() + "ms\n\n\nPress any key to continue.");
        System.out.println("\n-----------\nThe next block starts in 5s\n"+stimType+"\n-----------\n");
        runScreen(instruct);
        waitScreen();

        input.getBufferClient().putEvent(new BufferEvent("stimulus.stimType",stimType,-1));
        float[][] tgtStim=new float[1][stimSeq[0].length];
        int[]     tgtTime={0};
        for ( int seqi=0; seqi<tgtSeq.length; seqi++){
            // show target
            for(int ti=0;ti<tgtStim[0].length;ti++)
                if ( ti==tgtSeq[seqi] ) tgtStim[0][ti]=2; else tgtStim[0][ti]=0;
            // N.B. Always set the stimSeq first....
            cursor.setStimSeq(tgtStim,tgtTime,new boolean[]{false});
            cursor.setDuration(tgtDuration);
            input.getBufferClient().putEvent(new BufferEvent("stimulus.target",tgtSeq[seqi],-1));
            runScreen(cursor);
            waitScreen();

            // Play the stimulus
            // N.B. Always set the stimSeq first....
            cursor.setStimSeq(stimSeq,stimTime_ms,contColor);
            cursor.setDuration(seqDuration);
            cursor.setTarget(tgtSeq[seqi]);
            input.getBufferClient().putEvent(new BufferEvent("stimulus.trial","start",-1));
            runScreen(cursor);
            waitScreen();
            input.getBufferClient().putEvent(new BufferEvent("stimulus.trial","end",-1));

            // Blank for inter-sequence
            blank.setDuration((int)(interStimulusDuration * 1000));
            runScreen(blank);
            waitScreen();
        }
    }
    public void runBlock(String stimType, float seqDuration, int[] tgtSeq, float[][] stimSeq, int[] stimTime_ms)  throws java.io.IOException  {
        runBlock(stimType,seqDuration,tgtSeq,stimSeq,stimTime_ms,false);
    }

    long getCurTime(){return java.lang.System.currentTimeMillis();}

    public void startUpdateThread(){

        // Create a new thread to run update at regular interval
        // i.e. this simulates the once/frame call to render
        try {  Thread.sleep(1000); } catch (InterruptedException ignore) {}
        Thread updateThread = new Thread() {
            @Override
            public void run() {
                long tnext=getCurTime()+UPDATE_INTERVAL;
                long update_interval = UPDATE_INTERVAL;
                while (true) {
                    update_interval = UPDATE_INTERVAL;
                    if ( screen != null ) {
                        if ( screen.isDone() ) {
                            synchronized ( _controller ) { _controller.notify(); }
                        } else {
                            //update_interval = _screen.nextFrameTime()-getCurTime();
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
    }
}
