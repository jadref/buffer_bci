/**
 *
 * @author Philip van den Broek, TSG, Radboud University, Nijmegen
 * 
 * 
 */

import com.sun.jna.NativeLibrary;
import edu.ucsd.sccn.LSL;
import java.io.*;
import java.security.CodeSource;
//import nl.fcdonders.fieldtrip.bufferserver.BufferServer;
import nl.fcdonders.fieldtrip.bufferclient.*;

public class Lsl2ft {
    //private static BufferServer ftServer = null;
    private static BufferClient ftClient = null;
    //boolean putHeader(final int nChans, final float fSample,final int dataType)
    
    public static void main(String[] args) throws Exception{
        // arguments: LSL type stream, FieldTrip ip-address, FieldTrip port
        String address = "localhost";
        String LSLstream;
        int port;         
        String path;
        if (args.length < 1) LSLstream  = "EEG";       else LSLstream  = args[0];
        if (args.length < 2) port       = 1972;        else port       = Integer.parseInt(args[1]);
        if (args.length < 3) path       = "";          else path       = args[2]; 
                    
        System.out.println("Connecting to LabStreamingLayer supported device:\n");
        System.out.println("Type LSL stream                        : " + LSLstream);
        System.out.println("Forwarding to FieldTrip buffer on port : " + port);
        if (path.isEmpty())  System.out.println("Not saving data!");
        else System.out.println("Saving to                              : " + path);
            
        
        CodeSource codeSource = Lsl2ft.class.getProtectionDomain().getCodeSource();
        File jarFile = new File(codeSource.getLocation().toURI().getPath());
        String jarDir = jarFile.getParentFile().getPath();

        NativeLibrary.addSearchPath("liblsl64.dylib", jarDir);
        NativeLibrary.addSearchPath("liblsl64.dll", jarDir);
        LSL.StreamInfo[] results = LSL.resolve_stream("type",LSLstream);        
        LSL.StreamInlet sinlet = new LSL.StreamInlet(results[0]);
        LSL.StreamInfo sinfo = sinlet.info();
        System.out.println("Connected to LSL type '" +sinfo.type()+ "' stream from device: " +sinfo.name());
               
//         // start fieldtrip buffer server (LSL data will be forwarded to this buffer)
//         ftServer = new BufferServer();
//         ftServer.Start(port,1024*60,10*60,path);
        
        // fieldtrip client forwards LSL data to fieltrip server                
        ftClient = new BufferClient();
        // wait a bit for client to be initialized
        java.lang.Thread.sleep(100);
        // connect to server
        System.out.println("Connect FieldTrip client to FieldTrip buffer server");
        try {
            ftClient.connect(address,port);
        }
        catch (IOException e) {
                System.out.println("Cannot connect to FieldTrip buffer @ " + address + ":" + port + " \n");
                cleanup();
        }        
        System.out.println("Client connected to FieldTrip buffer @ " + address + ":" + port + " \n");     
        // create fieldtrip header from lsl header info
        float samplerate         = (float)sinfo.nominal_srate();
        int numChans             = sinfo.channel_count();
        boolean doProcessTrigger = false;
        int triggerChannel       = 0;
        
        // create fieldtrip header from lsl meta data (https://code.google.com/p/xdf/wiki/EEGMetaData)
        Header hdr = new Header(numChans, samplerate, DataType.FLOAT32);        
        // add label info
        LSL.XMLElement ch = sinfo.desc().child("channels").child("channel");
        for (int k=0;k<sinfo.channel_count();k++) {
            hdr.labels[k] = ch.child_value("label");
            System.out.println("  " + ch.child_value("label"));
            ch = ch.next_sibling();
            // check for trigger channel, only for  Cognionics device (needs improvement for generalization)
            if (sinfo.type().equals("EEG") & sinfo.name().startsWith("Cog MPB") & hdr.labels[k].equals("TRIGGER")) {
                doProcessTrigger = true;
                triggerChannel = k;
            }
            
            // add ... dataType and labels
            //     <unit>            <!-- measurement unit (strongly preferred unit: microvolts) --> 
            //     <type>            <!-- channel content-type (EEG, EMG, EOG, ...) --> 
            //     <label>           <!-- channel label, according to labeling scheme;             
        }        
        // send header info to fieldtrip server
        System.out.println("Send LSL header to fieldtrip buffer");
        ftClient.putHeader(hdr);
        
        System.out.println("Start streaming data");
        // todo: constanten eruit!!
        long counter = 0;
        try {            
            float[]     isample = new float[numChans];
            float[][]   osample = new float[1][numChans];
            float       oldTrig = 0;
            while (true) {
                // receive data
                sinlet.pull_sample(isample);// sinlet.pull_sample(sample,0.0) specify timeout>=0 for non-blocking
                counter = counter + 1;
                for(int j=0;j<isample.length;j++) {
                    osample[0][j] = isample[j];
                }
                ftClient.putData(osample);
                if (counter % (int)samplerate == 1) {
                    System.out.println("Sample " + counter);//print progress every second
                }
                // do we need to translate trigger channel to FieldTrip events
                if (doProcessTrigger==true) {
                    if (isample[triggerChannel] != oldTrig) {
                        if (counter > 1 & isample[triggerChannel]!=0) {
                            // send FieldTrip event
                            int trigger;
                            String io_interface;
                            if (isample[triggerChannel]<256) {
                                trigger = (int)isample[triggerChannel];
                                io_interface = "parallel";
                            }
                            else {
                                // NB: Note that the numbers are scaled up by a factor of 256. 
                                // This is to make sure that the the serial port codes 
                                // to not conflict with the codes from the parallel port
                                trigger = (int)isample[triggerChannel]/256;
                                io_interface = "serial";
                            }
                            BufferEvent e = new BufferEvent("stimulus",trigger,counter);
                            ftClient.putEvent(e);
                            System.out.println("******* Trigger marker (" + io_interface + ") " + trigger + " event sent to FieldTrip buffer ******");
                        }
                        oldTrig = isample[triggerChannel];
                    }
                }
            }
        } finally {
            cleanup();
        }    
    }
    private static void cleanup() throws IOException {
        System.out.println("Cleanup lsl2ft....\n");                
        if (ftClient != null) {
            ftClient.disconnect();
        }
//         if (ftServer != null) {
//             ftServer.stopBuffer();
//             ftServer.cleanup();
//         }
        System.exit(-1);
    }
}
