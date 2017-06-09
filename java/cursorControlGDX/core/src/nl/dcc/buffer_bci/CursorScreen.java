package nl.ru.dcc.buffer_bci;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
package nl.dcc.buffer_bci;
import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.utils.TimeUtils;


// Generic interface for a screen in the experiment
interface CursorScreen {
	 // This method is called every time the screen should be re-drawn
    public void render(float delta);
	 // Reset the screen to it's initial state and re-run
	 public void start();
	 public boolean isDone();
	 public long nextFrameTime();
};

class BlankScreen implements Screen, CursorScreen {
	final Game game;
    OrthographicCamera camera;

	public BlankScreen(final Game gam){
		this.game=gam;
        // create the camera and the SpriteBatch
        camera = new OrthographicCamera();
        camera.setToOrtho(false, 800, 480);
	}

	 volatile long _t0=-1; // time we started running
	 int _duration_ms=1000; // time we run for
	 public void setDuration_ms(int duration_ms){ _duration_ms=duration_ms; }
	 public void setDuration(float duration){ _duration_ms=(int)(duration*1000); }
	 public int getDuration(){ return _duration_ms; }
	 public void start(){  
		  System.out.println("BlankScreen : " + _duration_ms);				 
		  _t0=java.lang.System.currentTimeMillis(); 
	 }
	 public boolean isDone(){
		  boolean _isDone = _t0>0 && java.lang.System.currentTimeMillis() > _duration_ms + _t0;		  
		  if ( _isDone ){
				System.out.println("Run-time: " + (java.lang.System.currentTimeMillis()-_t0) + " / " + _duration_ms);
		  }
		  return _isDone;
	 }
	 public long nextFrameTime(){return _t0>0?_t0+_duration_ms:0;}
	 public void render(float delta) {
         // clear the screen with a dark blue color. The
         // arguments to glClearColor are the red, green
         // blue and alpha component in the range [0,1]
         // of the color to be used to clear the screen.
         Gdx.gl.glClearColor(0, 0, 0.2f, 1);
         Gdx.gl.glClear(GL10.GL_COLOR_BUFFER_BIT);

         // tell the camera to update its matrices.
         camera.update();
     }
};

// TODO [] : convert to use GDX input drivers
class BlankWaitKeyScreen extends BlankScreen implements java.awt.event.KeyListener, CursorScreen {
	 @Override
	 public void keyTyped(java.awt.event.KeyEvent event) {
		  //System.out.println("Got keyTyped event");
		  setDuration(0); // set screen duration =0 to force it to finish
	 }
	 @Override public void keyPressed(java.awt.event.KeyEvent event) { }
	 @Override public void keyReleased(java.awt.event.KeyEvent event) { }
	 // Independent of duration force re-draw check at least every 250ms
	 @Override
	 public long nextFrameTime(){return _t0>0?_t0+Math.min(250,_duration_ms):0;}
}


class InstructScreen implements Screen, CursorScreen {
	final Game game;
    OrthographicCamera camera;

	 volatile long _t0=-1; // time we started running
	 int _duration_ms=1000; // time we run for
	 String _string=null;
	public InstructScreen(final Game gam){
		this.game=gam;
        // create the camera and the SpriteBatch
        camera = new OrthographicCamera();
        camera.setToOrtho(false, 800, 480);
	}
	 public void setDuration_ms(int duration_ms){ _duration_ms=duration_ms; }
	 public void setDuration(float duration){ _duration_ms=(int)(duration*1000); }
	 public int getDuration(){ return _duration_ms; }
	 public void start(){ // just record the current time so we know when to quit
		  System.out.println("Instruct Start : " + _duration_ms);				 
		  _t0=java.lang.System.currentTimeMillis();
	 }
	 public boolean isDone(){
		  boolean _isDone = _t0>0 && java.lang.System.currentTimeMillis() > _duration_ms + _t0;		  
		  if ( _isDone ){
				System.out.println("Run-time: " + (java.lang.System.currentTimeMillis()-_t0) + " / " + _duration_ms);
		  }
		  return _isDone;
	 }
	 public long nextFrameTime(){return _t0>0?_t0+_duration_ms:0;}
	 public void setString(String str){_string=str;}

	@override
	 public void render(float delta) {
		//TODO []: convert to use GDX drawing commands
		  if ( _t0<0 ) return; // Do nothing if not started yet
        // tell the SpriteBatch to render in the
        // coordinate system specified by the camera.
        game.batch.setProjectionMatrix(camera.combined);

        // begin a new batch and draw the bucket and
        // all drops
        game.batch.begin();
        String s = _string;
        int x=(int)(c.getWidth()*.1);
        int y=(int)(c.getHeight()*.3);
        for ( String line : s.split("\n") ) {
            game.font.draw(game.batch,line,x,y);
            y+=game.font.getFontMetrics().getHeight();
        }
        // Write the run-time to the screen
        g.drawString("Run-time: " + elapsed_ms + " / " + _duration_ms,
                camera.getWidth()/10, (camera.getHeight()*9)/10);
        game.batch.end();

        // Resume  controller thread when finished running
        long elapsed_ms = java.lang.System.currentTimeMillis()-_t0;
	 }
};

class InstructWaitKeyScreen extends InstructScreen implements java.awt.event.KeyListener {
	 InstructWaitKeyScreen(final Game gam) { super(gam); }
	 @Override
	 public void keyTyped(java.awt.event.KeyEvent event) {
		  //System.out.println("Got keyTyped event");
		  setDuration(0); // set screen duration =0 to force it to finish
	 }
	 @Override public void keyPressed(java.awt.event.KeyEvent event) {}
	 @Override public void keyReleased(java.awt.event.KeyEvent event) {}

	 // Independent of duration force re-draw check=keyPress check at least every 250ms
	 @Override
	 public long nextFrameTime(){return _t0>0?Math.min(java.lang.System.currentTimeMillis()+250,_t0+_duration_ms):0;}
}
