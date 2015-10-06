package nl.dcc.fieldtripbuffer;

import nl.fcdonders.fieldtrip.bufferserver.FieldtripBufferMonitor;

/**
 * Class containing all the constants of this project.
 *
 * @author wieke
 *
 */
public final class C {
	public static final String FILTER = "com.dcc.fieldtripbuffer.filter";

	public static final String MESSAGE_TYPE = "a";
	public static final String BUFFER_INFO = "b";
	public static final String CLIENT_INFO = "c";

	public static final int UPDATE_REQUEST = 0;
	public static final int UPDATE = 1;
	public static final int REQUEST_PUT_HEADER = 2;
	public static final int REQUEST_FLUSH_HEADER = 3;
	public static final int REQUEST_FLUSH_SAMPLES = 4;
	public static final int REQUEST_FLUSH_EVENTS = 5;

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

	public static final String TAG = "fieldtripbuffer";

	public static final String WAKELOCKTAG = "com.dcc.fieldtripbuffer.wakelock";

	public static final String WAKELOCKTAGWIFI = "com.dcc.fieldtripbuffer.wakelockwifi";
}
