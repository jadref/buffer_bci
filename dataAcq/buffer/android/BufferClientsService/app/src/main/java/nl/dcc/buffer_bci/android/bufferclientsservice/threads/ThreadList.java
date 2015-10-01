package nl.dcc.buffer_bci.android.bufferclientsservice.threads;

public abstract class ThreadList {
    public static final Class[] list = {
            FilePlaybackThread.class,
            Toaster.class,
            ContinuousClassifierThread.class,
            MuseConnection.class
    };
}
