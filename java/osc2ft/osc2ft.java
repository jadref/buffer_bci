import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.SocketException;
import java.io.*;
import nl.fcdonders.fieldtrip.bufferclient.*;
import com.illposed.osc.*;
import com.illposed.osc.utility.OSCByteArrayToJavaConverter;

class osc2ft {
	 static int VERB=0; // global verbosity level
	 static int BUFFERSIZE = 65500;

	 public static void main(String[] args) throws IOException,InterruptedException {
		  
		  if ( args.length==0 ) {
				System.out.println("osc2ft oscaddress:oscport bufferhost:bufferport nchannels oscsamplerate buffdownsampleratio buffpacketsize calgain caloffset");
		  }
		  
		  // osc address:port
		  String oscaddress = "/data";
		  int    oscport    = 5555;
		  if (args.length>=1) {
				oscaddress = args[0];
				int sep = oscaddress.indexOf(':');
				if ( sep>0 ) {
					 oscport=Integer.parseInt(oscaddress.substring(sep+1,oscaddress.length()));
					 oscaddress=oscaddress.substring(0,sep);
				}
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
		  int nch = 4;
		  if (args.length>=3) { nch = Integer.parseInt(args[2]);	}
		  int sampleRate = 100;
		  if (args.length>=4) { sampleRate = Integer.parseInt(args[3]); }		  
		  int buffdownsample=1;
		  if (args.length>=5) { 
				System.out.println("Warning, buff-down-sample currently isn't supported.  Argument ignored.");
				//buffdownsample = Integer.parseInt(args[4]); 
		  }		  
		  int buffpacketsize=1;		  
		  if (args.length>=6) { buffpacketsize = Integer.parseInt(args[5]); }		  
		  double calgain=1;		  
		  if (args.length>=7) { calgain = Double.parseDouble(args[6]); }		  
		  double caloffset=0;		  
		  if (args.length>=8) { caloffset = Double.parseDouble(args[7]); }		  
		  
		  // print the current settings
		  System.out.println("OSC server: " + oscaddress + " : " + oscport);
		  System.out.println("Buffer server: " + buffhostname + " : " + buffport);
		  System.out.println("nCh : " + nch + " fs : " + sampleRate);
		  System.out.println("#samp/buf : " + buffdownsample + " buff_packet : " + buffpacketsize);
		  System.out.println("calgain : " + calgain + " caloffset : " + caloffset);
		  
		
		  // open the listening connection to the OSC server
		  DatagramSocket oscsock = new DatagramSocket(oscport);
		  oscsock.setReceiveBufferSize(10*BUFFERSIZE); // make the net receive buffer big
		  byte[] buffer = new byte[BUFFERSIZE];
		  int oscsamp=0;  // current sample number in buffer-packet recieved from osc
		  int buffsamp=0; // current sample number in buffer-packet to send to buffer
		  int buffch=0;   // current channel number in buffer-packet to send to buffer
		  int numel=0;
		  int[] buffpacksz = new int[] {nch,buffpacketsize};
		  double[][] databuff = new double[buffpacketsize][nch];
		  DatagramPacket packet = new DatagramPacket(buffer, BUFFERSIZE);
		  OSCByteArrayToJavaConverter converter = new OSCByteArrayToJavaConverter();
		
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
		
		  // send the header information
		  Header hdr = new Header(nch,sampleRate,DataType.FLOAT64);
		  if ( VERB>0 ){ System.out.println("Sending header: " + hdr.toString()); }
		  C.putHeader(hdr);
	  		
		  // Now do the data forwarding
		  while ( true ) {			 
				// wait for an OSC message
				oscsock.receive(packet);
				// parse the message and extract (if needed) into a set of messages to process
				OSCPacket oscPacket = converter.convert(buffer,packet.getLength());
				OSCPacket[] packets;
				java.util.Date timeStamp;
				if (oscPacket instanceof OSCBundle) { 
					 timeStamp = ((OSCBundle) oscPacket).getTimestamp();
					 packets   = ((OSCBundle) oscPacket).getPackets();
				} else {
					 packets = new OSCPacket[1];
					 packets[0] = oscPacket;
				}
				// process all the messages
				if ( VERB>0 ){ System.out.println("Got " + packets.length + " OSC packet(s).");}
				for ( int pi=0; pi<packets.length; pi++ ) { 
					 OSCPacket curPacket = packets[pi];
					 if ( curPacket instanceof OSCBundle ) {
						  System.out.println("Error bundle within bundle! igored");
						  continue;
					 } 
					 // OSC message
					 OSCMessage curMessage = (OSCMessage)curPacket;
					 String address = curMessage.getAddress();
					 Object[] msgargs  = curMessage.getArguments();
					 if ( VERB>0 ){ System.out.println(pi + ") " + address + " (" + msgargs.length + ")"); }
					 if ( address.equals(oscaddress) ) { // data to work with
						  if ( VERB>0 ){ System.out.println("Message matches data address, proc arguments"); }
						  // extract the data and store in the dataBuffer to be sent to the FT buffer
						  // all arguments should be data to forward, and hence convertable to double
						  for ( int di=0; di<msgargs.length; di++){
								if ( msgargs[di] instanceof Integer ) {
									 databuff[buffsamp][buffch] += ((Integer)msgargs[di]).doubleValue()*calgain+caloffset;
								} else if ( msgargs[di] instanceof Float ) {
									 databuff[buffsamp][buffch] += ((Float)msgargs[di]).doubleValue()*calgain+caloffset;
								} else if ( msgargs[di] instanceof Double ) {
									 databuff[buffsamp][buffch] += ((Double)msgargs[di]).doubleValue()*calgain+caloffset;
								} else { // not something we can work with!
									 System.out.println("Unsupported data type, ignored");
								}

								// increment the cursor position
								if ( VERB>0 ){ System.out.print('.');} 
								buffch++; numel++;
								// move to next buffer sample
								// assume each osc packet corresponds to *at least* all channels for 1 sample
								if(buffch>=databuff[buffsamp].length || buffch==msgargs.length){ 
									 if ( VERB>0 ){ System.out.println("Got 1 samples worth of data"); }
									 buffch=0; oscsamp++; // start new sample
									 buffsamp++; // move to next buffer sample
									 if ( buffsamp >= databuff.length ) { // got a full buffer packet's worth
										  if ( VERB>0 ){ System.out.println("Got buffer packets worth of data. Sending");}
										  // so forward to the buffer
										  // N.B. for efficiency this should probably be double-buffered (sic)
										  C.putData(databuff);
										  // clear out all the old data
										  for ( int i=0; i<databuff.length; i++){
												for ( int j=0; j<databuff[i].length; j++){
													 databuff[i][j]=0;
												}
										  }
										  oscsamp=0; buffsamp=0;
									 }
								}
						  }
					 }
				} // messages in the received packet
		  }
		  // should cleanup correctly... but java doesn't allow unreachable code..
		  // C.disconnect();
		  // oscsock.close();
	 }
}
