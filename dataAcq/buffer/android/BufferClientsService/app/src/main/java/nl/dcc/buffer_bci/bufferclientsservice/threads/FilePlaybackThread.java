package nl.dcc.buffer_bci.bufferclientsservice.threads;

import nl.dcc.buffer_bci.bufferclientsservice.base.Argument;
import nl.dcc.buffer_bci.bufferclientsservice.base.ThreadBase;
import nl.dcc.buffer_bci.signalprocessing.FilePlayback;
import java.io.IOException;
import java.io.InputStream;


public class FilePlaybackThread extends ThreadBase {

    public static final String TAG = FilePlaybackThread.class.toString();

    private int VERB = 1; // global verbosity level
    private String hostname;
    private int port;
    private double speedup;
    private int blockSize;
    private String dataDir;
    private InputStream dataReader;
    private InputStream eventReader;
    private InputStream headerReader;

    @Override
    public Argument[] getArguments() {
        final Argument[] arguments = new Argument[4];

        arguments[0] = new Argument("Buffer Address", "localhost:1972");
        arguments[1] = new Argument("Speedup", 1.0, false);
        arguments[2] = new Argument("Buffer size", 5, false);
        arguments[3] = new Argument("Data directory", "res/raw/");
        return arguments;
    }

    @Override
    public String getName() {
        return "File Playback";
    }


    @Override
    public void validateArguments(Argument[] arguments) {
        final String address = arguments[0].getString();

        try {
            final String[] split = address.split(":");
            arguments[0].validate();
            try {
                Integer.parseInt(split[1]);
            } catch (final NumberFormatException e) {
                arguments[0].invalidate("Wrong hostname format.");
            }

        } catch (final ArrayIndexOutOfBoundsException e) {
            arguments[0].invalidate("Integer expected after colon.");
        }
    }

    private void initialize() {
        hostname = arguments[0].getString();
        int sep = hostname.indexOf(':');
        if ( sep>0 ) {
            port=Integer.parseInt(hostname.substring(sep+1,hostname.length()));
            hostname=hostname.substring(0,sep);
        }
        speedup = arguments[1].getDouble();
        blockSize = arguments[2].getInteger();
        dataDir = arguments[3].getString();
        android.updateStatus("Address: " + hostname + ":" + String.valueOf(port));
    }

    @Override
    public void mainloop() {
        initialize();
        initFiles();
        FilePlayback filePlayback = new FilePlayback(hostname,port,dataReader,eventReader,headerReader,speedup,blockSize);
        filePlayback.mainloop();
        stop();
    }

    public void stop() {
        super.stop();
        try {
            cleanup();
        } catch (final IOException e) {
            e.printStackTrace();
        }
    }

    void initFiles() {
        String samples_str = dataDir + "/samples";
        String events_str = dataDir + "/events";
        String header_str = dataDir + "/header";
		  try {
				if ( isExternalStorageReadable() ){ // if available read from external storage
				  dataReader=new FileInputStream(new File(Environment.getExternalFilesDir(),samples_str));
				  eventReader=new FileInputStream(new File(Environment.getExternalFilesDir(),events_str));
			  	  headerReader=new FileInputStream(new File(Environment.getExternalFilesDir(),header_str));
				} else {
					 android.util.Log.w("FilePlayback","External storage is not readable.");
					 dataReader = this.getClass().getClassLoader().getResourceAsStream(samples_str);
					 eventReader = this.getClass().getClassLoader().getResourceAsStream(events_str);
					 headerReader = this.getClass().getClassLoader().getResourceAsStream(header_str);
				}
		  } catch ( FileNotFoundException e ) {
				e.printStackTrace();
		  } catch ( IOException e ) {
				e.printStackTrace();
		  }
		  if ( dataReader==null ) {
				android.util.Log.w("FilePlayback","Huh, couldnt open file stream : " + samples_str);
		  }
	 }

    void cleanup() throws IOException {
        if (headerReader != null) {
            headerReader.close();
            headerReader = null;
        }
        if (eventReader != null) {
            eventReader.close();
            eventReader = null;
        }
        if (dataReader != null) {
            dataReader.close();
            dataReader = null;
        }
        run = false;
    }


}
