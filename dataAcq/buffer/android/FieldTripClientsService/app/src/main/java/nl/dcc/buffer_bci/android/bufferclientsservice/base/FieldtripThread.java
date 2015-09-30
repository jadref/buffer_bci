package nl.dcc.buffer_bci.android.bufferclientsservice.base;

public abstract class FieldtripThread {

    public abstract Argument[] getArguments();

    public abstract String getName();

    public abstract void mainloop();

    public abstract boolean validateArguments(Argument[] arguments);

}
