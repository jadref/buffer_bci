package nl.dcc.buffer_bci;


/**
 * Class containing all the constants of this project.
 *
 * @author wieke
 */

public final class C {
    // Intents from controller to the server
    public static final String FILTER_FOR_SERVER = "nl.dcc.buffer_bci.bufferserverservice.serverfilter";
    // Broadcast events from the server service
    public static final String FILTER_FR0M_SERVER= "nl.dcc.buffer_bci.bufferserverservice";

    public static final String SEND_FLUSHBUFFER_REQUEST_TO_SERVICE = "nl.dcc.buffer_bci.bufferserverservice.action.FLUSH";
    public static final String SERVER_SERVICE_PACKAGE_NAME = "nl.dcc.buffer_bci"; // N.B. This MUST match the package the service is installed in
    public static final String SERVER_SERVICE_CLASS_NAME = "nl.dcc.buffer_bci.bufferserverservice.BufferServerService";
    public static final int    SERVER_SERVICE_NOTIFICATION_ID = 1;
    public static final int    SERVER_INFO_UPDATE_INTERVAL=5000; // time between heartbeat client info updates

    // Intents from controller to the clients
    public static final String FILTER_FOR_CLIENTS = "nl.dcc.buffer_bci.bufferclientsservice.clientsfilter";
    // Broadcast events from the client service
    public static final String FILTER_FROM_CLIENTS= "nl.dcc.buffer_bci.bufferclientsservice";
    public static final String CLIENTS_SERVICE_PACKAGE_NAME = "nl.dcc.buffer_bci"; // N.B. This MUST match the package the service is installed in!
    public static final String CLIENTS_SERVICE_CLASS_NAME = "nl.dcc.buffer_bci.bufferclientsservice.BufferClientsService";
    public static final int    CLIENTS_SERVICE_NOTIFICATION_ID = 2;
    public static final int    CLIENTS_INFO_UPDATE_INTERVAL=5000; // time between heartbeat client info updates

    // TODO: This should really just a be a broadcast from server/clients which is caught by the controller (or others) to update there status
    public static final String SEND_UPDATE_INFO_TO_CONTROLLER_ACTION = "nl.dcc.buffer_bci.bufferservicecontroller.action.UPDATEINFO";

    public static final String MESSAGE_TYPE = "a";

    public static final String IS_BUFFER_INFO = "b_info";
    public static final String BUFFER_INFO = "b";

    public static final String IS_BUFFER_CONNECTION_INFO = "c_info";
    public static final String BUFFER_CONNECTION_INFO = "c";
    public static final String BUFFER_CONNECTION_N_INFOS = "c_nClients";

    public static final String THREAD_INDEX = "t_index";
    public static final String THREAD_ID = "t_id";
    public static final String THREAD_ARGUMENTS = "t_args";
    public static final String THREAD_STRING_FOR_ARG = "t_arg_str";
    public static final String THREAD_N_ARGUMENTS = "t_nArgs";
    public static final String IS_THREAD_INFO = "t_Info";
    public static final String THREAD_INFO = "t";

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
    public static final int ERROR_PROTOCOL = 0;
    public static final int ERROR_CONNECTION = 1;
    public static final int ERROR_VERSION = 2;

    public static final String WAKELOCKTAG = "nl.dcc.buffer_bci.bufferservice.wakelock";

    public static final String WAKELOCKTAGWIFI = "nl.dcc.buffer_bci.bufferservice.wakelockwifi";
}
