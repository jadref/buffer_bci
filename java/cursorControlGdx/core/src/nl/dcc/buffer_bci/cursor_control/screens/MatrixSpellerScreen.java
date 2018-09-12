package nl.dcc.buffer_bci.cursor_control.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.graphics.g2d.freetype.FreeTypeFontGenerator;

import nl.fcdonders.fieldtrip.bufferclient.BufferEvent;
import nl.fcdonders.fieldtrip.bufferclient.SamplesEventsCount;
import nl.dcc.buffer_bci.BufferBciInput;
import nl.dcc.buffer_bci.cursor_control.StimSeq;

public class MatrixSpellerScreen extends StimulusSequenceScreen {

	// GRAPHICS RELATED VARIABLES
	private SpriteBatch batch;
	private BitmapFont font;
	private Sprite[][] fgGrid = new Sprite[6][5];
	private Sprite[][] bgGrid = new Sprite[6][5];
	private Sprite[][] tgtGrid = new Sprite[6][5];
   private Sprite[][] fbGrid = new Sprite[6][5];

    // state tracking variables
    public static int VERB=0;
    static public int UPDATE_INTERVAL=1000/60; // Graphics re-draw rate
    static public int avesleep=0;

    // Fixed info about the texture we will be slicing up..
    static final String TEXTUREFILENAME="grid.png";
    static final int nTEXTUREROWS=6;
    static final int nTEXTURECOLS=5;

    // model of the screen
    String[][] symbols=null;

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


    SamplesEventsCount _sec=new SamplesEventsCount(0,0); // Track of the number of events/samples processed so far
    int nskip=0;

    private BufferBciInput input;

    public MatrixSpellerScreen(String[][] symbols, BufferBciInput input) { // Initialize variables
        this.symbols=symbols;
        this.input = input;

		// Determine column and row sizes for the currently used screen. Defined
		// relative to the size of a 1080p screen.
      int nRows = symbols.length;
      int nCols = symbols[0].length;

		float gridWidth = Gdx.graphics.getWidth();
		float gridHeight = Gdx.graphics.getHeight();
      // so text is square
		float cellSize = Math.min(gridHeight / nRows, gridWidth / nCols);

      // Create sprites for each column and row of the grid

      // Rip regions out of the complete GRID image to make sprites,
      // We will render these sprites at run time onto the screen
		// Create grid sprites
      // Grabbing the grid texture.
      Texture gridTexture = new Texture(TEXTUREFILENAME);
		for (int x = 0; x < nTEXTUREROWS; x++) {
			for (int y = 0; y < nTEXTURECOLS; y++) {
				TextureRegion texture = new TextureRegion(gridTexture,
						0 + x * 180, 720 - y * 180, 180, 180);
				bgGrid[x][y] = new Sprite(texture);
				bgGrid[x][y].setSize(cellSize, cellSize);
				bgGrid[x][y].setPosition(x * cellSize, y * cellSize);
				bgGrid[x][y].setColor(defaultColors[0]);

				fgGrid[x][y] = new Sprite(texture);
				fgGrid[x][y].setSize(cellSize, cellSize);
                fgGrid[x][y].setPosition(x * cellSize, y * cellSize);
				fgGrid[x][y].setColor(defaultColors[1]);

				tgtGrid[x][y] = new Sprite(texture);
				tgtGrid[x][y].setSize(cellSize, cellSize);
                tgtGrid[x][y].setPosition(x * cellSize, y * cellSize);
				tgtGrid[x][y].setColor(defaultColors[2]);

				fbGrid[x][y] = new Sprite(texture);
				fbGrid[x][y].setSize(cellSize, cellSize);
                fbGrid[x][y].setPosition(x * cellSize, y * cellSize);
				fbGrid[x][y].setColor(defaultColors[3]);
			}
		}

//		// Generate a BitmapFont based on a freetype Ubuntu font.
//		FreeTypeFontGenerator generator = new FreeTypeFontGenerator(
//				Gdx.files.internal("Ubuntu-R.ttf"));
//		FreeTypeFontGenerator.FreeTypeFontParameter parameter = new FreeTypeFontGenerator.FreeTypeFontParameter();
//		parameter.size = 26;
//		font = generator.generateFont(parameter);
//		generator.dispose();
    }

