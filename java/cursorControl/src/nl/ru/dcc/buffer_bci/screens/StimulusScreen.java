package nl.ru.dcc.buffer_bci.screens;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

public abstract class StimulusScreen implements Screen {
    public static final Color WINDOWBACKGROUNDCOLOR=new Color(.5f,.5f,.5f,1f);
    protected int duration_ms;
    protected long startTime = 0;

    // re-director from render into update then draw.
    public void render(Component c, Graphics g, float delta){
        update(delta);
        draw(c,g);
    };
    public long nextFrameTime(){ return -1l; }
    
    // main re-drawing functions, to be implemented in the actual classes
    public abstract void draw(Component c, Graphics g);
    public abstract void update(float delta);

    // Helper functions
    public void setDuration_ms(int ms){duration_ms = ms;}
    public void setDuration(float duration){setDuration_ms((int) (1000 * duration));}
    public int getDuration_ms() { return duration_ms; }
    public static final long getTime_ms() { return System.currentTimeMillis(); }    
    public long getTimeLeft_ms() { return (startTime + duration_ms) - getTime_ms(); }
    public long getTimeSpent_ms(){ return getTime_ms() - startTime;}
    public void log(String tag, String msg) { System.out.println(tag + "::" + msg); }
    public void log(String msg) { System.out.println(msg); }    
    
    public void start() {
        startTime = getTime_ms();
        donelogged=false;
        log(this.getClass().getSimpleName(), "Start at: " + startTime + ", duration: " + duration_ms);
    }

    private boolean donelogged=false;
    public boolean isDone() {
        boolean done = startTime + duration_ms < getTime_ms();
        if(done) {
            if (!donelogged) { // guard for logging lots of times..
                log(this.getClass().getSimpleName(), "Run-time: " + (getTime_ms() - startTime));
                donelogged=true;
            }
        } else {
            donelogged=false;
        }
        return done;
    }
    
    // Helper methods to easily enable/disable key-press based end-of-screen
    // TODO: [] make this easier to use?
    public void clearisDoneOnKeyPress(java.awt.Component c) {
        c.removeKeyListener(keyAdapter);
        c.removeMouseListener(mouseAdaptor);
    }
    public void setisDoneOnKeyPress(java.awt.Component c) {
        c.addKeyListener(keyAdapter);
        c.addMouseListener(mouseAdaptor);
    }
    KeyListener keyAdapter = new KeyAdapter(){
            @Override
            public void keyReleased(KeyEvent keycode) {
                setDuration(0); // Force finish.
            }
        };
    MouseListener mouseAdaptor = new MouseAdapter(){
            @Override
            public void mouseReleased(java.awt.event.MouseEvent e){
                setDuration(0);                    
            }
        };    
}
