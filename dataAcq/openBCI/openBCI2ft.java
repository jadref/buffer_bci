import java.io.*;
import nl.fcdonders.fieldtrip.bufferclient.*;
//import OpenBCI_ADS1299;
//import jssc.SerialPortList;

class openBCI2ft {
	 static int VERB=1; // global verbosity level
	 static int BUFFERSIZE = 65500;

	 //these settings are for a single OpenBCI board
	 static int openBCIbaud = 115200;
	 static int OpenBCI_Nchannels = 8; //normal OpenBCI has 8 channels
	 static int openBCIvaluesperpacket = 8;
	 static int openBCIDataMode = OpenBCI_ADS1299.DATAMODE_BIN;

	 //use this for when daisy-chaining two OpenBCI boards
	 //int openBCIbaud = 2*115200; //baud rate from the Arduino
	 //final int OpenBCI_Nchannels = 16; //daisy chain has 16 channels

	 //properties of the openBCI board
	 static float fs_Hz = 250.0f;  //sample rate used by OpenBCI board
	 static private float ADS1299_Vref = 4.5f;  //reference voltage for ADC in ADS1299
	 static private float ADS1299_gain = 24;    //assumed gain setting for ADS1299
	 static private float scale_fac_uVolts_per_count = ADS1299_Vref / ((float)Math.pow(2,23)-1) / ADS1299_gain  * 1000000.f; //ADS1299 datasheet Table 7, confirmed through experiment
	 static private float openBCI_impedanceDrive_amps = (float)6.0e-9;  //6 nA
	 boolean isBiasAuto = true;

	 //other data fields
	 static int nchan = OpenBCI_Nchannels; //normally, nchan = OpenBCI_Nchannels
	 static int nchan_active_at_startup = nchan;  //how many channels to be LIVE at startup
	 static int n_aux_ifEnabled = 1;  //if DATASOURCE_NORMAL_W_AUX then this is how many aux channels there will be
	 static int prev_time_millis = 0;
	 DataStatus is_railed[];
	 final int threshold_railed = ((int)Math.pow(2,23))-1000;
	 final int threshold_railed_warn = (int)(Math.pow(2,23)*0.75);

	 //program constants
	 int openBCI_byteCount = 0;
	 int inByte = -1;    // Incoming serial data

