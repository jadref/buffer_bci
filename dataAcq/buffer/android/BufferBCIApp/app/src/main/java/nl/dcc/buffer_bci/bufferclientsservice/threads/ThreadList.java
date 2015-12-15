package nl.dcc.buffer_bci.bufferclientsservice.threads;

public abstract class ThreadList {
    public static final Class[] list = {
		  SignalProxyThread.class,
		  FilePlaybackThread.class,
		  MuseConnection.class,
		  //Toaster.class,
		  AlphaContClassifierThread.class,
		  //ContinuousClassifierThread.class,
		  AlphaLatContClassifierThread.class,
    };
}
