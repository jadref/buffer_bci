package nl.ru.dcc.buffer_bci.cursor_control.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import nl.fcdonders.fieldtrip.bufferclient.BufferEvent;
import nl.fcdonders.fieldtrip.bufferclient.SamplesEventsCount;
import nl.ru.dcc.buffer_bci.BufferBciInput;
import nl.ru.dcc.buffer_bci.cursor_control.StimSeq;

/**
 * Created by Lars on 1-12-2015.
 */
public class CursorScreen extends CursorControlScreen {
    Color[] defaultColors={new Color(.5f,.5f,.5f, 1.0f), // bgColor
            new Color(1f,1f,1f, 1.0f),    // fgColor
            new Color(0f,1f,0f, 1.0f)};   // tgtColor
    int   nSymbs=8;

    public static int VERB=0;
    static public int UPDATE_INTERVAL=1000/60; // Graphics re-draw rate
    static public int avesleep=0;

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

    public CursorScreen(int nSymb, BufferBciInput input) { // Initialize variables
        nSymbs=nSymb;
        this.input = input;
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
            input.getBufferClient().putEvent(new BufferEvent("prediction",nprob,-1));
        }

        SamplesEventsCount sec=input.getBufferClient().poll(); // get current sample/event count
        if ( sec.nEvents>_sec.nEvents ) {// new events to process
            // get the new events
            BufferEvent[] evs = input.getBufferClient().getEvents(_sec.nEvents,sec.nEvents-1);
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
//        // N.B. easy alternative is to have the sampled auto-filled-in with
//        // buff.putEvent(new BufferEvent("stimulus.stimState",ss,-1));// -1=auto-fill-samp
//        int samp=(int)buff.getSamp();// current sample count
//        buff.putEvent(new BufferEvent("stimulus.stimState",_ss,samp));
//        // Is this a target flash event
//        if ( _tgt>=0 && (_ss[_tgt]==1 || _ss[_tgt]==0) ) {
//            buff.putEvent(new BufferEvent("stimulus.tgtState",_ss[_tgt],samp));
//        }
        input.getBufferClient().putEvent(new BufferEvent("stimulus.stimState", _ss, -1));
        if(_tgt >= 0 && (_ss[_tgt]==1 || _ss[_tgt]==1)) {
            input.getBufferClient().putEvent(new BufferEvent("stimulus.tgtState",_ss[_tgt], -1));
        }
    }

    @Override
    public void draw(){
        // Clear screen.
        Gdx.gl.glClearColor(0,0,0,0);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        // Initialize shape renderer
        ShapeRenderer renderer = new ShapeRenderer();

        double stimRadius = 1.0/(nSymbs/2.0+1.0); // relative coordinates
        // draw the targets -- centers
        for ( int i=0; i<_ss.length; i++){
            double theta= 2.0*Math.PI*i/_ss.length;
            double x    = Math.cos(theta)*(1.0 - 2*stimRadius)/2.0 + .5; // center in rel-coords
            double y    = Math.sin(theta)*(1.0 - 2*stimRadius)/2.0 + .5;

            // get the basic color we should be
            Color color;
            if ( _colors==null ) { // intensity
                color = new Color(_ss[i],_ss[i],_ss[i], 1.0f);
            } else { // colortable
                color = _colors[(int)_ss[i]];
            }
//            g.setColor(color);
//            g.fillOval((int)(getWidth()*(x-stimRadius/2)),(int)(getHeight()*(y - stimRadius/2)),
//                    (int)(getWidth()*stimRadius), (int)(getHeight()*stimRadius));

            renderer.setColor(color);
            renderer.ellipse((int)(getWidth()*(x-stimRadius/2)),(int)(getHeight()*(y - stimRadius/2)),
                    (int)(getWidth()*stimRadius), (int)(getHeight()*stimRadius));

            // Draw a ring round the center to give feedback about the predictions..
            if ( _sprob[i]>0 ) { // include the effect of any predictions
                if ( VERB>1 ) System.out.println("sProb[ " + i + "]=" + _sprob[i]);
                // N.B. ensure it's as a float!
                if ( _sprob[i]>1f/_ss.length ) { // Green is fixed, scale down red+blue
                    float cscale=(1f-_sprob[i])/(1f-1f/_ss.length);
                    if ( VERB>1 ) System.out.println("scale : " + cscale);
                    color=new Color(color.r*cscale,
                            color.g,
                            color.b*cscale,
                            1.0f);
                } else { // Red is fixed, scale down green/blue
                    float cscale=_sprob[i]*_ss.length;
                    if ( VERB>1 ) System.out.println("scale : " + cscale);
                    color=new Color(color.r,
                            color.g/255f*cscale,
                            color.b/255f*cscale,
                            1.0f);
                }
                renderer.setColor(color);
                //g.setStroke(new BasicStroke((int)(stimRadius*getWidth()/20)));
//                g.drawOval((int)(getWidth()*(x-stimRadius/2)),(int)(getHeight()*(y - stimRadius/2)),
//                        (int)(getWidth()*stimRadius), (int)(getHeight()*stimRadius));
                renderer.ellipse((int)(getWidth()*(x-stimRadius/2)),(int)(getHeight()*(y - stimRadius/2)),
                        (int)(getWidth()*stimRadius), (int)(getHeight()*stimRadius));

            }

        }

        // draw the fixation point
        if ( _colors==null ) renderer.setColor(defaultColors[0]); else renderer.setColor(_colors[0]);
        renderer.ellipse((int)(getWidth()*(1.0/2-stimRadius/4)),(int)(getHeight()*(1.0/2-stimRadius/4)),
                (int)(getWidth()*stimRadius/2), (int)(getHeight()*stimRadius/2));

    }

    @Override
    public void update(float delta) {

    }
};
