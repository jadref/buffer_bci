package nl.dcc.buffer_bci.bufferclientsservice.base;

import android.util.Log;
import nl.fcdonders.fieldtrip.bufferclient.BufferClient;
import nl.fcdonders.fieldtrip.bufferclient.Header;

import java.io.IOException;

public abstract class ThreadBase {

    public static final String TAG = ThreadBase.class.toString();

    public Argument[] arguments;
    protected boolean run = false;
    protected AndroidHandle androidHandle;

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
            if (arg.getDescription().equals(argDescription)) {
                arg = argument;
                return;
            }
        }
        Log.i(TAG, "Argument " + argDescription + " does not exist.");
    }

    public void setHandle(final AndroidHandle android) {
        this.androidHandle = android;
    }

    public void stop() {
        run = false;
    }
    public boolean isrunning(){ return run; }

    public abstract void validateArguments(final Argument[] arguments);

}
