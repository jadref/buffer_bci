package nl.dcc.buffer_bci;

import java.awt.Dimension;
import java.awt.Toolkit;
import java.io.FileNotFoundException;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;

import com.leapmotion.leap.Vector;

public class LeapToScreenData {

	private ArrayList<Vector> AvgPos;

	public LeapToScreenData() {
		AvgPos = new ArrayList<Vector>();
	}

	public void setAvgPos(Vector ap) {
		AvgPos.add(ap);
	}

	public void show() {
		Dimension screen = Toolkit.getDefaultToolkit().getScreenSize(); // Height: 900, Width: 1600
		try {
			new View(screen, AvgPos);
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
}
