//C++ TO JAVA CONVERTER TODO TASK: There is no preprocessor in Java:
///#if __WIN32__ || __WIN64__
///#else
 /** for the tcp connection **/
///#endif

/* disable NAGLE packet merging algorithm, which can delay small
	packets by up to 30ms! */
//C++ TO JAVA CONVERTER TODO TASK: There is no preprocessor in Java:
///#if DISABLE_NAGLE
///#endif

//C++ TO JAVA CONVERTER TODO TASK: There is no preprocessor in Java:
///#if BLUETOOTH
///#endif



final class DefineConstants
{
	public static final int DEFAULTPORT = 4242; //*< default port number for the frontend server >*
	public static final int ZAAGCH = 13; //*< default channels for sawtooth signal >*
	public static final int MNCN = 1024; //*< maximum characters in filename
	public static final int TMSACKNOWLEDGE = 0x00;
	public static final int TMSCHANNELDATA = 0x01;
	public static final int TMSFRONTENDINFOREQ = 0x03;
	public static final int TMSRTCREADREQ = 0x06;
	public static final int TMSRTCDATA = 0x07;
	public static final int TMSRTCTIMEREADREQ = 0x1E;
	public static final int TMSRTCTIMEDATA = 0x1F;
	public static final int TMSFRONTENDINFO = 0x02;
	public static final int TMSKEEPALIVEREQ = 0x27;
	public static final int TMSVLDELTADATA = 0x2F;
	public static final int TMSVLDELTAINFOREQ = 0x30;
	public static final int TMSVLDELTAINFO = 0x31;
	public static final int TMSIDREADREQ = 0x22;
	public static final int TMSIDDATA = 0x23;
	public static final int TMSCFGSIZE = 1024;
	public static final String VERSION = "$Revision: 0.1 $";
	public static final int TMSBLOCKSYNC = 0xAAAA; //*< TMS block sync word
	public static final int RESPSIZE = 2048; // max size of the response message
}