	@Override
	public void dispose() {
		batch.dispose();
		font.dispose();
	}

    public void setDuration_ms(int duration_ms){ _duration_ms=duration_ms; }
    public void setDuration(float duration){ _duration_ms=(int)(duration*1000); }
    public int getDuration(){ return _duration_ms; }
    public void start(){
        super.start();
        System.out.println("Cursor Screen : " + _duration_ms);
        // set to -1 to indicate that no-valid frames have been drawn yet
        framei=-1;
        // just record the current time so we know when to quit
        _t0=-1;getCurTime(); // absolute time we started this stimulus
        _loopStartTime=-1; // absolute time we started this stimulus loop
        // get current sample/event count, everything before this time is ignored..
        try {
            _sec = input.getBufferClient().poll(); // get current sample/event count
        } catch (java.io.IOException ex) {
            System.out.println("Could not get initial event count");
            ex.printStackTrace();
        }
    }
    synchronized public boolean isDone(){
        // mark as finished
        boolean _isDone = _t0>0 && getCurTime() > _duration_ms + _t0;
        if ( _isDone ){
            if ( VERB>=0 )
                System.out.println("Run-time: " + (getCurTime()-_t0) + " / " +
                        _duration_ms + " ( " + (UPDATE_INTERVAL - avesleep) + " ) ");
            framei=-1; // mark as finished
        }
        return _isDone;
    }

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
            _stimSeq[ti]=new float[stimSeq[ti].length];
            java.lang.System.arraycopy(stimSeq[ti],0,_stimSeq[ti],0,stimSeq[ti].length);
        }
        // Init the state tracking variables
        _ss   = _stimSeq[0];
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

    @Override
    public void update(float delta) {
        if( _t0<0 && framei<0 ){ // first call since start, record timing
            _t0=getCurTime(); // absolute time we started this stimulus
            _loopStartTime=_t0; // absolute time we started this stimulus loop
            framei=0;
        }
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
                System.out.println("[" + oframei + "]@" + (getCurTime()-_t0) +
                            "ms: Dropped " + (framei-oframei-1) + " frames" +
                        " deltaTime = " + (getCurTime()-_t0 - _stimTime_ms[oframei]));
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
            int oframei=framei;
            // Skip to the next frame to draw
            while ( _stimTime_ms[framei] <= curTime-_loopStartTime ){
                framei++;
                if ( framei>=_stimSeq.length ) { // loop and update loop start time
                    framei=0;
                    if( _stimTime_ms[_stimTime_ms.length-1]<=0 ) break; // guard against zero-stimTime sequences
                    // cycle round, update the start time for this loop to reflect the current time
                    _loopStartTime += _stimTime_ms[_stimTime_ms.length-1];
                }
            }
            if( framei-oframei > 1 ){
                System.out.println("dropped frame");
            }
            _nextFrameTime = Math.min(_stimTime_ms[framei]+_loopStartTime,_duration_ms+_t0);
            _ss = _stimSeq[framei];
            //java.lang.System.copyarray(_stimSeq[framei],0,_ss,0,_ss.length);// paranoid?
        }
    }

    @Override
        public void draw(){

        // Clear screen.
        Gdx.gl.glClearColor(0,0,0,0);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);
        SpriteBatch batch = new SpriteBatch();
        batch.begin();

        batch.disableBlending();
        int si=0;
        for (int x = 0; x < symbols.length; x++) {
            for (int y = 0; y < symbols[0].length; y++) {
                if( si< _ss.length ){
                    if( _ss[si] <= 0 ){ // background
                        bgGrid[x][y].draw(batch);
                    } else if ( _ss[si] == 1 ){ // foreground
                        fgGrid[x][y].draw(batch);
                    } else if ( _ss[si] == 2 ){ // target
                        tgtGrid[x][y].draw(batch);
                    } else if ( _ss[si] == 3 ){ // feedback
                        fbGrid[x][y].draw(batch);
                    }
                } else { // if not given then set to BG
                    bgGrid[x][y].draw(batch);
                }
                si++;
            }
        }
        batch.end();
    }
}