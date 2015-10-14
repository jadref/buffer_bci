package nl.dcc.buffer_bci.bufferclientsservice.threads;

import nl.dcc.buffer_bci.bufferclientsservice.base.Argument;
import nl.dcc.buffer_bci.bufferclientsservice.base.ThreadBase;
import nl.dcc.buffer_bci.SignalProxy;
import java.io.IOException;
import java.io.InputStream;


public class SignalProxyThread extends ThreadBase {

    public static final String TAG = SignalProxyThread.class.toString();

    private int VERB = 1; // global verbosity level
    private String hostname;
    private int port;
    private int blockSize;
	 private float fSample;

    @Override
    public Argument[] getArguments() {
        final Argument[] arguments = new Argument[4];

        arguments[0] = new Argument("Buffer Address", "localhost:1972");
        arguments[1] = new Argument("nChannels", 4, false);
        arguments[2] = new Argument("Sample Rate", 100, false);
        arguments[3] = new Argument("Blocksize", 1, false);
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
		  nChannels = arguments[1].getInteger();
        fSample = arguments[2].getString();
        blockSize = arguments[3].getInteger();
        android.updateStatus("Address: " + hostname + ":" + String.valueOf(port));
    }

    @Override
    public void mainloop() {
        initialize();
        SignalProxy signalProxy = new SignalProxy(hostname,port,nChannels,fSample,blockSize);
        signalProxy.mainloop();
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
