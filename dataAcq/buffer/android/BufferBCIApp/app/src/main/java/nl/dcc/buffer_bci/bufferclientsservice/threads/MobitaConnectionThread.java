package nl.dcc.buffer_bci.bufferclientsservice.threads;

import android.os.Environment;
import android.util.Log;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;

import nl.dcc.buffer_bci.bufferclientsservice.base.Argument;
import nl.dcc.buffer_bci.bufferclientsservice.base.ThreadBase;
import nl.dcc.buffer_bci.Mobita2ft;


public class MobitaConnectionThread extends ThreadBase {

    public static final String TAG = MobitaConnectionThread.class.getSimpleName();

    private int VERB = 1; // global verbosity level
    private String bufferhostport;
    private String mobitahostport;
    private int blockSize;
    private float fSample;
    Mobita2ft mobita2ft =null;

    @Override
    public Argument[] getArguments() {
        final Argument[] arguments = new Argument[]{
                new Argument("Buffer Address", "localhost:1972"),
                new Argument("Sample Rate",250.0, false),
                new Argument("Buffer size", 5, false),
                new Argument("Mobita Address","10.11.12.13:4242"),
        };
        return arguments;
    }

    @Override
    public String getName() { return TAG; }

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
        bufferhostport = arguments[0].getString();
        int sep = bufferhostport.indexOf(':');
        if ( sep>0 ) {
            Integer.parseInt(bufferhostport.substring(sep+1,bufferhostport.length()));
        }
        mobitahostport = arguments[3].getString();
        sep = mobitahostport.indexOf(':');
        if ( sep>0 ) {
            Integer.parseInt(mobitahostport.substring(sep+1,mobitahostport.length()));
        }
        fSample   = arguments[1].getDouble().floatValue();
        blockSize = arguments[2].getInteger();
        androidHandle.updateStatus("Address: " + bufferhostport);
    }

    @Override
    public void mainloop() {
        initialize();
        mobita2ft = new Mobita2ft(bufferhostport, fSample, blockSize, mobitahostport);
        mobita2ft.mainloop();
        try {
            cleanup();
        } catch (IOException e) {
            e.printStackTrace();
        }
        mobita2ft=null;
    }

    @Override
    public void stop() { if ( mobita2ft!=null ) mobita2ft.stop(); }
    @Override public boolean isrunning(){ if ( mobita2ft !=null ) return mobita2ft.isrunning(); return false; }

    void cleanup() throws IOException {
        run = false;
    }


}
