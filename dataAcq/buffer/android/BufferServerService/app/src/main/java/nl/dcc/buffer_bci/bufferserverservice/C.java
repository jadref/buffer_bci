package nl.dcc.buffer_bci.bufferserverservice;

import nl.fcdonders.fieldtrip.bufferserver.FieldtripBufferMonitor;

/**
 * Class containing all the constants of this project.
 *
 * @author wieke
 */
public final class C {
    public static final String FILTER = "nl.dcc.buffer_bci.bufferserverservice.filter";
    public static final String SEND_UPDATEINFO_TO_CONTROLLER_ACTION = "nl.dcc.buffer_bci.bufferservicecontroller.action.UPDATEINFO";

    public static final String MESSAGE_TYPE = "a";

    public static final String IS_BUFFER_INFO = "b_info";
    public static final String BUFFER_INFO = "b";
    public static final String BUFFER_INFO_ADDRESS = "b_address";
    public static final String BUFFER_INFO_NSAMPLES = "b_nSamples";
    public static final String BUFFER_INFO_NEVENTS = "b_nEvents";
    public static final String BUFFER_INFO_DATATYPE = "b_dataType";
    public static final String BUFFER_INFO_NCHANNELS = "b_nChannels";
    public static final String BUFFER_INFO_FSAMPLE = "b_fSample";
    public static final String BUFFER_INFO_STARTTIME = "b_startTime";

    public static final String IS_CLIENT_INFO = "c_info";
    public static final String CLIENT_INFO = "c";
    public static final String CLIENT_N_INFOS = "c_nClients";

    public static final String CLIENT_INFO_ADDRESS = "c_address";
    public static final String CLIENT_INFO_CLIENTID = "c_clientID";
    public static final String CLIENT_INFO_SAMPLESGOTTEN = "c_samplesGotten";
    public static final String CLIENT_INFO_SAMPLESPUT = "c_samplesPut";
    public static final String CLIENT_INFO_EVENTSGOTTEN = "c_eventsGotten";
    public static final String CLIENT_INFO_EVENTSPUT = "c_eventsPut";
    public static final String CLIENT_INFO_LASTACTIVITY = "c_lastActivity";
    public static final String CLIENT_INFO_WAITEVENTS = "c_waitEvents";
    public static final String CLIENT_INFO_WAITSAMPLES = "c_waitSamples";
    public static final String CLIENT_INFO_ERROR = "c_error";
    public static final String CLIENT_INFO_TIMELASTACTIVITY = "c_timeLastActivity";
    public static final String CLIENT_INFO_TIME = "c_time";
    public static final String CLIENT_INFO_WAITTIMEOUT = "c_waitTimeout";
    public static final String CLIENT_INFO_CONNECTED = "c_connected";
    public static final String CLIENT_INFO_CHANGED = "c_changed";
    public static final String CLIENT_INFO_DIFF = "c_diff";

    public static final int THREAD_INFO_TYPE = 0;
    public static final int UPDATE = 1;
    public static final int REQUEST_PUT_HEADER = 2;
    public static final int REQUEST_FLUSH_HEADER = 3;
    public static final int REQUEST_FLUSH_SAMPLES = 4;
    public static final int REQUEST_FLUSH_EVENTS = 5;
    public static final int THREAD_STOP = 6;
    public static final int THREAD_PAUSE = 7;
    public static final int THREAD_START = 8;
    public static final int THREAD_UPDATE_ARGUMENTS = 9;
    public static final int THREAD_UPDATE_ARG_FROM_STR = 10;
    public static final int THREAD_INFO_BROADCAST=11;
    public static final int BUFFER_INFO_BROADCAST=12;

    public static final int BUFFER_INFO_PARCEL = 0;
    public static final int CLIENT_INFO_PARCEL = 1;

    public static final int CONNECTED = 0;
    public static final int DISCONNECTED = 1;
    public static final int GOTSAMPLES = 2;
    public static final int GOTEVENTS = 3;
    public static final int GOTHEADER = 4;
    public static final int PUTSAMPLES = 5;
    public static final int PUTEVENTS = 6;
    public static final int PUTHEADER = 7;
    public static final int FLUSHSAMPLES = 8;
    public static final int FLUSHEVENTS = 9;
    public static final int FLUSHHEADER = 10;
    public static final int POLL = 11;
    public static final int WAIT = 12;
    public static final int STOPWAITING = 13;

    public static final int ERROR_NONE = -1;
    public static final int ERROR_PROTOCOL = FieldtripBufferMonitor.ERROR_PROTOCOL;
    public static final int ERROR_CONNECTION = FieldtripBufferMonitor.ERROR_CONNECTION;
    public static final int ERROR_VERSION = FieldtripBufferMonitor.ERROR_VERSION;

    public static final String WAKELOCKTAG = "nl.dcc.buffer_bci.bufferservice.wakelock";

    public static final String WAKELOCKTAGWIFI = "nl.dcc.buffer_bci.bufferservice.wakelockwifi";
}
