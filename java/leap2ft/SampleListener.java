package nl.dcc.buffer_bci;

import java.io.IOException;
import java.io.PrintWriter;

import leap.experiment.LeapToScreenData;

import com.leapmotion.leap.Controller;
import com.leapmotion.leap.Finger;
import com.leapmotion.leap.FingerList;
import com.leapmotion.leap.Frame;
import com.leapmotion.leap.Hand;
import com.leapmotion.leap.Listener;
import com.leapmotion.leap.Vector;

import nl.fcdonders.fieldtrip.bufferclient.*;


public class SampleListener extends Listener {
	
	private double[][] data;
	
	private PrintWriter writer;
	
	private Vector avgPos;
	private Frame frame;
	private LeapToScreenData ls;
	static int VERB=1; // global verbosity level
	static int BUFFERSIZE = 65500;
	private String[] args;
	
	private double lastX = -1000;
	private double lastY = -1000;
	private double lastZ = -1000;

	private BufferClientClock C;
	private BufferClientClock C2;
	
	public BufferClientClock getBCC() {
		return C;
	}
	
    public void onInit(Controller controller) {
    	System.out.println("initialized");
    }
    
    public void setUp(PrintWriter writer) {
    	ls = new LeapToScreenData();
    	this.writer = writer;

	  // buffer host:port
	  String buffhostname = "localhost";
	  int buffport = 1972;
	  int buffport2 = 1973;
	  if (args.length>=2) {
			buffhostname = args[1];
			int sep = buffhostname.indexOf(':');
			if ( sep>0 ) {
				 buffport=Integer.parseInt(buffhostname.substring(sep+1,buffhostname.length()));
				 buffhostname=buffhostname.substring(0,sep);
			}
	  }
	  
	  int nch = 3;
	  int sampleRate = 300;
	
	  // open the connection to the buffer server		  
	  C = new BufferClientClock();
	  C2 = new BufferClientClock();
	  while ( !C.isConnected() ) {
			System.out.println("Connecting to "+buffhostname+":"+buffport);
			try { 
			C.connect(buffhostname, buffport);
			} catch (IOException ex){
			}
			if ( !C.isConnected() ) { 
				 System.out.println("Couldn't connect. Waiting");
				 try {
					Thread.sleep(1000);
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
	  }
	  while ( !C2.isConnected() ) {
			System.out.println("Connecting to "+buffhostname+":"+buffport);
			try { 
			C2.connect(buffhostname, buffport);
			} catch (IOException ex){
			}
			if ( !C2.isConnected() ) { 
				 System.out.println("Couldn't connect. Waiting");
				 try {
					Thread.sleep(1000);
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
	  }
	
	  // send the header information
	  Header hdr = new Header(nch,sampleRate,DataType.FLOAT64);
	  if ( VERB>0 ){ System.out.println("Sending header: " + hdr.toString()); }
	  try {
		C.putHeader(hdr);
		C2.putHeader(hdr);
		} catch (IOException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
    }
    
    public void setData(String[] args) {
    	this.args = args;
    }

    public void onConnect(Controller controller) {
    }

    public void onDisconnect(Controller controller) {
    }

    public void onExit(Controller controller) {
    	System.out.println("exited");
        ls.show();
    }

    public void onFrame(Controller controller) {
    	//System.out.println("new frame");
    	
    	// Data that needs to be sent to buffer
    	data = new double[1][3]; // data -> X, Y, Z coordinates of the current frame
    	// Get the most recent frame and report some basic information
        frame = controller.frame();
        if (!frame.hands().isEmpty()) {
        	//System.out.println("hands not empty");
            // Get the first hand
            Hand hand = frame.hands().get(0);

            // Check if the hand has any fingers
            FingerList fingers = hand.fingers();
            
            //if (!fingers.isEmpty()) {
            if (fingers.count() == 1) { // calculate only when 1 finger is seen to prevent false data
                // Calculate the hand's average finger tip position
                avgPos = Vector.zero();
                for (Finger finger : fingers) {
                    avgPos = avgPos.plus(finger.tipPosition());
                }
                avgPos = avgPos.divide(fingers.count());
                ls.setAvgPos(avgPos);
                data[0][0] = avgPos.getX();
                data[0][1] = avgPos.getY();
                data[0][2] = avgPos.getZ();
                //System.out.println(data[0][0] + " " + data[0][1] + " " + data[0][2]);
                //if (data != null) {
					try {
						C.putData(data);
					} catch (IOException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
						//System.out.println(e.toString());
					}
				//}
            }
            else if (fingers.count() == 0) {
            	data[0][0] = -999;
            	data[0][1] = -999;
            	data[0][2] = -999;
            	try {
					C.putData(data);
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
					//System.out.println(e.toString());
				}
            }
            else {
            	if (!(lastX == -1000) && !(lastY == -1000) && !(lastZ == -1000)) {
            		 double newX = 1000;
            		 double newY = 1000;
            		 double newZ = 1000;
            		 for (Finger finger : fingers) {
            			 double tempX = finger.tipPosition().getX() - lastX;
            			 double tempY = finger.tipPosition().getY() - lastY;
            			 double tempZ = finger.tipPosition().getZ() - lastZ;
            			 // Euclidean distance
            			 if (Math.sqrt(tempX*tempX + tempY*tempY+ tempZ*tempZ) < (newX + newY + newZ)) {
            				 newX = tempX;
            				 newY = tempY;
            				 newZ = tempZ;
            			 }
            		 }
            		 data[0][0] = newX;
            		 data[0][1] = newY;
            		 data[0][2] = newZ;
            		 try {
						C.putData(data);
					} catch (IOException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
            	}
            	else {
            		avgPos = Vector.zero();
                    for (Finger finger : fingers) {
                        avgPos = avgPos.plus(finger.tipPosition());
                    }
                    avgPos = avgPos.divide(fingers.count());
                    data[0][0] = avgPos.getX();
                    data[0][1] = avgPos.getY();
                    data[0][2] = avgPos.getZ();
                    
                    try {
						C.putData(data);
					} catch (IOException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
            	}
            }
        }
        else {
        	data[0][0] = -888;
        	data[0][1] = -888;
        	data[0][2] = -888;
        	try {
				C.putData(data);
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
        }
        lastX = data[0][0];
        lastY = data[0][1];
        lastZ = data[0][2];
        writer.println(data[0][0] + "; " + data[0][1] + "; " + data[0][2]);
	}
        
    public Vector getAvgPos() {
    	if (!(avgPos == null))
    		return avgPos;
    	else
    		return Vector.zero();
    }
    
    public long getTimestamp() {
    	return frame.timestamp();
    }
    
    public LeapToScreenData getLS() {
    	return ls;
    }
    
}
