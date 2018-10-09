package nl.dcc.buffer_bci.cursor_control.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import nl.fcdonders.fieldtrip.bufferclient.BufferEvent;
import nl.fcdonders.fieldtrip.bufferclient.SamplesEventsCount;
import nl.dcc.buffer_bci.BufferBciInput;
import nl.dcc.buffer_bci.cursor_control.StimSeq;

/**
 * Created by Lars on 1-12-2015.
 */
public abstract class StimulusSequenceScreen extends StimulusScreen {
    Color[] defaultColors={new Color(.5f,.5f,.5f, 1.0f), // bgColor  GREY
                           new Color(1f,1f,1f, 1.0f),    // fgColor  WHITE
                           new Color(0f,1f,0f, 1.0f),    // tgtColor GREEN
                           new Color(0f,0f,1f, 1f)};     // fbColor BLUE    
    protected int _tgt=-1;

    public abstract void setStimSeq(float [][]stimSeq, int[] stimTime_ms, boolean [] eventSeq, Color[] colors);

    // helper functions for default cases
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
};