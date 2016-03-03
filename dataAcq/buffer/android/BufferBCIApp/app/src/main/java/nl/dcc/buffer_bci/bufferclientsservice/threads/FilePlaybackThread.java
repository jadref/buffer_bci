package nl.dcc.buffer_bci.bufferclientsservice.threads;

import android.annotation.TargetApi;
import android.os.Build;
import android.os.Environment;
import android.util.Log;

import nl.dcc.buffer_bci.bufferclientsservice.base.Argument;
import nl.dcc.buffer_bci.bufferclientsservice.base.ThreadBase;
import nl.dcc.buffer_bci.FilePlayback;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
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
    FilePlayback filePlayback=null;

    @Override
    public Argument[] getArguments() {
        final Argument[] arguments = new Argument[]{
                new Argument("Buffer Address", "localhost:1972"),
        new Argument("Speedup", 1.0, false),
        new Argument("Buffer size", 5, false),
        new Argument("Data directory", "raw_buffer/")
        };
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
        androidHandle.updateStatus("Address: " + hostname + ":" + String.valueOf(port));
    }

    @Override
    public void mainloop() {
        initialize();
        try {
            initFiles();
        } catch (FileNotFoundException e) { // abort if can't open files
            run=false;
            return;
        }
        filePlayback = new FilePlayback(hostname,port,dataReader,eventReader,headerReader,speedup,blockSize);
        filePlayback.mainloop();
        try {
            cleanup();
        } catch (IOException e) {
            e.printStackTrace();
        }
        filePlayback=null;
    }

    @Override
    public void stop() { if ( filePlayback!=null ) filePlayback.stop(); }
    @Override public boolean isrunning(){ if ( filePlayback!=null ) return filePlayback.isrunning(); return false; }


    void initFiles() throws FileNotFoundException {
        if ((dataDir.length() != 0) && !dataDir.endsWith("/")) { dataDir = dataDir + "/"; } // guard path if needed
        String samples_str = dataDir + "samples";
        String events_str = dataDir + "events";
        String header_str = dataDir + "header";
        if ( isExternalStorageReadable() ) { // if available read from external storage
            try {
                dataReader = androidHandle.openReadFile(samples_str);
                eventReader = androidHandle.openReadFile(events_str);
                headerReader = androidHandle.openReadFile(header_str);
            } catch (FileNotFoundException e) {
                e.printStackTrace();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        if ( dataReader == null ){ // fall back on the resources directory
            Log.w("FilePlayback", "External storage is not readable.");
            dataReader = this.getClass().getClassLoader().getResourceAsStream("assets/"+samples_str);
            eventReader = this.getClass().getClassLoader().getResourceAsStream("assets/"+events_str);
            headerReader = this.getClass().getClassLoader().getResourceAsStream("assets/"+header_str);
        }
        if ( dataReader==null ) {
            Log.w("FilePlayback", "Huh, couldn't open file stream : " + samples_str);
            throw new FileNotFoundException(samples_str);
        }
    }

    /* Checks if external storage is available for read and write */
    public boolean isExternalStorageWritable() {
        String state = Environment.getExternalStorageState();
        return Environment.MEDIA_MOUNTED.equals(state);
    }
    /* Checks if external storage is available to at least read */
    public boolean isExternalStorageReadable() {
        String state = Environment.getExternalStorageState();
        if (Environment.MEDIA_MOUNTED.equals(state) ||
                Environment.MEDIA_MOUNTED_READ_ONLY.equals(state)) {
            return true;
        }
        return false;
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
