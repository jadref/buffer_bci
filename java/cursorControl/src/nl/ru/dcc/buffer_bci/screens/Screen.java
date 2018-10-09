package nl.ru.dcc.buffer_bci.screens;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

// Generic interface for a screen in the experiment
public interface Screen {
	 // This method is called every time the screen should be re-drawn
    public void render(Component c, Graphics g, float deltatime);
	 // Reset the screen to it's initial state and re-run
	 public void start();
	 public boolean isDone();
	 public long nextFrameTime();

    public void log(String str);
};
