package bmird.radboud.fieldtripbufferservicecontroller;


/**
 * Class containing all the constants of this project.
 *
 * @author wieke
 *
 */

public final class C {
	public static final String FILTER_FROM_SERVER = "bmird.radboud.fieldtripbufferservicecontroller.serverfilter";
    public static final String FILTER_FOR_CLIENTS = "bmird.radboud.fieldtripclientsservice.clientsfilter";
    public static final String SEND_FLUSHBUFFER_REQUEST_TO_SERVICE = "bmird.radboud.fieldtripserverservice.action.FLUSH";
    public static final String SERVER_SERVICE_PACKAGE_NAME = "bmird.radboud.fieldtripserverservice";
    public static final String SERVER_SERVICE_CLASS_NAME = "bmird.radboud.fieldtripserverservice.FieldTripServerService";
    public static final String CLIENTS_SERVICE_PACKAGE_NAME = "bmird.radboud.fieldtripclientsservice";
    public static final String CLIENTS_SERVICE_CLASS_NAME = "bmird.radboud.fieldtripclientsservice.FieldTripClientsService";

	public static final String MESSAGE_TYPE = "a";

    public static final String IS_BUFFER_INFO = "b_info";
	public static final String BUFFER_INFO = "b";

    public static final String IS_CLIENT_INFO = "c_info";
    public static final String CLIENT_INFO = "c";
    public static final String CLIENT_N_INFOS = "c_nClients";

    public static final String THREAD_INDEX = "t_index";
    public static final String THREAD_ID = "t_id";
    public static final String THREAD_ARGUMENTS = "t_args";
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

	public static final String TAG = "fieldtripbuffer_service_controller";

	public static final String WAKELOCKTAG = "com.dcc.fieldtripbuffer.wakelock";

	public static final String WAKELOCKTAGWIFI = "com.dcc.fieldtripbuffer.wakelockwifi";
}
