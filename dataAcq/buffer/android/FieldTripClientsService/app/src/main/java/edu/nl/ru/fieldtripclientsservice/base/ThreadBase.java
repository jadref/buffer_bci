package edu.nl.ru.fieldtripclientsservice.base;

import android.util.Log;
import nl.fcdonders.fieldtrip.bufferclient.BufferClient;
import nl.fcdonders.fieldtrip.bufferclient.Header;

import java.io.IOException;

public abstract class ThreadBase {

    public static final String TAG = ThreadBase.class.toString();

    public Argument[] arguments;
    protected boolean run = false;
    protected AndroidHandle android;

    protected boolean connect(final BufferClient client, final String address, final int port) throws IOException,
            InterruptedException {
        if (!client.isConnected()) {
            client.connect(address, port);
            android.updateStatus("Waiting for header.");
        } else {
            return false;
        }
        Header hdr = null;
        do {
            try {
                hdr = client.getHeader();
            } catch (IOException e) {
                if (!e.getMessage().contains("517")) {
                    throw e;
                }
                Thread.sleep(1000);
            }
        } while (hdr == null);
        return true;
    }

    public abstract Argument[] getArguments();

    public void setArguments(final Argument[] arguments) {
        this.arguments = arguments;
    }

    public abstract String getName();

    public abstract void mainloop();

    public void pause() {
        run = false;
    }

    public void setArgument(final Argument argument) {
        String argDescription = argument.getDescription();
        for (Argument arg : this.arguments) {
            if (arg.getDescription() == argDescription) {
                arg = argument;
                return;
            }
        }
        Log.i(TAG, "Argument " + argDescription + " does not exist.");
    }

    public void setHandle(final AndroidHandle android) {
        this.android = android;
    }

    public void stop() {
        run = false;
    }

    public abstract void validateArguments(final Argument[] arguments);

}
