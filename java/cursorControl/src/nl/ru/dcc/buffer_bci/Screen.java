package nl.ru.dcc.buffer_bci;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

// Generic interface for a screen in the experiment
interface Screen {
	 // This method is called every time the screen should be re-drawn
    public void render(Graphics g);
	 // Reset the screen to it's initial state and re-run
	 public void start();
	 public boolean isDone();
	 public long nextFrameTime();
};

class BlankScreen implements Screen {
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
	 public void render(Graphics gg) { }
};

class BlankWaitKeyScreen extends BlankScreen implements java.awt.event.KeyListener {
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


class InstructScreen implements Screen {
	 volatile long _t0=-1; // time we started running
	 int _duration_ms=1000; // time we run for
	 String _string=null;
	 java.awt.Component c=null;
	 InstructScreen(java.awt.Component cc){ c=cc;}
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
	 
	 public void render(Graphics gg) {
		  if ( _t0<0 ) return; // Do nothing if not started yet
		  Graphics2D g = (Graphics2D) gg;
		  String s = _string;
		  int x=(int)(c.getWidth()*.1);
		  int y=(int)(c.getHeight()*.3);
		  for ( String line : s.split("\n") ) {
				g.drawString(line,x,y);
				y+=g.getFontMetrics().getHeight();
		  }
		  
		  // Resume  controller thread when finished running
		  long elapsed_ms = java.lang.System.currentTimeMillis()-_t0;
		  // Write the run-time to the screen
		  g.drawString("Run-time: " + elapsed_ms + " / " + _duration_ms, 
							c.getWidth()/10, (c.getHeight()*9)/10);
	 }
};


class InstructWaitKeyScreen extends InstructScreen implements java.awt.event.KeyListener {
	 InstructWaitKeyScreen(java.awt.Component cc){ super(cc); }
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
