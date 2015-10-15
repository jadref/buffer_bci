package nl.dcc.buffer_bci.bufferclientsservice;

/**
 * Class containing all the constants of this project.
 *
 * @author wieke
 */
public final class C {
    public static final String FILTER_FOR_CLIENTS = "nl.dcc.buffer_bci.bufferclientsservice.clientsfilter";
    public static final String SEND_UPDATE_INFO_TO_CONTROLLER_ACTION = "nl.dcc.buffer_bci.bufferservicecontroller.action.UPDATEINFO";

    public static final String MESSAGE_TYPE = "a";
    public static final String THREAD_INDEX = "t_index";
    public static final String THREAD_ARGUMENTS = "t_args";
    public static final String THREAD_STRING_FOR_ARG = "t_arg_str";
    public static final String THREAD_ID = "t_id";
    public static final String THREAD_N_ARGUMENTS = "t_nArgs";
    public static final String IS_THREAD_INFO = "t_Info";
    public static final String THREAD_INFO = "t";

    public static final int THREAD_INFO_TYPE = 0;
    public static final int UPDATE = 1;
    public static final int THREAD_STOP = 6;
    public static final int THREAD_PAUSE = 7;
    public static final int THREAD_START = 8;
    public static final int THREAD_UPDATE_ARGUMENTS = 9;
    public static final int THREAD_UPDATE_ARG_FROM_STR = 10;
    public static final int THREAD_INFO_BROADCAST=11;
    public static final int CLIENTS_INFO_BROADCAST=12;

    public static final String WAKELOCKTAG = "nl.dcc.buffer_bci.bufferservice.wakelock";

    public static final String WAKELOCKTAGWIFI = "nl.dcc.buffer_bci.bufferservice.wakelockwifi";

}
