package nl.dcc.buffer_bci;
import java.io.*;
import com.leapmotion.leap.Controller;

public class leap2ft {	 
		 
    public static void main(String[] args) throws IOException,InterruptedException {
        // Create a sample listener and controller
        PrintWriter writer = new PrintWriter("outputleap.txt", "UTF-8");
        SampleListener listener = new SampleListener();
        Controller controller = new Controller();
        listener.setData(args);
        listener.setUp(writer);
		        
        // Have the sample listener receive events from the controller
        controller.addListener(listener);
		        
        new Events(listener, writer);
		        
        // Keep this process running until Enter is pressed
        System.out.println("Press Enter to quit...");
        try {
            System.in.read();
        } catch (IOException e) {
            e.printStackTrace();
        }
        
        // Remove the sample listener when done
        controller.removeListener(listener);
        writer.close();

        // should cleanup correctly... but java doesn't allow unreachable code..
        // C.disconnect();
        // oscsock.close();
    }
}

