package nl.ru.dcc.buffer_bci.screens;
import nl.fcdonders.fieldtrip.bufferclient.*;
import java.awt.*;
import java.awt.event.*;


public class CursorScreen extends StimulusSequenceScreen {
    int   nSymbs=8;    
    BufferClientClock buff=null;
    SamplesEventsCount sec=null; 
    public CursorScreen(int nSymb, BufferClientClock buff) { // Initialize variables
        this.buff=buff;
        nSymbs=nSymb;
    }
    
    public void start(){
        super.start();
        // get current sample/event count, everything before this time is ignored..
        if ( buff!=null ) try { sec=buff.poll(); } catch (java.io.IOException e) {}
    }
    
    public void update(float delta) {
        super.update(delta);
        
        // Send event logging we've moved to the next frame
        if ( isNewframe() && buff!=null && buff.isConnected() ) {
            try {
                getPredictions();
                if ( _es ) sendEvents();
            } catch (java.io.IOException ex){
                System.out.println("putEvents and/or getPredictions failed");
                ex.printStackTrace();
            }
        }
    }

    int nskip=0;
    void getPredictions() throws java.io.IOException {
        if( buff==null || !buff.isConnected() ) return;
        if( _sprob==null || _sprob.length<_ss.length ) _sprob = new float[_ss.length];
        SamplesEventsCount cursec=buff.poll(); // get current sample/event count
        if ( cursec.nEvents>sec.nEvents ) {// new events to process
            // get the new events
            BufferEvent[] evs = buff.getEvents(sec.nEvents,cursec.nEvents-1);
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
        sec=cursec;
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

    public void draw(Component c, Graphics gg){
        // draw the current display state
        Graphics2D g = (Graphics2D) gg;				 				 
        double stimRadius = 1.0/(nSymbs/2.0+1.0); // relative coordinates
        float width  = c.getWidth();
        float height = c.getHeight();
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
            g.fillOval((int)(width*(x-stimRadius/2)),(int)(height*(y - stimRadius/2)),
                       (int)(width*stimRadius), (int)(height*stimRadius)); 

            // Draw a ring round the center to give feedback about the predictions..
            if ( _sprob!=null && _sprob[i]>0 ) { // include the effect of any predictions
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
                g.setStroke(new BasicStroke((int)(stimRadius*width/20)));
                g.drawOval((int)(width*(x-stimRadius/2)),(int)(height*(y - stimRadius/2)),
                           (int)(width*stimRadius), (int)(height*stimRadius)); 
							
            }
					  
        }

        // draw the fixation point
        if ( _colors==null ) g.setColor(defaultColors[0]); else g.setColor(_colors[0]);
        g.fillOval((int)(width*(1.0/2-stimRadius/4)),(int)(height*(1.0/2-stimRadius/4)),
                   (int)(width*stimRadius/2), (int)(height*stimRadius/2));				 
				 
    }
};
