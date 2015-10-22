package nl.dcc.buffer_bci.bufferclientsservice.base;

public abstract class BufferThread {

    public abstract Argument[] getArguments();

    public abstract String getName();

    public abstract void mainloop();

    public abstract boolean validateArguments(Argument[] arguments);

}
