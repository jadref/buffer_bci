package nl.dcc.buffer_bci;

import java.awt.*;
import java.io.FileNotFoundException;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;

import javax.swing.*;

import com.leapmotion.leap.Vector;

public class View extends JPanel {
	private static final long serialVersionUID = 1L;
	private JFrame frame;
	private ArrayList<Vector> points;
	private Dimension d;
	
	public View(Dimension d, ArrayList<Vector> points) throws FileNotFoundException, UnsupportedEncodingException {
		this.points = points;
		this.d = d;
		frame = new JFrame("Shapes");
		frame.setBounds(1000,1000,3000,1000);
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		frame.setLocationRelativeTo(null);
		frame.setVisible(true);
		frame.setSize(d.height,d.width);
		frame.add(this);
	}
	
	protected void paintComponent(Graphics g) {
	    super.paintComponent(g);
	    Graphics2D g2 = (Graphics2D) g;
		g2.setStroke(new BasicStroke(3));	
		for (int i = 0 ; i < points.size() - 1 ; i++) {
			g2.drawLine(Math.round(points.get(i).getX()) + d.width/2, -Math.round(points.get(i).getY()) + d.height - 50, Math.round(points.get(i+1).getX()) + d.width/2, -Math.round(points.get(i+1).getY()) + d.height - 50);
		}
    }
	
}