	 public static void main(String[] args) throws IOException,InterruptedException {



		  // jssc.SerialPort serialPort = new jssc.SerialPort("/dev/ttyUSB0");
        // try {
        //     serialPort.openPort();//Open serial port
        //     serialPort.setParams(jssc.SerialPort.BAUDRATE_115200, 
        //                          jssc.SerialPort.DATABITS_8,
        //                          jssc.SerialPort.STOPBITS_1,
        //                          jssc.SerialPort.PARITY_NONE);
        //     serialPort.writeString("b");//Write data to port
		  // 		Thread.sleep(1000);
		  // 		byte [] resp=serialPort.readBytes();
		  // 		for ( int i=0; i<resp.length; i++ ) System.out.print((char)resp[i]);
        //     serialPort.closePort();//Close serial port
        // }
        // catch (Exception ex) {
        //     System.out.println(ex);
        // }
		  
		  if ( args.length==0 ) {
				System.out.println("openBCI2ft openBCIport bufferhost:bufferport nchannels openBCIsamplerate buffdownsampleratio buffpacketsize");
		  }
		  
		  // openBCI port
		  String    openBCIport    = null;
		  if (args.length>=1) {
				openBCIport=args[0];
		  }
		  // buffer host:port
		  String buffhostname = "localhost";
		  int buffport = 1972;
		  if (args.length>=2) {
				buffhostname = args[1];
				int sep = buffhostname.indexOf(':');
				if ( sep>0 ) {
					 buffport=Integer.parseInt(buffhostname.substring(sep+1,buffhostname.length()));
					 buffhostname=buffhostname.substring(0,sep);
				}
		  }
		  int nch = OpenBCI_Nchannels;
		  if (args.length>=3) { nch = Integer.parseInt(args[2]);	}
		  int sampleRate = (int)fs_Hz;
		  if (args.length>=4) { 
				System.out.println("Warning, samplerate fixed for this hardware. Argument ignored.");
				//sampleRate = Integer.parseInt(args[3]); 
		  }		  
		  int buffdownsample=1;
		  if (args.length>=5) { 
				System.out.println("Warning, buff-down-sample currently isn't supported.  Argument ignored.");
				//buffdownsample = Integer.parseInt(args[4]); 
		  }		  
		  int buffpacketsize=sampleRate/50;
		  if ( buffpacketsize<=0 ) buffpacketsize=1;
		  if (args.length>=6) { buffpacketsize = Integer.parseInt(args[5]); }		  

		  if ( openBCIport == null ) { // list available ports and exit
				System.out.println("No serial port defined.  Current serial ports connected are:");
				String[] portNames = jssc.SerialPortList.getPortNames();
				for(int i = 0; i < portNames.length; i++){
					 System.out.println(portNames[i]);
				}
				System.out.println();
				System.exit(1);
		  }
		  
		  // print the current settings
		  System.out.println("OPENBCI port: " + openBCIport);
		  System.out.println("Buffer server: " + buffhostname + " : " + buffport);
		  System.out.println("nCh : " + nch + " fs : " + sampleRate);
		  System.out.println("#samp/buf : " + buffdownsample + " buff_packet : " + buffpacketsize);

		  // open the connection to the buffer server		  
		  BufferClientClock C = new BufferClientClock();
		  while ( !C.isConnected() ) {
				System.out.println("Connecting to "+buffhostname+":"+buffport);
				try { 
					 C.connect(buffhostname, buffport);
				} catch (IOException ex){
				}
				if ( !C.isConnected() ) { 
					 System.out.println("Couldn't connect. Waiting");
					 Thread.sleep(1000);
				}
		  }
		  System.out.println("Connected to buffer!");
		
		  // send the header information
		  Header hdr = new Header(nch,sampleRate,DataType.FLOAT64);
		  if ( VERB>0 ){ System.out.println("Sending header: " + hdr.toString()); }
		  C.putHeader(hdr);
		
		  // open the openBCI port and start the data streaming
		  int nDataValuesPerPacket = nchan;
		  if (openBCIDataMode == OpenBCI_ADS1299.DATAMODE_BIN_WAUX) nDataValuesPerPacket += n_aux_ifEnabled;		  
		  DataPacket_ADS1299 curPacket = new DataPacket_ADS1299(nDataValuesPerPacket); 
		  OpenBCI_ADS1299 openBCI = null;
		  while ( true ) {
				try {
					 openBCI = new OpenBCI_ADS1299(openBCIport,openBCIbaud,nDataValuesPerPacket); // open port
					 break;
				} catch (Exception e) {
					 System.out.println("Trying to connect to serial port : " + openBCIport);
					 Thread.sleep(1000); 
				}
		  }		  
		  while ( openBCI.updateState()<=0 ){ // start data streaming					 break;
				System.out.println("Waiting for startup to complete, on port : " + openBCIport);
				Thread.sleep(1000); 
		  }
		  System.out.println("Connected to serial port.");
		  // Setup the channel set to use:
		  try {
				openBCI.startDataTransfer();
				//for ( int i=0; i<1000; i++) openBCI.read(true);
		  } catch ( Exception e) {
				System.err.println("Error changing sending state");
				System.err.println((jssc.SerialPortException)e);
				System.exit(-1);
		  }

		  byte[] buffer = new byte[BUFFERSIZE];
		  int openBCIsamp=0;  // current sample number in buffer-packet recieved from openBCI
		  int buffsamp=0; // current sample number in buffer-packet to send to buffer
		  int buffch=0;   // current channel number in buffer-packet to send to buffer
		  int numel=0;
		  int[] buffpacksz = new int[] {nch,buffpacketsize};
		  double[][] databuff = new double[buffpacketsize][nch];
		
	  		
		  long startT=System.currentTimeMillis();
		  long updateT=startT;
		  // Now do the data forwarding
		  while ( true ) {			 
				// wait for an OPENBCI message
				// read from serial port until a complete packet is available
				// Question: does this block intelligently?
				while ( !openBCI.isNewDataPacketAvailable ) {
					 if ( VERB>1 ){ System.out.println("Waiting for data packet from openBCI."); }
					 try { 
						  openBCI.read(false);
						  Thread.sleep(1000/sampleRate);
					 } catch (jssc.SerialPortException e){ // Catch all exceptions.. including SerialPortException
						  System.out.println("Serial port exception!");
						  System.err.println(e);
						  System.exit(-1);
					 }
				}
				if ( VERB>1 ){ System.out.println("Got a data packet from openBCI"); }
				// get (a copy of) the data just read
				openBCI.copyDataPacketTo(curPacket); 
				//next, gather the new data into the "little buffer"
				for (int Ichan=0; Ichan < nchan; Ichan++) {   //loop over each cahnnel
					 //scale the data into engineering units ("microvolts") and save to the "little buffer"
					 databuff[buffsamp][Ichan] += curPacket.values[Ichan] * scale_fac_uVolts_per_count;
				} 				
				// increment the cursor position
				if ( VERB>0 ){
					 if ( System.currentTimeMillis()-updateT > 10*1000 ) {
						  updateT=System.currentTimeMillis();
						  System.out.print((float)(System.currentTimeMillis()-startT)/1000.0 + "," + buffsamp + "\r");
					 }
				}

				// move to next buffer sample
				buffsamp++; // move to next buffer sample
				if ( buffsamp >= databuff.length ) { // got a full buffer packet's worth
					 if ( VERB>1 ){ System.out.println("Got buffer packets worth of data. Sending");}
					 // so forward to the buffer
					 // N.B. for efficiency this should probably be double-buffered (sic)
					 C.putData(databuff);
					 // clear out all the old data
					 for ( int i=0; i<databuff.length; i++){
						  for ( int j=0; j<databuff[i].length; j++){
								databuff[i][j]=0;
						  }
					 }
					 buffsamp=0;
				}
		  }
		  // should cleanup correctly... but java doesn't allow unreachable code..
		  // C.disconnect();
	 }
} // class
